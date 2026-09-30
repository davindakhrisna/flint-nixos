# Build homelab elsewhere and switch offline

Use this procedure to update an existing NixOS homelab without compiling on it.
The builder and homelab must both be `x86_64-linux`. Use a local console for the
first switch: this configuration disables OpenSSH and enables Tailscale SSH.

Before building, compare the root, boot, and swap UUIDs in
`hosts/homelab/_hardware.nix` with `lsblk -f` on homelab. Build only after they
match the installed machine.

## Build and export on the builder

The exporter requires a clean Git checkout. In this repository, create a clean
worktree at the committed revision so unrelated local edits can stay in place:

```bash
git worktree add --detach ../flint-homelab-build HEAD
cd ../flint-homelab-build
nix develop
./scripts/check.sh homelab
./scripts/export-offline.sh homelab /path/to/usb/flint-offline-homelab
```

The exporter builds the full system, copies its closure and flake inputs to
`cache/`, and includes a source archive in `flint/`. Make sure the USB drive has
space for the closure. The first build can be large even though homelab does no
compilation.

## Import and switch on homelab

Mount the drive and set `bundle` to its actual mount path. These commands do not
format any disk:

```bash
bundle=/path/to/usb/flint-offline-homelab
sudo nix copy --all --from "file://$bundle/cache"
system_path=$(cat "$bundle/system-store-path")
sudo nix path-info "$system_path"
sudo nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

The profile command records a bootable generation; the final command activates
it now. No flake evaluation or source checkout is needed on homelab to switch
this prebuilt closure.

## Provision secrets and inspect services

Run the bundled provisioner on homelab from a terminal. It prompts for a
username and password if no secrets file is supplied. Set
`ANTHROPIC_API_KEY` before running it if Hermes should use its configured
Anthropic model.

```bash
bash "$bundle/flint/scripts/server/provision-secrets.sh"
sudo systemctl status couchdb.service couchdb-init-databases.service
sudo systemctl status tailscale-serve.service hermes-agent.service
```

CouchDB waits for a nonempty admin password file, so its first start is skipped
until the provisioner writes the secret and starts the service. If the
provisioner reports an unstarted Audiobookshelf or Immich service, run it again
after those services start.

Keep the bundle until the machine has rebooted successfully. The previous
system generation remains available in the boot menu for rollback.
