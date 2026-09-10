<p align="center">
  <strong>F L I N T</strong>
  <br>
  <em>One flake to rule them all.</em>
</p>

---

## What is this?

Flint is my personal NixOS configuration. It manages everything from kernel parameters to Neovim keybindings in a single, reproducible flake. Drop a new host file in `hosts/`, set a few options, and `nh os switch` gives you the whole stack.

> [!NOTE]
> Built on [flake-parts](https://github.com/hercules-ci/flake-parts) + [import-tree](https://github.com/denful/import-tree). Modules are discovered automatically — no manual import lists.

---

## Stack

| Layer | What's in it |
|:------|:-------------|
| **Desktop** | Hyprland (Wayland), UWSM, Waybar, Rofi, Dunst, Hyprlock, Awww wallpapers |
| **Shell** | Zsh + Vi mode, Starship prompt, fzf, bat, eza, fd, ripgrep, zoxide |
| **Editor** | Nixvim (LazyVim workflow) — Gruvbox, Snacks.nvim, Flash, Trouble, LSP |
| **Dev** | `minimal` / `full` workstation profiles, direnv + nix-direnv, `mkenv` project environments |
| **System** | Declarative hardware (Intel/AMD × Nvidia/AMD), PipeWire, Docker, Quad9 DNS |
| **Gaming** | Steam, Gamescope, MangoHud, GameMode |

---

## Development Profiles

Set `dev = "minimal"` or `dev = "full"` per host. Both provide the daily development workstation; `full` adds resource-heavy creative and compatibility applications.

```
minimal → Git/GitHub CLI, direnv, Nixvim, Zed, mkenv, CLI/container/database tools, AI coding tools
full    → minimal + Godot, Blender, LibreSprite, Winboat
```

> [!TIP]
> Compilers, language runtimes, SDKs, and formatters are project-scoped. `mkenv` bootstraps a `flake.nix` + `.envrc` for C/C++, Go, TypeScript, Python, Rust, Flutter, or Nix. Run `mkenv ts`, for example, or use `mkenv` for a fuzzy picker.

---

## Quick Start

**Rebuild:**
```bash
nh os switch
```

**Lint & format:**
```bash
nix develop          # also activated automatically by direnv
alejandra .          # format
deadnix .            # find dead code
statix check .       # anti-patterns
```

**Pre-switch validation:**
```bash
./scripts/check.sh                # checks and dry-builds powerhouse + template
./scripts/check.sh powerhouse     # check and dry-build one host
nh os switch                      # activate only after validation passes
```

The validation script also rejects untracked `.nix` files, because Git-backed
flakes cannot see them even when they exist in the working tree.

**Bootstrap a dev environment:**
```bash
mkenv rust my-project
cd my-project        # direnv activates automatically
```

---

## Adding a New Host

```bash
cp -r hosts/template hosts/my-machine
```

Edit `hosts/my-machine/default.nix` — set hostname, timezone, user, hardware vars, and which modules to import. After mounting the target at `/mnt`, generate and copy its hardware configuration explicitly:

```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-machine/_hardware.nix
```

> [!CAUTION]
> Don't forget to update disk UUIDs in `_hardware.nix` — they're unique to each machine.

---

## Offline Install

Flint supports fully offline installation via Nix closure archives. Build on a connected machine, export to USB, import on target.

See [docs/offline-installation.md](docs/offline-installation.md) for the full guide.

---

## Docs

- [Architecture & Module Structure](docs/architecture.md)
- [Offline Installation Guide](docs/offline-installation.md)

---

<sub>NixOS unstable · flake-parts · home-manager · nixvim · hyprland</sub>
