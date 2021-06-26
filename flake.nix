{
  description = "guest NixOS images with minimal footprint";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    {
      nixosModules.miniguest = import modules/miniguest.nix inputs;
    } //
    eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
miniguest = pkgs.callPackage ./miniguest { };
      in
      rec {
        defaultPackage = miniguest;
        packages = { inherit miniguest; };
        defaultApp = mkApp { drv = miniguest; };
      });
}
