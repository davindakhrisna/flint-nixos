# Flint

Flint is a multi-host, dendritic NixOS configuration flake built with **flake-parts**, **import-tree**, and **Home Manager**. It manages everything from declarative kernel and disk layouts (Disko) to Hyprland desktop environments, developer toolchains, and a unified homelab server suite.

> [!NOTE]
> Flint uses dendritic auto-discovery via `import-tree`. Module files in `modules/` and `hosts/` are registered automatically—no manual import trees needed.

---

## Hosts

| Host | Description | Specs / Role |
| :--- | :--- | :--- |
| **`powerhouse`** | Main Desktop Workstation | Intel + NVIDIA, UWSM Hyprland, Dual-boot (Windows), Full Dev + AI + Extras |
| **`homelab`** | Headless / Portable Server | AMD + Btrfs Disko, Tailscale Serve, Glance, NAS, Vaultwarden, Media & Sync |
| **`noble`** | Secondary Machine | Intel Mobile |
| **`template`** | Clean Slate Template | Starting scaffold for new host setups |

---

## Architecture & Layers

| Layer | Location | Components |
| :--- | :--- | :--- |
| **System** | `modules/system/` | Base, Boot (Limine), Security, Audio (PipeWire), Containers (Docker, Waydroid), Virtualization (KVM/Libvirt), Hardware options |
| **Desktop** | `modules/home/desktop/` | Hyprland (Lua modular config), UWSM, Waybar, Rofi, Dunst, Hypridle, Hyprlock, Awww wallpapers |
| **Shell** | `modules/home/shell/` | Zsh + Vi mode, Starship prompt, fzf, bat, eza, fd, ripgrep, zoxide, CLI tools |
| **Productivity** | `modules/home/productivity/` | GUI programs (`programs.nix`), Coding (`coding.nix` + LazyVim), Agents (`agents.nix`), Dev Tools (`tools.nix`), Creative suite (`creative.nix`), and `mkenv` dev templates |
| **Server** | `hosts/homelab/server/` | Centralized services (`services.nix`), Glance dashboard, Tailscale Serve, Vaultwarden, qBittorrent, Jackett, Audiobookshelf, Immich, CouchDB, Samba NAS |
| **Extras** | `scripts/extra/` | Standalone modular helpers (`xinu.sh`, `stealth.sh`) toggled via `var.extra` |

---

## Feature Flags & Extras

Hosts configure capabilities declaratively under `var.features` and `var.extra`:

```nix
var = {
  cpu = "intel";
  gpu = "nvidia";
  features = {
    desktop = true;
    audio = true;
    bluetooth = true;
    tailscale = true;
    docker = true;
    libvirt = true;
    coding = true;
    agents = true;
    tools = true;
    creative = true;
  };
  extra = {
    xinu = true; # Provisions diskless QEMU/TFTP Xinu OS environment
    stealth = true; # Builds & binds headless AI screenshot solver (SUPER+Z / X / C)
  };
};
```

---

## Installation (`install.sh`)

<!-- TODO: install.sh automation implementation -->

---

## Quick Start & Workflow

### 1. Rebuild & Activate

```bash
nh os switch
```

### 2. Validation & Quality Checks

Run the pre-switch test suite to validate formatting, ShellCheck, Lua syntax, dead code, and dry-build evaluations:

```bash
# Validate and dry-build specific host
./scripts/check.sh powerhouse
./scripts/check.sh homelab

# Or validate all hosts
./scripts/check.sh
```

### 3. Development Environment Bootstrapping

Project toolchains are scoped per-project using `mkenv` templates:

```bash
mkenv rust my-project
cd my-project # direnv loads flake devShell automatically
```

Supported templates: `c`, `flutter`, `go`, `nix`, `py`, `rust`, `ts`.

---

## Adding a New Host

1. Copy the template:
   ```bash
   cp -r hosts/template hosts/my-machine
   ```
2. Configure `hosts/my-machine/default.nix` (hostname, username, disk config, features, and hardware).
3. If using Disko, customize `_disko.nix` for your partition layout.
4. Validate with `./scripts/check.sh my-machine` before deploying.

---

<sub>NixOS · flake-parts · import-tree · home-manager · hyprland · disko</sub>
