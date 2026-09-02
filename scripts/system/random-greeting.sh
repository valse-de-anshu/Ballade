#!/bin/bash

MPV="/usr/bin/mpv"
NOTIFY="/usr/bin/notify-send"

GREETINGS_DIR="$HOME/.local/share/login_greetings"
SUB_FILE="$GREETINGS_DIR/subtitles.txt"

[ -d "$GREETINGS_DIR" ] || exit 1

shopt -s nullglob
AUDIO_FILES=("$GREETINGS_DIR"/*.flac)
[ ${#AUDIO_FILES[@]} -eq 0 ] && exit 1

RANDOM_INDEX=$(( RANDOM % ${#AUDIO_FILES[@]} ))
SELECTED_FILE="${AUDIO_FILES[$RANDOM_INDEX]}"
BASENAME=$(basename "$SELECTED_FILE")

SUBTITLE=$(grep "^$BASENAME|" "$SUB_FILE" | cut -d '|' -f2)

# Get audio duration (seconds → milliseconds)
DURATION=$(ffprobe -i "$SELECTED_FILE" -show_entries format=duration -v quiet -of csv="p=0")
DURATION_MS=$(printf "%.0f" "$(echo "$DURATION * 1000" | bc)")

# Play audio (no waiting, no lifecycle hacks)
"$MPV" --no-video --no-terminal --keep-open=no --volume=85 --audio-buffer=0.1 "$SELECTED_FILE" &

# Show notification with proper timeout
"$NOTIFY" -t "$DURATION_MS" "" "$SUBTITLE"