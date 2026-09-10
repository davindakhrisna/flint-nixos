#!/usr/bin/env bash
# =============================================================================
# Focus Mode Toggle (Turns off hypridle and hyprlock)
# =============================================================================

RUNTIME_DIR="${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/flint"
mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
STATUS_FILE="$RUNTIME_DIR/hypr_focusmode_active"

if [ -f "$STATUS_FILE" ]; then
    # --- DISABLE FOCUS MODE ---
    rm -f "$STATUS_FILE"
    systemctl --user start hypridle.service 2>/dev/null || true
    notify-send -u normal -i preferences-desktop-screensaver "Focus Mode" "Focus Mode <b>DISABLED</b>\nIdle timer and auto-lock restored."
else
    # --- ENABLE FOCUS MODE ---
    touch "$STATUS_FILE"
    systemctl --user stop hypridle.service 2>/dev/null || pkill -x hypridle 2>/dev/null || true
    notify-send -u normal -i preferences-desktop-screensaver "Focus Mode" "Focus Mode <b>ENABLED</b>\nIdle timer and screen lock turned off."
fi
