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

function run_nix {
	command "$nix" --experimental-features "nix-command flakes ca-references" "$@"
}

flake=
guest_name=

function parse_flake_reference {
	[[ $1 =~ ^(.*)\#([^\#\"]*)$ ]] || die "cannot parse flake reference"
	flake="${BASH_REMATCH[1]}"
	guest_name="${BASH_REMATCH[2]}"
}

function install_profile {
	[[ $# -eq 2 ]] || die "$FUNCNAME: wrong number of arguments!"
	local guest_name="$1"
	local target="$2"
	run_nix profile install --profile "$profiles_dir/$guest_name" "$target" ||
		die "unable to install $guest_name!" $?
}

function upgrade_profile {
	[[ $# -eq 1 ]] || die "$FUNCNAME: wrong number of arguments!"
	local guest_name="$1"
	run_nix profile upgrade --profile "$profiles_dir/$guest_name" ||
		die "unable to upgrade $guest_name!" $?
}

function reset_profile {
	[[ $# -eq 1 ]] || die "$FUNCNAME: wrong number of arguments!"
	local guest_name="$1"
	run_nix profile remove --profile "$profiles_dir/$guest_name" '.*' ||
		die "unable to remove guest!" $?
}

function have_control_of_symlink {
	[[ $# -eq 1 ]] || die "$FUNCNAME: wrong number of arguments!"
	local symlink="$guests_dir/$guest_name"
	[[ ! -e $symlink || -L $symlink && $(readlink $symlink) -ef "$profiles_dir/$guest_name" ]] || {
		echo >&2 "not touching $guests_dir/$guest_name because it's not in an expected state"
		false
	}
}
