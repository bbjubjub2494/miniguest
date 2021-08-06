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

function run_nix {
	command "$nix" --experimental-features "nix-command flakes" "$@"
}

flake=
guest_name=

function parse_flake_reference {
	[[ $1 =~ ^(.*)\#([^\#\"]*)$ ]] || die "cannot parse flake reference"
	flake="${BASH_REMATCH[1]}"
	guest_name="${BASH_REMATCH[2]}"
}
