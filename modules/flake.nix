{
  description = "Module for guests";

  outputs = _: {
    nixosModule = import ./miniguest.nix;
  };
}
