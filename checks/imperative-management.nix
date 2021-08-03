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
      environment.systemPackages = [ miniguest ];
      environment.etc."pinned-nixpkgs".source = pinned-nixpkgs;
      system.extraDependencies = [ (import pinned-nixpkgs { inherit system; }).stdenvNoCC ];
      virtualisation.memorySize = 1024;
    };
    testScript = ''
      machine.copy_from_host("${data/flake1}", "/tmp/flake1")
      machine.succeed("""
      cat > /tmp/flake1/params.json << EOF
        ${builtins.toJSON { inherit system; }}
      EOF
      # override nixpkgs
      ${nixFlakes}/bin/nix --experimental-features "nix-command flakes" flake update /tmp/flake1 --override-input nixpkgs /etc/pinned-nixpkgs
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
}
