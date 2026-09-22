#!/usr/bin/env bash
# =============================================================================
# Focus Mode Status Indicator for Waybar
# =============================================================================

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/flint"
STATUS_FILE="$RUNTIME_DIR/hypr_focusmode_active"

if [ -f "$STATUS_FILE" ]; then
    printf '{"text":"󰈈\\nON","tooltip":"Focus Mode","class":"on"}\n'
else
    printf '{"text":"󰈉\\nOFF","tooltip":"Focus Mode","class":"off"}\n'
fi
