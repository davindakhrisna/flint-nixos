#!/usr/bin/env bash
set -euo pipefail

mode="$1"
config_file="$2"
state_file="$3"
server_json="$4"
[[ "$mode" == enable || "$mode" == disable ]] || exit 2

managed_command=""
[[ ! -f "$state_file" ]] || managed_command="$(<"$state_file")"
if [[ "$mode" == disable && -z "$managed_command" ]]; then
  exit 0
fi
if [[ "$mode" == disable && ! -e "$config_file" ]]; then
  rm -f "$state_file"
  exit 0
fi

mkdir -p "$(dirname "$config_file")"
config_input=/dev/null
[[ ! -e "$config_file" ]] || config_input="$config_file"
config_tmp="$(mktemp "$config_file.XXXXXX")"
trap 'rm -f "$config_tmp"' EXIT
jq --slurp --argjson server "$server_json" --arg mode "$mode" --arg managed "$managed_command" '
  if length == 0 then {}
  elif length == 1 and (.[0] | type == "object") then .[0]
  else error("MCP config must contain one JSON object") end
  | if (.mcpServers // {} | type) != "object" then error("mcpServers must be an object") else . end
  | if $mode == "enable" then .mcpServers.headroom = $server
    elif .mcpServers.headroom.command == $managed and .mcpServers.headroom.args == ["mcp", "serve"]
    then del(.mcpServers.headroom)
    else . end
' "$config_input" > "$config_tmp"
if ! cmp -s "$config_tmp" "$config_file"; then
  mv -f "$config_tmp" "$config_file"
fi
if [[ "$mode" == enable ]]; then
  mkdir -p "$(dirname "$state_file")"
  jq -r '.command' <<< "$server_json" > "$state_file"
else
  rm -f "$state_file"
fi
