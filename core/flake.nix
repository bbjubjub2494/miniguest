{
  description = "Module for guests";

  outputs = _: rec {
    nixosModules.core = import ./default.nix;
    nixosModules.default = nixosModules.core;
  };
}
