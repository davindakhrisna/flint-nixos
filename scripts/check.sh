#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
validation_tmp="$(mktemp -d)"
trap 'rm -rf -- "$validation_tmp"' EXIT

if (($# > 0)); then
  hosts=("$@")
else
  mapfile -t hosts < <(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]')
fi

echo "==> Checking Git visibility"
untracked_files="$(git ls-files --others --exclude-standard | grep -vxF 'TODO.md' || true)"
if [[ -n "$untracked_files" ]]; then
  echo "Error: Git-backed flakes cannot see these untracked files:" >&2
  printf '%s\n' "$untracked_files" >&2
  echo "Stage them or add an intentional ignore rule before evaluation." >&2
  exit 1
fi

echo "==> Checking whitespace"
git diff --check
git diff --cached --check

echo "==> Checking formatting"
alejandra --check .
for template in modules/home/dev/templates/*/flake.nix.template; do
  stack="$(basename "$(dirname "$template")")"
  stack_dir="$validation_tmp/$stack"
  mkdir -p "$stack_dir"
  cp "$template" "$stack_dir/flake.nix"
  printf 'use flake\n' >"$stack_dir/.envrc"
  alejandra --check "$stack_dir/flake.nix"
  nix-instantiate --parse "$template" >/dev/null
  nix flake check "path:$stack_dir" --no-build --all-systems
done

echo "==> Checking shell scripts"
shellcheck scripts/*.sh
find modules/home -type f -name '*.sh' -print0 | xargs -0 shellcheck

echo "==> Checking desktop configuration syntax"
find modules/home/desktop -type f -name '*.lua' -print0 | xargs -0 luac -p
sed -E 's@^[[:space:]]*//.*$@@; s@([},])[[:space:]]*//.*$@\1@' \
  modules/home/desktop/_pkgs/config/waybar/config.jsonc | jq empty

echo "==> Checking dead code"
deadnix --fail .

echo "==> Running static analysis"
statix check .

echo "==> Evaluating flake outputs"
nix flake check --no-build

for host in "${hosts[@]}"; do
  echo "==> Dry-building $host"
  nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --dry-run
done

echo "==> All checks passed"
