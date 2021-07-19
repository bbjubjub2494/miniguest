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
      storeCorruptionWarning = mkOption {
        description = "Whether to display a warning about container guests being able to corrupt the Nix store.";
        default = true;
        type = types.bool;
      };
    };
  };

  imports = [
    internal/build.nix
    internal/qemu-glue.nix
    internal/lxc-glue.nix
  ];
}
