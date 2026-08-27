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
