#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

host="${1:-powerhouse}"
destination="${2:-$PWD/flint-offline-$host}"
destination="$(realpath -m "$destination")"

dirty_files="$(git status --porcelain | grep -vxF '?? TODO.md' || true)"
if [[ -n "$dirty_files" ]]; then
  echo "Error: commit all configuration changes before creating an offline bundle." >&2
  printf '%s\n' "$dirty_files" >&2
  exit 1
fi

if [[ -e "$destination" ]]; then
  echo "Error: destination already exists: $destination" >&2
  exit 1
fi

mkdir -p "$destination/cache" "$destination/flint"

echo "==> Building $host"
system_path="$(nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link --print-out-paths)"

echo "==> Copying the system closure"
nix copy --to "file://$destination/cache" "$system_path"

echo "==> Archiving the flake and every locked input"
flake_path="$(nix flake archive --json --to "file://$destination/cache" . | jq -r '.path')"

echo "$system_path" >"$destination/system-store-path"
echo "$flake_path" >"$destination/flake-store-path"
git rev-parse HEAD >"$destination/git-revision"
git archive HEAD | tar -x -C "$destination/flint"

cat >"$destination/INSTALL.txt" <<EOF
Flint offline installation bundle for: $host

1. Mount the target filesystems under /mnt and this bundle under /mnt-usb.
2. Import every closure and flake-input path:
     nix copy --all --from file:///mnt-usb/cache
3. Install from the archived flake store path:
     nixos-install --flake path:$(cat "$destination/flake-store-path")#$host --no-channel-copy
4. Set passwords when prompted, then reboot.

The editable committed source is included in the flint/ directory.
EOF

echo "==> Offline bundle created at $destination"
