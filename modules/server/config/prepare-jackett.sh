#!/usr/bin/env bash
set -euo pipefail
umask 077

api_key_file=/var/lib/secrets/jackett-api-key
config_file=/var/lib/jackett/.config/Jackett/ServerConfig.json
mkdir -p /var/lib/jackett/.config/Jackett/Indexers

if [ ! -s "$api_key_file" ]; then
  od -An -tx1 -N16 /dev/urandom | tr -d ' \n' > "$api_key_file"
fi
chmod 0640 "$api_key_file"
chown root:jackett "$api_key_file"
api_key=$(<"$api_key_file")

if [ -s "$config_file" ]; then
  cat "$config_file"
else
  printf '{}\n'
fi | jq \
  --arg api_key "$api_key" \
  --arg flaresolverr_url "http://127.0.0.1:${FLARESOLVERR_PORT}" \
  --argjson jackett_port "$JACKETT_PORT" \
  '.APIKey = $api_key
   | .Port = $jackett_port
   | .LocalBindAddress = "127.0.0.1"
   | .AllowExternal = false
   | .AllowCORS = false
   | .UpdateDisabled = true
   | .CacheEnabled = true
   | .CacheTtl = 2100
   | .CacheMaxResultsPerIndexer = 1000
   | .FlareSolverrUrl = $flaresolverr_url
   | .FlareSolverrMaxTimeout = 55000' \
  > "$config_file.new"

chmod 0600 "$config_file.new"
chown jackett:jackett "$config_file.new"
mv -f "$config_file.new" "$config_file"
