# Architecture

Flint uses **flake-parts** as the flake framework and **import-tree** for automatic module discovery. Every `.nix` file placed inside `modules/` or `hosts/` is imported without any manual wiring.

---

## How Modules Compose

```
flake.nix
  ├── import-tree ./modules   ← auto-discovers all system & home modules
  └── import-tree ./hosts     ← auto-discovers all host definitions
```

Each host in `hosts/<name>/default.nix` selects which home-manager modules to load:

```nix
home-manager.users.kryisnn = { ... }: {
  imports = with self.homeModules; [
    home-manager desktop shell productivity dev
    entertainment-social entertainment-gaming
  ];
  dev = "max";  # ← tier selector
};
```

---

## System Modules (`modules/system/`)

| File | Responsibility |
|:-----|:---------------|
| `base.nix` | Nix settings, kernel hardening, PipeWire, Docker, Quad9 DNS, overlays |
| `desktop.nix` | Hyprland UWSM session, Lemurs display manager, system fonts, Flatpak |
| `hardware.nix` | Declarative `var.cpu` / `var.gpu` / `var.nvidia.mode` abstraction |
| `gaming.nix` | Steam, GameMode, Gamescope |
| `utils.nix` | System-wide CLI utilities and helpers |

> [!NOTE]
> `hardware.nix` uses `lib.mkIf` guards — unused hardware paths are completely eliminated. An AMD machine never evaluates Nvidia driver logic.

---

## Home Modules (`modules/home/`)

| Directory | Responsibility |
|:----------|:---------------|
| `desktop/` | Hyprland config (Lua via Hyprlang), Waybar, Dunst, Rofi, Hyprlock, Swww, GTK theming |
| `dev/` | Tiered dev tools, Nixvim (LazyVim workflow), `mkenv` bootstrapper, templates |
| `shell/` | Zsh (vi-mode, plugins), Starship prompt, fzf, bat, eza, fd, ripgrep, zoxide |
| `entertainment/` | Gaming (MangoHud, Sober) and social (Discord, Spotify) |
| `productivity/` | Obsidian, Sioyek, TUI tools |
| `home.nix` | Base HM config, XDG compliance, session variables |

---

## Dev Tier System

Defined in `modules/home/dev/default.nix` as an enum option:

```nix
options.dev = lib.mkOption {
  type = lib.types.enum [ "off" "min" "mid" "max" ];
  default = "mid";
};
```

Each tier file uses conditional activation:

```nix
# min.nix  → activates when dev != "off"
# mid.nix  → activates when dev ∈ { "mid", "max" }
# max.nix  → activates when dev == "max"
```

> [!TIP]
> `_mkenv.nix` lives in `dev/` and ships `mkenv`, a CLI tool that generates per-project `flake.nix` + `.envrc` files for any supported stack. Templates are stored in `dev/templates/<stack>/`.

---

## Hardware Abstraction

The `var` option set in `hardware.nix` drives all hardware configuration:

```nix
var = {
  cpu = "intel";          # → microcode + thermald
  gpu = "nvidia";         # → proprietary drivers, VA-API, env vars
  nvidia.mode = "sync";   # → PRIME sync (laptop) or "desktop" / "offload"
};
```

Nvidia config also supports clock tuning via a systemd oneshot:

```nix
nvidia.baseClockMHz = 2100;  # applied at boot
```

> [!IMPORTANT]
> Bus IDs for PRIME (`nvidia.intelBusId`, `nvidia.nvidiaBusId`) default to common values but should be verified with `lspci | grep VGA` on each machine.

---

## Dual Boot

```nix
var.dualBoot = {
  enable = true;
  windowsEntry = "uuid(XXXX-XXXX):/EFI/Microsoft/Boot/bootmgfw.efi";
};
```

Limine bootloader is configured with limited generations to keep the boot menu clean.

---

## Validation

```bash
alejandra .                    # format
deadnix .                      # dead code
statix check .                 # anti-patterns
nh os build --dry              # dry build (evaluates without applying)
nh os switch                   # build + activate
```
