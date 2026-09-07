#!/usr/bin/env bash
# =============================================================================
# Battery Monitor Daemon & Dunst Notification Dispatcher
# Monochromatic Brutalist Dunst Notifications
# =============================================================================

# Find battery device
BAT_DIR=""
for b in /sys/class/power_supply/BAT* /sys/class/power_supply/battery; do
    if [ -d "$b" ]; then
        BAT_DIR="$b"
        break
    fi
done

# Find AC adapter
AC_DIR=""
for a in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
    if [ -d "$a" ]; then
        AC_DIR="$a"
        break
    fi
done

if [ -z "$BAT_DIR" ]; then
    echo "No battery found on this system."
    exit 0
fi

get_capacity() {
    cat "$BAT_DIR/capacity" 2>/dev/null || echo 100
}

get_status() {
    cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown"
}

get_ac_online() {
    if [ -n "$AC_DIR" ] && [ -f "$AC_DIR/online" ]; then
        cat "$AC_DIR/online" 2>/dev/null || echo 1
    else
        # Fallback: if battery status is Charging or Full, treat as AC online
        local st
        st=$(get_status)
        if [ "$st" = "Charging" ] || [ "$st" = "Full" ]; then
            echo 1
        else
            echo 0
        fi
    fi
}

# Test mode for visual inspection
if [ "$1" = "--test" ]; then
    echo "Running Battery Notification Test..."
    CAP=$(get_capacity)
    dunstify -u low -i "battery-charging" -h string:x-dunst-stack-tag:battery -a "Power" "Power Connected" "AC adapter plugged in. Battery at ${CAP}%."
    sleep 1.5
    dunstify -u low -i "battery" -h string:x-dunst-stack-tag:battery -a "Power" "Power Disconnected" "Running on battery (${CAP}%)."
    sleep 1.5
    dunstify -u normal -i "battery-low" -h string:x-dunst-stack-tag:battery -a "Power" "Battery Low (20%)" "Battery is discharging. Please connect a charger."
    sleep 1.5
    dunstify -u critical -i "battery-caution" -h string:x-dunst-stack-tag:battery -a "Power" "Battery Critical (10%)" "Battery level is dangerously low (10%)."
    echo "Test completed."
    exit 0
fi

# Track alert state
WARNED_20=0
WARNED_10=0
WARNED_5=0
PREV_AC=$(get_ac_online)

while true; do
    CAP=$(get_capacity)
    STATUS=$(get_status)
    CURRENT_AC=$(get_ac_online)

    # Detect AC plug / unplug transitions
    if [ "$CURRENT_AC" -ne "$PREV_AC" ]; then
        if [ "$CURRENT_AC" -eq 1 ]; then
            dunstify -u low -i "battery-charging" -h string:x-dunst-stack-tag:battery -a "Power" "Power Connected" "AC adapter plugged in. Battery at ${CAP}%."
            # Reset warnings when plugged in
            WARNED_20=0
            WARNED_10=0
            WARNED_5=0
        else
            dunstify -u low -i "battery" -h string:x-dunst-stack-tag:battery -a "Power" "Power Disconnected" "Running on battery (${CAP}%)."
        fi
        PREV_AC="$CURRENT_AC"
    fi

    # Battery thresholds when discharging
    if [ "$CURRENT_AC" -eq 0 ] || [ "$STATUS" = "Discharging" ]; then
        if [ "$CAP" -le 5 ] && [ "$WARNED_5" -eq 0 ]; then
            dunstify -u critical -i "battery-empty" -h string:x-dunst-stack-tag:battery -a "Power" "Battery Depleted (${CAP}%)" "Battery level is critical. Connect charger now."
            WARNED_5=1
            WARNED_10=1
            WARNED_20=1
        elif [ "$CAP" -le 10 ] && [ "$WARNED_10" -eq 0 ]; then
            dunstify -u critical -i "battery-caution" -h string:x-dunst-stack-tag:battery -a "Power" "Battery Critical (${CAP}%)" "Battery level is low. Please plug in your charger."
            WARNED_10=1
            WARNED_20=1
        elif [ "$CAP" -le 20 ] && [ "$WARNED_20" -eq 0 ]; then
            dunstify -u normal -i "battery-low" -h string:x-dunst-stack-tag:battery -a "Power" "Battery Low (${CAP}%)" "Battery reached 20%. Connect charger soon."
            WARNED_20=1
        fi
    else
        # If charging/full and capacity recovered, reset thresholds
        if [ "$CAP" -gt 25 ]; then
            WARNED_20=0
            WARNED_10=0
            WARNED_5=0
        fi
    fi

    # Sleep interval: check more frequently when battery is low
    if [ "$CAP" -le 15 ]; then
        sleep 30
    else
        sleep 60
    fi
done
