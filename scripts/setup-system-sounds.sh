#!/bin/bash
# QuickShell Ballade - 1-Click Sound & Hardware Event Installer for Arch Linux
# Usage: ./setup-system-sounds.sh

set -euo pipefail

BALLADE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$BALLADE_DIR/scripts"
SYSTEM_DIR="$BALLADE_DIR/scripts/system"

echo "🎵 Setting up QuickShell Ballade Sound Events..."

# 1. Ensure scripts are executable
chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true

# 2. Setup Systemd User Service for USB
mkdir -p "$HOME/.config/systemd/user"
cp -f "$SYSTEM_DIR/usb-audio@.service" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
echo "✅ Installed systemd user service: usb-audio@.service"

# 3. Setup Power Audio Executor in ~/.local/bin
mkdir -p "$HOME/.local/bin"
cp -f "$SCRIPTS_DIR/power-audio-executor.sh" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/power-audio-executor.sh"

# Create power command symlinks in ~/.local/bin if desired
for cmd in poweroff reboot shutdown; do
    ln -sf "$HOME/.local/bin/power-audio-executor.sh" "$HOME/.local/bin/$cmd" 2>/dev/null || true
done
echo "✅ Installed power-audio-executor.sh and power command links in ~/.local/bin"

# 4. Install udev rules for USB hardware detection (if root permissions are available)
if [ -d "/etc/udev/rules.d" ]; then
    if sudo -n cp -f "$SYSTEM_DIR/99-usb-audio.rules" /etc/udev/rules.d/ 2>/dev/null; then
        sudo -n udevadm control --reload-rules 2>/dev/null && sudo -n udevadm trigger 2>/dev/null || true
        echo "✅ Installed & reloaded /etc/udev/rules.d/99-usb-audio.rules"
    else
        echo "ℹ️ Note: Optional USB sound udev rule can be installed anytime with:"
        echo "   sudo cp ~/.config/quickshell/ballade/scripts/system/99-usb-audio.rules /etc/udev/rules.d/ && sudo udevadm control --reload"
    fi
fi

echo "🎉 All QuickShell Ballade sound services have been configured!"
