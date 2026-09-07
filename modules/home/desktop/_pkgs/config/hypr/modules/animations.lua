-- =============================================================================
-- Animations & Motion Curves
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- =============================================================================

-- Enable animations
hl.config({
    animations = {
        enabled = true,
    },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

-- Animation tree
hl.animation({ leaf = "global",           enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",           enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",          enabled = true,  speed = 4.5,  spring = "easy" })
hl.animation({ leaf = "windowsIn",        enabled = true,  speed = 3.8,  spring = "easy",         style = "slide bottom" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 2.0,  bezier = "almostLinear", style = "slide bottom" })
hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 4.0,  spring = "easy" })
hl.animation({ leaf = "fadeIn",           enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",          enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",             enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",           enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",         enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slide top" })
hl.animation({ leaf = "layersOut",        enabled = true,  speed = 2.0,  bezier = "linear",       style = "slide top" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true,  speed = 1.39, bezier = "almostLinear" })

-- Workspaces (Vertical Up-Down Transitions)
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefadevert 20%" })
hl.animation({ leaf = "workspacesIn",     enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefadevert 20%" })
hl.animation({ leaf = "workspacesOut",    enabled = true,  speed = 3.0,  bezier = "almostLinear", style = "slidefadevert 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefadevert 20%" })

hl.animation({ leaf = "zoomFactor",       enabled = true,  speed = 7,    bezier = "quick" })
