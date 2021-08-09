{
  description = "Module for declarative guests";

  outputs = inputs@{ self, nixpkgs }: rec {
    nixosModules.declarative = import ./default.nix inputs;
    nixosModule = nixosModules.declarative;
  };
}
