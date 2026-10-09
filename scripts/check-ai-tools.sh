#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
validation_dir="$(mktemp -d)"
trap 'rm -rf "$validation_dir"' EXIT
config_file="$validation_dir/agent/mcp.json"
state_file="$validation_dir/state/headroom"
server='{"type":"stdio","command":"/managed/headroom","args":["mcp","serve"],"env":{"HEADROOM_MCP_CHECK_PROXY":"0"}}'
manage() {
  bash "$repo_root/modules/home/dev/config/headroom-mcp.sh" "$1" "$config_file" "$state_file" "$server"
}
manage enable
jq -e '.mcpServers.headroom.command == "/managed/headroom"' "$config_file" >/dev/null
cp "$config_file" "$validation_dir/first.json"
manage enable
cmp "$config_file" "$validation_dir/first.json"

# Other servers, settings and explicit denylist choices survive registration.
jq '.mcpServers.other = {command:"custom"} | .disabledServers = ["other"] | .custom = 42' "$config_file" > "$validation_dir/edit.json"
mv "$validation_dir/edit.json" "$config_file"
manage enable
jq -e '.mcpServers.other.command == "custom" and .custom == 42 and .disabledServers == ["other"]' "$config_file" >/dev/null
manage disable
jq -e '(.mcpServers | has("headroom") | not) and .mcpServers.other.command == "custom"' "$config_file" >/dev/null
test ! -e "$state_file"

# A user-replaced Headroom command is not removed on a light-profile switch.
manage enable
jq '.mcpServers.headroom.command = "/custom/headroom"' "$config_file" > "$validation_dir/edit.json"
mv "$validation_dir/edit.json" "$config_file"
manage disable
jq -e '.mcpServers.headroom.command == "/custom/headroom"' "$config_file" >/dev/null

# Malformed JSON/config shape must never destroy either config or ownership state.
for invalid in '{invalid' 'null' '[]' '{} {}' '{"mcpServers":42}'; do
  printf '%s' "$invalid" > "$config_file"
  printf 'unchanged-state' > "$state_file"
  if manage enable 2>/dev/null; then
    echo "Error: accepted invalid MCP configuration" >&2
    exit 1
  fi
  test "$(<"$config_file")" = "$invalid"
  test "$(<"$state_file")" = unchanged-state
done
rm "$config_file"
manage disable
test ! -e "$config_file"
test ! -e "$state_file"
echo "AI tool configuration checks passed"
