hl.unbind("CTRL + SUPER + T")
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd("qs -c ballade ipc call wallpaperSelector toggle"), {description = "Shell: Toggle wallpaper selector"} )
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("SUPER+ALT+Space", hl.dsp.exec_cmd("bash ~/.config/hypr/custom/scripts/compact_window.sh"), {description = "Toggle compact centered window"} )

-- Disable panel family cycling (prevents UI corruption on CTRL+SUPER+P)
hl.unbind("CTRL + SUPER + P")

-- Bind SUPER+I to Ballade's Settings widget
hl.unbind("SUPER + I")
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -c ballade ipc call settings toggle"), {description = "Shell: Toggle Settings"} )


