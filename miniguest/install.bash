# Copyright 2021 Julie Bettens
#
# This file is part of the Miniguest companion.
#
# The Miniguest companion is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Miniguest is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Miniguest.  If not, see <https://www.gnu.org/licenses/>.

source install_arg.bash

parse_flake_reference "$_arg_flake_reference"

mkdir -p "$guests_dir" || die "" $?
mkdir -p "$profiles_dir" || die "" $?
run_nix build --profile "$profiles_dir/$guest_name" "$flake#nixosConfigurations.$guest_name.config.system.build.miniguest" || die "unable to build guest!" $?
ln -sf "$profiles_dir/$guest_name" "$guests_dir" || die "" $?
