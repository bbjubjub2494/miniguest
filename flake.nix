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
      defaultTemplate = {
        description = "Example guest configurations";
        path = ./template;
      };
    } // eachDefaultSystem (system: rec {
      packages.miniguest = nixpkgs.legacyPackages.${system}.callPackage ./miniguest { };
      defaultPackage = packages.miniguest;
      defaultApp = mkApp { drv = packages.miniguest; };
      devShell = devshell.legacyPackages.${system}.fromTOML ./devshell.toml;
      checks = import ./checks inputs system;
    });
}
