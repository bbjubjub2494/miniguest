{ runCommand, fakeroot }:

runCommand "miniguest-lxc-template" { nativeBuildInputs = [ fakeroot ]; } ''
  cat >config << EOF
  lxc.include = LXC_TEMPLATE_CONFIG/common.conf

  lxc.mount.entry = /nix/store nix/store none ro,bind,create=dir 0 0
  lxc.mount.entry = /etc/miniguests/LXC_NAME/boot boot none ro,bind,create=dir 0 0
  lxc.init.cmd = /boot/init
  EOF
  mkdir -p rootfs/{nix/store,boot}

  mkdir -p $out
  fakeroot tar cJf $out/rootfs.tar.xz -C rootfs .
  fakeroot tar cJf $out/meta.tar.xz config
''
