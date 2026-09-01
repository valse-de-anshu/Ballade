#!/usr/bin/env bash
# ==============================================================================
# Ballade CAVA Dynamic Theming & Live Reloader
# Updates ~/.config/cava/config color gradient and sends reload signal to running instances.
# ==============================================================================

PRESET_NAME="${1:-green}"
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"

if [ -z "$1" ] && [ -f "$CONFIG_FILE" ]; then
    PRESET_NAME=$(jq -r '.theme.activePreset // "green"' "$CONFIG_FILE" 2>/dev/null)
fi

CAVA_CONFIG_DIR="$HOME/.config/cava"
CAVA_CONFIG="$CAVA_CONFIG_DIR/config"
CAVA_THEMES_DIR="$CAVA_CONFIG_DIR/themes"

mkdir -p "$CAVA_CONFIG_DIR" "$CAVA_THEMES_DIR"

declare -a GRADIENT_COLORS

case "$PRESET_NAME" in
    green|atelier|everforest)
        GRADIENT_COLORS=(
            "'#18211e'"
            "'#2b3339'"
            "'#36a166'"
            "'#5f9182'"
            "'#7d9726'"
            "'#83c092'"
            "'#a7c080'"
            "'#dbbc7f'"
        )
        ;;
    pink|sakura)
        GRADIENT_COLORS=(
            "'#25171f'"
            "'#3b2030'"
            "'#5e314d'"
            "'#f38ba8'"
            "'#e05688'"
            "'#f5c2e7'"
            "'#eba0ac'"
            "'#cba6f7'"
        )
        ;;
    red|crimson)
        GRADIENT_COLORS=(
            "'#261314'"
            "'#3d1a1c'"
            "'#612528'"
            "'#ba6236'"
            "'#d32f2f'"
            "'#e78284'"
            "'#ea6962'"
            "'#fab387'"
        )
        ;;
    purple|amethyst)
        GRADIENT_COLORS=(
            "'#1a162b'"
            "'#26233a'"
            "'#524f67'"
            "'#9ccfd8'"
            "'#c4a7e7'"
            "'#bb9af7'"
            "'#9c27b0'"
            "'#f6c177'"
        )
        ;;
    blue|tokyo_night|tokyonight)
        GRADIENT_COLORS=(
            "'#1a1b26'"
            "'#24283b'"
            "'#414868'"
            "'#565f89'"
            "'#7aa2f7'"
            "'#7dcfff'"
            "'#b4f9f8'"
            "'#bb9af7'"
        )
        ;;
    grayscale|nord|monochrome|bw)
        GRADIENT_COLORS=(
            "'#242831'"
            "'#2e3440'"
            "'#3b4252'"
            "'#4c566a'"
            "'#88c0d0'"
            "'#81a1c1'"
            "'#5e81ac'"
            "'#eceff4'"
        )
        ;;
    golden|gold|amber|yellow)
        GRADIENT_COLORS=(
            "'#1d1810'"
            "'#2b2416'"
            "'#4a3e26'"
            "'#b8a055'"
            "'#dca561'"
            "'#e0af68'"
            "'#f0b849'"
            "'#ff9e3b'"
        )
        ;;
    orange|sunset|tangerine)
        GRADIENT_COLORS=(
            "'#241814'"
            "'#38231c'"
            "'#59362a'"
            "'#d3869b'"
            "'#ea6962'"
            "'#e78a4e'"
            "'#ff9248'"
            "'#fab387'"
        )
        ;;
    *)
        GRADIENT_COLORS=(
            "'#18211e'"
            "'#2b3339'"
            "'#36a166'"
            "'#5f9182'"
            "'#7d9726'"
            "'#83c092'"
            "'#a7c080'"
            "'#dbbc7f'"
        )
        ;;
esac

cat <<EOF > "$CAVA_CONFIG"
## CAVA Configuration — Dynamic Ballade Theme ($PRESET_NAME)
## Source: MPD FIFO at /tmp/mpd.fifo

[general]
framerate = 60
autosens = 1
sensitivity = 150
bars = 0
bar_width = 2
bar_spacing = 1
sleep_timer = 5

[input]
method = fifo
source = /tmp/mpd.fifo
sample_rate = 44100
sample_bits = 16
channels = 2

[output]
method = noncurses
channels = mono
mono_option = average
reverse = 0
continuous_rendering = 1

[color]
gradient = 1
gradient_color_1 = ${GRADIENT_COLORS[0]}
gradient_color_2 = ${GRADIENT_COLORS[1]}
gradient_color_3 = ${GRADIENT_COLORS[2]}
gradient_color_4 = ${GRADIENT_COLORS[3]}
gradient_color_5 = ${GRADIENT_COLORS[4]}
gradient_color_6 = ${GRADIENT_COLORS[5]}
gradient_color_7 = ${GRADIENT_COLORS[6]}
gradient_color_8 = ${GRADIENT_COLORS[7]}

[smoothing]
noise_reduction = 50

[eq]
1 = 1.2
2 = 1.1
3 = 1.0
4 = 1.0
5 = 0.9
EOF

cat <<EOF > "$CAVA_THEMES_DIR/${PRESET_NAME}"
[color]
gradient = 1
gradient_color_1 = ${GRADIENT_COLORS[0]}
gradient_color_2 = ${GRADIENT_COLORS[1]}
gradient_color_3 = ${GRADIENT_COLORS[2]}
gradient_color_4 = ${GRADIENT_COLORS[3]}
gradient_color_5 = ${GRADIENT_COLORS[4]}
gradient_color_6 = ${GRADIENT_COLORS[5]}
gradient_color_7 = ${GRADIENT_COLORS[6]}
gradient_color_8 = ${GRADIENT_COLORS[7]}
EOF

# Copy to ballade dotfiles too
mkdir -p "$HOME/.config/quickshell/ballade/dotfiles/cava/themes"
cp -f "$CAVA_CONFIG" "$HOME/.config/quickshell/ballade/dotfiles/cava/config"
cp -f "$CAVA_THEMES_DIR/${PRESET_NAME}" "$HOME/.config/quickshell/ballade/dotfiles/cava/themes/${PRESET_NAME}"

# Reload running CAVA processes smoothly via USR2 / USR1 signal
if pidof cava >/dev/null 2>&1; then
    pkill -USR2 -x cava 2>/dev/null || pkill -USR1 -x cava 2>/dev/null || true
fi
