#!/usr/bin/env bash
# =============================================================================
# AWWW Daemon Initialization & Wallpaper Restore Script
# =============================================================================

# Start awww-daemon if not already running
if ! awww query >/dev/null 2>&1; then
    awww-daemon &
    sleep 0.3
fi

CURRENT_FILE="$HOME/.config/awww/current_wallpaper"

# Restore saved wallpaper if available
if [ -f "$CURRENT_FILE" ] && [ -s "$CURRENT_FILE" ]; then
    WALL="$(cat "$CURRENT_FILE")"
    if [ -f "$WALL" ]; then
        awww img "$WALL" --transition-type none
        exit 0
    fi
fi

# Fallback: pick first image from wallpapers directory
DEFAULT_WALL="$(find "$HOME/.config/awww/wallpapers" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | head -n 1)"
if [ -n "$DEFAULT_WALL" ] && [ -f "$DEFAULT_WALL" ]; then
    awww img "$DEFAULT_WALL" --transition-type none
    echo "$DEFAULT_WALL" > "$CURRENT_FILE"
fi
