-- =============================================================================
-- Window Rules & Layer Rules
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- =============================================================================

---------------------------
---- WINDOW RULES ---------
---------------------------

-- Ignore maximize requests from all apps
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Clean popups & context menus (no borders, shadows, or background blur)
hl.window_rule({
    name      = "clean-xwayland-popups",
    match     = {
        class    = "^$",
        title    = "^$",
        xwayland = true,
        float    = true,
    },
    no_border = true,
    no_shadow = true,
    no_blur   = true,
})

hl.window_rule({
    name      = "clean-browser-popups",
    match     = {
        class    = "^(Helium|chromium|google-chrome)$",
        float    = true,
    },
    no_border = true,
    no_shadow = true,
    no_blur   = true,
})

-- Hyprland-run floating position
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Floating centered terminal for TUIs (gazelle, bluetui, etc.)
hl.window_rule({
    name   = "floating-tui-term",
    match  = { class = "floating-term" },
    float  = true,
    center = true,
    size   = "950 620",
})

-- Floating centered window rules for screenshot annotation apps (satty, swappy)
hl.window_rule({
    name   = "screenshot-annotator",
    match  = { class = "^(com\\.gabm\\.satty|satty|swappy)$" },
    float  = true,
    center = true,
})

---------------------------
---- LAYER RULES ----------
---------------------------

-- Waybar: preserve proper layer order
hl.layer_rule({
    name  = "waybar-order",
    match = { namespace = "waybar" },
    order = 1,
})

-- Rofi: dim background when launched
hl.layer_rule({
    name       = "rofi-dim",
    match      = { namespace = "^rofi$" },
    dim_around = true,
})
