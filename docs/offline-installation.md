# Offline Installation

Flint creates a local Nix binary cache containing both the complete system
closure and every locked flake input. This matters because importing only the
system closure is insufficient: a fresh installer must also evaluate the flake
without contacting GitHub.

## Create the bundle

Commit the configuration first, attach the destination drive, and run:

```bash
nix develop
./scripts/export-offline.sh powerhouse /path/to/usb/flint-offline-powerhouse
```

The exporter deliberately refuses a dirty working tree so the archived system,
flake inputs, and editable source all describe the same Git revision. It builds
the selected host, copies its closure into a portable binary cache, archives all
locked flake inputs into that cache, and includes the committed repository.

The resulting directory contains:

```text
flint-offline-powerhouse/
├── cache/              local Nix binary cache
├── flint/              editable source at the recorded revision
├── flake-store-path    immutable archived flake path
├── system-store-path   built system closure path
├── git-revision        source revision
└── INSTALL.txt         installation commands
```

## Install offline

Boot the NixOS installer, connect the bundle drive, and mount the target root and
EFI filesystems under `/mnt`. Device names below are examples; verify every
device with `lsblk -f` before running formatting or mounting commands.

Import the entire cache:

```bash
nix copy --all --from file:///mnt-usb/flint-offline-powerhouse/cache
```

Install from the immutable flake path recorded in the bundle:

```bash
flake_path="$(cat /mnt-usb/flint-offline-powerhouse/flake-store-path)"
nixos-install \
  --flake "path:$flake_path#powerhouse" \
  --no-channel-copy
```

Because the archived flake itself and all its inputs are already in `/nix/store`,
this evaluation does not need a network connection or a pre-populated fetcher
cache. Set passwords when prompted, then reboot.

## Installing different hardware

Do not install the `powerhouse` closure on unrelated hardware. Start from the
host template, mount the target filesystems, and generate its hardware module:

```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-machine/_hardware.nix
```

Set the host's CPU, GPU, Nvidia PRIME IDs if applicable, filesystem paths, and
feature flags. Commit those changes and create a bundle for that host on a
compatible `x86_64-linux` builder.

## Verification

Before disconnecting the build machine, confirm the bundle records exist and
inspect its binary cache:

```bash
test -s /path/to/bundle/flake-store-path
test -s /path/to/bundle/system-store-path
nix path-info --store file:///path/to/bundle/cache --all >/dev/null
```

The cache's `.narinfo` files contain the hashes Nix uses to verify imported
paths. Keep an additional checksum of the bundle directory if the transport
medium or transfer process is untrusted.
