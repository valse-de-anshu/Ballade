#!/usr/bin/env bash

# The main hyprland config ALREADY toggles the floating state when SUPER+ALT+Space is pressed.
# So this script runs at the same time. We wait a tiny bit for the float to apply,
# then jump in and fix the size/position!

sleep 0.15

# Get active window info
WINDOW_INFO=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW_INFO" | jq '.floating')
CLASS=$(echo "$WINDOW_INFO" | jq -r '.class')
TITLE=$(echo "$WINDOW_INFO" | jq -r '.title // ""')
FULLSCREEN=$(echo "$WINDOW_INFO" | jq '.fullscreen')

# Check if active window is a popup/dialog — skip those
IS_POPUP=$(echo "$TITLE" | grep -iE "(copying|moving|deleting|extracting|compressing|properties|overwrite|file already exists|confirm|progress|kio|open file|save as|select a file)")

# Only apply compact sizing if the window is NOW floating and NOT a small popup/dialog
if [ "$IS_FLOATING" = "true" ] && [ -z "$IS_POPUP" ]; then

    # If it was fullscreen, unset it first
    if [ "$FULLSCREEN" != "0" ] && [ "$FULLSCREEN" != "null" ]; then
        hyprctl dispatch "hl.dsp.window.fullscreen({ action = 'unset' })"
        sleep 0.1
    fi

    # All windows get the same compact size — 1200x800
    # (Dolphin and Kitty are no longer special-cased)
    hyprctl dispatch "hl.dsp.window.resize({ x = 1200, y = 800, 'exact' })"

    # Center it perfectly
    hyprctl dispatch "hl.dsp.window.center()"
fi
