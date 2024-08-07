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

{ lib, ... }:

with lib;
{
  options = {
    boot.miniguest = {
      enable = mkEnableOption "turn this configuration into a miniguest guest system.";
      guestType = mkOption {
        description = "Which hypervisor technology this guest should be configured for.";
        default = "qemu";
        type = types.enum [ "qemu" "lxc" ];
      };
      qemu.fsType = mkOption {
        description = "Which shared file system to use to mount the host store";
        default = "9p";
        type = types.enum [ "9p" "virtiofs" ];
      };
    };
  };

  imports = [
    internal/build.nix
    internal/qemu-glue.nix
    internal/lxc-glue.nix
  ];
}
