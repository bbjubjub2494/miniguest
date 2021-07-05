{ lib, ... }:

# Mix-in for a LXC container mini-guest.

{
  boot.isContainer = lib.mkDefault true;
}
