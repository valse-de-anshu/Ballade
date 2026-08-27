-- ============================================================
-- Personal blur override for Illogical Impulse
-- ============================================================

hl.config({
    cursor = {
        no_warps = true,
        warp_on_change_workspace = 0,
    },
    decoration = {
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,

            size = 16,
            passes = 4,
            ignore_opacity = true,

            brightness = 0.85,
            noise = 0.02,
            contrast = 1.0,
            vibrancy = 0.35,
            vibrancy_darkness = 0.5,

            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8,
        },
    },
})

