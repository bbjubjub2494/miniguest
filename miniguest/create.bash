source create_arg.bash

name="$_arg_guest_name"

set_color_red=$'\e[1m\e[31m'
reset_color=$'\e(B\e[m'

case "${_arg_hypervisor:?}" in
libvirt)
	cat <<EOF
# Create $name using:
virt-install \\
  --connect qemu:///system \\
  -n $name --os-variant nixos-unstable \\
  --memory 1536 \\
  --disk none \\
  --import \\
  --boot kernel=/etc/miniguests/$name/kernel,initrd=$guests_dir/$name/initrd \\
  --filesystem /nix/store,nix-store,readonly=yes,accessmode=squash \\
  --filesystem /etc/miniguests/$name/boot,boot,readonly=yes,accessmode=squash \\

EOF
	;;
lxc)
	cat <<EOF
#$set_color_red WARNING: make sure root is uid-mapped, otherwise you might experience store corruption in the host!$reset_color
# Create $name using:
lxc-create $name \\
  -f extra-config \\
  -t local -- \\
  -m @lxc_template@/meta.tar.xz \\
  -f @lxc_template@/rootfs.tar.xz \\

EOF
	;;
esac
