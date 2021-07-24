#! @bash@/bin/sh

source @out@/lib/main_arg.bash

guests_dir="$_arg_guests_dir"
profiles_dir="/nix/var/nix/profiles/miniguest-profiles"
nix="$_arg_nix"

source @out@/lib/functions.bash

if test "${_arg_command:?}" = install; then
	source @out@/lib/install.bash "${_arg_leftovers[@]}"
fi
