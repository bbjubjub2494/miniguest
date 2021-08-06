#! @bash@/bin/sh

source main_arg.bash

guests_dir="$_arg_guests_dir"
profiles_dir="/nix/var/nix/profiles/miniguest-profiles"
nix="$_arg_nix"

source functions.bash

if test "${_arg_command:?}" = install; then
	source install.bash "${_arg_leftovers[@]}"
fi
