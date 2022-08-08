/* Copyright 2022 Louis Bettens
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

#include "error.hh"

namespace fs = std::filesystem;
using namespace nix;

Context ContextBuilder::build() {
  if (!symlink_path)
    fs::create_directory(default_symlinks_dir);
  if (!profile_path)
    fs::create_directory(default_profiles_dir);
  return {symlink_path.value_or(default_symlinks_dir / guest_name),
          profile_path.value_or(default_profiles_dir / guest_name)};
}

void Context::ensure_symlink() {
  auto st = fs::symlink_status(symlink_path);
  if (!fs::exists(st))
    fs::create_symlink(profile_path, symlink_path);
  else
    check_symlink(st);
}
void Context::check_symlink(const fs::file_status &st) {
  if (!fs::is_symlink(st) || fs::read_symlink(symlink_path) != profile_path)
    throw Error(1,
                "not touching symlink because it's not in an expected state");
}
void Context::remove_symlink() {
  auto st = fs::symlink_status(symlink_path);
  if (fs::exists(st))
    check_symlink(st);

  fs::remove(symlink_path);
}
