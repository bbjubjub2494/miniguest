{ stdenv, argbash, bash, nixFlakes, shellcheck }:

stdenv.mkDerivation {
  name = "miniguest";
  src = ./.;
  inherit bash nixFlakes;

  nativeBuildInputs = [ argbash ];

  buildPhase = ''
    for f in *.bash; do
      substituteAllInPlace $f
    done
    for f in *_arg.bash; do
      argbash --strip=all -i "$f"
    done
  '';

  installPhase = ''
    mkdir -p $out/{lib,bin}
      mv main.bash $out/bin/miniguest
      chmod +x $out/bin/miniguest
      mv *.bash $out/lib
  '';

  doInstallCheck = true;

  installCheckInputs = [ shellcheck ];

  installCheckPhase = ''
    shellcheck -x -s bash $out/bin/miniguest
  '';
}
