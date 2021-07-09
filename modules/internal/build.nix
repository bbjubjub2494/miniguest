{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.boot.miniguest;
in
mkIf cfg.enable {
  system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
      mkdir -p $out/boot
      ln -sT ${config.system.build.toplevel}/init $out/boot/init
    ${lib.optionalString (cfg.hypervisor == "qemu")
    "cp -P ${config.system.build.toplevel}/{kernel,initrd} -t $out"
    }
  '';
}
