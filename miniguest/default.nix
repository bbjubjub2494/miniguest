{ stdenv, argbash, bash, nixFlakes, shellcheck, makeWrapper }:

stdenv.mkDerivation {
  name = "miniguest";
  src = ./.;
  inherit bash nixFlakes;

  nativeBuildInputs = [ argbash makeWrapper ];

  buildPhase = ''
    for f in *.bash; do
      substituteAllInPlace $f
    done
    for f in *_arg.bash; do
      argbash --strip=all -i "$f"
    done
  '';

  installPhase = ''
    mkdir -p $out/{libexec/miniguest,bin}
      mv *.bash $out/libexec/miniguest
      chmod +x $out/libexec/miniguest/main.bash
      makeWrapper $out/libexec/miniguest/main.bash $out/bin/miniguest \
        --prefix PATH ":" "$out/libexec/miniguest"
  '';

  doInstallCheck = true;

  installCheckInputs = [ shellcheck ];

  installCheckPhase = ''
    shellcheck -x -s bash $out/bin/miniguest
  '';
}
