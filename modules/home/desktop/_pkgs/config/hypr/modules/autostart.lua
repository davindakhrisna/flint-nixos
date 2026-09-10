-- =============================================================================
-- Autostart Services and Daemons
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- =============================================================================

hl.on("hyprland.start", function ()
    -- UWSM owns the systemd environment, session targets, portals, and the
    -- user services declared by Home Manager.
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    -- Start the visible session components as soon as the compositor socket is
    -- ready instead of waiting for graphical-session.target to settle.
    hl.exec_cmd("systemctl --user start --no-block waybar.service awww-restore.service flint-battery-monitor.service")
end)
