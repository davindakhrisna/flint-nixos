#!/usr/bin/env bash
set -euo pipefail

secret_file=$1
admin_user=$2
password=$(<"$secret_file")
auth_header="Authorization: Basic $(printf '%s' "${admin_user}:${password}" | base64 -w 0)"

for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:5984/_up >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -fsS http://127.0.0.1:5984/_up >/dev/null

for db in _users _replicator _global_changes obsidian-sync; do
  status=$(curl -sS -o /dev/null -w '%{http_code}' -H "$auth_header" -X PUT "http://127.0.0.1:5984/$db")
  case "$status" in
    201|202|412) ;;
    *) echo "CouchDB database $db returned HTTP $status" >&2; exit 1 ;;
  esac
done
