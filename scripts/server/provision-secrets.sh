#!/usr/bin/env bash

set -euo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ "$(hostname -s)" != homelab ]; then
  echo "This provisioner must run on homelab." >&2
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  exec sudo --preserve-env=USERNAME,PASSWORD,EMAIL,OPENAI_API_KEY,ANTHROPIC_API_KEY,INITIAL_PASSWORD,CUSTOM_BASE_URL,OPENAI_BASE_URL,WHATSAPP_ENABLED,WHATSAPP_MODE,WHATSAPP_ALLOWED_USERS,WHATSAPP_ALLOW_ALL_USERS,WHATSAPP_DM_POLICY,WHATSAPP_GROUP_POLICY bash "$0" "$@"
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=== Homelab Unified Service Credentials Provisioner ===${NC}\n"

ENV_FILE=""
HERMES_ONLY=false
if [ "${1:-}" = --hermes-only ]; then
  HERMES_ONLY=true
  shift
fi
if [ -n "${1:-}" ] && [ ! -f "$1" ]; then
  echo "Credentials file does not exist: $1" >&2
  exit 1
elif [ -n "${1:-}" ]; then
  ENV_FILE="$1"
elif [ -f "${SCRIPT_DIR}/.secrets.env" ]; then
  ENV_FILE="${SCRIPT_DIR}/.secrets.env"
elif [ -f "${SCRIPT_DIR}/secrets.env" ]; then
  ENV_FILE="${SCRIPT_DIR}/secrets.env"
fi

if [ -n "$ENV_FILE" ]; then
  echo -e "${BLUE}ℹ Loading credentials from ${ENV_FILE}...${NC}"
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

if [ -z "${USERNAME:-}" ]; then
  if [ -t 0 ]; then
    read -rp "Enter username [kryisnn]: " INPUT_USER
    USERNAME="${INPUT_USER:-kryisnn}"
  else
    echo -e "${RED}Error: USERNAME environment variable is required.${NC}" >&2
    exit 1
  fi
fi

if ! "$HERMES_ONLY" && [ -z "${PASSWORD:-}" ]; then
  if [ -t 0 ]; then
    read -rsp "Enter password to apply across all services: " INPUT_PASS
    echo
    if [ -z "$INPUT_PASS" ]; then
      echo -e "${RED}Error: Password cannot be empty.${NC}" >&2
      exit 1
    fi
    PASSWORD="$INPUT_PASS"
  else
    echo -e "${RED}Error: PASSWORD environment variable is required.${NC}" >&2
    exit 1
  fi
fi

EMAIL="${EMAIL:-${USERNAME}@homelab.local}"
if [ -z "${INITIAL_PASSWORD:-${PASSWORD:-}}" ]; then
  echo "Set INITIAL_PASSWORD in scripts/server/.secrets.env before provisioning 9Router." >&2
  exit 1
fi
dashboard_password="${PASSWORD:-}"
if "$HERMES_ONLY" && [ -z "$dashboard_password" ] && [ ! -s /var/lib/secrets/hermes-dashboard.env ]; then
  dashboard_password="$INITIAL_PASSWORD"
fi

SECRETS_DIR="/var/lib/secrets"
mkdir -p "$SECRETS_DIR"
chmod 0711 "$SECRETS_DIR"

echo -e "\n${BOLD}Applying credentials for user: ${GREEN}${USERNAME}${NC} (${CYAN}${EMAIL}${NC})\n"

run_python() {
  if command -v python3 >/dev/null 2>&1; then
    python3 "$@"
  elif [ -x /run/current-system/sw/bin/python3 ]; then
    /run/current-system/sw/bin/python3 "$@"
  else
    nix --extra-experimental-features "nix-command flakes" shell nixpkgs#python3 -c python3 "$@"
  fi
}

unit_exists() {
  systemctl cat "$1" >/dev/null 2>&1
}

