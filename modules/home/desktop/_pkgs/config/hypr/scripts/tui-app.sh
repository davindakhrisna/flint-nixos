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

# Gazelle uses ANSI colors semantically. Give it a restrained accessible
# palette instead of Kitty's intentionally near-monochrome global palette.
if [ "${1:-}" = "gazelle" ]; then
    kitty_options+=(
        -o color1=#ff6b6b -o color2=#8bd49c -o color3=#f2d478
        -o color4=#7aa2f7 -o color5=#c099ff -o color6=#7dcfff
        -o color9=#ff8e8e -o color10=#a6e3a1 -o color11=#ffe59a
        -o color12=#9ab8ff -o color13=#d5b3ff -o color14=#9de7f7
    )
fi

exec kitty "${kitty_options[@]}" -e "$@"
