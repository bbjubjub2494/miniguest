{
  description = "Companion tool for Miniguest";

  outputs = _: {
    overlay = import ./overlay.nix;
  };
}
