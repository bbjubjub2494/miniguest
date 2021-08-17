# Low-footprint NixOS images
![Latest release](https://img.shields.io/github/v/release/lourkeur/miniguest)
![License](https://img.shields.io/github/license/lourkeur/miniguest)

![GitHub contributors](https://img.shields.io/github/contributors/lourkeur/miniguest?style=social)
![GitHub Repo stars](https://img.shields.io/github/stars/lourkeur/miniguest?style=social)

Miniguest makes lightweight [NixOS] guest images for popular virtualisation
tools.  The guest systems live entirely on the host's Nix store.  The host
system does not need to be NixOS.

## How lightweight?

Lighter than if it were the host system.  There is no disk image, no 
bootloader, no ISO.  Just plain immutable files that are friendly to Nix's
deduplication mechanisms.

## Getting started

You can read the [Installation guide], then the [Usage guide].

## Support Vector

QEMU virtual machines and Linux containers are supported.

For VMs, [Libvirt] integration is present. For containers, Miniguest can
produce templates in [LXC] format.

## Related work

- [`nixos-container`](https://nixos.org/manual/nixos/stable#ch-containers):
  Miniguest takes inspiration from NixOS's containers, however, containers 
  wraps `systemd-nspawn`, whereas Miniguest delegates container management
  to any supported hypervisor.
  
- `nixos-rebuild build-vm`:
  Miniguest borrows the store-sharing mechanism from NixOS's built-in
  lightweight QEMU VMs when applicable, but it lets a framework take care of
  the VM configuration and lifecycle.

[NixOS]: https://nixos.org
[Libvirt]: https://libvirt.org
[LXC]: https://linuxcontainers.org/lxc/introduction/
[Installation guide]: ./INSTALL.md
[Usage guide]: ./USAGE.md
