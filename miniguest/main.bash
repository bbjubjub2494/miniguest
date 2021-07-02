#! @bash@/bin/sh

source @out@/lib/main_arg.bash

source @out@/lib/functions.bash

guests_dir="$_arg_guests_dir"
if test "${_arg_command:?}" = install; then
	source @out@/lib/install.bash "${_arg_leftovers[@]}"
fi
