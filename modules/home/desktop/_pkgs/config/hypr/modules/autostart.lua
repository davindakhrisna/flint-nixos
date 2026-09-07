-- =============================================================================
-- Autostart Services and Daemons
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- =============================================================================

hl.on("hyprland.start", function ()
    -- Export Wayland & Hyprland environment to systemd and D-Bus for screen sharing portals
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland.service xdg-desktop-portal.service")

    -- Cursor setup
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 20")

    -- Waybar launcher script (with IPC preload shim)
    hl.exec_cmd(os.getenv("HOME") .. "/.config/waybar/launch.sh &")

    -- AWWW wallpaper daemon & restore
    hl.exec_cmd(os.getenv("HOME") .. "/.config/awww/init.sh &")

    -- Battery monitoring daemon
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/battery-monitor.sh &")
end)
