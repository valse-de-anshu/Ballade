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

-- Frosted glass blur for Window Overview and Clipboard
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.05 })

hl.layer_rule({ match = { namespace = "quickshell:clipboard" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:clipboard" }, xray = true })
hl.layer_rule({ match = { namespace = "quickshell:clipboard" }, ignore_alpha = 0.05 })

-- Lock faux screen corners from animating or scaling (prevents corner dark glitch & flicker)
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, no_anim = true })

-- ============================================================
-- AIRI Desktop Companion (Waifu) Rules
-- ============================================================
-- All Stage Tamagotchi windows must float
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*" },
    float = true,
})

-- Main floating waifu avatar: completely transparent, borderless, pinned across workspaces
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*", title = "^AIRI$" },
    float = true,
    pin = true,
    no_blur = true,
    no_shadow = true,
    border_size = 0,
    opacity = "1.0 1.0",
    size = { 450, 600 },
})

-- Floating chat bubble window
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*", title = "^Chat$" },
    float = true,
    pin = true,
    no_blur = true,
    no_shadow = true,
    border_size = 0,
})

-- Auxiliary AIRI windows (Onboarding, Settings, DevTools)
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*", title = ".*Welcome.*" },
    float = true,
    center = true,
    size = { 1000, 650 },
})
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*", title = ".*Settings.*" },
    float = true,
    center = true,
    size = { 1000, 650 },
})
hl.window_rule({
    match = { class = ".*stage-tamagotchi.*", title = ".*Developer Tools.*" },
    float = true,
    size = { 900, 600 },
})



