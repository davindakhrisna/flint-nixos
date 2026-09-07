#!/usr/bin/env bash

# Power menu using rofi for lock, screensave, hibernate, restart, shut down

lock="  Lock"
screensave="󰍹  Screensave"
hibernate="  Hibernate"
restart="  Restart"
shutdown="  Shut Down"

chosen=$(printf "%s\n%s\n%s\n%s\n%s\n" "$lock" "$screensave" "$hibernate" "$restart" "$shutdown" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 300px; border-radius: 0px;} listview {lines: 5;}')

case "$chosen" in
    "$lock")
        hyprlock
        ;;
    "$screensave")
        hyprctl dispatch "hl.dsp.dpms('off')" 2>/dev/null || hyprctl dispatch dpms off
        ;;
    "$hibernate")
        systemctl hibernate
        ;;
    "$restart")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
