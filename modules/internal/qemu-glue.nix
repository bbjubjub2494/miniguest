{ config, lib, ... }:

# Mix-in for a QEMU or KVM mini-guest.

with lib;
let
  cfg = config.boot.miniguest;
in
mkIf (cfg.enable && cfg.guestType == "qemu") {
  fileSystems."/boot" = {
    device = "boot";
    fsType = "9p";
    neededForBoot = true;
  };

  fileSystems."/nix/store" = {
    device = "nix-store";
    fsType = "9p";
  };

  boot.initrd.postMountCommands = ''
    test "$stage2Init" = /init && stage2Init=/boot/init
  '';

  boot.loader.grub.enable = mkDefault false;
}
