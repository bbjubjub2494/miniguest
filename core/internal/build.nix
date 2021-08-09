# Copyright 2021 Louis Bettens
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

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.boot.miniguest;
in
mkIf cfg.enable {
  system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
      mkdir -p $out/boot
      ln -sT ${config.system.build.toplevel}/init $out/boot/init
    ${lib.optionalString (cfg.guestType == "qemu")
    "cp -P ${config.system.build.toplevel}/{kernel,initrd} -t $out"
    }
  '';
}
