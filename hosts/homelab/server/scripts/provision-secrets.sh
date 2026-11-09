#!/usr/bin/env bash

set -euo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
SECRETS_FILE="${REPO_DIR}/hosts/homelab/secrets.yaml"

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=== Homelab Declarative SOPS Credentials Provisioner ===${NC}\n"

if [ -t 0 ]; then
	read -r -p "Enter username [${USERNAME:-kryisnn}]: " INPUT_USER
	USERNAME="${INPUT_USER:-${USERNAME:-kryisnn}}"

	if [ -z "${PASSWORD:-}" ]; then
		while true; do
			read -r -s -p "Enter password to apply across all services: " INPUT_PASS
			echo
			if [ -z "$INPUT_PASS" ]; then
				echo -e "${RED}Error: Password cannot be empty. Please try again.${NC}" >&2
				continue
			fi
			read -r -s -p "Confirm password: " INPUT_PASS_CONFIRM
			echo
			if [ "$INPUT_PASS" != "$INPUT_PASS_CONFIRM" ]; then
				echo -e "${RED}Error: Passwords do not match. Please try again.${NC}" >&2
				continue
			fi
			PASSWORD="$INPUT_PASS"
			break
		done
	fi
else
	USERNAME="${USERNAME:-kryisnn}"
	if [ -z "${PASSWORD:-}" ]; then
		echo -e "${RED}Error: PASSWORD environment variable is required in non-interactive mode.${NC}" >&2
		exit 1
	fi
fi

echo -e "\n${BOLD}Generating declarative secrets for user: ${GREEN}${USERNAME}${NC}..."

run_python() {
	if command -v python3 >/dev/null 2>&1; then
		python3 "$@"
	elif [ -x /run/current-system/sw/bin/python3 ]; then
		/run/current-system/sw/bin/python3 "$@"
	else
		nix --extra-experimental-features "nix-command flakes" shell nixpkgs#python3 -c python3 "$@"
	fi
}

gen_shadow_hash() {
	if command -v mkpasswd >/dev/null 2>&1; then
		mkpasswd -m sha-512 "$1"
	else
		nix --extra-experimental-features "nix-command flakes" shell nixpkgs#mkpasswd -c mkpasswd -m sha-512 "$1"
	fi
}

SHADOW_HASH=$(gen_shadow_hash "$PASSWORD")

QBIT_HASH=$(printf '%s' "$PASSWORD" | run_python -c '
import hashlib, os, base64, sys
password = sys.stdin.read()
salt = os.urandom(16)
iterations = 100000
dk = hashlib.pbkdf2_hmac("sha512", password.encode(), salt, iterations)
print(f"@ByteArray({base64.b64encode(salt).decode()}:{base64.b64encode(dk).decode()})")
')

JACKETT_KEY=$(run_python -c 'import os; print(os.urandom(16).hex())')

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
TMP_SECRETS="${TMP_DIR}/secrets.yaml"

cat <<EOF >"$TMP_SECRETS"
vaultwarden_env: |
  ADMIN_TOKEN=${PASSWORD}
couchdb_password: ${PASSWORD}
qbittorrent_webui: |
  WebUI\\Username=${USERNAME}
  WebUI\\Password_PBKDF2=${QBIT_HASH}
jackett_api_key: ${JACKETT_KEY}
user_password: ${PASSWORD}
user_password_hash: ${SHADOW_HASH}
EOF

echo -e "Encrypting secrets with SOPS..."

run_sops() {
	if command -v sops >/dev/null 2>&1; then
		sops "$@"
	else
		nix --extra-experimental-features "nix-command flakes" shell nixpkgs#sops -c sops "$@"
	fi
}

mkdir -p "$(dirname "$SECRETS_FILE")"
cd "$REPO_DIR"

run_sops --filename-override "$SECRETS_FILE" --encrypt "$TMP_SECRETS" >"${TMP_DIR}/encrypted.yaml"
mv -f "${TMP_DIR}/encrypted.yaml" "$SECRETS_FILE"

echo -e "\n${BOLD}${GREEN}✓ Declarative secrets successfully encrypted into: ${SECRETS_FILE}${NC}"
echo -e "The secrets are now managed declaratively via SOPS."
echo -e "Deploy to homelab with: ${BOLD}nh os switch${NC} or ${BOLD}nixos-rebuild switch --flake .#homelab${NC}\n"
