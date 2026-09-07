#!/usr/bin/env bash
# =============================================================================
# Volume Control & Dunst OSD Notification
# Monochromatic Brutalist Dunst OSD
# =============================================================================

ACTION="$1"

case "$ACTION" in
    up)
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        MIC_OUT=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        if echo "$MIC_OUT" | grep -q "MUTED"; then
            dunstify -u low -i "microphone-sensitivity-muted" -h string:x-dunst-stack-tag:mic -a "Audio" "Microphone: Muted"
        else
            dunstify -u low -i "microphone-sensitivity-high" -h string:x-dunst-stack-tag:mic -a "Audio" "Microphone: Active"
        fi
        exit 0
        ;;
    *)
        echo "Usage: $0 {up|down|mute|mic-mute}"
        exit 1
        ;;
esac

OUT=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOL=$(echo "$OUT" | awk '{print int($2 * 100)}')

if echo "$OUT" | grep -q "MUTED"; then
    dunstify -u low -i "audio-volume-muted" -h string:x-dunst-stack-tag:volume -h int:value:0 -a "Audio" "Volume: Muted"
else
    if [ "$VOL" -ge 70 ]; then
        ICON="audio-volume-high"
    elif [ "$VOL" -ge 30 ]; then
        ICON="audio-volume-medium"
    else
        ICON="audio-volume-low"
    fi
    dunstify -u low -i "$ICON" -h string:x-dunst-stack-tag:volume -h int:value:"$VOL" -a "Audio" "Volume: ${VOL}%"
fi
