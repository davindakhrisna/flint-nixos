#!/usr/bin/env bash

until tailscale status >/dev/null 2>&1; do
  sleep 2
done

dns_name=$(tailscale status --json | jq -er '.Self.DNSName | select(type == "string" and length > 0) | rtrimstr(".")' || true)

tailscale serve reset
tailscale serve --bg --https=443 http://127.0.0.1:8080
tailscale serve --bg --https=8443 http://127.0.0.1:2283
tailscale serve --bg --https=8444 http://127.0.0.1:8222
tailscale serve --bg --https=8446 http://127.0.0.1:5984
tailscale serve --bg --https=8448 http://127.0.0.1:8787
tailscale serve --bg --https=8449 http://127.0.0.1:9120
tailscale serve --bg --https=8450 http://127.0.0.1:8000
tailscale serve --bg --https=8451 http://127.0.0.1:8090
tailscale serve --bg --https=8452 http://127.0.0.1:9117

if [ -n "$dns_name" ]; then
  mkdir -p /run/homelab

  printf 'HOMELAB_HOST=%s\n' "$dns_name" > /run/homelab/glance.env.new
  if ! cmp -s /run/homelab/glance.env.new /run/homelab/glance.env 2>/dev/null; then
    mv /run/homelab/glance.env.new /run/homelab/glance.env
    chmod 0644 /run/homelab/glance.env
    systemctl --no-block try-restart glance.service || true
  else
    rm -f /run/homelab/glance.env.new
  fi

  printf 'DOMAIN=https://%s:8444\n' "$dns_name" > /run/homelab/vaultwarden.env.new
  if ! cmp -s /run/homelab/vaultwarden.env.new /run/homelab/vaultwarden.env 2>/dev/null; then
    mv /run/homelab/vaultwarden.env.new /run/homelab/vaultwarden.env
    systemctl --no-block try-restart vaultwarden.service || true
  else
    rm -f /run/homelab/vaultwarden.env.new
  fi

  printf 'HERMES_DASHBOARD_PUBLIC_URL=https://%s:8449\n' "$dns_name" > /run/homelab/hermes.env.new
  if ! cmp -s /run/homelab/hermes.env.new /run/homelab/hermes.env 2>/dev/null; then
    mv /run/homelab/hermes.env.new /run/homelab/hermes.env
    systemctl --no-block try-restart hermes-backend.service || true
  else
    rm -f /run/homelab/hermes.env.new
  fi
fi

tailscale serve status || true
