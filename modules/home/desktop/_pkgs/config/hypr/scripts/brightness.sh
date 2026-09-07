#!/usr/bin/env bash
# =============================================================================
# Display Brightness Control & Dunst OSD Notification
# Monochromatic Brutalist Dunst OSD
# =============================================================================

ACTION="$1"

case "$ACTION" in
    up)
        brightnessctl -e4 -n2 set 5%+ >/dev/null 2>&1
        ;;
    down)
        brightnessctl -e4 -n2 set 5%- >/dev/null 2>&1
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac

BRIGHT=$(brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%')

if [ -n "$BRIGHT" ]; then
    dunstify -u low -i "display-brightness" -h string:x-dunst-stack-tag:brightness -h int:value:"$BRIGHT" -a "Display" "Brightness: ${BRIGHT}%"
fi
