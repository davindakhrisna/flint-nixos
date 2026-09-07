#!/usr/bin/env bash
# Switch power profiles across: balanced -> performance -> power-saver -> balanced

current=$(powerprofilesctl get)

case "$current" in
    power-saver)
        next="balanced"
        ;;
    balanced)
        next="performance"
        ;;
    performance)
        next="power-saver"
        ;;
    *)
        next="balanced"
        ;;
esac

if powerprofilesctl set "$next"; then
    notify-send -t 2000 -a "Waybar" "Power Profile" "Active profile: <b>${next}</b>" -i "battery"
fi
