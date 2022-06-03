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

with nixpkgs.legacyPackages.${system};
with self.packages.${system};
let
  # need a fixed-output copy of nixpkgs for offline use and reproducibility
  pinned-nixpkgs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "21.05";
    sha256 = "sha256-ZjBd81a6J3TwtlBr3rHsZspYUwT9OdhDk+a/SgSEf7I=";
  };

  mkTest = { name, testScript }: nixosTest {
    inherit name;
    machine = {
      environment.systemPackages = [
        # wrapper clears PATH to check for implicit dependencies
        (writeShellScriptBin "miniguest" ''PATH= exec ${miniguest}/bin/miniguest "$@"'')
      ];
      system.extraDependencies = [ pinned-nixpkgs (import pinned-nixpkgs { inherit system; }).stdenvNoCC ];
      virtualisation.memorySize = 1024;
    };
    testScript = ''
      machine.copy_from_host("${data/flake1}", "/tmp/flake1")
      machine.succeed("""
      cat > /tmp/flake1/params.json << EOF
        ${builtins.toJSON { inherit system; }}
      EOF
      # override nixpkgs
      ${nixFlakes}/bin/nix --experimental-features "nix-command flakes" flake update /tmp/flake1 --override-input nixpkgs ${pinned-nixpkgs}
      """);
    '' + testScript;
  };
in
lib.optionalAttrs stdenv.isLinux {
  install_dummy = mkTest {
    name = "miniguest-install-dummy";
    testScript = ''
      machine.succeed("""
        miniguest install /tmp/flake1#dummy
      """)
      assert "foo" in machine.succeed("""
        cat /etc/miniguests/dummy/boot/init
      """)
    '';
  };

  install_rename = mkTest {
    name = "miniguest-install-rename";
    testScript = ''
      machine.succeed("""
        miniguest install --name=renamed_dummy /tmp/flake1#dummy
      """)
      assert "foo" in machine.succeed("""
        cat /etc/miniguests/renamed_dummy/boot/init
      """)
      assert "/nix/var/nix/profiles/miniguest-profiles/renamed_dummy\n" == machine.succeed("""
        readlink /etc/miniguests/renamed_dummy
      """)
    '';
  };

  install_nonexistent = mkTest {
    name = "miniguest-install-nonexistent";
    testScript = ''
      machine.fail("""
        miniguest install /tmp/flake1#nonexistent
      """)
      machine.succeed("""
        test ! -e /etc/miniguests/nonexistent
      """)
      machine.succeed("""
        test ! -e /nix/var/nix/miniguest-profiles/nonexistent
      """)
    '';
  };

  remove_dummy = mkTest {
    name = "miniguest-remove-dummy";
    testScript = ''
      machine.succeed("""
        miniguest install /tmp/flake1#dummy
      """)
      machine.succeed("""
        miniguest remove dummy
      """)
      machine.succeed("""
        test ! -e /etc/miniguests/nonexistent
      """)
      machine.succeed("""
        test ! -e /nix/var/nix/miniguest-profiles/nonexistent
      """)
    '';
  };
}
