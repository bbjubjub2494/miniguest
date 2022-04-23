# Copyright 2021 Louis Bettens
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
      self.overlay
    ];

    overlay = import tool/overlay.nix;

    nixosModules.core = import ./core;
    nixosModules.declarative = import ./declarative inputs;

    defaultTemplate = {
      description = "Example guest configurations";
      path = ./template;
    };

    outputsBuilder = channels: rec {
      packages = rec {
        inherit (channels.nixpkgs) miniguest;
        default = miniguest;
      };
      defaultPackage = packages.default;
      defaultApp = fup.lib.mkApp { drv = packages.default; };
      devShell = channels.nixpkgs.callPackage nix/devshell.nix { };
      checks = import ./checks inputs channels.nixpkgs.system;
    };
  };
}
