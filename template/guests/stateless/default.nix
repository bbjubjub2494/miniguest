{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Use miniguest
  boot.miniguest.enable = true;
  boot.miniguest.guestType = "qemu";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  users.users.root.hashedPassword = "";
}
