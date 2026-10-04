#!/usr/bin/env bash
set -euo pipefail
umask 077

destination=$1
owner=$2
group=$3
shift 3

temporary=$(mktemp "${destination}.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT

for file in "$@"; do
  if [ -r "$file" ]; then
    cat "$file" >> "$temporary"
    printf '\n' >> "$temporary"
  else
    echo "Hermes environment file is not readable: $file" >&2
  fi
done

chown "$owner:$group" "$temporary"
chmod 0640 "$temporary"
mv -f -- "$temporary" "$destination"
