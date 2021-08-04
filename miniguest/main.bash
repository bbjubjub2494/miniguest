#! @bash@/bin/sh

# Copyright 2021 Louis Bettens
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

source main_arg.bash

guests_dir="$_arg_guests_dir"
profiles_dir="/nix/var/nix/profiles/miniguest-profiles"
nix="$_arg_nix"

source functions.bash

set -- "${_arg_leftovers[@]}" # reset parameters to subcommand arguments
if test "${_arg_command:?}" = install; then
	source install.bash
elif test "${_arg_command:?}" = create; then
	source create.bash
fi
