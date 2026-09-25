-- Restore Gloomi cursor after Illogical Impulse
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Gloomi_x 24")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/kdeconnect_auto_reconnect.sh")
end)

