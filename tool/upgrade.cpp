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

#include <cassert>
#include <iostream>
#include <vector>

using namespace nix;
namespace fs = std::filesystem;

struct CmdUpgrade : virtual EvalCommand, virtual MixProfile {
  std::string guest_name;

  CmdUpgrade() { expectArg("name", &guest_name); }

  void run(ref<Store> store) override {
    ContextBuilder bld;
    bld.guest_name = guest_name;
    if (profile)
      bld.profile_path = *profile;

    Context ctx = bld.build();
    profile = ctx.profile_path.native();

    ProfileManifest manifest(*getEvalState(), *profile);

    for (auto &element : manifest.elements) {
      if (!element.source || element.source->originalRef.input.isLocked())
        continue;

      auto installable = std::make_shared<InstallableFlake>(
          nullptr, getEvalState(), FlakeRef(element.source->originalRef), "",
          Strings{element.source->attrPath}, Strings{}, flake::LockFlags{});
      auto [attrPath, resolvedRef, drv] = installable->toDerivation();
      if (element.source->resolvedRef == resolvedRef)
        continue;
      printInfo("upgrading '%s' from flake '%s' to '%s'",
                element.source->attrPath, element.source->resolvedRef,
                resolvedRef);
      auto result = Installable::build(getEvalStore(), store, Realise::Outputs,
                                       {installable});

      element.source = {installable->flakeRef, resolvedRef, attrPath};
      element.updateStorePaths(getEvalStore(), store, result);
    }
    updateProfile(manifest.build(store));
  }

  virtual ~CmdUpgrade() = default;
};

static auto rCmdUpgrade = registerCommand<CmdUpgrade>("upgrade");
