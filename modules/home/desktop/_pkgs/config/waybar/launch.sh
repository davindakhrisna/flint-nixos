#!/usr/bin/env bash
# Terminate already running waybar instances
pkill -9 -x .waybar-wrapped 2>/dev/null
pkill -9 -x waybar 2>/dev/null
sleep 0.2

SHIM="$HOME/.config/waybar/shim/libhypr_waybar_shim.so"

if [ -f "$SHIM" ]; then
    LD_PRELOAD="$SHIM" exec waybar "$@"
else
    exec waybar "$@"
fi
