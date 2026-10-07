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
username and password if no secrets file is supplied. Configure the Hermes
9Router key in `scripts/server/.secrets.env` as described below.

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

## Customize Hermes

`hermes setup` refuses to run because the NixOS module owns the installation.
Edit `modules/server/config/hermes/_settings.nix` for the default model,
toolsets, terminal settings, and other agent behavior. Nix merges
these settings into `/var/lib/hermes/.hermes/config.yaml` on each switch;
changes to those same keys through Hermes are replaced by the next switch.

Keep service credentials and Hermes environment settings together in the ignored
`scripts/server/.secrets.env`, using `scripts/server/secrets.env.example` as the
template. Protect the real file with `chmod 600 scripts/server/.secrets.env`.
The provisioner writes only the Hermes provider and WhatsApp settings into
`/var/lib/secrets/hermes-provider.env` (root-owned, mode 0600); the shared Linux
password is not copied into Hermes. Both Hermes services refresh their runtime
`.env` from provisioned files before starting. After editing the secrets file, run:

```bash
bash scripts/server/provision-secrets.sh --hermes-only
```

For offline deployments, copy `.secrets.env` separately and run the provisioner
on homelab. Credentials never enter the Nix store or the offline bundle.

The 9Router endpoint is `http://localhost:20128/v1`. Set `CUSTOM_BASE_URL` to
support legacy custom routing and `OPENAI_BASE_URL` to the same URL to bind
`OPENAI_API_KEY` to it; both are included in the example. The named `providers.9router` entry in Nix
sets the endpoint and reads its key through `key_env = "OPENAI_API_KEY"`.
Both `Casual` and `Agentic` are listed explicitly; Hermes uses the `Agentic`
combo by default; launch `hermes chat -m Casual` for the `Casual` combo, or use
`/model Casual` inside a chat. Model names are case-sensitive and are configured
in YAML/Nix rather than `.env`; this Hermes version does not read `OPENAI_MODEL`.
The provisioner saves `INITIAL_PASSWORD` in `/var/lib/secrets/9router.env`
(root-owned, mode 0600). Set it in the provisioning secrets file or environment;
when omitted it uses `PASSWORD`. systemd loads it on every 9Router start. It is
only the initial login password: an existing saved password hash takes priority.
9Router startup waits until this secret file exists.
On this homelab, Casual was migrated from retired Groq models to the verified
`groq/openai/gpt-oss-120b` and `groq/openai/gpt-oss-20b` routes. Its original
combo is backed up privately under `~/.9router/`; combo state stays outside Git.

9Router runs at boot as `kryisnn`, preserving the CLI's existing providers and
combos, and listens only on loopback. Its web UI is at `http://localhost:20128`.
Before the first switch, stop an existing manually launched 9Router instance
so the service can bind port 20128.

Hermes enables `terminal`, `file`, `memory`, `session_search`, `skills`, `todo`,
`clarify`, `browser`, `web`, `computer_use`, `delegation`, and `mcp-headroom` for the
CLI, dashboard, and WhatsApp. Tools run as `hermes` in `/var/lib/hermes/workspace`.
9Router handles inference using `Agentic` by default, with `Casual` also available.

All added tool backends run on homelab:

- Browser automation uses Nix-packaged agent-browser and Chromium, with a
  two-minute inactivity timeout and no cloud browser provider.
- Search uses a loopback-only SearXNG process on port 9121, without Redis or a
  hosted search API. Only DuckDuckGo, Bing, and Wikipedia are loaded; optional
  plugins and downloaded tracker-rule feeds are disabled. Searches still query
  public search engines.
- Extraction uses the small `web-local-extract` plugin, Python's HTML parser,
  and Hermes's SSRF-safe HTTP client. Responses are capped at 2 MiB; scripts and
  styles are removed. JavaScript-only pages need the browser. Hosted free API
  fallbacks are disabled.
- Computer control uses a pinned local cua-driver and a dedicated authenticated
  Xvfb/Openbox desktop on display `:99`. It controls the Hermes desktop rather
  than the owner's login session. No VNC server or desktop container is added.
  Driver telemetry and cursor overlays are disabled. Chromium starts on demand;
  the small virtual display remains available while Hermes runs. The selected
  9Router combo needs a vision-capable model for screenshot-based work.
- `delegate_task` provides Hermes subagents. Local Headroom MCP runs through
  `headroom mcp serve`, with telemetry disabled and a prebuilt tokenizer cache.

Edit `modules/server/config/hermes/hermes-soul.md` to change personality and project
workflow. The agent introduces itself as **Junggo**; service names and runtime paths
continue to use Hermes. Nix installs it as `/var/lib/hermes/.hermes/SOUL.md`; direct
edits to that managed copy are replaced on activation. It includes the owner's Codex
AGENTS.md baseline and explicitly authorizes Graphify initialization for every
new project. It also requires Headroom compression, bounded Codex delegation,
verification, and Tailscale Serve for serveable projects.

