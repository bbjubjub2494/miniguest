{
  description = "guest NixOS images with minimal footprint";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    {
      nixosModules.miniguest = import modules/miniguest.nix;
    } //
    eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        defaultPackage = miniguest;
        miniguest = pkgs.callPackage ./miniguest { };
        defaultApp = mkApp { drv = miniguest; };
      });
}
