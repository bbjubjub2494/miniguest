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
  declarative_host_cross = if system != "x86_64-linux" then null else
  nixosSystem {
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
        miniguests.container.system = "i686-linux";
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
} // optionalAttrs (stdenv.isLinux && stdenv.isx86_64) {
  build_declarative_host_cross = declarative_host.config.system.build.toplevel;
}
