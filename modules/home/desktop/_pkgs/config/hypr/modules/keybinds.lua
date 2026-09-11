-- =============================================================================
-- Keybindings Configuration
-- https://wiki.hypr.land/Configuring/Binds/
-- =============================================================================

local mainMod     = "SUPER"

-- Applications & Launchers
local app         = "flint-launch "
local terminal    = app .. 'kitty zsh -c "fetch || true; exec zsh"'
local fileManager = app .. "dolphin"
local menu        = app .. "rofi -show drun"
local launcher    = app .. "rofi -show drun"

-- Core Application Binds
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(app .. "hyprlock"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Window Focus (Super + Arrow keys)
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Workspaces (Super + [1-9, 0])
-- Move active window to workspace (Super + Shift + [1-9, 0])
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special Workspace (Scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll Through Existing Workspaces (Super + Scroll)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/Resize Windows with Super + Mouse Dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- =============================================================================
-- Utility & Script Binds
-- =============================================================================
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

-- Multimedia Keys: Volume & Display Brightness with Dunst OSD
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scriptsDir .. "/volume.sh mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/volume.sh mic-mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/brightness.sh down"),
  { locked = true, repeating = true })

-- Media Player Controls (requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots: Print / Super+Shift+S (Region), Super+Print (Full Screen)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(scriptsDir .. "/screenshot.sh region"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(scriptsDir .. "/screenshot.sh full"))

-- Screen Recording Toggle (Super + Alt + R)
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/screenrecord.sh"))

-- Color Picker
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(scriptsDir .. "/hyprpicker.sh"))

-- Game Mode Toggle
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/gamemode.sh"))

-- Focus Mode Toggle
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(scriptsDir .. "/focusmode.sh"))

-- =============================================================================
-- Apps
-- =============================================================================

hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(app .. "helium"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(app .. "obsidian"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(app .. "spotify"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(app .. "vesktop"))
