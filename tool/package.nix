# Copyright 2022 Julie Bettens
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

{ lib, stdenv, boost, miniguest-lxc-template, meson, ninja, nixFlakes, nlohmann_json, pkg-config }:

stdenv.mkDerivation {
  pname = "miniguest";
  version = "0.2";
  src = builtins.path { name = "source"; path = ./.; };
  lxc_template = miniguest-lxc-template;

  nativeBuildInputs = [ meson ninja nlohmann_json pkg-config ];
  buildInputs = [ boost nixFlakes ];

  postPatch = ''
    for f in *.cpp; do
      substituteAllInPlace $f
    done
  '';

  meta = with lib; {
    description = "The companion tool for Miniguest";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ bbjubjub2494 ];
  };
}
