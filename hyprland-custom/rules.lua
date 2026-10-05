-- ===========================================================
-- Personal window rules for Illogical Impulse
-- ============================================================

-- Re-enable blur for all normal windows (Frosted Glass)
hl.window_rule({
    match = { class = ".*" },
    no_blur = false,
})

-- Frosted glass window transparency (0.93 active, 0.88 inactive)
hl.window_rule({
    match = { class = ".*" },
    opacity = "0.93 0.88",
})


-- NOTE: Kitty and Dolphin no longer auto-open in compact float mode.
-- Use Super+Alt+Space to manually toggle any window into a centered compact float.
-- The auto-tile daemon (auto_tile_multiwindow.py) will tile them when a 2nd window opens.

-- Compact floating popup for Gwenview screenshot annotation
hl.window_rule({
    match = { class = "org.kde.gwenview" },
    float = true,
    size = { 1000, 650 },
    center = true,
})

-- Frosted glass blur for desktop background widgets (same as sidebars)
hl.layer_rule({ match = { namespace = "quickshell:desktopWidgets" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:desktopWidgets" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:desktopWidgets" }, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "quickshell:desktopWidgets" }, no_anim = true })

-- Frosted glass blur for Settings panel (SUPER+I)
hl.layer_rule({ match = { namespace = "quickshell:settings" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:settings" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:settings" }, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "quickshell:settings" }, no_anim = true })

-- Frosted glass blur for Desktop Context Menu
hl.layer_rule({ match = { namespace = "quickshell:desktopMenu" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:desktopMenu" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:desktopMenu" }, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "quickshell:desktopMenu" }, no_anim = true })

-- Frosted glass blur for Bar (top, bottom, left, right)
hl.layer_rule({ match = { namespace = "quickshell:bar" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, ignore_alpha = 0.05 })

hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, ignore_alpha = 0.05 })


