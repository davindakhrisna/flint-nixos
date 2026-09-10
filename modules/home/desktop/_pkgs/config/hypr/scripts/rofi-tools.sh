#!/usr/bin/env bash
# =============================================================================
# Rofi Tools / Scripts Launcher Mode
# =============================================================================

SCRIPTS_DIR="$HOME/.config/hypr/scripts"

# Handle action selection
if [ -n "$1" ]; then
    case "$1" in
        *"Screenshot (Regional)"*)
            "$SCRIPTS_DIR/screenshot.sh" region >/dev/null 2>&1 &
            ;;
        *"Screenshot (Full)"*|*"Screenshot (Full Screen)"*)
            "$SCRIPTS_DIR/screenshot.sh" full >/dev/null 2>&1 &
            ;;
        *"Screen Record"*)
            "$SCRIPTS_DIR/screenrecord.sh" >/dev/null 2>&1 &
            ;;
        *"Color Picker"*)
            "$SCRIPTS_DIR/hyprpicker.sh" >/dev/null 2>&1 &
            ;;
        *"Game Mode"*)
            "$SCRIPTS_DIR/gamemode.sh" >/dev/null 2>&1 &
            ;;
        *"Focus Mode"*)
            "$SCRIPTS_DIR/focusmode.sh" >/dev/null 2>&1 &
            ;;
    esac
    exit 0
fi

# List tools with Papirus-Dark icons
printf '  Screenshot (Regional)\0icon\x1fcamera-photo\x1finfo\x1fregion\n'
printf '󰹑  Screenshot (Full Screen)\0icon\x1fvideo-display\x1finfo\x1ffull\n'
printf '󰻃  Screen Record (Toggle)\0icon\x1fmedia-record\x1finfo\x1frecord\n'
printf '󰈊  Color Picker (Hyprpicker)\0icon\x1fcolor-select\x1finfo\x1fpicker\n'
printf '󰊴  Game Mode (Toggle)\0icon\x1finput-gaming\x1finfo\x1fgamemode\n'
printf '󰈈  Focus Mode (Toggle)\0icon\x1fpreferences-desktop-screensaver\x1finfo\x1ffocusmode\n'
