#!/usr/bin/env bash
set -euo pipefail

[[ $# == 2 && "$1" =~ ^[0-9]{4}$ && "$2" =~ ^[0-9]{4,5}$ ]] || {
  echo "Usage: flint-hermes-serve HTTPS_PORT LOCAL_PORT" >&2; exit 2;
}
public=$((10#$1))
local_port=$((10#$2))
((public >= 8460 && public <= 8499 && local_port >= 1024 && local_port <= 65535)) || exit 2
exec 9>/run/lock/flint-hermes-serve.lock
flock -x 9
status=$(tailscale serve status --json)
jq -e 'type == "object" and (.TCP == null or (.TCP | type == "object"))' <<< "$status" >/dev/null
if jq -e --arg port "$public" '(.TCP // {}) | has($port)' <<< "$status" >/dev/null; then
  echo "Tailscale port $public is already in use; choose another" >&2; exit 1;
fi
exec tailscale serve --bg --https="$public" "http://127.0.0.1:$local_port"
