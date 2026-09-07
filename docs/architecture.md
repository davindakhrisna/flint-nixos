# ❄️ Flint NixOS Configuration - Architecture & Overview

Flint is a modular, multi-host NixOS configuration built with **Flake-Parts** and **Import-Tree** for clean modularity, declarative hardware abstraction, and tiered development profiles.

---

## 📁 Repository Structure

```
.
├── flake.nix                  # Flake definition with inputs and flake-parts root
├── flake.lock                 # Pinned dependencies lockfile
├── docs/                      # Documentation
│   └── offline-installation.md
├── hosts/                     # Machine-specific host configurations
│   ├── powerhouse/            # Primary desktop configuration
│   │   ├── _hardware.nix      # Disk mounts and hardware scan definitions
│   │   └── default.nix        # Host entrypoint & user declarations
│   └── template/              # Ready-to-use template for new machines
│       ├── _hardware.nix
│       └── default.nix
└── modules/                   # Shared modular components
    ├── home/                  # Home Manager modules
    │   ├── desktop/           # Hyprland, Wayland ecosystem, Dolphin, QuickShell
    │   ├── dev/               # Tiered developer tools (min / mid / max / nixvim)
    │   ├── entertainment/     # Social (Discord/Spotify) and Gaming (MangoHud/Sober)
    │   ├── productivity/      # TUI & GUI productivity apps (Obsidian, Sioyek, etc.)
    │   ├── shell/             # Zsh, Starship prompt, Modern CLI tools
    │   └── home.nix           # Base Home Manager & XDG compliance rules
    └── system/                # NixOS System-level modules
        ├── base.nix           # Kernel hardening, pipewire, docker, DNS (9.9.9.9), overlays
        ├── default.nix        # Core system modules bundle
        ├── desktop.nix        # Hyprland UWSM, Lemurs display manager, global fonts
        ├── gaming.nix         # Steam, GameMode optimizations
        ├── hardware.nix       # CPU (Intel/AMD) & GPU (Nvidia/AMD/Intel) abstractions
        └── utils.nix          # System-wide utilities and helper packages
```

---

## ⚙️ Key Architectural Features

### 1. Hardware Abstraction Layer (`var.cpu` & `var.gpu`)
Declarative hardware options defined in [`modules/system/hardware.nix`](../modules/system/hardware.nix):
- **CPU:** `"intel"` (enables microcode & thermald) or `"amd"` (enables AMD microcode).
- **GPU:** `"nvidia"` (loads proprietary drivers, VA-API acceleration, and Wayland session variables), `"amd"` (amdgpu & VA-API/VDPAU), or `"intel"`.
- **Nvidia Modes:** `"desktop"` (discrete GPU), `"offload"` (PRIME dynamic power offload), or `"sync"`.

### 2. Tiered Development Profiles (`dev`)
Configurable in each host's user configuration:
- `"off"`: No development packages or compilers loaded.
- `"min"`: C/C++ toolchain (GCC, Make), Git, GitHub CLI, direnv, and Neovim (`nixvim`).
- `"mid"`: Everything in `min` + Go, Node.js, Python, Zed Editor, container tools (`lazydocker`), and AI tools.
- `"max"`: Everything in `mid` + Flutter SDK, Android tools, Godot 4, Blender, and game/asset creation software.

### 3. DNS & Network Configuration
Default network configurations automatically set Quad9 DNS:
- Primary: `9.9.9.9`
- Secondary: `149.112.112.112`
- NetworkManager automatically prioritizes these nameservers across all network interfaces.

### 4. XDG Compliance & Dotfile Cleanliness
Strict adherence to the XDG Base Directory specification:
- Cargo, Rustup, Go, NPM, Gradle, and Android directories are redirected to `~/.local/share` and `~/.cache`.
- Legacy dotfiles (`.zshenv`, `.gtkrc-2.0`) in `$HOME` root are disabled or relocated to keep the user home directory clean.

---

## 🧪 Validation & Linting Commands

Run validation checks directly using the following commands:

```bash
# 1. Format code
nix run nixpkgs#alejandra -- .

# 2. Check for dead/unused code
nix run nixpkgs#deadnix -- .

# 3. Check for anti-patterns and style suggestions
nix run nixpkgs#statix -- check .

# 4. Dry evaluation (validate configuration logic without building)
nix eval .#nixosConfigurations.powerhouse.config.system.build.toplevel.drvPath
```
