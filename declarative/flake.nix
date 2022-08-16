{
  description = "Module for declarative guests";

  outputs = inputs@{ self, nixpkgs }: rec {
    nixosModules.declarative = import ./default.nix inputs;
    nixosModules.default = nixosModules.declarative;
  };
}
