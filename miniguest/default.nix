{ stdenv, bash, nixFlakes, shellcheck }:

stdenv.mkDerivation {
name = "miniguest";
  src = ./.;
  inherit bash nixFlakes;

  installPhase = ''
  mkdir -p $out/bin
  substituteAll miniguest.bash $out/bin/miniguest
  '';

  doInstallCheck = true;

  installCheckInputs = [ shellcheck ];

  installCheckPhase = ''
  shellcheck -s bash $out/bin/miniguest
  '';
}
