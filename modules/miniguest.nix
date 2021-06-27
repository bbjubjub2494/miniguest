inputs@{ nixpkgs, ... }:
{ baseModules, config, lib, pkgs, modules, specialArgs, system, ... }:

with lib;
let
  kvmConfig = nixpkgs.lib.nixosSystem {
    inherit baseModules specialArgs;
    system = config.nixpkgs.initialSystem;
    modules = [ profiles/kvm-guest.nix ] ++ modules;
  };
in
{
  options = {
    boot.miniguest = {
      enable = mkEnableOption "turn this configuration into a miniguest guest system.";
    };
  };

  config = mkIf config.boot.miniguest.enable {
    system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
      mkdir -p $out/boot
      cp -P ${kvmConfig.config.system.build.toplevel}/{kernel,initrd} -t $out
      ln -sT ${kvmConfig.config.system.build.toplevel}/init $out/boot/init
    '';
  };
}
