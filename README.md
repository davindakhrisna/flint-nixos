# ❄️ Flint Bootstrap - Multi-host NixOS Configuration

A clean, modular, and performant multi-host NixOS configuration built with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/denful/import-tree).

---

> [!WARNING]
> This config serves as a bootstrap for future NixOS configuration. It is modular and dendritic, making it easy to customize to your own liking. Please thoroughly read and review the entire configuration before using it.

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
