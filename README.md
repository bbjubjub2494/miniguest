# Low-footprint NixOS images

This tool makes lightweight [NixOS](https://nixos.org/) virtual machines and
containers for popular virtualisation tools.  The guest systems live entirely 
on the host's Nix store.  The host system does not need to be NixOS.

## How lightweight?

Lighter than if it were the host system.  There is no disk image, no 
bootloader, no ISO.  Just plain immutable file that are friendly to Nix's
deduplication mechanisms.

## Support Vector

Libvirt KVM guests are the current primary focus.  Any hypervisor that is 
capable of direct-kernel boot can most likely work as well.  Libvirt OS
containers will come in the future.

## Installation

If the Nix you drive already has [flakes] enabled, just use the following command:
```sh
nix profile install github:bbjubjub2494/miniguest
```

Otherwise don't worry, miniguest can be bootstrapped under Nix 2.3 and older with with:
```sh
nix-env -if https://github.com/bbjubjub2494/miniguest/archive/refs/heads/master.zip
```

If you do not have Nix installed, refer to [this
page](https://nixos.org/download.html#nix-quick-install), then look at the
second command.

[flakes]: https://nixos.wiki/wiki/Flakes

## Getting started

You base your flake on the template. Copy the `template/` directory from the
repository, or run:
```sh
nix flake new -t github:bbjubjub2494/miniguest
```

## Usage

Guest system configuration must be presented within a Nix flake, import the
`nixosModules.miniguest` module from the miniguest flake, and set
`boot.miniguest.enable` to true.  The miniguest tool can then be invoked with
```sh
sudo miniguest install «flakePath»#«guestName»
```
The configuration will then be built and will appear under
`/etc/miniguests/«guestName»`.

It is recommended to create at most one domain per configuration so that they
can all be rebuilt independently of each other.

## Related work

- [`nixos-container`](https://nixos.org/manual/nixos/stable/index.html#ch-containers):
  Miniguest takes inspiration from NixOS's containers, however, containers 
  wraps `systemd-nspawn`, whereas miniguests delegates actual guest management
  to any supported hypervisor.
  
- `nixos-rebuild build-vm`:
  Miniguest borrows the store-sharing mechanism from NixOS's built-in 
  lightweight QEMU VMs when applicable, but it lets libvirt take care of the VM
  configuration and lifecycle.
