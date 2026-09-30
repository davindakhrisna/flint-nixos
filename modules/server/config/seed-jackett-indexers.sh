#!/usr/bin/env bash
set -euo pipefail

api_key=$(</var/lib/secrets/jackett-api-key)
jackett="http://127.0.0.1:${JACKETT_PORT}"

for attempt in {1..30}; do
  if curl --connect-timeout 2 --max-time 5 -fsS "$jackett/api/v2.0/server/config?apikey=$api_key" >/dev/null 2>&1; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    echo "Jackett did not become ready in time" >&2
    exit 1
  fi
  sleep 1
done

for indexer in 1337x thepiratebay yts eztv limetorrents torrentgalaxy nyaasi badass-torrents solidtorrents glodls; do
  echo "Configuring Jackett indexer: $indexer"
  curl --connect-timeout 2 --max-time 10 -fsS -X POST \
    "$jackett/api/v2.0/indexers/$indexer/config?apikey=$api_key" \
    -H "Content-Type: application/json" -d '{}' >/dev/null ||
    echo "Jackett could not configure $indexer" >&2
done
