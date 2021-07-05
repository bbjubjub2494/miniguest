{
  description = "My Miniguest guests";

  inputs = {
    nixos.url = "nixpkgs/nixos-unstable";
    miniguest.url = "github:bbjubjub2494/miniguest";
    miniguest.inputs.nixpkgs.follows = "nixos";
    flake-utils.follows = "miniguest/flake-utils";
  };

  outputs = { self, nixos, miniguest, flake-utils }:
    with nixos.lib; {
      nixosConfigurations = attrsets.genAttrs [ "container" "stateless" ] (name:
        nixosSystem {
          system = "x86_64-linux";
          modules = [ miniguest.nixosModules.miniguest (./guests + "/${name}") ];
        });
    } // flake-utils.lib.eachDefaultSystem (system:
      with import nixos
        {
          inherit system;
          overlays = [ miniguest.overlay ];
        }; {
        devShell = mkShell { buildInputs = [ miniguest ]; };
      });
}
