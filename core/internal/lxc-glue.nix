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

{ config, lib, ... }:

# Mix-in for a LXC container mini-guest.

with lib;
let cfg = config.boot.miniguest;
in
mkIf (cfg.enable && cfg.guestType == "lxc") {
  warnings = lib.optional (cfg.storeCorruptionWarning) ''
    Running a guest in LXC without enabling UID mapping or otherwise confining the guest's superuser can result in host store corruption!
    Double-check your container settings!
    You can suppress this warning with:
      boot.miniguest.storeCorruptionWarning = false;
  '';
  boot.isContainer = mkDefault true;
}
