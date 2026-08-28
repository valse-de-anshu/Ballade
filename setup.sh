#!/bin/bash
# 🎼 QuickShell Ballade - Automated 1-Click Environment Initializer
# Sets up directories, wallpaper presets, sound events, and permissions.

set -euo pipefail

BALLADE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BALLADE_DIR/scripts"

echo "🎼 Initializing QuickShell Ballade..."

# 1. Ensure all shell scripts are executable
echo "🔑 Making scripts executable..."
find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "$BALLADE_DIR/setup.sh" 2>/dev/null || true

# 2. Create standard directories
echo "📁 Creating standard user directories..."
mkdir -p "$HOME/Pictures/Wallpapers"
for preset in green purple pink red blue golden orange grayscale; do
    mkdir -p "$HOME/Pictures/Wallpapers/$preset"
    # Provide starter wallpaper if folder is completely empty
    if [ -z "$(ls -A "$HOME/Pictures/Wallpapers/$preset" 2>/dev/null)" ]; then
        if [ -f "$BALLADE_DIR/assets/images/default_wallpaper.png" ]; then
            cp "$BALLADE_DIR/assets/images/default_wallpaper.png" "$HOME/Pictures/Wallpapers/$preset/default.png"
            echo "   ↳ Added starter wallpaper to $HOME/Pictures/Wallpapers/$preset/"
        fi
    fi
done

mkdir -p "$HOME/.config/illogical-impulse/presets"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/micro/colorschemes"
mkdir -p "$HOME/.local/share/konsole"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.cache/illogical-impulse"

# 3. Setup System Sounds & Audio Daemons
if [ -f "$SCRIPTS_DIR/setup-system-sounds.sh" ]; then
    echo "🔊 Initializing system sound hooks and user services..."
    bash "$SCRIPTS_DIR/setup-system-sounds.sh" || true
fi

# 4. Setup Custom Hyprland Overrides (Blur, Opacity & Keybindings)
if [ -d "$BALLADE_DIR/hyprland-custom" ] && [ -d "$HOME/.config/hypr" ]; then
    mkdir -p "$HOME/.config/hypr/custom"
    cp -rn "$BALLADE_DIR/hyprland-custom/"* "$HOME/.config/hypr/custom/" 2>/dev/null || true
    echo "🪟 Installed Hyprland custom blur, rules, and keybinding overrides to ~/.config/hypr/custom/"
fi

# 5. Install Bundled Application Dotfiles & Cursor Themes
if [ -d "$BALLADE_DIR/dotfiles" ]; then
    echo "📦 Installing application configurations (rmpc, mpv, starship, fastfetch, cava, btop, wlogout, fuzzel, micro, kitty, Kvantum, matugen, Joplin, Vencord, KDE)..."
    for app in "$BALLADE_DIR/dotfiles"/*; do
        if [ -d "$app" ]; then
            app_name="$(basename "$app")"
            if [ "$app_name" = "icons" ]; then
                mkdir -p "$HOME/.icons"
                cp -rn "$app/"* "$HOME/.icons/" 2>/dev/null || true
                echo "   ↳ Custom cursor theme (Gloomi_x) installed to ~/.icons/"
            elif [ "$app_name" = "color-schemes" ]; then
                mkdir -p "$HOME/.local/share/color-schemes"
                cp -rn "$app/"* "$HOME/.local/share/color-schemes/" 2>/dev/null || true
                echo "   ↳ KDE color schemes installed to ~/.local/share/color-schemes/"
            elif [ "$app_name" = "konsole" ]; then
                mkdir -p "$HOME/.local/share/konsole"
                [ -d "$app/share" ] && cp -rn "$app/share/"* "$HOME/.local/share/konsole/" 2>/dev/null || true
                [ -f "$app/konsolerc" ] && cp -n "$app/konsolerc" "$HOME/.config/konsolerc" 2>/dev/null || true
                echo "   ↳ Konsole configurations installed"
            elif [ "$app_name" = "kde" ]; then
                [ -f "$app/kdeglobals" ] && cp -n "$app/kdeglobals" "$HOME/.config/kdeglobals" 2>/dev/null || true
                echo "   ↳ KDE globals installed"
            elif [ "$app_name" = "joplin" ]; then
                mkdir -p "$HOME/.config/joplin-desktop"
                cp -rn "$app/"* "$HOME/.config/joplin-desktop/" 2>/dev/null || true
                echo "   ↳ Joplin theme styles installed to ~/.config/joplin-desktop/"
            elif [ "$app_name" = "vencord" ]; then
                mkdir -p "$HOME/.config/Vencord/themes"
                cp -rn "$app/"* "$HOME/.config/Vencord/themes/" 2>/dev/null || true
                echo "   ↳ Vencord DiscordPlus theme installed to ~/.config/Vencord/themes/"
            else
                mkdir -p "$HOME/.config/$app_name"
                cp -rn "$app/"* "$HOME/.config/$app_name/" 2>/dev/null || true
            fi
        fi
    done
    if [ -f "$BALLADE_DIR/dotfiles/starship/starship.toml" ]; then
        cp -n "$BALLADE_DIR/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml" 2>/dev/null || true
    fi
    if [ -d "$BALLADE_DIR/scripts/theming/micro-themes" ]; then
        mkdir -p "$HOME/.config/micro/colorschemes"
        cp -rn "$BALLADE_DIR/scripts/theming/micro-themes/"* "$HOME/.config/micro/colorschemes/" 2>/dev/null || true
    fi
    if [ -f "$BALLADE_DIR/scripts/theming/fastfetch-wrapper.sh" ]; then
        mkdir -p "$HOME/.local/bin"
        cp -f "$BALLADE_DIR/scripts/theming/fastfetch-wrapper.sh" "$HOME/.local/bin/fastfetch"
        chmod +x "$HOME/.local/bin/fastfetch"
    fi
    if [ -d "$BALLADE_DIR/scripts/rmpc" ]; then
        mkdir -p "$HOME/.local/bin"
        cp -f "$BALLADE_DIR/scripts/rmpc/rmpc-run" "$HOME/.local/bin/rmpc-run"
        cp -f "$BALLADE_DIR/scripts/rmpc/rmpc-fetch-lyrics" "$HOME/.local/bin/rmpc-fetch-lyrics"
        chmod +x "$HOME/.local/bin/rmpc-run"
        chmod +x "$HOME/.local/bin/rmpc-fetch-lyrics"
        echo "   ↳ rmpc custom scripts installed to ~/.local/bin/"
    fi
    echo "   ↳ Application dotfiles installed to ~/.config/ and ~/.local/share/"
fi

echo ""
echo "✨ QuickShell Ballade setup is complete!"
echo "🚀 You can now launch Ballade anytime with: qs -c ballade"

