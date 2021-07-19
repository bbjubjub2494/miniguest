{ modulesPath, ... }:

{
  # Use miniguest
  boot.miniguest.enable = true;
  boot.miniguest.guestType = "lxc";

  users.users.root.hashedPassword = "";
}
