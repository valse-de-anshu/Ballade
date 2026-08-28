#!/usr/bin/env bash
# ==============================================================================
# Ballade Micro Text Editor Theme Orchestrator
# Applies systemic colorscheme to micro editor matching active preset
# ==============================================================================

THEME_KEY="${1:-green}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MICRO_CONFIG_DIR="$HOME/.config/micro"
MICRO_SCHEMES_DIR="$MICRO_CONFIG_DIR/colorschemes"
MICRO_SETTINGS="$MICRO_CONFIG_DIR/settings.json"

case "$THEME_KEY" in
    green|atelier|everforest) THEME_NAME="green" ;;
    pink|sakura) THEME_NAME="pink" ;;
    purple|amethyst) THEME_NAME="purple" ;;
    red|crimson) THEME_NAME="red" ;;
    blue|tokyo_night|tokyonight) THEME_NAME="blue" ;;
    grayscale|nord|monochrome|bw) THEME_NAME="grayscale" ;;
    golden|gold|amber|yellow) THEME_NAME="golden" ;;
    orange|sunset|tangerine) THEME_NAME="orange" ;;
    *) THEME_NAME="green" ;;
esac

SRC_SCHEME="$SCRIPT_DIR/micro-themes/${THEME_NAME}.micro"

if [ -f "$SRC_SCHEME" ]; then
    mkdir -p "$MICRO_SCHEMES_DIR"
    cp "$SRC_SCHEME" "$MICRO_SCHEMES_DIR/${THEME_NAME}.micro"
    cp "$SRC_SCHEME" "$MICRO_SCHEMES_DIR/ballade.micro"
    
    if [ -f "$MICRO_SETTINGS" ]; then
        if command -v jq &>/dev/null; then
            tmp=$(mktemp)
            jq --arg scheme "ballade" '.colorscheme = $scheme' "$MICRO_SETTINGS" > "$tmp" && mv "$tmp" "$MICRO_SETTINGS"
        else
            sed -i 's/"colorscheme": *"[^"]*"/"colorscheme": "ballade"/' "$MICRO_SETTINGS"
        fi
    else
        mkdir -p "$MICRO_CONFIG_DIR"
        echo '{"colorscheme": "ballade"}' > "$MICRO_SETTINGS"
    fi
    echo "[Micro Themer] Applied $THEME_NAME theme to $MICRO_SETTINGS"
fi
