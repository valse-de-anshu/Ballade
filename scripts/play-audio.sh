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
    if command -v paplay &>/dev/null; then
        PA_VOL=$((65536 * VOL / 100))
        paplay --volume="$PA_VOL" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v mpv &>/dev/null; then
        mpv --no-video --no-terminal --no-audio-display --force-window=no --really-quiet --volume="$VOL" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v pw-play &>/dev/null; then
        VOL_NORM=$(awk "BEGIN {printf \"%.2f\", $VOL/100}")
        pw-play --volume "$VOL_NORM" "$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
    if command -v canberra-gtk-play &>/dev/null; then
        canberra-gtk-play --file="$PLAY_TARGET" >>"$LOG" 2>&1 && exit 0
    fi
fi
