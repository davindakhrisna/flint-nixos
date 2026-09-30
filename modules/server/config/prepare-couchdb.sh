#!/usr/bin/env bash
set -euo pipefail

secret_file=$1
admin_user=$2
sync_user=$3

test -s "$secret_file" || { echo "CouchDB admin secret is missing" >&2; exit 1; }
password=$(<"$secret_file")

# CouchDB loads local.ini after extraConfigFiles, so remove stale admin entries there.
if [ -f /var/lib/couchdb/local.ini ]; then
  sed -i "/^${admin_user}[[:space:]]*=/d; /^${sync_user}[[:space:]]*=/d" /var/lib/couchdb/local.ini
fi

printf '[admins]\n%s = %s\n%s = %s\n' "$admin_user" "$password" "$sync_user" "$password" > /run/couchdb-admin/admin.ini
chmod 0600 /run/couchdb-admin/admin.ini
