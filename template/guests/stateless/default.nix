{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Use miniguest
  boot.loader.grub.enable = false;
  boot.miniguest.enable = true;

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  users.users.root.hashedPassword = "";
}
