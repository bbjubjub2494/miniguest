{
  description = "A Miniguest guest";

  outputs = { self, nixpkgs }: with nixpkgs.lib; with importJSON ./params.json; {
    nixosConfigurations.dummy.config.system.build.miniguest =
      nixpkgs.legacyPackages.${system}.runCommand "dummy" { } ''
        mkdir -p $out/boot
        echo foo > $out/boot/init
      '';
  };
}
