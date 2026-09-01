#!/usr/bin/env bash
# ==============================================================================
# Ballade rmpc Dynamic Theming & Live Reloader
# Updates ~/.config/rmpc/config.ron theme and hot-reloads running instances.
# ==============================================================================

PRESET_NAME="${1:-green}"
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"

if [ -z "$1" ] && [ -f "$CONFIG_FILE" ]; then
    PRESET_NAME=$(jq -r '.theme.activePreset // "green"' "$CONFIG_FILE" 2>/dev/null)
fi

case "$PRESET_NAME" in
    green|atelier|everforest) RMPC_THEME="green" ;;
    pink|sakura)              RMPC_THEME="pink" ;;
    red|crimson)              RMPC_THEME="red" ;;
    purple|amethyst)          RMPC_THEME="purple" ;;
    blue|tokyo_night|tokyonight) RMPC_THEME="tokyo_night" ;;
    grayscale|nord|monochrome|bw) RMPC_THEME="nord" ;;
    golden|gold|amber|yellow) RMPC_THEME="golden" ;;
    orange|sunset|tangerine)  RMPC_THEME="orange" ;;
    *)                        RMPC_THEME="green" ;;
esac

RMPC_CONFIG="$HOME/.config/rmpc/config.ron"
if [ -f "$RMPC_CONFIG" ]; then
    sed -i "s/theme: Some(\"[^\"]*\")/theme: Some(\"$RMPC_THEME\")/" "$RMPC_CONFIG"
    touch "$RMPC_CONFIG"
fi

DOTFILES_RMPC="$HOME/.config/quickshell/ballade/dotfiles/rmpc/config.ron"
if [ -f "$DOTFILES_RMPC" ]; then
    sed -i "s/theme: Some(\"[^\"]*\")/theme: Some(\"$RMPC_THEME\")/" "$DOTFILES_RMPC"
fi
