#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_dir"

./scripts/check.sh homelab

echo "==> Checking homelab headless configuration"
test "$(nix eval --raw .#nixosConfigurations.homelab.config.networking.hostName)" = homelab
test "$(nix eval --json .#nixosConfigurations.homelab.config.var.features.desktop)" = false
test "$(nix eval --json .#nixosConfigurations.homelab.config.services.displayManager.ly.enable)" = false
