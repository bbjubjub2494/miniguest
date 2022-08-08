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

struct CmdRemove : virtual EvalCommand, virtual MixProfile {
  std::string guest_name;

  CmdRemove() {
    expectArg("name", &guest_name);
  }

  std::string description() override {
    return "uninstall a guest";
  }

  std::string doc() override {
    return R""(miniguest remove [-h|--help] <guest-name>
	<guest-name>: name of guest to remove
	-h, --help: Prints help)"";
  }

  void run(ref<Store> store) override {
    ContextBuilder bld;
    bld.guest_name = guest_name;
    if (profile)
      bld.profile_path = *profile;

    Context ctx = bld.build();
    profile = ctx.profile_path.native();

    // reset profile first
    ProfileManifest manifest(*getEvalState(), *profile);
    manifest.elements.clear();
    updateProfile(manifest.build(store));

    // then clean the symlink
    ctx.remove_symlink();
  }

  virtual ~CmdRemove() = default;
};

static auto rCmdRemove = registerCommand<CmdRemove>("remove");
