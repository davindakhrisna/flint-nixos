#!/usr/bin/env bash
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
    notify-send -t 2500 -a "Waybar" "Bluetooth" "bluetoothctl is unavailable"
    exit 1
fi

controller_info="$(bluetoothctl show 2>/dev/null || true)"
powered="$(printf '%s\n' "$controller_info" | awk '/Powered:/ {print $2; exit}')"
case "$powered" in
    yes)
        bluetoothctl power off >/dev/null
        state="Off"
        ;;
    no)
        bluetoothctl power on >/dev/null
        state="On"
        ;;
    *)
        notify-send -t 2500 -a "Waybar" "Bluetooth" "No Bluetooth controller found"
        exit 1
        ;;
esac

notify-send -t 2000 -a "Waybar" "Bluetooth" "Powered ${state}"
