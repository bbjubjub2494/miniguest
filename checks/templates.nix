inputs@{ self, nixpkgs, ... }: system:

with nixpkgs.legacyPackages.${system};
with self.packages.${system};
let
in
lib.optionalAttrs stdenv.isLinux {
  create_container = nixosTest {
    name = "miniguest-create-container";
    machine = {
      imports = [ self.nixosModules.declarative ];

      virtualisation.lxc.enable = true;
      users.users.root = {
        subUidRanges = [{ startUid = 1000000; count = 65536; }];
        subGidRanges = [{ startGid = 1000000; count = 65536; }];
      };

      miniguests.container.configuration = {
        boot.miniguest.enable = true;
        boot.miniguest.guestType = "lxc";
      };
      environment.systemPackages = [ miniguest ];

      virtualisation.memorySize = 1024;
    };
    testScript = ''
      machine.succeed("""
      cat >extra-config <<EOF
      lxc.idmap = u 0 1000000 65536
      lxc.idmap = g 0 1000000 65536
      EOF
      """);
      machine.succeed("""
      miniguest create -t lxc container | sh
      """);
      machine.succeed("""
      lxc-start container
      """);
    '';
  };
}
