function run_nix {
	@nixFlakes@/bin/nix --experimental-features "nix-command flakes" "$@"
}

flake=
guest_name=

function parse_flake_reference {
	[[ $1 =~ ^(.*)\#([^\#\"]*)$ ]] || die "cannot parse flake reference"
	flake="${BASH_REMATCH[1]}"
	guest_name="${BASH_REMATCH[2]}"
}
