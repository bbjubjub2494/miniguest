/** Copyright Nix contributors
 * Distributed under the GNU LGPL-2.1 license
 *
 * from Nix 2.8.1
 */
#include "archive.hh"
#include "builtins/buildenv.hh"
#include "command.hh"
#include "common-args.hh"
#include "derivations.hh"
#include "flake/flakeref.hh"
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
// from nix/profile.cc
struct ProfileElementSource
{
    FlakeRef originalRef;
    // FIXME: record original attrpath.
    FlakeRef resolvedRef;
    std::string attrPath;
    // FIXME: output names

    bool operator < (const ProfileElementSource & other) const
    {
        return
            std::pair(originalRef.to_string(), attrPath) <
            std::pair(other.originalRef.to_string(), other.attrPath);
    }
};

struct ProfileElement
{
    StorePathSet storePaths;
    std::optional<ProfileElementSource> source;
    bool active = true;
    // FIXME: priority

    std::string describe() const
    {
        if (source)
            return fmt("%s#%s", source->originalRef, source->attrPath);
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
        // FIXME: respect meta.outputsToInstall
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
            switch(version){
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
                if (e.value(sUrl,"") != "") {
                    element.source = ProfileElementSource{
                        parseFlakeRef(e[sOriginalUrl]),
                        parseFlakeRef(e[sUrl]),
                        e["attrPath"]
                    };
                }
                elements.emplace_back(std::move(element));
            }
        }

	/*
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
	*/
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
            if (element.source) {
                obj["originalUrl"] = element.source->originalRef.to_string();
                obj["url"] = element.source->resolvedRef.to_string();
                obj["attrPath"] = element.source->attrPath;
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
                    pkgs.emplace_back(store->printStorePath(path), true, 5);
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
