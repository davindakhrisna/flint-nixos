# ❄️ Flint Bootstrap - Multi-host NixOS Configuration

A clean, modular, and performant multi-host NixOS configuration built with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

---

[!WARNING] Read before proceeding

This config serve as a bootstrap to future nixos configuration, it is modular and dendritic making it easy to customize to your own liking. Please thoroughly read and check the whole configuration before proceeding into anything, it is still my personal (opinionated maybe?) configuration for my own dev workflow.

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
