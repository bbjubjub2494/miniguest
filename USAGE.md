# Usage
## Imperative guests

A guest declaration must live in a Nix Flake.  To get started, you can use the
flake template.

To build and deploy a guest, run
```sh
sudo miniguest install «flakeRef»#«guestName»
```

When built, an imperative guest live in its own nix profile.  It must be
updated manually, and old generations can be garbage collected.  You can update
with
```sh
sudo miniguest upgrade «guestName»
```

To remove a guest, run
```sh
sudo miniguest remove «guestName»
```

## Declarative guests

On a NixOS host, guests can be embedded in the configuration of the host,
provided it lives in a flake.

## Configuring the hypervisor

To configure a guest in your hypervisor, for example Libvirt, run
```sh
miniguest create -t libvirt «guestName»
```
This will print a command. Edit the command if you wish, and execute it.
