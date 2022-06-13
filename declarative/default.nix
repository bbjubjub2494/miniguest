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

inputs:
{ config, lib, ... }:
with lib;
{
  options.miniguests = mkOption {
    description = "A set of NixOS configurations to be built and made available as miniguests.";
    default = { };
    type = types.attrsOf (types.submodule ({ options, name, ... }:
      {
        options = {
          configuration = mkOption {
            description = ''
              A specification of the desired configuration of this
              container, as a NixOS module.
            '';
            type = mkOptionType {
              name = "Toplevel NixOS config";
              merge = lib.options.mergeOneOption;
            };
          };
          system = mkOption {
            description = ''
              specifies the nix platform type for which the guest should be built.
            '';
            type = types.str;
            default = config.nixpkgs.system;
            defaultText = literalDocBook "same as the host";
          };
        };
      }));
  };

  imports = [ (import ./internal.nix inputs) ];
}
