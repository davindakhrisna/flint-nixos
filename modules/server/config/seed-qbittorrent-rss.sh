#!/usr/bin/env bash
set -euo pipefail

api_key=$(</var/lib/secrets/jackett-api-key)
qbittorrent="http://127.0.0.1:${QBITTORRENT_PORT}"

for attempt in {1..30}; do
  if curl -fsS "$qbittorrent/api/v2/app/version" >/dev/null 2>&1; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    echo "qBittorrent Web API did not become ready" >&2
    exit 1
  fi
  sleep 1
done

add_feed() {
  local name="$1" category="$2" url existing_url
  url="http://127.0.0.1:${JACKETT_PORT}/api/v2.0/indexers/all/results/torznab/api?apikey=$api_key&t=search"
  [ -z "$category" ] || url="$url&cat=$category"

  existing_url="$(curl -fsS "$qbittorrent/api/v2/rss/items?withData=false" | jq -r --arg path "Jackett/$name" '.[$path].url // ""')"
  [ "$existing_url" = "$url" ] && return
  if [ -n "$existing_url" ]; then
    curl -fsS -X POST "$qbittorrent/api/v2/rss/removeItem" \
      --data-urlencode "path=Jackett/$name" >/dev/null
  fi
  curl -fsS -X POST "$qbittorrent/api/v2/rss/addFeed" \
    --data-urlencode "url=$url" \
    --data-urlencode "path=Jackett/$name" >/dev/null
}

add_feed All ''
add_feed Movies 2000
add_feed TV 5000
add_feed Audio 3000
add_feed Books 7000
add_feed Anime 5070
add_feed Software 4000
add_feed HD-Movies 2040
add_feed HD-TV 5040
add_feed Lossless-Audio 3040
