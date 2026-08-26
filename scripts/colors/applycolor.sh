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

  local preset_theme_file="$SCRIPT_DIR/../theming/kitty-themes/${active_preset}.conf"
  if [ -n "$active_preset" ] && [ -f "$preset_theme_file" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$preset_theme_file" "$HOME/.config/kitty/current-theme.conf"
  else
    # Check if terminal escape sequence template exists
    if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
      echo "Template file not found for Kitty theme. Skipping that."
      return
    fi
    # Copy template
    mkdir -p "$STATE_DIR"/user/generated/terminal
    cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
    # Apply colors
    for i in "${!colorlist[@]}"; do
      sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
    done

    # Copy to kitty's config directory so it actually applies!
    mkdir -p "$HOME/.config/kitty"
    cp "$STATE_DIR"/user/generated/terminal/kitty-theme.conf "$HOME/.config/kitty/current-theme.conf"
  fi

  # Reload running Kitty instances
  if pgrep -f kitty >/dev/null; then
    kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
  fi
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
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
