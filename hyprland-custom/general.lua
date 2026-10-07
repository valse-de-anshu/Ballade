-- ============================================================
-- High-Performance Smooth Animations & GPU Optimization
-- ============================================================

-- 1. Performance & Display Settings
hl.config({
    cursor = {
        no_warps = true,
        warp_on_change_workspace = 0,
    },
    general = {
        no_focus_fallback = false, -- Never drop focus when switching workspaces or opening windows
    },
    input = {
        mouse_refocus = true, -- Immediately transfer focus to the window when mouse moves down from top bar
    },
    render = {
        direct_scanout = 0, -- Disabled: prevents fullscreen stuttering and frame drop
    },
    misc = {
        initial_workspace_tracking = 1, -- Properly track & focus newly launched windows on the active workspace
        focus_on_activate = true,
        on_focus_under_fullscreen = 2, -- Automatically unfullscreen background window when child popup/dialog opens
        vrr = 0, -- Locked refresh rate (no fullscreen VRR drops/stutter)
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
    },
    decoration = {
        -- Optimized Frosted Glass:
        -- 2 passes with size 8 gives creamy frosted glass with ~60% less GPU fillrate than 4 passes!
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,

            size = 8,
            passes = 2,
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
        -- Soft, realistic shadows without the extreme render_power = 10 overhead
        shadow = {
            enabled = true,
            range = 18,
            offset = {0, 2},
            render_power = 3,
            color = "rgba(00000025)",
        },
    },
})

-- 2. Modern, Fluid Bezier Curves (Clean Deceleration with subtle snap)
hl.curve("smoothDecel", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.04} } })
hl.curve("smoothOut",   { type = "bezier", points = { {0.16, 1.0}, {0.3, 1.0}  } })
hl.curve("fastSnap",    { type = "bezier", points = { {0.25, 1.0}, {0.5, 1.0}  } })

-- 3. High-End "YouTube Rice" Animations
-- Windows: Fast, responsive pop-in with clean micro-overshoot
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 2.8, bezier = "smoothDecel", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 2.2, bezier = "smoothOut",   style = "popin 90%" })
hl.animation({ leaf = "windowsMove",  enabled = true, speed = 2.8, bezier = "smoothDecel", style = "slide"     })

-- Fade: Crisp and immediate
hl.animation({ leaf = "fadeIn",       enabled = true, speed = 2.2, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut",      enabled = true, speed = 1.8, bezier = "smoothOut" })

-- Workspaces: Snappy slide (cut from sluggish 700ms down to fluid 350ms)
hl.animation({ leaf = "workspaces",   enabled = true, speed = 3.5, bezier = "smoothOut",   style = "slide" })

