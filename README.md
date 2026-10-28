# Flint

A multi-host, dendritic NixOS configuration flake powered by **flake-parts**, **import-tree**, and **Home Manager**.

Module files in `modules/` and `hosts/` are discovered automatically via `import-tree`.

---

## Hosts

| Host | Role | Description |
| :--- | :--- | :--- |
| **`powerhouse`** | Workstation | Intel + NVIDIA, UWSM Hyprland, Dual-boot, Dev, Agents, Extras |
| **`homelab`** | Server | AMD + Disko Btrfs, Tailscale Serve, Glance, NAS, Vaultwarden, Media |
| **`noble`** | Laptop | Intel Mobile |
| **`template`** | Scaffold | Minimal starting point for new machines |

---

## Structure

| Directory | Layer | Purpose |
| :--- | :--- | :--- |
| `modules/system/` | System | Boot (Limine), audio, virtualization, docker, hardware |
| `modules/home/desktop/` | Desktop | Hyprland (Lua config), UWSM, Waybar, Rofi, Dunst |
| `modules/home/shell/` | Shell | Zsh, Starship, fzf, CLI tools |
| `modules/home/productivity/` | User Apps | GUI programs, coding toolchains, LazyVim, AI agents, `mkenv` |
| `hosts/homelab/server/` | Homelab | Glance, Tailscale Serve, Vaultwarden, qBittorrent, Immich, NAS |
| `scripts/extra/` | Extras | Modular standalone tasks (`xinu`, `stealth`) toggled via options |

---

## Declarative Options

Hosts configure capabilities in `hosts/<name>/default.nix`:

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
    xinu = false;     # QEMU/TFTP Xinu OS lab environment
    stealth = false;  # AI screen solver keybinds (SUPER+Z / X / C)
  };
};
```

---

## Workflow

```bash
# Rebuild and switch system
nh os switch

# Validate code, formatting, ShellCheck, and dry-build evaluations
./scripts/check.sh [host]

# Scaffold a project dev environment (via direnv + flakes)
mkenv <template> <project-name>   # c, flutter, go, nix, py, rust, ts
```

### Adding a Machine

1. `cp -r hosts/template hosts/<name>`
2. Edit `hosts/<name>/default.nix` (and `_hardware.nix` / `_disko.nix` as needed).
3. Validate: `./scripts/check.sh <name>`
