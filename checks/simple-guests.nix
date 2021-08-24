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

inputs@{ self, nixpkgs, ... }: system:

with nixpkgs.lib;
let
  kvm_guest = nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.core
      {
        boot.miniguest.enable = true;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
          options = [ "defaults" "mode=755" ];
        };
      }
    ];
  };
  lxc_guest = nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.core
      {
        boot.miniguest.enable = true;
        boot.miniguest.guestType = "lxc";
      }
    ];
  };
in
with nixpkgs.legacyPackages.${system};
optionalAttrs stdenv.isLinux {
  build_kvm_guest = kvm_guest.config.system.build.miniguest;
  build_lxc_guest = lxc_guest.config.system.build.miniguest;
}
