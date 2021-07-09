{ lib, ... }:

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

  imports = [
    internal/build.nix
    internal/qemu-glue.nix
    internal/lxc-glue.nix
  ];
}
