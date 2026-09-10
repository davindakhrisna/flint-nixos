#!/usr/bin/env bash
# =============================================================================
# Hyprpicker Color Picker Utility
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

# Run hyprpicker in hex format
COLOR="$(hyprpicker -f hex -l 2>/dev/null)"

if [ -n "$COLOR" ]; then
    # Copy color code to clipboard
    echo -n "$COLOR" | wl-copy
    # Trigger notification
    notify-send -u normal -i color-select "Color Picker" "Color <b>$COLOR</b> copied to clipboard"
fi
