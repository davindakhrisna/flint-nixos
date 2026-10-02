#!/usr/bin/env bash
# =============================================================================
# Reload Desktop Components (Waybar, Wallpaper, Rofi)
# =============================================================================

set -euo pipefail

# Ensure graphical session or Hyprland compositor is active
if ! systemctl --user is-active --quiet graphical-session.target 2>/dev/null && ! pgrep -x Hyprland >/dev/null 2>&1; then
    exit 0
fi

# 1. Close any running Rofi instance and purge application drun cache
pkill -x rofi 2>/dev/null || true
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/rofi"*.druncache 2>/dev/null || true

# 2. Restart Waybar status bar
systemctl --user restart waybar.service 2>/dev/null || true

# 3. Reload Wallpaper (awww daemon + restore)
systemctl --user try-restart awww.service 2>/dev/null || true
systemctl --user restart awww-restore.service 2>/dev/null || true

# 4. Notify user
if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low -t 2000 -i view-refresh -a "Flint" "Desktop Reloaded" "Waybar, wallpaper, and Rofi refreshed." 2>/dev/null || true
fi
