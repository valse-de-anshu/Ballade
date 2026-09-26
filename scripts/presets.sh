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

        # Ensure calendar satellite companion settings are captured into preset
        CAL_TARGET="$CONFIG_DIR/calendar_target.json"
        if [ -f "$CAL_TARGET" ]; then
            sat_x=$(jq '.x // empty' "$CAL_TARGET" 2>/dev/null)
            sat_y=$(jq '.y // empty' "$CAL_TARGET" 2>/dev/null)
            sat_rot=$(jq '.rotation // empty' "$CAL_TARGET" 2>/dev/null)
            if [ -n "$sat_x" ] && [ -n "$sat_y" ]; then
                jq --argjson sx "$sat_x" --argjson sy "$sat_y" --argjson srot "${sat_rot:-0}" \
                    '.background.widgets.calendar.satelliteX = $sx | .background.widgets.calendar.satelliteY = $sy | .background.widgets.calendar.satelliteRotation = $srot' \
                    "$PRESETS_DIR/${name}.json" > "$PRESETS_DIR/${name}.json.tmp" \
                    && mv "$PRESETS_DIR/${name}.json.tmp" "$PRESETS_DIR/${name}.json"
            fi
        fi

        # Ensure theme key is preserved/set for core theme presets
        case "$name" in
            green|pink|red|purple|blue|golden|orange|grayscale|catppuccin)
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
            bundled_preset="$SCRIPT_DIR/../dotfiles/illogical-impulse/presets/${name}.json"
            if [ -f "$bundled_preset" ]; then
                cp "$bundled_preset" "$preset_file"
            else
                # If it's a built-in theme preset without a custom snapshot, apply directly via orchestrator
                case "$name" in
                    green|pink|red|purple|blue|golden|orange|grayscale|catppuccin)
                        "$SCRIPT_DIR/theming/apply-theme-preset.sh" "$name"
                        exit 0
                        ;;
                    *)
                        echo "Error: preset not found: $name" >&2
                        exit 1
                        ;;
                esac
            fi
        fi

        # Synchronize satellite companion settings to calendar_target.json if preset has them
        CAL_TARGET="$CONFIG_DIR/calendar_target.json"
        sat_x=$(jq '.background.widgets.calendar.satelliteX // empty' "$preset_file" 2>/dev/null)
        sat_y=$(jq '.background.widgets.calendar.satelliteY // empty' "$preset_file" 2>/dev/null)
        sat_rot=$(jq '.background.widgets.calendar.satelliteRotation // empty' "$preset_file" 2>/dev/null)
        if [ -n "$sat_x" ] && [ -n "$sat_y" ]; then
            if [ -f "$CAL_TARGET" ]; then
                jq --argjson sx "$sat_x" --argjson sy "$sat_y" --argjson srot "${sat_rot:-0}" \
                    '.x = $sx | .y = $sy | .rotation = $srot' \
                    "$CAL_TARGET" > "$CAL_TARGET.tmp" && cat "$CAL_TARGET.tmp" > "$CAL_TARGET" && rm -f "$CAL_TARGET.tmp"
            else
                jq -n --argjson sx "$sat_x" --argjson sy "$sat_y" --argjson srot "${sat_rot:-0}" \
                    '{"targets":[], "x": $sx, "y": $sy, "rotation": $srot}' > "$CAL_TARGET"
            fi
        fi

        # Merge preset with config: replace background.widgets fully so no stale/conflicting widgets persist
        jq -s '
            .[0] as $base | .[1] as $preset
            | ($base * $preset)
            | if $preset.background.widgets then .background.widgets = $preset.background.widgets else . end
            | del(._presetMeta)
        ' "$CONFIG_FILE" "$preset_file" > "${CONFIG_FILE}.tmp" \
            && cat "${CONFIG_FILE}.tmp" > "$CONFIG_FILE" \
            && rm -f "${CONFIG_FILE}.tmp"

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