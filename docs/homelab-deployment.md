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
system_path=$(cat "$bundle/system-store-path")
sudo nix copy --no-check-sigs --from "file://$bundle/cache" "$system_path"
sudo nix path-info "$system_path"
sudo nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

The profile command records a bootable generation; the final command activates
it now. No flake evaluation or source checkout is needed on homelab to switch
this prebuilt closure.

The cache is unsigned because it was exported from your own builder, so the
import explicitly accepts it with `--no-check-sigs`. Importing only
`system_path` also avoids copying flake inputs that are unnecessary for this
switch.

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

## Remote browser

After deploying a configuration that includes the browser module, connect your
phone to the tailnet and open `https://homelab.auxois-searobin.ts.net:8453`.
Start it first with `sudo firefox start`; use `sudo firefox stop` to terminate
the session and `sudo firefox status` to inspect it. Firefox stays stopped at
boot. Glance uses its standard HTTP monitor for Remote Browser, so a stopped
browser appears unavailable. Headroom and Obsidian Sync are omitted from the
dashboard.

Firefox runs on homelab and saves downloads to `/srv/nas/downloads`. Leaving
the page or losing the phone connection does not stop the browser session or an
active download. The browser image archive is included in the Nix system
closure and loaded locally when the service starts.

## Boot recovery

Docker retries every 30 seconds without exhausting its boot start limit. Each
automatically started Docker container requires Docker, starts after it is
ready, and restarts with it. This covers FlareSolverr when slow boot I/O causes
Docker's managed containerd to time out. Manual Firefox starts also require
Docker, but Firefox is excluded from automatic startup.

CouchDB initialization waits up to 120 seconds for its HTTP endpoint. Tmpfiles
cleanup retries transient failures up to three times within five minutes; a
persistent failure remains visible in `systemctl --failed`.

Tmpfiles restores Hermes state ownership to `hermes:hermes`. Homelab activation
disables the legacy `hermes-gateway` user unit, since the NixOS `hermes-agent`
service owns that state. The `kryisnn` user belongs to the `hermes` group for
interactive access. AI CLI updates use a shared file lock so activation and
the user timer cannot concurrently delete an installer's staging files.

After a switch or reboot, inspect both service managers:

```bash
systemctl --failed
systemctl --user --failed
systemctl status docker docker-firefox docker-flaresolverr hermes-agent hermes-backend
journalctl -b -u docker -u systemd-tmpfiles-clean -u couchdb-init-databases
journalctl --user -b -u flint-update-ai-tools
```
