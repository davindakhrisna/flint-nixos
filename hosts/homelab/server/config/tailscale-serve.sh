#!/usr/bin/env bash
set -euo pipefail

until tailscale status >/dev/null 2>&1; do
	sleep 2
done

dns_name=$(tailscale status --json | jq -er '.Self.DNSName | select(type == "string" and length > 0) | rtrimstr(".")' || true)

# Reconcile managed ports based on enabled services.
serve_or_off() {
	local enabled="$1"
	local port="$2"
	local target="$3"

	if [ "$enabled" = "1" ]; then
		tailscale serve --bg "--https=$port" "$target"
	else
		tailscale serve "--https=$port" off 2>/dev/null || true
	fi
}

serve_or_off "${ENABLE_GLANCE:-0}" 443 http://127.0.0.1:8080
serve_or_off "${ENABLE_IMMICH:-0}" 8443 http://127.0.0.1:2283
serve_or_off "${ENABLE_VAULTWARDEN:-0}" 8444 http://127.0.0.1:8222
serve_or_off "${ENABLE_COUCHDB:-0}" 8446 http://127.0.0.1:5984
serve_or_off "${ENABLE_DSH_WEB:-0}" 8449 http://127.0.0.1:3080
serve_or_off "${ENABLE_AUDIOBOOKSHELF:-0}" 8450 http://127.0.0.1:8000
serve_or_off "${ENABLE_QBITTORRENT:-0}" 8451 http://127.0.0.1:8090
serve_or_off "${ENABLE_JACKETT:-0}" 8452 http://127.0.0.1:9117
serve_or_off "${ENABLE_BROWSER:-0}" 8453 http://127.0.0.1:3000

# Remove obsolete/legacy Headroom port if present
tailscale serve --https=8448 off 2>/dev/null || true

if [ -n "$dns_name" ]; then
	mkdir -p /run/homelab

	if [ "${ENABLE_GLANCE:-0}" = "1" ]; then
		printf 'HOMELAB_HOST=%s\n' "$dns_name" >/run/homelab/glance.env.new
		if ! cmp -s /run/homelab/glance.env.new /run/homelab/glance.env 2>/dev/null; then
			mv /run/homelab/glance.env.new /run/homelab/glance.env
			chmod 0644 /run/homelab/glance.env
			systemctl --no-block try-restart glance.service || true
		else
			rm -f /run/homelab/glance.env.new
		fi
	fi

	if [ "${ENABLE_VAULTWARDEN:-0}" = "1" ]; then
		printf 'DOMAIN=https://%s:8444\n' "$dns_name" >/run/homelab/vaultwarden.env.new
		if ! cmp -s /run/homelab/vaultwarden.env.new /run/homelab/vaultwarden.env 2>/dev/null; then
			mv /run/homelab/vaultwarden.env.new /run/homelab/vaultwarden.env
			systemctl --no-block try-restart vaultwarden.service || true
		else
			rm -f /run/homelab/vaultwarden.env.new
		fi
	fi
fi

tailscale serve status || true
