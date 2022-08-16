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

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.boot.miniguest;
  closureInfo = pkgs.closureInfo {
    rootPaths = [ config.system.build.toplevel ];
  };
in
mkIf cfg.enable {
  system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
      mkdir -p $out/boot
      ln -sT ${config.system.build.toplevel}/init $out/boot/init
      cp ${closureInfo}/registration $out/boot/nix-path-registration
    ln -s ${pkgs.writeText "miniguest-config.json" (builtins.toJSON cfg)} $out/miniguest-config.json
    ${lib.optionalString (cfg.guestType == "qemu")
    "cp -P ${config.system.build.toplevel}/{kernel,initrd} -t $out"
    }
  '';

  # based on nixos/modules/profiles/docker-container.nix
  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store in the Nix
    # database.
    if [ -f /boot/nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /boot/nix-path-registration
    fi
    # nixos-rebuild also requires a "system" profile
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  '';
}
