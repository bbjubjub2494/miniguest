source @out@/lib/install_arg.bash

parse_flake_reference "$_arg_flake_reference"

mkdir -p "$guests_dir" || die "" $?
run_nix build --profile "$guests_dir/$guest_name" "$flake#nixosConfigurations.$guest_name.config.system.build.miniguest" || die "unable to build guest!" $?
