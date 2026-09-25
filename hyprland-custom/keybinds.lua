hl.unbind("CTRL + SUPER + T")
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd("qs -c ballade ipc call wallpaperSelector toggle"), {description = "Shell: Toggle wallpaper selector"} )
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("SUPER+ALT+Space", hl.dsp.exec_cmd("bash ~/.config/hypr/custom/scripts/compact_window.sh"), {description = "Toggle compact centered window"} )

-- Disable panel family cycling (prevents UI corruption on CTRL+SUPER+P)
hl.unbind("CTRL + SUPER + P")

-- Bind SUPER+I and CTRL+I to Ballade's Settings widget
hl.unbind("SUPER + I")
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -c ballade ipc call settings toggle"), {description = "Shell: Toggle Settings"} )
hl.unbind("CTRL + I")
hl.bind("CTRL + I", hl.dsp.exec_cmd("qs -c ballade ipc call settings toggle"), {description = "Shell: Toggle Settings"} )

-- Bind ALT+S to Snip and Annotate with Gwenview
local qsConfig = os.getenv("qsConfig") or "ballade"
local qsIsAlive = "qs -c " .. qsConfig .. " ipc call TEST_ALIVE"
hl.bind("ALT + S", hl.dsp.global("quickshell:regionAnnotate"), { description = "Utilities: Snip and annotate with Gwenview >> clipboard" })
hl.bind("ALT + S", hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || snip-annotate.py"))

-- Fast OCR with English + Hindi and immediate clipboard notification
hl.unbind("SUPER + SHIFT + X")
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"), { description = "Utilities: Character recognition >> clipboard" })
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd(
    qsIsAlive ..
    " || pidof slurp || (grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && text=$(tesseract \"/tmp/ocr_image.png\" stdout -l eng+hin 2>/dev/null) && if [ -n \"$text\" ]; then printf '%s' \"$text\" | wl-copy && notify-send -a 'OCR' -i 'edit-paste' 'Text Copied to Clipboard' \"$text\"; else notify-send -a 'OCR' -i 'dialog-warning' 'OCR' 'No text recognized'; fi; rm -f \"/tmp/ocr_image.png\")"
))


