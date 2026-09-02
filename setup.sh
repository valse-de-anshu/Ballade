#!/bin/bash
# 🎼 QuickShell Ballade - Automated 1-Click Environment Initializer
# Sets up directories, wallpaper presets, sound events, helper scripts, and permissions.

set -euo pipefail

BALLADE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BALLADE_DIR/scripts"

echo "🎼 Initializing QuickShell Ballade on target system ($USER @ $HOME)..."

# 1. Ensure all shell and Python scripts are executable
echo "🔑 Making scripts executable..."
find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
[ -d "$BALLADE_DIR/hyprland-custom/scripts" ] && find "$BALLADE_DIR/hyprland-custom/scripts" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "$BALLADE_DIR/setup.sh" 2>/dev/null || true

# 2. Create standard user directories
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
mkdir -p "$HOME/.local/share/login_greetings"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.cache/illogical-impulse"

# 3. Setup System Sounds & Audio Daemons
if [ -d "$BALLADE_DIR/sounds/login_greetings" ]; then
    mkdir -p "$HOME/.local/share/login_greetings"
    cp -rn "$BALLADE_DIR/sounds/login_greetings/"* "$HOME/.local/share/login_greetings/" 2>/dev/null || true
fi

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
                if [ -d "$HOME/.icons/Gloomi-x-Cursor-Custom" ] && [ ! -e "$HOME/.icons/Gloomi_x" ]; then
                    ln -sf "Gloomi-x-Cursor-Custom" "$HOME/.icons/Gloomi_x"
                fi
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
    echo "   ↳ Application dotfiles installed to ~/.config/ and ~/.local/share/"
fi

# 6. Install Helper Binaries & User Scripts to ~/.local/bin
echo "⚙️ Installing helper scripts and CLI utilities to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"

# Fastfetch launcher
if [ -f "$BALLADE_DIR/scripts/theming/fastfetch-wrapper.sh" ]; then
    cp -f "$BALLADE_DIR/scripts/theming/fastfetch-wrapper.sh" "$HOME/.local/bin/fastfetch"
    chmod +x "$HOME/.local/bin/fastfetch"
fi

# rmpc launcher and lyric fetcher
if [ -d "$BALLADE_DIR/scripts/rmpc" ]; then
    cp -f "$BALLADE_DIR/scripts/rmpc/rmpc-run" "$HOME/.local/bin/rmpc-run"
    cp -f "$BALLADE_DIR/scripts/rmpc/rmpc-fetch-lyrics" "$HOME/.local/bin/rmpc-fetch-lyrics"
    chmod +x "$HOME/.local/bin/rmpc-run" "$HOME/.local/bin/rmpc-fetch-lyrics"
    ln -sf "$HOME/.local/bin/rmpc-run" "$HOME/.local/bin/rmpc-launch" 2>/dev/null || true
    echo "   ↳ rmpc custom scripts installed to ~/.local/bin/"
fi

# Wayland clipboard utilities
if [ -d "$BALLADE_DIR/scripts/clipboard" ]; then
    cp -f "$BALLADE_DIR/scripts/clipboard/"* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/clipboard-image-transformer.py" "$HOME/.local/bin/copy-image-with-path.py" 2>/dev/null || true
    echo "   ↳ Clipboard image utilities installed to ~/.local/bin/"
fi

# System utilities & greetings
if [ -f "$BALLADE_DIR/scripts/system/random-greeting.sh" ]; then
    cp -f "$BALLADE_DIR/scripts/system/random-greeting.sh" "$HOME/.local/bin/random-greeting.sh"
    chmod +x "$HOME/.local/bin/random-greeting.sh"
fi

if [ -f "$BALLADE_DIR/scripts/system/systemctl-wrapper" ]; then
    cp -f "$BALLADE_DIR/scripts/system/systemctl-wrapper" "$HOME/.local/bin/systemctl"
    chmod +x "$HOME/.local/bin/systemctl"
fi

if [ -f "$BALLADE_DIR/scripts/system/loginctl-wrapper" ]; then
    cp -f "$BALLADE_DIR/scripts/system/loginctl-wrapper" "$HOME/.local/bin/loginctl"
    chmod +x "$HOME/.local/bin/loginctl"
fi

# Screen Time 24-hour Watchdog Daemon
if [ -f "$BALLADE_DIR/scripts/system/ballade-screentime.service" ]; then
    mkdir -p "$HOME/.config/systemd/user"
    cp -f "$BALLADE_DIR/scripts/system/ballade-screentime.service" "$HOME/.config/systemd/user/ballade-screentime.service"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user enable --now ballade-screentime.service >/dev/null 2>&1 || true
    fi
    echo "   ↳ 24-hour Screen Time daemon installed & enabled (ballade-screentime.service)"
fi

# Power audio executor & symlinks
if [ -f "$SCRIPTS_DIR/power-audio-executor.sh" ]; then
    cp -f "$SCRIPTS_DIR/power-audio-executor.sh" "$HOME/.local/bin/power-audio-executor.sh"
    chmod +x "$HOME/.local/bin/power-audio-executor.sh"
    for cmd in poweroff reboot shutdown; do
        ln -sf "$HOME/.local/bin/power-audio-executor.sh" "$HOME/.local/bin/$cmd" 2>/dev/null || true
    done
fi

# 7. Initialize Theme & Build Dynamic Ecosystem Colors
if [ -f "$SCRIPTS_DIR/theming/apply-theme-preset.sh" ]; then
    echo "🎨 Initializing default theme preset (green)..."
    bash "$SCRIPTS_DIR/theming/apply-theme-preset.sh" green >/dev/null 2>&1 || true
    echo "   ↳ Synchronized 16 subsystems (Kitty, Starship, Micro, CAVA, rmpc, Fastfetch, Kvantum, KDE)"
fi

echo ""
echo "✨ QuickShell Ballade setup is complete!"
echo "🚀 You can now launch Ballade anytime with: qs -c ballade"
