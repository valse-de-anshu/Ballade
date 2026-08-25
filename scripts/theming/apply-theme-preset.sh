#!/usr/bin/env bash
# ==============================================================================
# Ballade Multi-Theme Orchestrator
# Applies systemic themes across QuickShell, Hyprland, Kitty, KDE/Dolphin,
# Tela Icons, rmpc, GTK, and Wallpaper Directory Routing.
# ==============================================================================

THEME_KEY="${1:-green}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
KITTY_THEMES_DIR="$SCRIPT_DIR/kitty-themes"
WALLPAPERS_BASE="$HOME/Pictures/Wallpapers"

case "$THEME_KEY" in
    green|atelier|everforest)
        PRESET_NAME="green"
        PRIMARY_HEX="#7D9726"
        ICON_THEME="Tela-circle-manjaro-dark"
        KDE_SCHEME="Atelier_Estuary_Dark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/green.conf"
        RMPC_THEME="green"
        WALLPAPER_DIR="$WALLPAPERS_BASE/green"
        ;;
    pink|sakura)
        PRESET_NAME="pink"
        PRIMARY_HEX="#E05688"
        ICON_THEME="Tela-circle-pink-dark"
        KDE_SCHEME="PinkDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/pink.conf"
        RMPC_THEME="pink"
        WALLPAPER_DIR="$WALLPAPERS_BASE/pink"
        ;;
    red|crimson)
        PRESET_NAME="red"
        PRIMARY_HEX="#D32F2F"
        ICON_THEME="Tela-circle-red-dark"
        KDE_SCHEME="RedDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/red.conf"
        RMPC_THEME="red"
        WALLPAPER_DIR="$WALLPAPERS_BASE/red"
        ;;
    purple|amethyst)
        PRESET_NAME="purple"
        PRIMARY_HEX="#9C27B0"
        ICON_THEME="Tela-circle-purple-dark"
        KDE_SCHEME="PurpleDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/purple.conf"
        RMPC_THEME="purple"
        WALLPAPER_DIR="$WALLPAPERS_BASE/purple"
        ;;
    blue|tokyo_night|tokyonight)
        PRESET_NAME="blue"
        PRIMARY_HEX="#7AA2F7"
        ICON_THEME="Tela-circle-blue-dark"
        KDE_SCHEME="TokyoNightDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/tokyo-night.conf"
        RMPC_THEME="tokyo_night"
        WALLPAPER_DIR="$WALLPAPERS_BASE/blue"
        ;;
    grayscale|nord|monochrome|bw)
        PRESET_NAME="grayscale"
        PRIMARY_HEX="#8892B0"
        ICON_THEME="Tela-circle-nord-dark"
        KDE_SCHEME="NordDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/nord.conf"
        RMPC_THEME="nord"
        WALLPAPER_DIR="$WALLPAPERS_BASE/grayscale"
        ;;
    *)
        echo "Unknown theme preset: $THEME_KEY. Defaulting to green."
        PRESET_NAME="green"
        PRIMARY_HEX="#7D9726"
        ICON_THEME="Tela-circle-manjaro-dark"
        KDE_SCHEME="Atelier_Estuary_Dark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/green.conf"
        RMPC_THEME="green"
        WALLPAPER_DIR="$WALLPAPERS_BASE/green"
        ;;
esac

echo "[Theme Orchestrator] Applying theme preset: $PRESET_NAME ($PRIMARY_HEX)"

# 1. Ensure theme wallpaper directory exists
mkdir -p "$WALLPAPER_DIR"

