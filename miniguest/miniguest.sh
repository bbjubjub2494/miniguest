guestsDir=/etc/miniguests

function fail_with {
	local status=$1; shift
	test $status -gt 0 || fail "internal: bad status"
	if [ $# -gt 0 ]; then
		echo >&2 $*
	fi
	exit $status
}

function fail {
  fail_with 1 "$@"
}

function usage {
cat >&2 << END
usage: miniguest [guest-name]
END
}

function fail_with_usage {
	usage
	fail_with 2
}

# restrict the character range out of caution
function validate_guest_name {
[[ $guestName =~ ^[-[:graph:]]+$ ]] || fail "illegal guest name"
}

while arg="$1"; shift; do
	case "$arg" in
		*)
			if [ ! -v guestName ]; then
				guestName="$arg"
			else
			fail_with_usage
			fi
			;;
	esac
done

test -v guestName || fail_with_usage

validate_guest_name

mkdir -p "$guestsDir" || fail

nix build --profile "$guestsDir/$guestName" ".#nixosConfigurations.$guestName.config.system.build.miniguest" || fail
