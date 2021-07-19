{ config, lib, ... }:

# Mix-in for a LXC container mini-guest.

with lib;
let cfg = config.boot.miniguest;
in
mkIf (cfg.enable && cfg.guestType == "lxc") {
  warnings = lib.optional (cfg.storeCorruptionWarning) ''
    Running a guest in LXC without enabling UID mapping or otherwise confining the guest's superuser can result in host store corruption!
    Double-check your container settings!
    You can suppress this warning with:
      boot.miniguest.storeCorruptionWarning = false;
  '';
  boot.isContainer = mkDefault true;
}
