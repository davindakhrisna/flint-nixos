#!/usr/bin/env bash
# =============================================================================
# AWWW Wallpaper Picker with Rofi Integration & Image Previews
# =============================================================================

# Wallpaper source directories
WALLPAPER_DIRS=(
    "$HOME/.config/awww/wallpapers"
    # "$HOME/Pictures/Wallpaper"
)

# Cache directory for image preview thumbnails
CACHE_DIR="$HOME/.cache/awww/thumbnails"
mkdir -p "$CACHE_DIR"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/awww"
CURRENT_FILE="$STATE_DIR/current_wallpaper"
mkdir -p "$STATE_DIR"

# Ensure awww-daemon is running
ensure_daemon() {
    if ! awww query >/dev/null 2>&1; then
        awww-daemon &
        sleep 0.3
    fi
}

# If executed directly outside of rofi (no ROFI_RETV set), launch rofi in wallpaper mode with expanded previews
if [ -z "$ROFI_RETV" ] && [ -z "$1" ]; then
    ensure_daemon
    exec rofi -show wallpaper -modi "wallpaper:$0" -theme-str 'element-icon { size: 64px; } listview { lines: 6; } element { spacing: 16px; padding: 8px 12px; }'
fi

# If user selected an entry
if [ -n "$1" ] || [ -n "$ROFI_INFO" ]; then
    ensure_daemon

    TARGET=""
    if [ -n "$ROFI_INFO" ] && [ -f "$ROFI_INFO" ]; then
        TARGET="$ROFI_INFO"
    elif [ -n "$1" ]; then
        # Look up by display name or filename in configured wallpaper directories
        for dir in "${WALLPAPER_DIRS[@]}"; do
            [ -d "$dir" ] || continue
            for file in "$dir"/*; do
                [ -f "$file" ] || continue
                base="$(basename "$file")"
                name_no_ext="${base%.*}"
                if [ "$1" = "$base" ] || [ "$1" = "$name_no_ext" ]; then
                    TARGET="$file"
                    break 2
                fi
            done
        done
    fi

    if [ -n "$TARGET" ] && [ -f "$TARGET" ]; then
        # Set wallpaper with smooth fade transition
        awww img "$TARGET" --transition-type fade --transition-duration 1.2
        # Record current wallpaper for session restore
        printf '%s\n' "$TARGET" > "$CURRENT_FILE"
    fi
    exit 0
fi

# --- Generation Mode: List wallpapers for Rofi ---

FOUND=0

for dir in "${WALLPAPER_DIRS[@]}"; do
    [ -d "$dir" ] || continue

    while IFS= read -r -d '' img; do
        [ -f "$img" ] || continue
        FOUND=1

        filename="$(basename "$img")"
        display_name="${filename%.*}"

        # Unique hash for thumbnail cache
        hash="$(echo -n "$img" | md5sum | cut -d' ' -f1)"
        thumb="$CACHE_DIR/${hash}.png"

        # Generate thumbnail if not cached or source is newer
        if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
            magick "$img" -thumbnail 128x72^ -gravity center -extent 128x72 "$thumb" 2>/dev/null
        fi

        # Pass thumbnail as icon, full path in info, filename in meta
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\x1fmeta\x1f%s\n' "$display_name" "$thumb" "$img" "$filename"
    done < <(find "$dir" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.gif" \) -print0 2>/dev/null | sort -z)
done

if [ "$FOUND" -eq 0 ]; then
    echo -en "No wallpapers found in ~/.config/awww/wallpapers\0icon\x1fdialog-information\x1fnonselectable\x1ftrue\n"
fi
