#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
QUICKSHELL_CONFIG_NAME="$(basename "$CONFIG_DIR")"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

apply_kitty() {  
  local active_preset=""
  local config_file="$HOME/.config/illogical-impulse/config.json"
  if [ -f "$config_file" ]; then
    active_preset=$(jq -r '.theme.activePreset // empty' "$config_file" 2>/dev/null)
  fi

  local preset_file=""
  case "$active_preset" in
    blue|tokyo_night|tokyonight) preset_file="blue.conf" ;;
    grayscale|nord|monochrome|bw) preset_file="grayscale.conf" ;;
    green|atelier|everforest) preset_file="green.conf" ;;
    pink|sakura) preset_file="pink.conf" ;;
    purple|amethyst) preset_file="purple.conf" ;;
    red|crimson) preset_file="red.conf" ;;
    *) preset_file="${active_preset}.conf" ;;
  esac

  local preset_theme_file="$SCRIPT_DIR/../theming/kitty-themes/$preset_file"
  if [ -n "$active_preset" ] && [ -f "$preset_theme_file" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$preset_theme_file" "$HOME/.config/kitty/current-theme.conf"
  elif [ -f "$SCRIPT_DIR/../theming/kitty-themes/nord.conf" ]; then
    # Fallback to a clean, crisp dark theme instead of generating broken light mode
    mkdir -p "$HOME/.config/kitty"
    cp "$SCRIPT_DIR/../theming/kitty-themes/nord.conf" "$HOME/.config/kitty/current-theme.conf"
  fi

  # Reload running Kitty instances safely
  if pidof kitty >/dev/null 2>&1; then
    kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
  fi
}

apply_anyterm() {
  # Kitty and modern Wayland terminals reload via config/signal, avoid raw pts dumping to prevent raster corruption
  return 0
}

apply_konsole() {
  local konsole_theme="$HOME/.local/share/konsole/Quickshell.colorscheme"
  mkdir -p "$HOME/.local/share/konsole"
  
  hex2rgb() {
    local hex="${1#\#}"
    if [ ${#hex} -eq 6 ]; then
      printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    else
      echo "0,0,0"
    fi
  }

  echo "[General]" > "$konsole_theme"
  echo "Description=Dynamic Quickshell" >> "$konsole_theme"
  echo "Opacity=1" >> "$konsole_theme"

  local src_theme="$HOME/.config/kitty/current-theme.conf"
  if [ -f "$src_theme" ]; then
    while read -r line; do
      local key=$(echo "$line" | awk '{print $1}')
      local val=$(echo "$line" | awk '{print $2}')
      
      if [[ -z "$key" || -z "$val" || "$key" =~ ^# ]]; then
        continue
      fi
      
      if [[ "$key" == "background" ]]; then
        echo -e "[Background]\nColor=$(hex2rgb "$val")" >> "$konsole_theme"
      elif [[ "$key" == "foreground" ]]; then
        echo -e "[Foreground]\nColor=$(hex2rgb "$val")" >> "$konsole_theme"
      elif [[ "$key" =~ ^color([0-9]+)$ ]]; then
        local cnum="${BASH_REMATCH[1]}"
        echo -e "[Color${cnum}]\nColor=$(hex2rgb "$val")" >> "$konsole_theme"
        echo -e "[Color${cnum}Intense]\nColor=$(hex2rgb "$val")" >> "$konsole_theme"
      fi
    done < "$src_theme"
  fi

  local profile="$HOME/.local/share/konsole/Profile 1.profile"
  if [ -f "$profile" ]; then
    if grep -q "^ColorScheme=" "$profile"; then
      sed -i "s/^ColorScheme=.*/ColorScheme=Quickshell/" "$profile"
    else
      sed -i '1s/^/[Appearance]\nColorScheme=Quickshell\n\n/' "$profile"
    fi
  fi
}

apply_term() {
  apply_anyterm &
  apply_kitty &
}

# Always apply konsole since it's embedded in Dolphin UI
apply_konsole &

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
