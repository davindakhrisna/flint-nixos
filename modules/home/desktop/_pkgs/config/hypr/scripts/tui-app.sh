#!/usr/bin/env bash
# =============================================================================
# Floating TUI Launcher
# Launches TUI applications in a centered floating window that exits on Escape
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

exec kitty --class floating-term -o confirm_os_window_close=0 -o "map escape quit" -e "$@"
