#!/usr/bin/env bash
# =============================================================================
# AWWW Daemon Initialization & Wallpaper Restore Script
# =============================================================================

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/awww"
CURRENT_FILE="$STATE_DIR/current_wallpaper"
mkdir -p "$STATE_DIR"

# systemd ordering starts the daemon first, but wait briefly for its socket.
for _ in {1..20}; do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done

# Restore saved wallpaper if available
if [ -f "$CURRENT_FILE" ] && [ -s "$CURRENT_FILE" ]; then
    WALL="$(cat "$CURRENT_FILE")"
    if [ -f "$WALL" ]; then
        awww img "$WALL" --transition-type none
        exit 0
    fi
fi

# Fallback: pick first image from wallpapers directory
DEFAULT_WALL="$(find "${FLINT_DIR:-$HOME/.config/flint}/modules/home/desktop/_pkgs/config/awww/wallpapers" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | head -n 1)"
if [ -n "$DEFAULT_WALL" ] && [ -f "$DEFAULT_WALL" ]; then
    awww img "$DEFAULT_WALL" --transition-type none
    echo "$DEFAULT_WALL" > "$CURRENT_FILE"
fi
