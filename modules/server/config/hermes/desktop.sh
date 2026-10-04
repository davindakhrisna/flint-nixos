#!/usr/bin/env bash
set -euo pipefail

XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
for _ in {1..50}; do
  [[ -S "$XDG_RUNTIME_DIR/bus" ]] && break
  sleep 0.2
done
[[ -S "$XDG_RUNTIME_DIR/bus" ]] || { echo "Hermes user bus is unavailable" >&2; exit 1; }
touch "$XAUTHORITY"
chmod 600 "$XAUTHORITY"
xauth -f "$XAUTHORITY" add :99 . "$(openssl rand -hex 16)"
Xvfb :99 -screen 0 1280x800x24 -nolisten tcp -auth "$XAUTHORITY" &
display_pid=$!
trap 'kill "$display_pid"' EXIT
for _ in {1..50}; do
  if xdpyinfo >/dev/null 2>&1; then break; fi
  sleep 0.1
done
xdpyinfo >/dev/null
openbox &
systemd-notify --ready
wait "$display_pid"
