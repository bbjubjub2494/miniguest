source template_arg.bash

dest_dir="$_arg_dest_dir"

run_nix flake new -t github:bbjubjub2494/miniguest "$dest_dir"
