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
  dev = "full";  # or "minimal"
};
```

---

## System Modules (`modules/system/`)

| File | Responsibility |
|:-----|:---------------|
| `options.nix` | Shared system feature and host options, imported once by the aggregate system module |
| `base.nix` | Nix daemon, power profiles, shell helpers, and package overlays |
| `boot.nix` | Limine, UEFI, dual boot, and generation retention |
| `security.nix` | Kernel/network hardening and the sandboxed Vulnix timer |
| `networking.nix` | NetworkManager, Quad9 DNS-over-TLS/DNSSEC, and Tailscale |
| `audio.nix` | Feature-gated PipeWire, PulseAudio compatibility, JACK, and RTKit |
| `containers.nix` | Feature-gated Docker and Waydroid |
| `compute.nix` | Hardware-aware Ollama service |
| `desktop.nix` | Feature-gated Hyprland UWSM session and system fonts |
| `hardware.nix` | Declarative `var.cpu` / `var.gpu` / `var.nvidia.mode` abstraction |
| `gaming.nix` | Steam, GameMode, Gamescope |
| `utils.nix` | System-wide CLI utilities and helpers |

> [!NOTE]
> `hardware.nix` uses `lib.mkIf` guards — unused hardware paths are completely eliminated. An AMD machine never evaluates Nvidia driver logic.

---

## Home Modules (`modules/home/`)

| Directory | Responsibility |
|:----------|:---------------|
| `desktop/` | Hyprland config (Lua via Hyprlang), Waybar, Dunst, Rofi, Hyprlock, Awww, GTK theming |
| `dev/` | Development profiles, Nixvim (LazyVim workflow), `mkenv` bootstrapper, templates |
| `shell/` | Zsh (vi-mode, plugins), Starship prompt, fzf, bat, eza, fd, ripgrep, zoxide |
| `entertainment/` | Gaming (MangoHud, Sober) and social (Discord, Spotify) |
| `productivity/` | Obsidian, Sioyek, TUI tools |
| `home.nix` | Base HM config, XDG compliance, session variables |

---

## Development Profiles

Defined in `modules/home/dev/default.nix` as an enum option:

```nix
options.dev = lib.mkOption {
  type = lib.types.enum [ "minimal" "full" ];
  default = "minimal";
};
```

The profiles are deliberately workstation-focused:

- `minimal.nix` supplies editors, Git/GitHub, direnv, `mkenv`, daily database/container/network utilities, and AI coding tools.
- `full.nix` inherits `minimal` and adds Godot, Blender, LibreSprite, and Winboat.

> [!TIP]
> Compilers, runtimes, SDKs, and formatters are not Home Manager packages. `_mkenv.nix` ships `mkenv`, which generates per-project `flake.nix` + `.envrc` files for the `c`, `go`, `ts`, `py`, `rust`, `flutter`, and `nix` stacks. Their caches and mutable state live under the ignored `.direnv/` directory.

Flint itself follows the same workflow. Its tracked `.envrc` runs `use flake`, and `devShells.x86_64-linux.default` provides Alejandra, nixfmt, deadnix, statix, ShellCheck, Lua, and nix-prefetch-github.

---

## Hardware Abstraction

The `var` option set in `hardware.nix` drives all hardware configuration:

```nix
var = {
  cpu = "intel";          # → microcode + thermald
  gpu = "nvidia";         # → Nvidia kernel/userspace and VA-API support
  nvidia = {
    open = true;           # required choice: true for Turing and newer
    mode = "offload";     # Intel desktop with Nvidia available on demand
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};
```

For Wayland laptops, `offload` keeps the iGPU as the compositor device and exposes
the `nvidia-offload` wrapper for applications that need the discrete GPU.
Flint intentionally does not expose X11 PRIME-sync sessions: Hyprland Wayland
under UWSM is the only supported graphical environment. Xwayland remains enabled
strictly for application compatibility.

> [!IMPORTANT]
> PRIME Bus IDs (`nvidia.intelBusId`, `nvidia.nvidiaBusId`) must be obtained with `lspci` and set explicitly on each machine.

CPU and GPU default to `null`, and Nvidia's kernel-module flavor and PRIME
bus IDs have no guessed defaults. Hosts must make those hardware decisions
explicitly.

Workstation capabilities are independently selected under `var.features`:

```nix
features = {
  desktop = true;
  audio = true;
  bluetooth = true;
  docker = true;
  gaming = true;
  steamLocalTransfers = true;
  developerKernelAccess = true;
};
```

Steam firewall features default off even when gaming is enabled. Power Profiles
Daemon remains enabled for every host to retain power-aware operation.

---

## Dual Boot

```nix
var.dualBoot = {
  enable = true;
  windowsEntry = "uuid(EFI-UUID):/EFI/Microsoft/Boot/bootmgfw.efi";
};
```

Find the Windows EFI UUID with `lsblk -f`. Limine is configured with five
generations to keep useful rollback entries without an oversized boot menu.

---

## Validation

```bash
./scripts/check.sh             # full pre-switch protocol + dry builds
./scripts/check.sh powerhouse  # validate only one host
nh os switch                   # build + activate after checks pass
```

The protocol rejects untracked Nix files, checks whitespace and formatting,
runs deadnix and statix, evaluates every flake output, and dry-builds each
requested host without realizing or activating the system closure.
