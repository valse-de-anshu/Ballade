#!/usr/bin/env bash
# ==============================================================================
# Ballade Desktop Shell — Safety Mode / Boss Key (Windows Win+D Equivalent)
# ==============================================================================
# When triggered:
# 1. Remembers current workspace and focused window.
# 2. Immediately pauses all active media playback (YouTube, mpv, Spotify, etc.).
# 3. Closes active QuickShell drawers, search popups, and clipboard menus.
# 4. Unpins floating/Picture-in-Picture windows so they don't follow to safe space.
# 5. Switches immediately to the configured SAFE_WORKSPACE (Default: 11).
# 6. When toggled again, returns to original workspace, re-pins windows!
# ==============================================================================

set -eo pipefail

STATE_FILE="/tmp/ballade_safety_state.json"
CONFIG_FILE="$HOME/.config/hypr/custom/safety.conf"

# Default settings
SAFE_WORKSPACE="11"
PAUSE_MEDIA="true"
MUTE_AUDIO="false"
CLOSE_OVERLAYS="true"
UNPIN_WINDOWS="true"
SAFE_APP_CMD=""

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Get current active workspace ID / name
ACTIVE_WS_JSON=$(hyprctl activeworkspace -j 2>/dev/null || echo "{}")
CURRENT_WS=$(echo "$ACTIVE_WS_JSON" | jq -r '.id // .name // "1"')

# Determine if we are currently in Safe Mode
IS_IN_SAFE_MODE=false
if [ -f "$STATE_FILE" ]; then
    RECORDED_SAFE_WS=$(jq -r '.safe_workspace // empty' "$STATE_FILE" 2>/dev/null || echo "")
    if [ "$CURRENT_WS" = "$SAFE_WORKSPACE" ] || [ "$CURRENT_WS" = "$RECORDED_SAFE_WS" ]; then
        IS_IN_SAFE_MODE=true
    fi
fi

if [ "$IS_IN_SAFE_MODE" = "true" ]; then
    # ==========================================================================
    # EXIT SAFE MODE -> RESTORE PREVIOUS STATE
    # ==========================================================================
    PREV_WS=$(jq -r '.prev_workspace // "1"' "$STATE_FILE" 2>/dev/null || echo "1")
    MUTED_BY_US=$(jq -r '.muted_by_us // false' "$STATE_FILE" 2>/dev/null || echo "false")
    PREV_FOCUS=$(jq -r '.prev_focus // empty' "$STATE_FILE" 2>/dev/null || echo "")
    PINNED_ADDRS=$(jq -r '.pinned_addresses[]? // empty' "$STATE_FILE" 2>/dev/null || true)

    # 1. Switch back to previous workspace
    hyprctl dispatch "hl.dsp.focus({ workspace = $PREV_WS })" >/dev/null 2>&1

    # 2. Re-pin previously unpinned windows
    if [ -n "$PINNED_ADDRS" ]; then
        for addr in $PINNED_ADDRS; do
            if [ -n "$addr" ] && [ "$addr" != "null" ]; then
                hyprctl dispatch "hl.dsp.focus({ address = '$addr' })" >/dev/null 2>&1 || true
                hyprctl dispatch "hl.dsp.window.pin()" >/dev/null 2>&1 || true
            fi
        done
    fi

    # 3. Restore focused window if known
    if [ -n "$PREV_FOCUS" ] && [ "$PREV_FOCUS" != "null" ]; then
        hyprctl dispatch "hl.dsp.focus({ address = '$PREV_FOCUS' })" >/dev/null 2>&1 || true
    fi

    # 4. Unmute audio if muted by us (silently suppressing the OSD banner)
    if [ "$MUTED_BY_US" = "true" ]; then
        qs -c ballade ipc call osdVolume setSuppressed true >/dev/null 2>&1 || true
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 >/dev/null 2>&1 || true
        qs -c ballade ipc call osdVolume close >/dev/null 2>&1 || true
        (sleep 0.5 && qs -c ballade ipc call osdVolume setSuppressed false >/dev/null 2>&1) &
    fi

    # 5. Clean up state
    rm -f "$STATE_FILE"

else
    # ==========================================================================
    # ENTER SAFE MODE -> SHIFT TO SAFE SPACE
    # ==========================================================================
    
    # If already on SAFE_WORKSPACE and no state file, do nothing
    if [ "$CURRENT_WS" = "$SAFE_WORKSPACE" ]; then
        exit 0
    fi

    # 1. Get currently focused window address
    PREV_FOCUS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')

    # 2. Unpin pinned floating windows so they don't follow
    PINNED_ADDRS_JSON="[]"
    if [ "$UNPIN_WINDOWS" = "true" ]; then
        PINNED_LIST=$(hyprctl clients -j 2>/dev/null | jq -r '[.[] | select(.pinned == true) | .address] // []')
        PINNED_ADDRS_JSON="$PINNED_LIST"
        for addr in $(echo "$PINNED_LIST" | jq -r '.[]'); do
            if [ -n "$addr" ] && [ "$addr" != "null" ]; then
                hyprctl dispatch "hl.dsp.focus({ address = '$addr' })" >/dev/null 2>&1 || true
                hyprctl dispatch "hl.dsp.window.pin()" >/dev/null 2>&1 || true
            fi
        done
    fi

    # 3. Pause media immediately (pauses YouTube, Spotify, mpv without volume banners)
    if [ "$PAUSE_MEDIA" = "true" ]; then
        playerctl -a pause >/dev/null 2>&1 || true
    fi

    # 4. Mute audio if configured (silently suppressing the OSD banner)
    MUTED_BY_US=false
    if [ "$MUTE_AUDIO" = "true" ]; then
        qs -c ballade ipc call osdVolume setSuppressed true >/dev/null 2>&1 || true
        IS_MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -i "MUTED" || true)
        if [ -z "$IS_MUTED" ]; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 >/dev/null 2>&1 || true
            MUTED_BY_US=true
        fi
        qs -c ballade ipc call osdVolume close >/dev/null 2>&1 || true
        (sleep 0.5 && qs -c ballade ipc call osdVolume setSuppressed false >/dev/null 2>&1) &
    fi

    # 5. Close any open QuickShell overlays/menus/OSDs
    if [ "$CLOSE_OVERLAYS" = "true" ]; then
        qs -c ballade ipc call osdVolume close >/dev/null 2>&1 || true
        qs -c ballade ipc call sidebarLeft close >/dev/null 2>&1 || true
        qs -c ballade ipc call sidebarRight close >/dev/null 2>&1 || true
        qs -c ballade ipc call search close >/dev/null 2>&1 || true
        qs -c ballade ipc call clipboard close >/dev/null 2>&1 || true
        qs -c ballade ipc call settings close >/dev/null 2>&1 || true
        qs -c ballade ipc call session close >/dev/null 2>&1 || true
        qs -c ballade ipc call wallpaperSelector close >/dev/null 2>&1 || true
    fi

    # 6. Save state to file
    jq -n \
        --arg prev_ws "$CURRENT_WS" \
        --arg safe_ws "$SAFE_WORKSPACE" \
        --arg prev_focus "$PREV_FOCUS" \
        --argjson muted "$MUTED_BY_US" \
        --argjson pinned "$PINNED_ADDRS_JSON" \
        '{prev_workspace: $prev_ws, safe_workspace: $safe_ws, prev_focus: $prev_focus, muted_by_us: $muted, pinned_addresses: $pinned}' \
        > "$STATE_FILE"

    # 7. Switch to Safe Workspace
    hyprctl dispatch "hl.dsp.focus({ workspace = $SAFE_WORKSPACE })" >/dev/null 2>&1

    # 8. If SAFE_APP_CMD is specified and workspace is empty, launch it
    if [ -n "$SAFE_APP_CMD" ]; then
        WIN_COUNT=$(hyprctl workspaces -j 2>/dev/null | jq --arg safe_ws "$SAFE_WORKSPACE" '[.[] | select((.id | tostring) == $safe_ws or .name == $safe_ws) | .windows] | first // 0')
        if [ "$WIN_COUNT" -eq 0 ]; then
            eval "$SAFE_APP_CMD" >/dev/null 2>&1 &
        fi
    fi
fi
