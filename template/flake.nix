{
  description = "My Miniguest guests";

  inputs = {
    nixos.url = "nixpkgs/nixos-unstable";
    miniguest.url = "github:bbjubjub2494/miniguest?dir=core";
    miniguest.inputs.nixpkgs.follows = "nixos";
  };

  outputs = { self, nixos, miniguest }:
    with nixos.lib; {
      nixosConfigurations = attrsets.mapAttrs
        (name: _:
          nixosSystem {
            system = "x86_64-linux";
            modules = [ miniguest.nixosModules.core (./guests + "/${name}") ];
          })
        (builtins.readDir ./guests);
    };
}
