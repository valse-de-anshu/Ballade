#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <image_path> [model] [prompt]"
    echo "Tip: set GEMINI_WALLPAPER_MODEL and/or GEMINI_WALLPAPER_PROMPT to provide defaults."
    exit 1
fi

# Variables
SOURCE_IMG_PATH="$1"
MODEL="${2:-${GEMINI_WALLPAPER_MODEL:-gemini-2.5-flash}}" # We use the flash variant so it's fast
WALLPAPER_NAME="$(basename "$SOURCE_IMG_PATH")"
PROMPT="${3:-${GEMINI_WALLPAPER_PROMPT:-Categorize the wallpaper. Its file name is $WALLPAPER_NAME}}"
RESIZED_IMG_PATH="/tmp/quickshell/ai/wallpaper.jpg"

# Resize image for speed
mkdir -p "$(dirname "$RESIZED_IMG_PATH")"
if [[ "$SOURCE_IMG_PATH" =~ \.(mp4|webm|mkv|avi|mov)$ ]]; then
    ffmpeg -y -nostdin -loglevel error -ss 00:00:01 -i "$SOURCE_IMG_PATH" -vframes 1 -vf "scale=200:-1" -q:v 5 "$RESIZED_IMG_PATH" >/dev/null 2>&1 || ffmpeg -y -nostdin -loglevel error -i "$SOURCE_IMG_PATH" -vframes 1 -vf "scale=200:-1" -q:v 5 "$RESIZED_IMG_PATH" >/dev/null 2>&1
else
    magick "$SOURCE_IMG_PATH" -resize 200x -quality 50 "$RESIZED_IMG_PATH"
fi

# Get API key
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' | jq -r '.apiKeys.gemini')

# Encode image to base64
if [[ "$(base64 --version 2>&1)" = *"FreeBSD"* ]]; then
    B64FLAGS="--input"
else
    B64FLAGS="-w0"
fi
B64DATA="$(base64 $B64FLAGS $RESIZED_IMG_PATH)"
# echo $B64DATA

# Prepare request data
payload='{
    "contents": [{
        "parts":[
            {
                "inline_data": {
                "mime_type":"image/jpeg",
                "data": "'"$B64DATA"'"
                }
            },
            {"text": "'"$PROMPT"'"}
        ]
    }],
    "generationConfig": {
        "responseMimeType": "text/x.enum",
        "responseSchema": {
            "type": "string",
            "enum": [ "abstract", "anime", "city", "minimalist", "landscape", "plants", "person", "space" ]
        },
        "temperature": 0
    }
}'
# echo "$payload" | jq

# Make the request
response=$(curl "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
-H "x-goog-api-key: $API_KEY" \
-H 'Content-Type: application/json' \
-X POST \
-d "$payload" 2> /dev/null)
# echo "$response" | jq

# Write the result
echo "$response" | jq -r '.candidates[0].content.parts[0].text'
