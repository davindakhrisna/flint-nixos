#!/usr/bin/env bash
# =============================================================================
# Do Not Disturb (DnD) Mode Toggle
# Blocks and silences incoming desktop notifications via dunstctl
# =============================================================================

set -euo pipefail

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/flint"
mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
STATUS_FILE="$RUNTIME_DIR/hypr_dnd_active"

is_dnd_active() {
    if [ -f "$STATUS_FILE" ]; then
        return 0
    fi
    if command -v dunstctl >/dev/null 2>&1; then
        if dunstctl is-paused -e 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

enable_dnd() {
    touch "$STATUS_FILE"
    notify-send -u normal -i preferences-desktop-notification-bell "Do Not Disturb" "Do Not Disturb <b>ENABLED</b>\nNotifications are silenced." 2>/dev/null || true
    sleep 0.5
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused true 2>/dev/null || true
    fi
}

disable_dnd() {
    rm -f "$STATUS_FILE"
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused false 2>/dev/null || true
    fi
    notify-send -u normal -i preferences-desktop-notification-bell "Do Not Disturb" "Do Not Disturb <b>DISABLED</b>\nNotifications are restored." 2>/dev/null || true
}

case "${1:-toggle}" in
    on|enable)
        enable_dnd
        ;;
    off|disable)
        disable_dnd
        ;;
    status)
        if is_dnd_active; then
            echo "on"
            exit 0
        else
            echo "off"
            exit 1
        fi
        ;;
    toggle|*)
        if is_dnd_active; then
            disable_dnd
        else
            enable_dnd
        fi
        ;;
esac
