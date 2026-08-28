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
        ICON_THEME="Tela-circle-grey-dark"
        KDE_SCHEME="NordDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/nord.conf"
        RMPC_THEME="nord"
        WALLPAPER_DIR="$WALLPAPERS_BASE/grayscale"
        ;;
    golden|gold|amber|yellow)
        PRESET_NAME="golden"
        PRIMARY_HEX="#F0B849"
        ICON_THEME="Tela-circle-yellow-dark"
        KDE_SCHEME="GoldenDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/golden.conf"
        RMPC_THEME="golden"
        WALLPAPER_DIR="$WALLPAPERS_BASE/golden"
        ;;
    orange|sunset|tangerine)
        PRESET_NAME="orange"
        PRIMARY_HEX="#FF9248"
        ICON_THEME="Tela-circle-ubuntu-dark"
        KDE_SCHEME="OrangeDark"
        KITTY_THEME_FILE="$KITTY_THEMES_DIR/orange.conf"
        RMPC_THEME="orange"
        WALLPAPER_DIR="$WALLPAPERS_BASE/orange"
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
PRESETS_DIR="$HOME/.config/illogical-impulse/presets"
target_wall=""

# Priority 1: Check if a wallpaper is saved specifically in this preset's snapshot
if [ -f "$PRESETS_DIR/${PRESET_NAME}.json" ]; then
    saved_wall=$(jq -r '.background.wallpaperPath // empty' "$PRESETS_DIR/${PRESET_NAME}.json" 2>/dev/null)
    if [ -n "$saved_wall" ] && [ -f "$saved_wall" ]; then
        target_wall="$saved_wall"
    fi
fi

# Priority 2: Check if current config.json already has a wallpaper inside this preset's directory
if [ -z "$target_wall" ] && [ -f "$CONFIG_FILE" ]; then
    curr_wall=$(jq -r '.background.wallpaperPath // empty' "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$curr_wall" ] && [ -f "$curr_wall" ] && [[ "$curr_wall" == "$WALLPAPER_DIR"* ]]; then
        target_wall="$curr_wall"
    fi
fi

# Priority 3: Fallback to first available wallpaper in the theme folder
if [ -z "$target_wall" ]; then
    target_wall=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jpeg" \) 2>/dev/null | sort | head -n 1)
fi

if [ -n "$target_wall" ] && [ -f "$target_wall" ]; then
    echo "[Theme Orchestrator] Applying theme wallpaper: $target_wall"
    "$SCRIPT_DIR/../colors/switchwall.sh" --image "$target_wall" --mode dark >/dev/null 2>&1
else
    echo "[Theme Orchestrator] Applying solid color background: $PRIMARY_HEX"
    "$SCRIPT_DIR/../colors/switchwall.sh" --color "$PRIMARY_HEX" --mode dark >/dev/null 2>&1
fi

# 3. Apply GTK, KDE, Dolphin & Icon Themes
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true

# Update KDE kdeglobals for Dolphin and Qt settings
if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key AccentColor "$PRIMARY_HEX" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor "$PRIMARY_HEX" 2>/dev/null || true
elif command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_THEME" 2>/dev/null || true
    kwriteconfig5 --file kdeglobals --group General --key AccentColor "$PRIMARY_HEX" 2>/dev/null || true
fi

# 4. Apply KDE / Dolphin Colorscheme
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$KDE_SCHEME" >/dev/null 2>&1 || true
fi

