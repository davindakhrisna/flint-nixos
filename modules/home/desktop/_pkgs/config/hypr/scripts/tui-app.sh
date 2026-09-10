#!/usr/bin/env bash
# =============================================================================
# Floating TUI Launcher
# Launches TUI applications in a centered floating window that exits on Escape
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

kitty_options=(
    --class floating-term
    -o confirm_os_window_close=0
    -o "map escape quit"
)

exec uwsm app -- kitty "${kitty_options[@]}" -e "$@"
