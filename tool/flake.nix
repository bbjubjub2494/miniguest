{
  description = "Companion tool for Miniguest";

  outputs = _: {
    overlays.default = import ./overlay.nix;
  };
}
