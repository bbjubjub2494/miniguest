{
  description = "guest NixOS images with minimal footprint";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ self, nixpkgs, devshell, flake-utils }:
    with flake-utils.lib;
    {
      nixosModules.miniguest = import modules/miniguest.nix inputs;
      overlay = final: prev: {
        miniguest = final.callPackage ./miniguest { };
      };
    } // simpleFlake {
      inherit self nixpkgs;
      name = "miniguest";
      systems = defaultSystems;
      preOverlays = [ devshell.overlay ];
      overlay = final: prev: {
        miniguest = rec {
          miniguest = final.callPackage ./miniguest { };
          defaultPackage = miniguest;
          defaultApp = mkApp { drv = miniguest; };
          devShell = final.devshell.mkShell {
            imports = [ (final.devshell.importTOML ./devshell.toml) ];
          };
          checks = import ./checks inputs final prev;
        };
      };
    };
}
