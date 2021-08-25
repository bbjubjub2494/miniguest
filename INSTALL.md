# Installation guide
First, you will need the Nix package manager.  Installation instructions can be
found [here](https://nixos.org/manual/nix/stable#chap-installation).

Next, the miniguest tool can be installed with
```sh
git clone https://github.com/bbjubjub2494/miniguest
nix-env -if ./miniguest
```

Alternatively, if you use [Nix flakes](https://nixos.wiki/wiki/Flakes) you
should run
```sh
nix profile install github:bbjubjub2494/miniguest
```

A Nixpkgs overlay is also available
```nix
(import (builtins.fetchGit https://github.com/bbjubjub2494/miniguest)).overlay
```
