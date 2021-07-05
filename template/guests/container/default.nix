{ modulesPath, ... }:

{
  # Use miniguest
  boot.miniguest.enable = true;
  boot.miniguest.hypervisor = "lxc";

  users.users.root.hashedPassword = "";
}
