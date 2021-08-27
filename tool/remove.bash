source remove_arg.bash

guest_name="$_arg_guest_name"

reset_profile "$guest_name"

have_control_of_symlink "$guest_name" && rm -f "$guests_dir/$guest_name"
