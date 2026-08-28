#!/bin/bash
# QuickShell Ballade - USB Audio Player with dynamic config & volume scaling
# Usage: play-usb-audio.sh "usb in.flac" OR play-usb-audio.sh "usb out.flac" OR play-usb-audio.sh add OR play-usb-audio.sh remove

readonly CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BALLADE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

AUDIO_EVENT="$1"
ENABLED="true"
VOLUME="70"
AUDIO_PATH=""

if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
    ENABLED=$(jq -r '.sounds.enableUsbSounds // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    VOLUME=$(jq -r '.sounds.usbSoundVolume // .sounds.systemSoundVolume // 70' "$CONFIG_FILE" 2>/dev/null || echo "70")

    if [[ "$ENABLED" == "false" ]]; then
        exit 0
    fi

    if [[ "$AUDIO_EVENT" =~ "in" || "$AUDIO_EVENT" == "add" ]]; then
        AUDIO_PATH=$(jq -r '.sounds.usbPlugInSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
    else
        AUDIO_PATH=$(jq -r '.sounds.usbPlugOutSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
    fi
fi

if [[ -n "$AUDIO_PATH" && -f "$AUDIO_PATH" ]]; then
    vol_norm=$(awk "BEGIN {print $VOLUME/100}")
    pa_vol=$((65536 * VOLUME / 100))

    if command -v pw-play &>/dev/null; then
        pw-play --volume "$vol_norm" "$AUDIO_PATH" 2>/dev/null || true
    elif command -v paplay &>/dev/null; then
        paplay --volume="$pa_vol" "$AUDIO_PATH" 2>/dev/null || true
    elif command -v mpv &>/dev/null; then
        mpv --no-video --no-terminal --keep-open=no --volume="$VOLUME" --audio-buffer=0.1 "$AUDIO_PATH" 2>/dev/null || true
    fi
else
    # Fallback to system freedesktop sound theme
    if [[ "$AUDIO_EVENT" =~ "in" || "$AUDIO_EVENT" == "add" ]]; then
        canberra-gtk-play -i "device-added" 2>/dev/null || true
    else
        canberra-gtk-play -i "device-removed" 2>/dev/null || true
    fi
fi
