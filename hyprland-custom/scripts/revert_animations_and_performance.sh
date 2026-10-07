#!/usr/bin/env bash
# ==============================================================================
# Revert script: Restores previous blur & animation settings
# ==============================================================================

BACKUP_FILE="$HOME/.config/hypr/custom/general.lua.backup_pre_performance"
TARGET_FILE="$HOME/.config/hypr/custom/general.lua"

if [ -f "$BACKUP_FILE" ]; then
    echo "Restoring previous general.lua from $BACKUP_FILE..."
    cp "$BACKUP_FILE" "$TARGET_FILE"
    # Reload hyprland configuration
    hyprctl reload
    echo "Previous settings restored successfully and Hyprland reloaded!"
else
    echo "Error: Backup file $BACKUP_FILE not found."
    exit 1
fi