if ! "$HERMES_ONLY"; then
  echo -e "${BOLD}[1/8] Updating local Linux account password for '${USERNAME}'...${NC}"
  if id "$USERNAME" >/dev/null 2>&1; then
    if command -v chpasswd >/dev/null 2>&1; then
      echo "${USERNAME}:${PASSWORD}" | chpasswd
      echo -e "${GREEN}✓ System password updated for '${USERNAME}'.${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ User '${USERNAME}' not found in system accounts.${NC}"
  fi

  echo -e "\n${BOLD}[2/8] Configuring Samba NAS...${NC}"
  if command -v smbpasswd >/dev/null 2>&1; then
    if id "$USERNAME" >/dev/null 2>&1; then
      printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | smbpasswd -s -a "$USERNAME" >/dev/null
      echo -e "${GREEN}✓ Samba password updated for user '${USERNAME}'.${NC}"
      systemctl try-restart samba-smbd.service samba.service 2>/dev/null || true
    else
      echo -e "${YELLOW}⚠ User '${USERNAME}' does not exist on this system yet; skipping smbpasswd.${NC}"
    fi
  else
    echo -e "${YELLOW}ℹ smbpasswd utility not found; Samba will pick up password after NixOS rebuild.${NC}"
  fi

  echo -e "\n[3/8] Configuring Obsidian Sync (CouchDB)..."
  if unit_exists couchdb.service; then
    COUCHDB_SECRET_FILE="$SECRETS_DIR/obsidian-sync-admin-password"
    secret_tmp=$(mktemp "$COUCHDB_SECRET_FILE.XXXXXX")
    printf '%s' "$PASSWORD" >"$secret_tmp"
    chmod 0640 "$secret_tmp"
    chown root:couchdb "$secret_tmp"
    mv "$secret_tmp" "$COUCHDB_SECRET_FILE"

    systemctl restart couchdb.service
    systemctl restart couchdb-init-databases.service
    echo "CouchDB admin credentials and Obsidian Sync databases updated."
  else
    echo "CouchDB is not configured on this host; skipping."
  fi

  echo -e "\n${BOLD}[4/8] Configuring Vaultwarden Admin Token...${NC}"
  VAULTWARDEN_ENV="${SECRETS_DIR}/vaultwarden.env"
  printf "ADMIN_TOKEN=%s\n" "$PASSWORD" >"$VAULTWARDEN_ENV"
  chmod 0600 "$VAULTWARDEN_ENV"
  echo -e "${GREEN}✓ Vaultwarden ADMIN_TOKEN written to ${VAULTWARDEN_ENV}.${NC}"
  systemctl restart vaultwarden.service 2>/dev/null || true

  echo -e "\n${BOLD}[5/8] Configuring qBittorrent WebUI Credentials...${NC}"
  QBITTORRENT_SECRET_FILE="${SECRETS_DIR}/qbittorrent-webui"
  QBIT_HASH=$(printf '%s' "$PASSWORD" | run_python -c '
import hashlib, os, base64, sys
password = sys.stdin.read()
salt = os.urandom(16)
iterations = 100000
dk = hashlib.pbkdf2_hmac("sha512", password.encode(), salt, iterations)
print(f"@ByteArray({base64.b64encode(salt).decode()}:{base64.b64encode(dk).decode()})")
')

  cat <<EOF >"$QBITTORRENT_SECRET_FILE"
WebUI\\Username=${USERNAME}
WebUI\\Password_PBKDF2=${QBIT_HASH}
EOF
  chmod 0640 "$QBITTORRENT_SECRET_FILE"
  if id qbittorrent >/dev/null 2>&1 && getent group nas >/dev/null 2>&1; then
    chown qbittorrent:nas "$QBITTORRENT_SECRET_FILE" 2>/dev/null || true
  elif getent group nas >/dev/null 2>&1; then
    chown root:nas "$QBITTORRENT_SECRET_FILE" 2>/dev/null || true
  fi
  echo -e "${GREEN}✓ qBittorrent credentials (PBKDF2 SHA512) written to ${QBITTORRENT_SECRET_FILE}.${NC}"

  run_python "${REPO_DIR}/modules/server/config/torrent/apply-qbittorrent-credentials.py"
  systemctl restart qbittorrent.service 2>/dev/null || true

  echo -e "\n${BOLD}[6/8] Configuring Audiobookshelf Root User...${NC}"
  if systemctl is-active --quiet audiobookshelf.service 2>/dev/null; then
    abs_res=$(printf '%s\0%s' "$USERNAME" "$PASSWORD" | run_python -c '
import json, sys
username, password = sys.stdin.buffer.read().decode().split("\0", 1)
print(json.dumps({"newRoot": {"username": username, "password": password}}))
' | curl -s -X POST "http://127.0.0.1:8000/init" \
      -H "Content-Type: application/json" --data-binary @- 2>&1 || true)
    if echo "$abs_res" | grep -q '"user"'; then
      echo -e "${GREEN}✓ Audiobookshelf initialized with root user '${USERNAME}'.${NC}"
    else
      echo -e "${BLUE}ℹ Audiobookshelf root user already configured or server initialized.${NC}"
    fi
  else
    echo -e "${BLUE}ℹ Audiobookshelf service not running yet. Run provision script again after starting.${NC}"
  fi

  echo -e "\n${BOLD}[7/8] Configuring Immich Admin Account...${NC}"
  if systemctl is-active --quiet immich-server.service 2>/dev/null; then
    immich_res=$(printf '%s\0%s\0%s' "$EMAIL" "$PASSWORD" "$USERNAME" | run_python -c '
import json, sys
email, password, username = sys.stdin.buffer.read().decode().split("\0", 2)
print(json.dumps({"email": email, "password": password, "name": username}))
' | curl -s -X POST "http://127.0.0.1:2283/api/auth/admin-sign-up" \
      -H "Content-Type: application/json" --data-binary @- 2>&1 || true)
    if echo "$immich_res" | grep -q '"id"'; then
      echo -e "${GREEN}✓ Immich admin account registered (${EMAIL}).${NC}"
    else
      echo -e "${BLUE}ℹ Immich admin account already registered or instance initialized.${NC}"
    fi
  else
    echo -e "${BLUE}ℹ Immich service not running yet. Run provision script again after starting.${NC}"
  fi

fi

echo -e "\nConfiguring Hermes Agent credentials..."
HERMES_PROVIDER_SECRET_FILE="$SECRETS_DIR/hermes-provider.env"
HERMES_DASHBOARD_SECRET_FILE="$SECRETS_DIR/hermes-dashboard.env"
# systemd reads the password on every start; keep it out of the Nix store.
ROUTER_SECRET_FILE="$SECRETS_DIR/9router.env"
router_password="${INITIAL_PASSWORD:-${PASSWORD:-}}"
router_password="${router_password//\\/\\\\}"
router_password="${router_password//\"/\\\"}"
router_secret_tmp=$(mktemp "$ROUTER_SECRET_FILE.XXXXXX")
printf 'INITIAL_PASSWORD="%s"\n' "$router_password" >"$router_secret_tmp"
chmod 0600 "$router_secret_tmp"
chown root:root "$router_secret_tmp"
mv "$router_secret_tmp" "$ROUTER_SECRET_FILE"
if unit_exists 9router.service; then
  systemctl restart 9router.service
fi
echo "9Router INITIAL_PASSWORD persisted (used only until a password hash is saved)."

# Copy only Hermes settings; shared account passwords stay in their own files.
hermes_env_keys=(
  OPENAI_API_KEY ANTHROPIC_API_KEY CUSTOM_BASE_URL OPENAI_BASE_URL
  WHATSAPP_ENABLED WHATSAPP_MODE WHATSAPP_ALLOWED_USERS WHATSAPP_ALLOW_ALL_USERS
  WHATSAPP_DM_POLICY WHATSAPP_GROUP_POLICY
)
write_hermes_value() {
  local name=$1 value=${2-${!1}}
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s="%s"\n' "$name" "$value"
}
hermes_settings_supplied=false
for name in "${hermes_env_keys[@]}"; do
  if [[ -v "$name" ]]; then
    hermes_settings_supplied=true
    break
  fi
done

if "$hermes_settings_supplied"; then
  {
    for name in "${hermes_env_keys[@]}"; do
      if [[ -v "$name" ]]; then
        write_hermes_value "$name"
      fi
    done
  } >"$HERMES_PROVIDER_SECRET_FILE.tmp"
  chmod 0600 "$HERMES_PROVIDER_SECRET_FILE.tmp"
  mv "$HERMES_PROVIDER_SECRET_FILE.tmp" "$HERMES_PROVIDER_SECRET_FILE"
  echo "Hermes provider and WhatsApp settings updated."
elif [ -s "$HERMES_PROVIDER_SECRET_FILE" ]; then
  echo "Existing Hermes provider and WhatsApp settings retained."
else
  touch "$HERMES_PROVIDER_SECRET_FILE"
  chmod 0600 "$HERMES_PROVIDER_SECRET_FILE"
  echo "No Hermes settings supplied; configure scripts/server/.secrets.env and rerun this provisioner."
fi

if [ -n "$dashboard_password" ]; then
  HERMES_DASHBOARD_SESSION_SECRET=$(run_python -c 'import secrets; print(secrets.token_urlsafe(48))')
  {
    write_hermes_value HERMES_DASHBOARD_BASIC_AUTH_USERNAME "$USERNAME"
    write_hermes_value HERMES_DASHBOARD_BASIC_AUTH_PASSWORD "$dashboard_password"
    write_hermes_value HERMES_DASHBOARD_BASIC_AUTH_SECRET "$HERMES_DASHBOARD_SESSION_SECRET"
  } >"$HERMES_DASHBOARD_SECRET_FILE.tmp"
  chmod 0600 "$HERMES_DASHBOARD_SECRET_FILE.tmp"
  mv "$HERMES_DASHBOARD_SECRET_FILE.tmp" "$HERMES_DASHBOARD_SECRET_FILE"
else
  echo "Existing Hermes dashboard credentials retained."
fi
if unit_exists hermes-agent.service; then
  systemctl restart hermes-agent.service hermes-backend.service
fi

if "$HERMES_ONLY"; then
  echo "Hermes and 9Router secrets provisioned; other service credentials unchanged."
  exit 0
fi

systemctl reset-failed jackett.service 2>/dev/null || true
systemctl try-restart jackett.service 2>/dev/null || true

echo -e "\n${BOLD}${GREEN}========================================================================"
echo -e "Credential provisioning completed; review the service messages above."
echo -e "========================================================================${NC}\n"

printf "${BOLD}%-20s %-32s %-22s %-16s${NC}\n" "SERVICE" "URL / ENDPOINT" "USERNAME / LOGIN" "PASSWORD"
printf "%-20s %-32s %-22s %-16s\n" "--------------------" "--------------------------------" "----------------------" "----------------"
printf "%-20s %-32s %-22s %-16s\n" "Glance Dashboard" "https://<tailnet>" "-" "(No Auth / Port 443)"
printf "%-20s %-32s %-22s %-16s\n" "Vaultwarden Admin" "https://<tailnet>:8444/admin" "admin_token" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Vaultwarden Vault" "https://<tailnet>:8444" "Click 'Create account'" "<Your Choice>"
printf "%-20s %-32s %-22s %-16s\n" "qBittorrent WebUI" "https://<tailnet>:8451" "${USERNAME}" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Obsidian Sync" "https://<tailnet>:8446" "admin OR ${USERNAME}" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Audiobookshelf" "https://<tailnet>:8450" "${USERNAME}" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Immich" "https://<tailnet>:8443" "${EMAIL} (Email)" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Hermes Agent" "https://<tailnet>:8449" "-" "(API Key Configured)"
printf "%-20s %-32s %-22s %-16s\n" "Samba NAS" "\\\\192.168.50.1\\nas" "${USERNAME}" "<Your Password>"
printf "%-20s %-32s %-22s %-16s\n" "Linux Shell" "tailscale ssh ${USERNAME}@homelab" "${USERNAME}" "<Your Password>"
echo
