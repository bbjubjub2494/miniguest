inputs@{ self, nixpkgs, ... }: system:

with nixpkgs.lib;
let
  declarative_host = nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.declarative
      {
        boot.isContainer = true;
        miniguests.virtual-machine.configuration = {
          boot.miniguest.enable = true;

          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults" "mode=755" ];
          };
        };
        miniguests.container.configuration = {
          boot.miniguest.enable = true;
          boot.miniguest.guestType = "lxc";
        };
      }
    ];
  };
in
with nixpkgs.legacyPackages.${system};
optionalAttrs stdenv.isLinux {
  build_declarative_host = declarative_host.config.system.build.toplevel;
}
