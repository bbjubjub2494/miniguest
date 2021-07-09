{ config, lib, ... }:

# Mix-in for a LXC container mini-guest.

with lib;
let cfg = config.boot.miniguest;
in
mkIf (cfg.enable && cfg.hypervisor == "lxc") {
  boot.isContainer = mkDefault true;
}
