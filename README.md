# ❄️ Flint - Multi-host NixOS Configuration

A clean, modular, and performant multi-host NixOS configuration built with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

---

## ✨ Features

- 🖥️ **Desktop:** Hyprland (Wayland) with UWSM session management, Dolphin file manager, QuickShell, Lemurs display manager, and custom fonts.
- 🛠️ **Tiered Dev Environments:** Single-switch development profile (`dev = "off" | "min" | "mid" | "max"`) featuring Neovim (`nixvim`), Zed, Flutter, Go, Node, Python, and AI tools.
- ⚡ **Declarative Hardware Layer:** Automatic configuration for Intel/AMD CPUs and Nvidia/AMD GPUs (with PRIME offload/sync support).
- 🔒 **Security & Hardening:** Kernel sysctl security parameters, RTKit, PipeWire audio stack, automated weekly Vulnix CVE vulnerability scans, and Quad9 DNS (`9.9.9.9`).
- 🧹 **100% XDG Compliant:** Clean `$HOME` with all tool caches, histories, and configs redirected to standard XDG paths.
- 🚀 **Offline Ready:** Pre-built closure exports for seamless offline installation on new machines.

---

## 📚 Documentation

- [📦 Offline Installation Guide](docs/offline-installation.md)
- [🏛️ Architecture & Module Structure](docs/architecture.md)

---

## 🚀 Quick Commands

```bash
# Validate and evaluate configuration
nix eval .#nixosConfigurations.powerhouse.config.system.build.toplevel.drvPath

# Rebuild system using Nix Helper (nh)
nh os switch

# Format & Lint
nix run nixpkgs#alejandra -- .
nix run nixpkgs#deadnix -- .
nix run nixpkgs#statix -- check .
```