# 2. Apply Wallpaper & Colors
# Check if a wallpaper was loaded into config.json from the preset snapshot
saved_wall=$(jq -r '.background.wallpaperPath // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -n "$saved_wall" ] && [ -f "$saved_wall" ]; then
    echo "[Theme Orchestrator] Applying saved wallpaper: $saved_wall"
    "$SCRIPT_DIR/../colors/switchwall.sh" --image "$saved_wall" --mode dark >/dev/null 2>&1 &
else
    # Fallback: check if a wallpaper exists in the target theme folder
    first_wall=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jpeg" \) | head -n 1)

    if [ -n "$first_wall" ] && [ -f "$first_wall" ]; then
        echo "[Theme Orchestrator] Applying fallback theme wallpaper: $first_wall"
        "$SCRIPT_DIR/../colors/switchwall.sh" --image "$first_wall" --mode dark >/dev/null 2>&1 &
    else
        # Fallback to direct hex generation if folder has no wallpapers yet
        if command -v matugen &>/dev/null; then
            matugen color hex "$PRIMARY_HEX" --mode dark >/dev/null 2>&1
            "$SCRIPT_DIR/../colors/applycolor.sh" >/dev/null 2>&1 &
        fi
    fi
fi

# 3. Apply Icon Theme (GTK + KDE Plasma)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null &
fi
if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" 2>/dev/null
fi

# 4. Apply KDE Color Scheme (Dolphin, Konsole, Kate, System UI)
if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme "$KDE_SCHEME" >/dev/null 2>&1
fi

# 5. Apply Kitty Theme
if [ -f "$KITTY_THEME_FILE" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$KITTY_THEME_FILE" "$HOME/.config/kitty/current-theme.conf"
    
    # Ensure kitty.conf includes current-theme.conf
    if ! grep -q "include current-theme.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
        sed -i '/# BEGIN_KITTY_THEME/,/# END_KITTY_THEME/c\# BEGIN_KITTY_THEME\ninclude current-theme.conf\n# END_KITTY_THEME' "$HOME/.config/kitty/kitty.conf"
    fi
    
    # Live reload all running kitty instances
    kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
fi

# 6. Apply rmpc Music Player Theme
RMPC_CONFIG="$HOME/.config/rmpc/config.ron"
if [ -f "$RMPC_CONFIG" ]; then
    sed -i "s/theme: Some(\"[^\"]*\")/theme: Some(\"$RMPC_THEME\")/" "$RMPC_CONFIG"
fi

# 7. Apply Starship Prompt Theme
STARSHIP_PRESET="$HOME/.config/starship/${PRESET_NAME}.toml"
if [ -f "$STARSHIP_PRESET" ]; then
    cp "$STARSHIP_PRESET" "$HOME/.config/starship.toml"
fi

# 8. Update QuickShell configuration (active theme + wallpaper directory)
if [ -f "$CONFIG_FILE" ]; then
    tmp_config=$(mktemp)
    jq --arg theme "$PRESET_NAME" --arg dir "$WALLPAPER_DIR" \
        '.theme = (.theme // {}) | .theme.activePreset = $theme | .wallpaperSelector.userPath = $dir' \
        "$CONFIG_FILE" > "$tmp_config" && mv "$tmp_config" "$CONFIG_FILE"
fi

# 9. Auto-restart apps & Reloads
# ---------------------------------------------------------
# Kitty: live-reload via SIGUSR1 (no hard restart needed)
if pidof kitty > /dev/null 2>&1; then
    kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
fi

# Rebuild KDE service/icon cache BEFORE restarting Dolphin
kbuildsycoca6 --noincremental 2>/dev/null

# Ensure Dolphin follows system colors by stripping any hardcoded overrides
if [ -f ~/.config/dolphinrc ]; then
    sed -i '/^ColorScheme=/d' ~/.config/dolphinrc
fi

# Dolphin: restart to pick up new icon theme
if pidof dolphin > /dev/null 2>&1; then
    pkill -x dolphin 2>/dev/null || true
    sleep 0.5
    env XDG_CURRENT_DESKTOP=KDE dolphin >/dev/null 2>&1 &
fi

echo "[Theme Orchestrator] Successfully applied $PRESET_NAME preset."
