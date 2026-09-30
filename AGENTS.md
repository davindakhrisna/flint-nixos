# Repository Guidelines

## Project Structure & Module Organization

Flint is a multi-host NixOS flake. `flake.nix` uses flake-parts and import-tree to discover module `.nix` files under `modules/` and `hosts/`. Put machine definitions in `hosts/<name>/default.nix` and machine-specific hardware in `hosts/<name>/_hardware.nix`. Shared system settings live in `modules/system/`; Home Manager settings live in `modules/home/` by area (`desktop/`, `dev/`, `shell/`, and others). Custom package definitions live in `modules/system/packages/` with `_`-prefixed names so import-tree skips them. `scripts/` holds maintenance commands, and `docs/` holds guides. There is no separate test directory.

## Build, Test, and Development Commands

- `nix develop` enters the tooling shell; direnv loads it from `.envrc` when available.
- `alejandra .` formats Nix files. `deadnix .` and `statix check .` find unused Nix code and common anti-patterns.
- `./scripts/check.sh` checks formatting, shell and Lua syntax, flake outputs, and dry-builds all hosts. Pass a host, such as `./scripts/check.sh powerhouse`, to limit the dry-builds.
- `nh os switch` builds and activates the local system after validation. Use it only on the intended host.

## Coding Style & Naming Conventions

Follow nearby Nix code: two-space indentation, descriptive option names, and small files grouped by responsibility. Format Nix with Alejandra; the validation script enforces it. Keep shell scripts Bash-compatible and ShellCheck-clean. Place host-specific values in `hosts/` rather than shared modules. New `.nix` files must be tracked by Git before flake evaluation can see them.

## Testing Guidelines

This repository has no dedicated unit-test framework or coverage target. Treat `./scripts/check.sh` as the required pre-switch check. It also validates project flake templates, runs `shellcheck`, parses desktop Lua and Waybar JSONC, runs `deadnix` and `statix`, and checks the flake without building it. For a host change, run the check with that host name; for shared changes, check all hosts.

## Commit & Pull Request Guidelines

Recent commits use short subjects such as `feat(dev): ...`, `fix(waybar): ...`, and `add: ...`. Use a concise verb and scope when useful. In pull requests, explain affected hosts or modules, include the validation command and result, link a relevant issue when one exists, and add screenshots for visible desktop changes. Call out hardware assumptions and any change that requires a system switch.
