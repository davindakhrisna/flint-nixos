#!/usr/bin/env bash
# =============================================================================
# Game Mode Toggle (Disables animations, blur, rounding for maximum performance)
# =============================================================================

RUNTIME_DIR="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/flint"
mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
STATUS_FILE="$RUNTIME_DIR/hypr_gamemode_active"

if [ -f "$STATUS_FILE" ]; then
    # --- DISABLE GAME MODE (RESTORE AESTHETICS) ---
    rm -f "$STATUS_FILE"
    hyprctl reload config-only
    notify-send -u low -i input-gaming "Game Mode" "Game Mode <b>DISABLED</b>\nAnimations and effects restored."
else
    # --- ENABLE GAME MODE ---
    touch "$STATUS_FILE"
    hyprctl repl 'return hl.config({ animations = { enabled = false }, decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } }, general = { gaps_in = 0, gaps_out = 0 } })'
    notify-send -u low -i input-gaming "Game Mode" "Game Mode <b>ENABLED</b>\nAnimations and blur disabled for maximum performance."
fi
