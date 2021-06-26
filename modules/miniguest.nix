{ config, lib, pkgs, ... }:

with lib;
{
  options = {
    boot.miniguest = {
      enable = mkEnableOption "turn this configuration into a miniguest guest system.";
    };
  };
  config = mkIf config.boot.miniguest.enable {
    imports = [ profiles/kvm-guest ];
    system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
      mkdir -p $out/boot
      cp ${config.system.build.toplevel}/{kernel,initrd} -t $out
      ln -sT ${config.system.build.toplevel}/init $out/boot/init
    '';
  };
}
