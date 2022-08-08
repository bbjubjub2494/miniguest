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

#include <filesystem>
#include <optional>

struct ContextBuilder final {
  std::string guest_name;
  std::optional<std::filesystem::path> symlink_path, profile_path;
  std::filesystem::path default_symlinks_dir = "/etc/miniguests",
                        default_profiles_dir =
                            "/nix/var/nix/profiles/miniguest-profiles";

  struct Context build();
};

struct Context final {
  const std::filesystem::path symlink_path, profile_path;

  void ensure_symlink();
  void remove_symlink();

private:
  Context(std::filesystem::path symlink_path,
          std::filesystem::path profile_path)
      : symlink_path(symlink_path), profile_path(profile_path) {}
  friend Context ContextBuilder::build();

  void check_symlink(const std::filesystem::file_status &st);
};
