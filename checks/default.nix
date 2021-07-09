inputs@{ self, nixpkgs, ... }:
system:
let
  kvm_guest = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.miniguest
      {
        boot.miniguest.enable = true;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
          options = [ "defaults" "mode=755" ];
        };
      }
    ];
  };
  lxc_guest = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.miniguest
      {
        boot.miniguest.enable = true;
        boot.miniguest.hypervisor = "lxc";
      }
    ];
  };
in
with nixpkgs.legacyPackages.${system};
lib.optionalAttrs stdenv.isLinux {
  build_kvm_guest = kvm_guest.config.system.build.miniguest;
  build_lxc_guest = lxc_guest.config.system.build.miniguest;
}
