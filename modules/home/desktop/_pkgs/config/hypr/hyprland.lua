-- =============================================================================
-- Hyprland Main Configuration
-- Modular Architecture
-- =============================================================================

-- 1. Hardware & Outputs
require("modules.monitors")

-- 2. Environment Variables
require("modules.env")

-- 3. Startup & Daemons
require("modules.autostart")

-- 4. Appearance (Borders, Gaps, Colors, Decoration, Blur, Shadow)
require("modules.look")

-- 5. Motion (Bezier Curves, Springs, Animation Rules)
require("modules.animations")

-- 6. Window Layouts (Dwindle, Master, Scrolling)
require("modules.layouts")

-- 7. Input Devices (Keyboard, Mouse, Touchpad, Gestures)
require("modules.input")

-- 8. Window & Layer Rules (Focus rules, Float rules, Dimming, Layer ordering)
require("modules.rules")

-- 9. Keybindings
require("modules.keybinds")