`flint-hermes-codex` accepts exactly one existing directory inside the Hermes
workspace, reads its task from stdin, and runs the owner's existing Codex as
`kryisnn` with the workspace-write sandbox. Codex must already be installed and
logged in on homelab. The helper removes Hermes's provider environment; it does
not copy authentication or configure Codex to use 9Router.

`flint-hermes-serve HTTPS_PORT LOCAL_PORT` publishes only a loopback backend,
using an unused tailnet HTTPS port between 8460 and 8499. It refuses occupied
ports and does not enable Funnel. Run previews as persistent `hermes` user
services so they survive the tool call. Existing homelab routes are preserved.
The `hermes` account receives passwordless sudo for these two validated helpers
only. Hermes services permit privilege changes for those helpers and share the
X socket; filesystem protection remains enabled, with write access to Hermes
state and the owner's Codex state for delegation.

Runtime file creation and ownership rules, plus the per-start environment
refresh, live in `modules/server/tmpfiles.nix`. Service definitions and tool
configuration are imported by `modules/server/hermes.nix` from
`modules/server/config/hermes/`: `_settings.nix` holds model and tool choices,
`_tools.nix` wires integrations, `_packages.nix` packages helpers, and
`_desktop.nix` manages the private display. Shell helpers live beside them.

Validate settings and deploy on homelab:

```bash
./scripts/check.sh
bash scripts/server/provision-secrets.sh --hermes-only
nh os switch
sudo -u hermes -H flint-hermes-check
sudo -u hermes -H flint-hermes-check --inference
```

`--hermes-only` provisions 9Router and Hermes without changing Linux, Samba,
or other service passwords. Set `INITIAL_PASSWORD` in the ignored secrets file;
keep it stable across deployments. Existing Hermes dashboard credentials are
retained when `PASSWORD` is empty. On a fresh deployment, the dashboard uses
`INITIAL_PASSWORD` if no dashboard credentials or shared password exist.
The generated password on this homelab is stored only in `.secrets.env`.
An existing 9Router password hash still takes priority over INITIAL_PASSWORD.

`flint-hermes-check` reports inactive services, unavailable HTTP endpoints, and
missing combos with a nonzero exit status. `--inference` sends one short request
to each combo and consumes provider quota. It never prints credentials or model
response bodies. When WhatsApp is enabled, it also checks that the bridge is
connected. QR scanning, verifying a reply from an allowed sender, and verifying
rejection of an unlisted sender remain manual.

A successful build does not prove remote provider availability, model tool/vision
support, WhatsApp Web compatibility, Codex login, Tailscale certificates or peer
reachability. These require live tests after activation. SOUL instructions direct
Graphify, Headroom, delegation and serving; they cannot guarantee model compliance.
The dedicated desktop reports readiness before Hermes starts, and the serving
helper serializes route allocation and refuses malformed status or occupied ports.

## Connect WhatsApp

Your phone number belongs only in the ignored `scripts/server/.secrets.env`,
under `WHATSAPP_ALLOWED_USERS`; the example uses a placeholder. The initial
configuration uses bot mode on a second number, allows messages only from
your personal number, disables
groups, and leaves `WHATSAPP_ENABLED=false` until pairing finishes.

After switching to the new configuration, provision secrets if needed, then run:

```bash
sudo -u hermes -H flint-hermes-whatsapp-pair
```

The command installs the bridge's npm dependencies in writable Hermes state
and displays a QR code. Pairing and gateway startup use the same Nix-provided
Node/npm toolchain; the shared runtime patch honors `HERMES_NODE`, avoiding
Hermes PM downloads of generic Linux binaries. The bridge listens only on
`127.0.0.1:9122`, avoiding other services on port 3000. Add multiple allowed senders
as a comma-separated `WHATSAPP_ALLOWED_USERS` value in the private secrets file,
then reprovision with `--hermes-only`. On your phone, open WhatsApp → Linked Devices → Link a
Device on the account for your second (bot) number and scan it. Your personal
number belongs in the allowlist, not in the bot session. This pairs the session
without asking `hermes setup` to
rewrite Nix-managed settings. Credentials stay under Hermes's state directory.
Once it succeeds, set `WHATSAPP_ENABLED=true` in `scripts/server/.secrets.env`:

```bash
bash scripts/server/provision-secrets.sh --hermes-only
```

From your personal WhatsApp account, message the bot's second number to talk
to Hermes. Repeat the
pairing command when a new session is needed. The bridge uses WhatsApp Web,
rather than the official Business Cloud API.

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
