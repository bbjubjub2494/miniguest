# Copyright 2022 Julie Bettens
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

{ config, lib, ... }:

# Mix-in for a QEMU or KVM mini-guest.

with lib;
let
  cfg = config.boot.miniguest;
in
mkIf (cfg.enable && cfg.guestType == "qemu") {
  fileSystems."/boot" = {
    device = "boot";
    inherit (cfg.qemu) fsType;
    neededForBoot = true;
  };

  fileSystems."/nix/store" = {
    device = "nix-store";
    inherit (cfg.qemu) fsType;
  };

  boot.initrd.availableKernelModules = getAttr cfg.qemu.fsType {
    "9p" = [ "virtio_pci" "9p" "9pnet_virtio" ];
    virtiofs = [ "virtio_pci" "virtiofs" ];
  };

  boot.initrd.postMountCommands = ''
    test "$stage2Init" = /init && stage2Init=/boot/init
  '';

  boot.loader.grub.enable = mkDefault false;
}
