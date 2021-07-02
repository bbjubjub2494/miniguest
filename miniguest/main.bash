#! @bash@/bin/sh

source @out@/lib/main_arg.bash

guests_dir="$_arg_guests_dir"
nix="$_arg_nix"

source @out@/lib/functions.bash

if test "${_arg_command:?}" = install; then
	source @out@/lib/install.bash "${_arg_leftovers[@]}"
fi
