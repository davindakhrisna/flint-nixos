#!/usr/bin/env bash
# =============================================================================
# Screenshot Utility (Full and Region) with Clipboard & Annotation App
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

MODE="${1:-region}"
TEMP_FILE="$(mktemp /tmp/screenshot_XXXXXX.png)"

# Capture screenshot
if [ "$MODE" = "full" ] || [ "$MODE" = "screen" ]; then
    grim "$TEMP_FILE" || { rm -f "$TEMP_FILE"; exit 1; }
else
    GEOM="$(slurp 2>/dev/null)"
    # If user cancels slurp (Escape / outside click)
    if [ -z "$GEOM" ]; then
        rm -f "$TEMP_FILE"
        exit 0
    fi
    grim -g "$GEOM" "$TEMP_FILE" || { rm -f "$TEMP_FILE"; exit 1; }
fi

# Automatically copy to clipboard
if [ -s "$TEMP_FILE" ]; then
    wl-copy --type image/png < "$TEMP_FILE"
    notify-send -u low -i camera-photo "Screenshot Taken" "Copied to clipboard. Opening annotator..."
    
    # Satty owns copying the annotated image.  The initial wl-copy above keeps
    # the unedited capture available if it is cancelled; its Copy button now
    # explicitly invokes wl-copy with the edited image.
    if command -v satty >/dev/null 2>&1; then
        satty --filename "$TEMP_FILE" \
            --copy-command wl-copy \
            --actions-on-right-click save-to-clipboard \
            --actions-on-enter save-to-clipboard \
            --early-exit all
    elif command -v swappy >/dev/null 2>&1; then
        swappy -f "$TEMP_FILE"
    fi
fi

# Clean up temp file after annotation tool closes
rm -f "$TEMP_FILE"
