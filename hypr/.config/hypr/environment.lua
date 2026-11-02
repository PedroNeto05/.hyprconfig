-- See https://wiki.hypr.land/configuring/core/environment-variables/

-- Cursor Wayland (Hyprcursor)
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "20")

-- Cursor XWayland / GTK
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")

-- Desktop/session info
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- GTK backend
hl.env("GDK_BACKEND", "wayland,x11,*")

-- Qt
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- GTK / Libadwaita
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")
hl.env("GTK_APPEARANCE_PREFERENCE", "dark")
