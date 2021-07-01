inputs@{ self, nixpkgs, ... }:
final: prev:

let
  kvm_guest = nixpkgs.lib.nixosSystem {
    inherit (final) system;
    modules = [
      self.nixosModules.miniguest
      {
        boot.miniguest.enable = true;
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
          options = [ "defaults" "mode=755" ];
        };
      }
    ];
  };
in
final.lib.optionalAttrs final.stdenv.isLinux {
  build_kvm_guest = kvm_guest.config.system.build.miniguest;
}
