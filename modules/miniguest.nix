inputs@{ nixpkgs, ... }:
{ baseModules, config, lib, pkgs, modules, specialArgs, system, ... }:

with lib;
{
  options = {
    boot.miniguest = {
      enable = mkEnableOption "turn this configuration into a miniguest guest system.";
      hypervisor = mkOption {
        description = "Which hypervisor family this guest should be configured for.";
        default = "qemu";
        type = types.enum [ "qemu" "lxc" ];
      };
    };
  };

  config =
    let
      cfg = config.boot.miniguest;
      guestConfig = nixpkgs.lib.nixosSystem {
        inherit baseModules specialArgs;
        system = config.nixpkgs.initialSystem;
        modules = [ (./profiles + "/${cfg.hypervisor}-guest.nix") ] ++ modules;
      };
      inherit (guestConfig.config.system.build) toplevel;
    in
    mkIf cfg.enable {
      system.build.miniguest = pkgs.runCommand "miniguest-${config.system.name}-${config.system.nixos.label}" { } ''
          mkdir -p $out/boot
          ln -sT ${guestConfig.config.system.build.toplevel}/init $out/boot/init
        ${lib.optionalString (cfg.hypervisor == "qemu")
        "cp -P ${guestConfig.config.system.build.toplevel}/{kernel,initrd} -t $out"
        }
      '';
    };
}