# 5. Apply Kitty Terminal Theme
if [ -f "$KITTY_THEME_FILE" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp -f "$KITTY_THEME_FILE" "$HOME/.config/kitty/current-theme.conf"
    
    # Ensure kitty.conf includes current-theme.conf
    if ! grep -q "include current-theme.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
        sed -i '/# BEGIN_KITTY_THEME/,/# END_KITTY_THEME/c\# BEGIN_KITTY_THEME\ninclude current-theme.conf\n# END_KITTY_THEME' "$HOME/.config/kitty/kitty.conf"
    fi
    
    # Synchronize Konsole colorscheme
    konsole_theme="$HOME/.local/share/konsole/Quickshell.colorscheme"
    mkdir -p "$HOME/.local/share/konsole"
    {
        echo "[General]"
        echo "Description=Dynamic Quickshell"
        echo "Opacity=1"
        echo "Wallpaper="
        while read -r line; do
            key=$(echo "$line" | awk '{print $1}')
            val=$(echo "$line" | awk '{print $2}')
            [[ -z "$key" || -z "$val" || "$key" =~ ^# ]] && continue
            hex="${val#\#}"
            if [ ${#hex} -eq 6 ]; then
                rgb="$((16#${hex:0:2})),$((16#${hex:2:2})),$((16#${hex:4:2}))"
            else
                rgb="0,0,0"
            fi
            if [[ "$key" == "background" ]]; then
                echo -e "[Background]\nColor=$rgb"
                echo -e "[BackgroundFaint]\nColor=$rgb"
                echo -e "[BackgroundIntense]\nColor=$rgb"
            elif [[ "$key" == "foreground" ]]; then
                echo -e "[Foreground]\nColor=$rgb"
                echo -e "[ForegroundFaint]\nColor=$rgb"
                echo -e "[ForegroundIntense]\nColor=$rgb"
            elif [[ "$key" =~ ^color([0-9]+)$ ]]; then
                cnum="${BASH_REMATCH[1]}"
                echo -e "[Color${cnum}]\nColor=$rgb"
                echo -e "[Color${cnum}Intense]\nColor=$rgb"
            fi
        done < "$KITTY_THEME_FILE"
    } > "$konsole_theme" 2>/dev/null

    # Enforce ColorScheme=Quickshell in ~/.config/konsolerc and default profile
    if [ -f "$HOME/.config/konsolerc" ]; then
        if grep -q "ColorScheme=" "$HOME/.config/konsolerc"; then
            sed -i 's/^ColorScheme=.*/ColorScheme=Quickshell/' "$HOME/.config/konsolerc"
        else
            echo -e "\n[UiSettings]\nColorScheme=Quickshell" >> "$HOME/.config/konsolerc"
        fi
    fi
    for prof in "$HOME/.local/share/konsole/"*.profile; do
        if [ -f "$prof" ]; then
            if grep -q "ColorScheme=" "$prof"; then
                sed -i 's/^ColorScheme=.*/ColorScheme=Quickshell/' "$prof"
            else
                sed -i '1s/^/[Appearance]\nColorScheme=Quickshell\n\n/' "$prof"
            fi
        fi
    done
fi

# 6. Apply rmpc Music Player Theme
RMPC_CONFIG="$HOME/.config/rmpc/config.ron"
if [ -f "$RMPC_CONFIG" ]; then
    sed -i "s/theme: Some(\"[^\"]*\")/theme: Some(\"$RMPC_THEME\")/" "$RMPC_CONFIG"
fi

# 7. Apply Starship Prompt Theme
STARSHIP_SRC="$HOME/.config/starship/${PRESET_NAME}.toml"
if [ ! -f "$STARSHIP_SRC" ]; then
    STARSHIP_SRC="$SCRIPT_DIR/../../dotfiles/starship/${PRESET_NAME}.toml"
fi
if [ -f "$STARSHIP_SRC" ]; then
    cp -f "$STARSHIP_SRC" "$HOME/.config/starship.toml"
fi

# 8. Apply Micro Text Editor Theme
if [ -f "$SCRIPT_DIR/apply-micro-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-micro-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi

# 9. Apply VS Code / Code-OSS / Antigravity / Cursor Theme
if [ -f "$SCRIPT_DIR/apply-code-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-code-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi

# 10. Apply Fastfetch Theme (Image logo + Accent palette)
if [ -f "$SCRIPT_DIR/apply-fastfetch-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-fastfetch-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi

# 11. Apply Obsidian Theme (Translucency + Preset Accents)
if [ -f "$SCRIPT_DIR/apply-obsidian-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-obsidian-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi

# 12. Apply Joplin Theme (Catppuccin-Grade 3-Tier Depth UI + Rendered Markdown)
if [ -f "$SCRIPT_DIR/apply-joplin-theme.sh" ]; then
# 13. Apply Discord+ Theme (Current Wallpaper Sync)
if [ -f "$SCRIPT_DIR/apply-discord-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-discord-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi
    bash "$SCRIPT_DIR/apply-joplin-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
# 13. Apply Discord+ Theme (Current Wallpaper Sync)
if [ -f "$SCRIPT_DIR/apply-discord-theme.sh" ]; then
    bash "$SCRIPT_DIR/apply-discord-theme.sh" "$PRESET_NAME" >/dev/null 2>&1
fi
fi

# 13. Apply Discord / Vesktop / Vencord Theme
fi

# 14. Update QuickShell configuration (active theme + wallpaper directory)
if [ -f "$CONFIG_FILE" ]; then
    tmp_config=$(mktemp)
    jq --arg theme "$PRESET_NAME" --arg dir "$WALLPAPER_DIR" \
        '.theme = (.theme // {}) | .theme.activePreset = $theme | .wallpaperSelector.userPath = $dir' \
        "$CONFIG_FILE" > "$tmp_config" && cat "$tmp_config" > "$CONFIG_FILE" && rm "$tmp_config"
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
fi

# Joplin: restart with new theme if running, otherwise do nothing
python3 "$SCRIPT_DIR/restart-joplin.py" &
disown

echo "[Theme Orchestrator] Successfully applied $PRESET_NAME preset."

