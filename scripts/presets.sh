#!/usr/bin/env bash
# presets.sh - manage shell config presets | just for fun I could have done it from quickshell directly =P
# Usage:
#   presets.sh --save <name>
#   presets.sh --remove <name>
#   presets.sh --apply <name>

CONFIG_DIR="$HOME/.config/illogical-impulse"
CONFIG_FILE="$CONFIG_DIR/config.json"
PRESETS_DIR="$CONFIG_DIR/presets"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCHWALL="$SCRIPT_DIR/colors/switchwall.sh"

mkdir -p "$PRESETS_DIR"

action="$1"
name="$2"

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

case "$action" in
    --save)
        description="$3"
        
        # Keep existing _presetMeta if preset exists (to preserve .theme key)
        if [ -f "$PRESETS_DIR/${name}.json" ]; then
            existing_meta=$(jq '._presetMeta // empty' "$PRESETS_DIR/${name}.json")
        else
            existing_meta=""
        fi

        # Base snapshot without meta
        jq 'del(._presetMeta)' "$CONFIG_FILE" > "$PRESETS_DIR/${name}.json"
        
        # Restore meta and optionally update description
        if [ -n "$existing_meta" ] && [ "$existing_meta" != "{}" ]; then
            if [ -n "$description" ]; then
                jq --arg desc "$description" --argjson meta "$existing_meta" '._presetMeta = ($meta * {"description": $desc})' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
            else
                jq --argjson meta "$existing_meta" '._presetMeta = $meta' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
            fi
        else
            if [ -n "$description" ]; then
                jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
            fi
        fi

        # Ensure theme key is preserved/set for core theme presets
        case "$name" in
            green|pink|red|purple|blue|grayscale)
                jq --arg t "$name" '._presetMeta = ((._presetMeta // {}) * {"theme": $t})' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
                ;;
        esac
        ;;
    --remove)
        rm -f "$PRESETS_DIR/${name}.json"
        ;;
    --apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi
        jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" "$preset_file" \
            > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

        # If the preset declares a theme, run the full orchestrator
        theme_key=$(jq -r '._presetMeta.theme // empty' "$preset_file")
        if [ -n "$theme_key" ]; then
            "$SCRIPT_DIR/theming/apply-theme-preset.sh" "$theme_key"
        else
            "$SWITCHWALL" --noswitch
        fi
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac