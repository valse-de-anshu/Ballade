#!/usr/bin/env bash
# ==============================================================================
# Ballade Unified Audio Dispatcher
# Robust PipeWire / PulseAudio / MPV player with disk fallback & logging
# ==============================================================================

FILE=""
VOL="70"
FALLBACK=""
CATEGORY=""
LOG="/tmp/ballade-audio.log"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file|-f) FILE="$2"; shift 2 ;;
        --volume|-v) VOL="$2"; shift 2 ;;
        --fallback) FALLBACK="$2"; shift 2 ;;
        --category|-c) CATEGORY="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Check config.json toggle before playing any sound
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
    case "$CATEGORY" in
        login_greetings|startup)
            enabled=$(jq -r '.sounds.enableStartupSound // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
        shutdown|lock|logout|sleep|bell)
            enabled=$(jq -r '.sounds.enableSystemSounds // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
        notification)
            enabled=$(jq -r '.sounds.notifications // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
        charger-in|charger-out|power-plug|power-unplug)
            enabled=$(jq -r '.sounds.battery // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
        usb-in|usb-out)
            enabled=$(jq -r '.sounds.enableUsbSounds // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
        pomodoro)
            enabled=$(jq -r '.sounds.pomodoro // true' "$CONFIG_FILE" 2>/dev/null)
            [ "$enabled" = "false" ] && exit 0
            ;;
    esac
fi

# Strip file:// prefix
FILE="${FILE#file://}"
FALLBACK="${FALLBACK#file://}"

# Ensure volume is numeric between 0-100
VOL=$(echo "$VOL" | tr -dc '0-9')
[ -z "$VOL" ] && VOL=70
[ "$VOL" -gt 100 ] && VOL=100
[ "$VOL" -lt 0 ] && VOL=0

VOL_NORM=$(awk "BEGIN {printf \"%.2f\", $VOL/100}")
PA_VOL=$((65536 * VOL / 100))

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$(cd "$SCRIPT_DIR/../sounds" 2>/dev/null && pwd || echo "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ballade/sounds")"

PLAY_TARGET=""

if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    PLAY_TARGET="$FILE"
elif [ -n "$FALLBACK" ] && [ -f "$FALLBACK" ]; then
    PLAY_TARGET="$FALLBACK"
elif [ -f "$SOUNDS_DIR/shutdown_sound.flac" ] && [[ "$CATEGORY" =~ ^(shutdown|lock|logout|sleep)$ ]]; then
    PLAY_TARGET="$SOUNDS_DIR/shutdown_sound.flac"
elif [ -f "$SOUNDS_DIR/usb-in.flac" ] && [ "$CATEGORY" = "usb-in" ]; then
    PLAY_TARGET="$SOUNDS_DIR/usb-in.flac"
elif [ -f "$SOUNDS_DIR/usb-out.flac" ] && [ "$CATEGORY" = "usb-out" ]; then
    PLAY_TARGET="$SOUNDS_DIR/usb-out.flac"
elif [ -f "/usr/share/sounds/freedesktop/stereo/message.oga" ] && [ "$CATEGORY" = "notification" ]; then
    PLAY_TARGET="/usr/share/sounds/freedesktop/stereo/message.oga"
elif [ -f "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga" ] && [ "$CATEGORY" = "alarm" ]; then
    PLAY_TARGET="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
elif [ -f "/usr/share/sounds/ocean/stereo/power-plug.oga" ] && [ "$CATEGORY" = "charger-in" ]; then
    PLAY_TARGET="/usr/share/sounds/ocean/stereo/power-plug.oga"
elif [ -f "/usr/share/sounds/ocean/stereo/power-unplug.oga" ] && [ "$CATEGORY" = "charger-out" ]; then
    PLAY_TARGET="/usr/share/sounds/ocean/stereo/power-unplug.oga"
elif [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
    PLAY_TARGET="/usr/share/sounds/freedesktop/stereo/complete.oga"
elif [ -f "/usr/share/sounds/freedesktop/stereo/bell.oga" ]; then
    PLAY_TARGET="/usr/share/sounds/freedesktop/stereo/bell.oga"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Play request: file='$FILE' (vol=$VOL%, cat='$CATEGORY') -> resolved='$PLAY_TARGET'" >> "$LOG"

if [ -n "$PLAY_TARGET" ] && [ -f "$PLAY_TARGET" ]; then
    TIMEOUT_DUR="15s"
    if [ "$CATEGORY" = "alarm" ]; then
        TIMEOUT_DUR="30s"
    fi

    if command -v paplay &>/dev/null; then
        PA_VOL=$((65536 * VOL / 100))
        timeout "$TIMEOUT_DUR" paplay --volume="$PA_VOL" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v pw-play &>/dev/null; then
        VOL_NORM=$(awk "BEGIN {printf \"%.2f\", $VOL/100}")
        timeout "$TIMEOUT_DUR" pw-play --volume "$VOL_NORM" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v canberra-gtk-play &>/dev/null; then
        timeout "$TIMEOUT_DUR" canberra-gtk-play --file="$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v mpv &>/dev/null; then
        timeout "$TIMEOUT_DUR" mpv --no-config --keep-open=no --idle=no --no-video --no-terminal --no-audio-display --force-window=no --really-quiet --volume="$VOL" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
fi
