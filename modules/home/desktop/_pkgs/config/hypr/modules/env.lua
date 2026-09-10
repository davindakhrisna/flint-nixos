-- =============================================================================
-- Environment Variables
-- =============================================================================

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")

-- Path
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or ""))

-- Toolkit & Desktop Identity
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- GTK Theme & Dark Preference
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("GDK_BACKEND", "wayland,x11,*")

-- Qt Theming & Integration
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_STYLE_OVERRIDE", "adwaita-dark")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- GPU & Rendering. AQ_DRM_DEVICES is host-owned because DRM card ordering is
-- hardware-specific; do not override its stable PCI paths here.
hl.env("AQ_NO_MODIFIERS", "1") -- Linear multi-gpu buffer allocation avoids modifier fallback stalls
hl.env("__GL_VRR_ALLOWED", "0") -- Fix 144Hz panel refresh timing
