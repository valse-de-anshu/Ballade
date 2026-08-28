#!/usr/bin/env bash
# ==============================================================================
# Ballade Tree + Minimalist Dot Gauge Fastfetch Dynamic Themer
# Multi-Drive Telemetry + Aspect-Ratio Preserving Logo + Preset Theming
# ==============================================================================

THEME_KEY="${1:-green}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BALLADE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FASTFETCH_DIR="$HOME/.config/fastfetch"
FASTFETCH_CONFIG="$FASTFETCH_DIR/config.jsonc"

mkdir -p "$FASTFETCH_DIR"

if [ ! -f "$FASTFETCH_DIR/current_logo.png" ] && [ -f "$BALLADE_DIR/dotfiles/fastfetch/asset/1.png" ]; then
    cp "$BALLADE_DIR/dotfiles/fastfetch/asset/1.png" "$FASTFETCH_DIR/current_logo.png"
fi

case "$THEME_KEY" in
    green|atelier|everforest)
        PRESET="green"
        KEY_COLOR="38;2;125;151;38"       # Forest Sage (#7d9726)
        ACCENT_COLOR="38;2;165;152;13"    # Gold-Olive
        ;;
    golden|gold|amber|yellow)
        PRESET="golden"
        KEY_COLOR="38;2;240;184;73"      # Luminous Amber (#f0b849)
        ACCENT_COLOR="38;2;254;210;104"   # Pale Gold
        ;;
    orange|sunset|tangerine)
        PRESET="orange"
        KEY_COLOR="38;2;255;146;72"      # Autumn Sunset (#ff9248)
        ACCENT_COLOR="38;2;247;187;99"    # Citrus Ember
        ;;
    pink|sakura)
        PRESET="pink"
        KEY_COLOR="38;2;212;101;154"     # Sakura Pink (#d4659a)
        ACCENT_COLOR="38;2;240;98;146"    # Vibrant Orchid
        ;;
    purple|amethyst)
        PRESET="purple"
        KEY_COLOR="38;2;156;90;219"      # Amethyst Violet (#9c5adb)
        ACCENT_COLOR="38;2;186;104;200"   # Radiant Lavender
        ;;
    red|crimson)
        PRESET="red"
        KEY_COLOR="38;2;191;63;67"       # Crimson Scarlet (#bf3f43)
        ACCENT_COLOR="38;2;255;82;82"     # Neon Red
        ;;
    blue|tokyo_night|tokyonight)
        PRESET="blue"
        KEY_COLOR="38;2;122;162;247"     # Tokyo Night Blue (#7aa2f7)
        ACCENT_COLOR="38;2;187;154;247"   # Tokyo Purple
        ;;
    grayscale|nord|monochrome|bw)
        PRESET="grayscale"
        KEY_COLOR="38;2;136;192;208"     # Frost Blue (#88c0d0)
        ACCENT_COLOR="38;2;129;161;193"   # Glacier Ice
        ;;
    *)
        PRESET="green"
        KEY_COLOR="38;2;125;151;38"
        ACCENT_COLOR="38;2;165;152;13"
        ;;
esac

cat << EOF_JSON > "$FASTFETCH_CONFIG"
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "logo": {
    "source": "$FASTFETCH_DIR/current_logo.png",
    "type": "kitty",
    "width": 30,
    "preserveAspectRatio": true,
    "padding": {
      "top": 1,
      "left": 2,
      "right": 4
    }
  },
  "display": {
    "separator": "  ",
    "color": {
      "keys": "$KEY_COLOR"
    },
    "percent": {
      "type": 3
    },
    "bar": {
      "char": {
        "elapsed": "●",
        "total": "○"
      },
      "width": 10
    }
  },
  "modules": [
    {
      "type": "title",
      "format": " 󰣇  {user-name} @ {host-name}",
      "color": {
        "user": "$ACCENT_COLOR",
        "at": "$KEY_COLOR",
        "host": "$ACCENT_COLOR"
      }
    },
    "break",
    {
      "type": "custom",
      "format": " {#$KEY_COLOR}󰅐 SYSTEM{#}"
    },
    {
      "type": "os",
      "key": " ├── 󰣇  os          ",
      "format": "{3} ({12})"
    },
    {
      "type": "kernel",
      "key": " ├── 󰒋  kernel      ",
      "format": "{1} {2}"
    },
    {
      "type": "uptime",
      "key": " ├── 󱎫  uptime      "
    },
    {
      "type": "packages",
      "key": " └── 󰏖  pkgs        "
    },
    "break",
    {
      "type": "custom",
      "format": " {#$KEY_COLOR} DESKTOP{#}"
    },
    {
      "type": "wm",
      "key": " ├── 󱂬  wm          ",
      "format": "{1} (Wayland)"
    },
    {
      "type": "terminal",
      "key": " ├── 󰆍  term        ",
      "format": "{1}"
    },
    {
      "type": "shell",
      "key": " ├── 󱆃  shell       ",
      "format": "{1}"
    },
    {
      "type": "display",
      "key": " └── 󰍹  display     ",
      "format": "{1}x{2} @ {3}Hz"
    },
    "break",
    {
      "type": "custom",
      "format": " {#$KEY_COLOR}󰻠 HARDWARE{#}"
    },
    {
      "type": "cpu",
      "key": " ├── 󰻠  cpu         ",
      "format": "{1} ({5}c)"
    },
    {
      "type": "gpu",
      "key": " ├── 󰢮  gpu         ",
      "format": "{2}"
    },
    {
      "type": "memory",
      "key": " ├── 󰍛  RAM         "
    },
    {
      "type": "disk",
      "key": " ├── 󰋊  root        ",
      "folders": "/"
    },
    {
      "type": "disk",
      "key": " ├── 󰋊  home        ",
      "folders": "/home"
    },
    {
      "type": "disk",
      "key": " ├── 󰋊  maiden      ",
      "folders": "/mnt/maiden"
    },
    {
      "type": "disk",
      "key": " └── 󰋊  storage     ",
      "folders": "/mnt/storage"
    },
    "break",
    {
      "type": "colors",
      "symbol": "circle",
      "paddingLeft": 2
    }
  ]
}
EOF_JSON

cp -f "$FASTFETCH_CONFIG" "$BALLADE_DIR/dotfiles/fastfetch/config.jsonc" 2>/dev/null || true
echo "[Fastfetch Themer] Generated aspect-ratio preserved fastfetch config for $PRESET preset."
