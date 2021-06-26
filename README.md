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

## Dependencies

- Nix 2.4+
- Bash 4.0+

## Usage

Guest system configuration must be presented within a Nix flake, import this
flake's `nixosModules.miniguest` module, and set `boot.miniguest.enable` to
true.  The `miniguest` tool can then be invoked with the name of the guest as an
argument.  The configuration will then be built and will appear under
`/etc/miniguests/«guestName»`.  Refer to [this
template](templates/libvirt-kvm.xml) to create the corresponding libvirt
domain.

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
