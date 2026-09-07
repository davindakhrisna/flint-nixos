#!/usr/bin/env bash
# =============================================================================
# Hyprpicker Color Picker Utility
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

HYPRPICKER_CMD="hyprpicker"
if ! command -v hyprpicker >/dev/null 2>&1; then
    if [ -x "/nix/store/sd4pqfn12s6ma14a056aczc4q0jl5pc6-hyprpicker-0.4.7/bin/hyprpicker" ]; then
        HYPRPICKER_CMD="/nix/store/sd4pqfn12s6ma14a056aczc4q0jl5pc6-hyprpicker-0.4.7/bin/hyprpicker"
    fi
fi

# Run hyprpicker in hex format
COLOR="$($HYPRPICKER_CMD -f hex -l 2>/dev/null)"

if [ -n "$COLOR" ]; then
    # Copy color code to clipboard
    echo -n "$COLOR" | wl-copy
    # Trigger notification
    notify-send -u normal -i color-select "Color Picker" "Color <b>$COLOR</b> copied to clipboard"
fi
