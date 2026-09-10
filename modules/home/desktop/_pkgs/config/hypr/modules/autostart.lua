-- =============================================================================
-- Autostart Services and Daemons
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- =============================================================================

hl.on("hyprland.start", function ()
    -- UWSM owns the systemd environment, session targets, portals, and the
    -- user services declared by Home Manager.
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
