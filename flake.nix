# Copyright 2022 Julie Bettens
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# The flake file is the entry point for nix commands
{
  description = "guest NixOS images with minimal footprint";

  # Inputs are how Nix can use code from outside the flake during evaluation.
  inputs.devshell.url = "github:numtide/devshell";
  inputs.fup.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.3.1";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;

  # Outputs are the public-facing interface to the flake.
  outputs = inputs@{ self, devshell, fup, nixpkgs, ... }: fup.lib.mkFlake {

    inherit self inputs;

    sharedOverlays = [
      devshell.overlay
      self.overlays.default
    ];

    overlays.default = import tool/overlay.nix;

    nixosModules.core = import ./core;
    nixosModules.declarative = import ./declarative inputs;

    templates.default = {
      description = "Example guest configurations";
      path = ./template;
    };

    outputsBuilder = channels: rec {
      packages = rec {
        inherit (channels.nixpkgs) miniguest;
        default = miniguest;
      };
      apps.default = fup.lib.mkApp { drv = packages.default; };
      devShells.default = channels.nixpkgs.callPackage nix/devshell.nix { };
      checks = import ./checks inputs channels.nixpkgs.system;
    };

    # Sorry I don't have Darwin machines
    herculesCI.ciSystems = [ "x86_64-linux" "aarch64-linux" ];
  };
}
