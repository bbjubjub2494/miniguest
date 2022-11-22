/** Copyright Nix contributors
 * Distributed under the GNU LGPL-2.1 license
 *
 * from Nix 2.11.0
 */
#include "archive.hh"
#include "builtins/buildenv.hh"
#include "command.hh"
#include "common-args.hh"
#include "derivations.hh"
#include "flake/flakeref.hh"
#include "get-drvs.hh"
#include "local-fs-store.hh"
#include "names.hh"
#include "profiles.hh"
#include "shared.hh"
#include "store-api.hh"

#include <iomanip>
#include <nlohmann/json.hpp>
#include <regex>

// don't reformat copypasted code
// clang-format off

namespace nix {
// from nix-env/user-env.cc
inline DrvInfos queryInstalled(EvalState & state, const Path & userEnv)
{
    DrvInfos elems;
    if (pathExists(userEnv + "/manifest.json"))
        throw Error("profile '%s' is incompatible with 'nix-env'; please use 'nix profile' instead", userEnv);
    Path manifestFile = userEnv + "/manifest.nix";
    if (pathExists(manifestFile)) {
        Value v;
        state.evalFile(manifestFile, v);
        Bindings & bindings(*state.allocBindings(0));
        getDerivations(state, v, "", bindings, elems, false);
    }
    return elems;
}

inline bool createUserEnv(EvalState & state, DrvInfos & elems,
    const Path & profile, bool keepDerivations,
    const std::string & lockToken)
{
    /* Build the components in the user environment, if they don't
       exist already. */
    std::vector<StorePathWithOutputs> drvsToBuild;
    for (auto & i : elems)
        if (auto drvPath = i.queryDrvPath())
            drvsToBuild.push_back({*drvPath});

    debug(format("building user environment dependencies"));
    state.store->buildPaths(
        toDerivedPaths(drvsToBuild),
        state.repair ? bmRepair : bmNormal);

    /* Construct the whole top level derivation. */
    StorePathSet references;
    Value manifest;
    state.mkList(manifest, elems.size());
    size_t n = 0;
    for (auto & i : elems) {
        /* Create a pseudo-derivation containing the name, system,
           output paths, and optionally the derivation path, as well
           as the meta attributes. */
        std::optional<StorePath> drvPath = keepDerivations ? i.queryDrvPath() : std::nullopt;
        DrvInfo::Outputs outputs = i.queryOutputs(true, true);
        StringSet metaNames = i.queryMetaNames();

        auto attrs = state.buildBindings(7 + outputs.size());

        attrs.alloc(state.sType).mkString("derivation");
        attrs.alloc(state.sName).mkString(i.queryName());
        auto system = i.querySystem();
        if (!system.empty())
            attrs.alloc(state.sSystem).mkString(system);
        attrs.alloc(state.sOutPath).mkString(state.store->printStorePath(i.queryOutPath()));
        if (drvPath)
            attrs.alloc(state.sDrvPath).mkString(state.store->printStorePath(*drvPath));

        // Copy each output meant for installation.
        auto & vOutputs = attrs.alloc(state.sOutputs);
        state.mkList(vOutputs, outputs.size());
        for (const auto & [m, j] : enumerate(outputs)) {
            (vOutputs.listElems()[m] = state.allocValue())->mkString(j.first);
            auto outputAttrs = state.buildBindings(2);
            outputAttrs.alloc(state.sOutPath).mkString(state.store->printStorePath(*j.second));
            attrs.alloc(j.first).mkAttrs(outputAttrs);

            /* This is only necessary when installing store paths, e.g.,
               `nix-env -i /nix/store/abcd...-foo'. */
            state.store->addTempRoot(*j.second);
            state.store->ensurePath(*j.second);

            references.insert(*j.second);
        }

        // Copy the meta attributes.
        auto meta = state.buildBindings(metaNames.size());
        for (auto & j : metaNames) {
            Value * v = i.queryMeta(j);
            if (!v) continue;
            meta.insert(state.symbols.create(j), v);
        }

        attrs.alloc(state.sMeta).mkAttrs(meta);

        (manifest.listElems()[n++] = state.allocValue())->mkAttrs(attrs);

        if (drvPath) references.insert(*drvPath);
    }

    /* Also write a copy of the list of user environment elements to
       the store; we need it for future modifications of the
       environment. */
    std::ostringstream str;
    manifest.print(state.symbols, str, true);
    auto manifestFile = state.store->addTextToStore("env-manifest.nix",
        str.str(), references);

    /* Get the environment builder expression. */
    Value envBuilder;
    state.eval(state.parseExprFromString(R"(
{ derivations, manifest }:

derivation {
  name = "user-environment";
  system = "builtin";
  builder = "builtin:buildenv";

  inherit manifest;

  # !!! grmbl, need structured data for passing this in a clean way.
  derivations =
    map (d:
      [ (d.meta.active or "true")
        (d.meta.priority or 5)
        (builtins.length d.outputs)
      ] ++ map (output: builtins.getAttr output d) d.outputs)
      derivations;

  # Building user environments remotely just causes huge amounts of
  # network traffic, so don't do that.
  preferLocalBuild = true;

  # Also don't bother substituting.
  allowSubstitutes = false;
}
            )", "/"), envBuilder);

    /* Construct a Nix expression that calls the user environment
       builder with the manifest as argument. */
    auto attrs = state.buildBindings(3);
    attrs.alloc("manifest").mkString(
        state.store->printStorePath(manifestFile),
        {state.store->printStorePath(manifestFile)});
    attrs.insert(state.symbols.create("derivations"), &manifest);
    Value args;
    args.mkAttrs(attrs);

    Value topLevel;
    topLevel.mkApp(&envBuilder, &args);

    /* Evaluate it. */
    debug("evaluating user environment builder");
    state.forceValue(topLevel, [&]() { return topLevel.determinePos(noPos); });
    PathSet context;
    Attr & aDrvPath(*topLevel.attrs->find(state.sDrvPath));
    auto topLevelDrv = state.coerceToStorePath(aDrvPath.pos, *aDrvPath.value, context);
    Attr & aOutPath(*topLevel.attrs->find(state.sOutPath));
    auto topLevelOut = state.coerceToStorePath(aOutPath.pos, *aOutPath.value, context);

    /* Realise the resulting store expression. */
    debug("building user environment");
    std::vector<StorePathWithOutputs> topLevelDrvs;
    topLevelDrvs.push_back({topLevelDrv});
    state.store->buildPaths(
        toDerivedPaths(topLevelDrvs),
        state.repair ? bmRepair : bmNormal);

    /* Switch the current user environment to the output path. */
    auto store2 = state.store.dynamic_pointer_cast<LocalFSStore>();

    if (store2) {
        PathLocks lock;
        lockProfile(lock, profile);

        Path lockTokenCur = optimisticLockProfile(profile);
        if (lockToken != lockTokenCur) {
            printInfo("profile '%1%' changed while we were busy; restarting", profile);
            return false;
        }

        debug(format("switching to new user environment"));
        Path generation = createGeneration(ref<LocalFSStore>(store2), profile, topLevelOut);
        switchLink(profile, generation);
    }

    return true;
}

// from nix/profile.cc
struct ProfileElementSource
{
    FlakeRef originalRef;
    // FIXME: record original attrpath.
    FlakeRef resolvedRef;
    std::string attrPath;
    OutputsSpec outputs;

    bool operator < (const ProfileElementSource & other) const
    {
        return
            std::tuple(originalRef.to_string(), attrPath, outputs) <
            std::tuple(other.originalRef.to_string(), other.attrPath, other.outputs);
    }
};

struct ProfileElement
{
    StorePathSet storePaths;
    std::optional<ProfileElementSource> source;
    bool active = true;
    int priority = 5;

    std::string describe() const
    {
        if (source)
            return fmt("%s#%s%s", source->originalRef, source->attrPath, printOutputsSpec(source->outputs));
        StringSet names;
        for (auto & path : storePaths)
            names.insert(DrvName(path.name()).name);
        return concatStringsSep(", ", names);
    }

    std::string versions() const
    {
        StringSet versions;
        for (auto & path : storePaths)
            versions.insert(DrvName(path.name()).version);
        return showVersions(versions);
    }

    bool operator < (const ProfileElement & other) const
    {
        return std::tuple(describe(), storePaths) < std::tuple(other.describe(), other.storePaths);
    }

    void updateStorePaths(
        ref<Store> evalStore,
        ref<Store> store,
        const BuiltPaths & builtPaths)
    {
        storePaths.clear();
        for (auto & buildable : builtPaths) {
            std::visit(overloaded {
                [&](const BuiltPath::Opaque & bo) {
                    storePaths.insert(bo.path);
                },
                [&](const BuiltPath::Built & bfd) {
                    for (auto & output : bfd.outputs)
                        storePaths.insert(output.second);
                },
            }, buildable.raw());
        }
    }
};

struct ProfileManifest
{
    std::vector<ProfileElement> elements;

    ProfileManifest() { }

    ProfileManifest(EvalState & state, const Path & profile)
    {
        auto manifestPath = profile + "/manifest.json";

        if (pathExists(manifestPath)) {
            auto json = nlohmann::json::parse(readFile(manifestPath));

            auto version = json.value("version", 0);
            std::string sUrl;
            std::string sOriginalUrl;
            switch (version) {
                case 1:
                    sUrl = "uri";
                    sOriginalUrl = "originalUri";
                    break;
                case 2:
                    sUrl = "url";
                    sOriginalUrl = "originalUrl";
                    break;
                default:
                    throw Error("profile manifest '%s' has unsupported version %d", manifestPath, version);
            }

            for (auto & e : json["elements"]) {
                ProfileElement element;
                for (auto & p : e["storePaths"])
                    element.storePaths.insert(state.store->parseStorePath((std::string) p));
                element.active = e["active"];
                if(e.contains("priority")) {
                    element.priority = e["priority"];
                }
                if (e.value(sUrl, "") != "") {
                    element.source = ProfileElementSource {
                        parseFlakeRef(e[sOriginalUrl]),
                        parseFlakeRef(e[sUrl]),
                        e["attrPath"],
                        e["outputs"].get<OutputsSpec>()
                    };
                }
                elements.emplace_back(std::move(element));
            }
        }

        else if (pathExists(profile + "/manifest.nix")) {
            // FIXME: needed because of pure mode; ugly.
            state.allowPath(state.store->followLinksToStore(profile));
            state.allowPath(state.store->followLinksToStore(profile + "/manifest.nix"));

            auto drvInfos = queryInstalled(state, state.store->followLinksToStore(profile));

            for (auto & drvInfo : drvInfos) {
                ProfileElement element;
                element.storePaths = {drvInfo.queryOutPath()};
                elements.emplace_back(std::move(element));
            }
        }
    }

    std::string toJSON(Store & store) const
    {
        auto array = nlohmann::json::array();
        for (auto & element : elements) {
            auto paths = nlohmann::json::array();
            for (auto & path : element.storePaths)
                paths.push_back(store.printStorePath(path));
            nlohmann::json obj;
            obj["storePaths"] = paths;
            obj["active"] = element.active;
            obj["priority"] = element.priority;
            if (element.source) {
                obj["originalUrl"] = element.source->originalRef.to_string();
                obj["url"] = element.source->resolvedRef.to_string();
                obj["attrPath"] = element.source->attrPath;
                obj["outputs"] = element.source->outputs;
            }
            array.push_back(obj);
        }
        nlohmann::json json;
        json["version"] = 2;
        json["elements"] = array;
        return json.dump();
    }

    StorePath build(ref<Store> store)
    {
        auto tempDir = createTempDir();

        StorePathSet references;

        Packages pkgs;
        for (auto & element : elements) {
            for (auto & path : element.storePaths) {
                if (element.active)
                    pkgs.emplace_back(store->printStorePath(path), true, element.priority);
                references.insert(path);
            }
        }

        buildProfile(tempDir, std::move(pkgs));

        writeFile(tempDir + "/manifest.json", toJSON(*store));

        /* Add the symlink tree to the store. */
        StringSink sink;
        dumpPath(tempDir, sink);

        auto narHash = hashString(htSHA256, sink.s);

        ValidPathInfo info {
            store->makeFixedOutputPath(FileIngestionMethod::Recursive, narHash, "profile", references),
            narHash,
        };
        info.references = std::move(references);
        info.narSize = sink.s.size();
        info.ca = FixedOutputHash { .method = FileIngestionMethod::Recursive, .hash = info.narHash };

        StringSource source(sink.s);
        store->addToStore(info, source);

        return std::move(info.path);
    }

    static void printDiff(const ProfileManifest & prev, const ProfileManifest & cur, std::string_view indent)
    {
        auto prevElems = prev.elements;
        std::sort(prevElems.begin(), prevElems.end());

        auto curElems = cur.elements;
        std::sort(curElems.begin(), curElems.end());

        auto i = prevElems.begin();
        auto j = curElems.begin();

        bool changes = false;

        while (i != prevElems.end() || j != curElems.end()) {
            if (j != curElems.end() && (i == prevElems.end() || i->describe() > j->describe())) {
                std::cout << fmt("%s%s: ∅ -> %s\n", indent, j->describe(), j->versions());
                changes = true;
                ++j;
            }
            else if (i != prevElems.end() && (j == curElems.end() || i->describe() < j->describe())) {
                std::cout << fmt("%s%s: %s -> ∅\n", indent, i->describe(), i->versions());
                changes = true;
                ++i;
            }
            else {
                auto v1 = i->versions();
                auto v2 = j->versions();
                if (v1 != v2) {
                    std::cout << fmt("%s%s: %s -> %s\n", indent, i->describe(), v1, v2);
                    changes = true;
                }
                ++i;
                ++j;
            }
        }

        if (!changes)
            std::cout << fmt("%sNo changes.\n", indent);
    }
};
}
