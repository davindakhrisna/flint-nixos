#!/usr/bin/env bash
# =============================================================================
# Wi-Fi Toggle & Dunst OSD Notification
# =============================================================================

set -euo pipefail

notify_wifi() {
	local icon="$1"
	local message="$2"

	if command -v dunstify >/dev/null 2>&1; then
		dunstify -u low -i "$icon" -h string:x-dunst-stack-tag:wifi -a "Network" "$message"
	elif command -v notify-send >/dev/null 2>&1; then
		notify-send -u low -i "$icon" -a "Network" "$message"
	fi
}

if ! command -v nmcli >/dev/null 2>&1; then
	notify_wifi "network-wireless-offline" "Wi-Fi: Error (nmcli not found)"
	exit 1
fi

status="$(nmcli radio wifi 2>/dev/null || true)"

case "$status" in
enabled)
	if nmcli radio wifi off >/dev/null 2>&1; then
		notify_wifi "network-wireless-offline" "Wi-Fi: Disabled"
	else
		notify_wifi "network-wireless-offline" "Wi-Fi: Failed to disable"
		exit 1
	fi
	;;
disabled)
	if nmcli radio wifi on >/dev/null 2>&1; then
		notify_wifi "network-wireless" "Wi-Fi: Enabled"
	else
		notify_wifi "network-wireless-offline" "Wi-Fi: Failed to enable"
		exit 1
	fi
	;;
*)
	notify_wifi "network-wireless-offline" "Wi-Fi: Unknown state"
	exit 1
	;;
esac
