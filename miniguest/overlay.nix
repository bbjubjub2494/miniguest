final: prev: {
  miniguest-lxc-template = final.callPackage ./lxc-template.nix { };
  miniguest = final.callPackage ./package.nix { };
}
