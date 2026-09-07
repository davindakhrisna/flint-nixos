#!/usr/bin/env bash
# =============================================================================
# Screen Recording Toggle Utility (wf-recorder / wl-screenrec)
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

PID_FILE="/tmp/screenrecording.pid"
NAME_FILE="/tmp/screenrecording.path"

# Check if recording is active
is_recording() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        return 0
    elif pgrep -x wf-recorder >/dev/null 2>&1 || pgrep -x wl-screenrec >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

if is_recording; then
    # --- STOP RECORDING ---
    REC_PID=""
    [ -f "$PID_FILE" ] && REC_PID="$(cat "$PID_FILE" 2>/dev/null)"
    
    # Send SIGINT to gracefully close the video container
    if [ -n "$REC_PID" ] && kill -0 "$REC_PID" 2>/dev/null; then
        kill -INT "$REC_PID" 2>/dev/null
    else
        pkill -INT -x wf-recorder 2>/dev/null || pkill -INT -x wl-screenrec 2>/dev/null
    fi
    
    # Wait for recorder to flush file
    sleep 0.8
    rm -f "$PID_FILE"

    SAVED_FILE=""
    [ -f "$NAME_FILE" ] && SAVED_FILE="$(cat "$NAME_FILE" 2>/dev/null)"
    rm -f "$NAME_FILE"

    if [ -n "$SAVED_FILE" ] && [ -f "$SAVED_FILE" ]; then
        echo -n "$SAVED_FILE" | wl-copy
        notify-send -u normal -i media-playback-stop "Screen Recording Stopped" "Saved to $(basename "$SAVED_FILE")\n(Path copied to clipboard)"
    else
        notify-send -u normal -i media-playback-stop "Screen Recording Stopped" "Recording saved to ~/Videos"
    fi
else
    # --- START RECORDING ---
    # Ensure ~/Videos exists (handles minimal installs)
    VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
    mkdir -p "$VIDEOS_DIR"

    FILENAME="$VIDEOS_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    echo "$FILENAME" > "$NAME_FILE"

    # Start recorder (wf-recorder preferred, fallback to wl-screenrec)
    if command -v wf-recorder >/dev/null 2>&1; then
        wf-recorder -f "$FILENAME" >/dev/null 2>&1 &
        REC_PID=$!
    elif command -v wl-screenrec >/dev/null 2>&1; then
        wl-screenrec -f "$FILENAME" >/dev/null 2>&1 &
        REC_PID=$!
    else
        notify-send -u critical -i dialog-error "Screen Recording Error" "Neither wf-recorder nor wl-screenrec found!"
        exit 1
    fi

    echo "$REC_PID" > "$PID_FILE"
    notify-send -u normal -i media-record "Screen Recording Started" "Recording to $(basename "$FILENAME")\nTrigger again to stop."
fi
