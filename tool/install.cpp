/* Copyright 2022 Julie Bettens
 *
 * This file is part of the Miniguest companion.
 *
 * The Miniguest companion is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * Miniguest is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Miniguest.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "common.hpp"
#include "manifest.hpp"

#include "build-result.hh"
#include "command.hh"
#include "derived-path.hh"
#include "eval-cache.hh"

#include <iostream>
#include <vector>

using namespace nix;
namespace fs = std::filesystem;

namespace miniguest {

struct CmdInstall : virtual InstallableCommand, virtual MixProfile {
  std::optional<std::string> guest_name;
  bool force;

  CmdInstall() {
    addFlag({
        .longName = "force",
        .shortName = 'f',
        .description = "Override an existing guest",
        .handler = {&force, true},
    });
    addFlag({
        .longName = "name",
        .shortName = 'n',
        .description = "Name of the guest (default: attribute name)",
        .labels = {"name"},
        .handler = {&guest_name},
    });
  }

  std::string description() override {
    return "build the guest and install it into a nix profile";
  }

  std::string doc() override {
    return R""(miniguest install [-n|--name <arg>] <flake-reference>
	<flake-reference>: guest to build
	-f, --force: override an existing guest
	-n, --name: name of the profile (no default))"";
  }

  Strings getDefaultFlakeAttrPaths() override {
    return {"nixosConfigurations.default"};
  }
  Strings getDefaultFlakeAttrPathPrefixes() override {
    return {"nixosConfigurations."};
  }

  void run(ref<Store> store) override {
    auto evalState = getEvalState();

    if (!guest_name)
      guest_name = installable->getCursor(*evalState)->getAttrPath().back();

    ContextBuilder bld;
    bld.guest_name = *guest_name;
    if (profile)
      bld.profile_path = *profile;

    Context ctx = bld.build();
    profile = ctx.profile_path.native();
    ProfileManifest manifest(*getEvalState(), *profile);

    if (!manifest.elements.empty() && !force)
      throw Error("A guest named “" + *guest_name +
                  "” is already installed! use --force to replace it");

    auto installableFlake =
        std::static_pointer_cast<InstallableFlake>(installable);
    for (auto &a : installableFlake->attrPaths)
      a += ".config.system.build.miniguest";
    auto result = Installable::build(getEvalStore(), store, Realise::Outputs,
                                     {installable});

    auto [attrPath, resolvedRef, drv] = installableFlake->toDerivation();

    ProfileElement element;
    element.source = {installableFlake->flakeRef, resolvedRef, attrPath};
    element.updateStorePaths(getEvalStore(), store, result);
    manifest.elements = {element};
    updateProfile(manifest.build(store));

    ctx.ensure_symlink();
  }

  virtual ~CmdInstall() = default;
};

static auto rCmdInstall = registerCommand<CmdInstall>("install");

} // namespace miniguest
