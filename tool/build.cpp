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
#include "local-fs-store.hh"

#include <cassert>
#include <iostream>
#include <vector>

using namespace nix;
namespace fs = std::filesystem;

struct CmdBuild : virtual InstallableCommand {
  std::optional<std::string> guest_name;

  CmdBuild() {
    addFlag({
        .longName = "name",
        .shortName = 'n',
        .description = "Name of the guest (default: attribute name)",
        .labels = {"name"},
        .handler = {&guest_name},
    });
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

    auto installableFlake =
        std::static_pointer_cast<InstallableFlake>(installable);
    for (auto &a : installableFlake->attrPaths)
      a += ".config.system.build.miniguest";
    auto result = Installable::build(getEvalStore(), store, Realise::Outputs,
                                     {installable});

    auto symlink = absPath("result");
    store.dynamic_pointer_cast<LocalFSStore>()->addPermRoot(result[0], symlink);

    // todo: link result
  }

  virtual ~CmdBuild() = default;
};

static auto rCmdBuild = registerCommand<CmdBuild>("build");
