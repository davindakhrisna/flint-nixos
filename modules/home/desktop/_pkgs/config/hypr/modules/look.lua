-- =============================================================================
-- Look & Feel: Appearance, Borders, Gaps, Decoration & Misc
-- https://wiki.hypr.land/Configuring/Basics/Variables/
-- =============================================================================

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 20,

        border_size = 1,

        col = {
            active_border   = "rgba(255, 255, 255, 0.4)",
            inactive_border = "rgba(0, 0, 0, 1)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 0,
        rounding_power = 0,

        -- Transparency of focused and unfocused windows
        active_opacity   = 0.95,
        inactive_opacity = 0.50,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled        = true,
            size           = 6,
            passes         = 2,
            vibrancy       = 0.1696,
            ignore_opacity = true,
        },
    },

    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true,  -- Disables the random hyprland logo / background
    },

    cursor = {
        no_hardware_cursors  = false, -- KMS hardware cursor plane prevents full-frame re-render on mouse movement
        enable_hyprcursor    = true,
        sync_gsettings_theme = true,
    },

    render = {
        direct_scanout = 1, -- Direct scanout for fullscreen apps bypasses compositor
    },
})
