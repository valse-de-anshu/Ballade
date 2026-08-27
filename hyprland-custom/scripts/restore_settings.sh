#!/usr/bin/env bash

# This script restores the user's custom hyprland settings (like frosted glass and keybinds)
# by copying them over from a safe backup directory that is immune to dotfile script wipes.

BACKUP_DIR="$HOME/.config/hypr/custom_backup_safe"
CUSTOM_DIR="$HOME/.config/hypr/custom"

if [ -d "$BACKUP_DIR" ]; then
    echo "Restoring custom Hyprland settings from safe backup..."
    cp -r "$BACKUP_DIR/"* "$CUSTOM_DIR/"
    echo "Settings restored successfully!"
    echo "You may need to reload your Hyprland or AGS for changes to take effect."
else
    echo "Error: Backup directory $BACKUP_DIR does not exist. Cannot restore."
fi
