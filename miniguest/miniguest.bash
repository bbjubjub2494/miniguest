guestsDir=/etc/miniguests

function nix {
	@nixFlakes@/bin/nix --experimental-features "nix-command flakes" "$@"
}

function err {
	echo >&2 "$@"
}

function fail_with {
	local status=$1
	shift
	test "$status" -gt 0 || fail "internal: bad status"
	if [ $# -gt 0 ]; then
		err "$@"
	fi
	exit "$status"
}

function fail {
	fail_with 1 "$@"
}

function usage {
	cat >&2 <<END
usage: miniguest install <flake reference>
END
}

function fail_with_usage {
	usage
	fail_with 2
}

function parse_flake_reference {
	[[ $1 =~ ^(.*)\#([^\#\"]*)$ ]] || fail "cannot parse flake reference"
	flake="${BASH_REMATCH[1]}"
	guestName="${BASH_REMATCH[2]}"
}

# parse common flags
while
	arg="$1"
	shift
do
	case "$arg" in
	install)
		doInstall=yes
		break
		;;
	*)
		err "unrecognized: $arg"
		fail_with_usage
		;;
	esac
done

# parse install subcommand flags
while
	arg="$1"
	test $doInstall && shift
do
	case "$arg" in
	*)
		if test ! -v flake; then
			parse_flake_reference "$arg"
		else
			fail_with_usage
		fi
		;;
	esac
done

test -v flake || fail_with_usage

if test $doInstall; then
	mkdir -p "$guestsDir" || fail
	nix build --profile "$guestsDir/$guestName" "$flake#nixosConfigurations.$guestName.config.system.build.miniguest" || fail
fi
