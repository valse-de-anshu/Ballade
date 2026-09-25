[← Back to Main README](../README.md)

# 🎨 App Theming & Setup Guide (Discord, Joplin, Obsidian, Micro & CLI)

This guide shows you how to set up, customize, and get the most out of **Discord / Vesktop**, **Joplin**, **Obsidian**, **Micro**, and terminal utilities in the Ballade desktop environment from scratch.

---

## 💬 1. Discord & Vesktop Customization

### Step 1: Install Discord or Vesktop
You can use either official **Discord** (with Vencord) or **Vesktop** (standalone client with Vencord pre-bundled):
* **Option A: Vesktop (Recommended)**:
  ```bash
  sudo pacman -S vesktop   # or via yay/paru
  ```
  Vesktop comes with built-in Vencord, screensharing with audio on Wayland, and automatically picks up Ballade's synced themes and QuickCSS.
* **Option B: Official Discord with Vencord**:
  ```bash
  sudo pacman -S discord
  VencordInstaller -install -branch stable
  ```

### Step 2: Choose Your Theme
Ballade bundles two tailored CSS themes for Vesktop / Vencord in `dotfiles/vencord/`:
1. **`DiscordPlus.theme.css` (Dynamic Wallpaper & Accent Harmony)**:
   - Synchronizes your active desktop wallpaper into Discord as a smooth backdrop.
   - Dynamically shifts accent colors to match the active Ballade preset (`green`, `purple`, `orange`, `pink`, `catppuccin`, etc.).
2. **`ballade-theme.css` (Translucent Frosted Glass Mode)**:
   - Pure translucent frosted glass without a wallpaper canvas.
   - Blends seamlessly into Hyprland's Wayland compositor blur.

### Step 3: Fix Video Playback in Group Chats
On Linux, Discord's default media player doesn't decode some MP4/H.264 formats out of the box.
* **Fix**: Open Discord **User Settings (⚙️)** $\to$ **Voice & Video** $\to$ scroll down to **Video Codec** $\to$ turn **ON** `OpenH264 Video Codec provided by Cisco Systems, Inc.`.

### Step 4: Reloading Styles
Whenever you switch themes in QuickShell, press **`Ctrl + R`** inside Discord to immediately refresh styles.

---

## 📓 2. Joplin Note-Taking Suite

### How It Works
1. **Depth Theming**: Custom styles are written to `~/.config/joplin-desktop/userchrome.css` (app UI) and `userstyle.css` (rendered markdown notes).
2. **Preset Harmony**: All color presets are supported with 3-tier background depths (sidebar, note list, and editor canvas).
3. **Smart Tray Restart**: If Joplin is open when you switch themes in QuickShell, Ballade quietly restarts it minimized to the system tray (`scripts/theming/restart-joplin.py`) so you never have to manually close and reopen it. If Joplin is closed, nothing happens.

---

## 💎 3. Obsidian Knowledge Base

### How It Works
1. **CSS Snippet Integration**: Ballade writes custom CSS snippets directly to your Obsidian vaults at `.obsidian/snippets/ballade-theme.css`.
2. **Accent Matching**: Highlight colors, tags, and active note tabs automatically reflect your active preset.
3. **Enabling the Snippet**: In Obsidian **Settings (⚙️)** $\to$ **Appearance** $\to$ scroll to **CSS Snippets** $\to$ toggle **ON** `ballade-theme`.

---

## 📝 4. Micro Terminal Text Editor

Ballade ships a configured **micro** terminal editor setup in `dotfiles/micro/`:
* **`init.lua`**:
  - Automatically loads the configured theme upon startup.
  - Status bar real-time word counter (`wordCount`).
  - Date and time insertion helpers (`insertDate` and `insertDateTime`).
  - Line / selection duplication automation.
* **Colorschemes**:
  - Full suite of Material Design 3 and Catppuccin color schemes matching all Ballade presets (`catppuccin`, `green`, `blue`, `golden`, `orange`, `pink`, `purple`, `red`, `grayscale`, `atelier-estuary`).

---

## 🎵 5. Music & Visualizers (rmpc, mpv, CAVA)

* **rmpc (Music Player Client)**:
  - Configured at `~/.config/rmpc/config.ron`.
  - Automatically loads synced themes matching the active Ballade preset.
  - Automatically adapts lyrics and helper binary paths to the target machine's `$HOME`.
* **mpv**:
  - High performance shaders (Anime4K, FSRCNNX, cinematic film color grades).
  - Modern `uosc` overlay interface with pre-compiled `ziggy-linux` companion binary.
* **CAVA**:
  - Real-time gradient audio visualizer synchronized to the active desktop theme preset.

---

## 📱 6. Hyprland Custom & KDE Connect Reconnect Service

* **KDE Connect Auto-Reconnect** (`~/.config/hypr/custom/scripts/kdeconnect_auto_reconnect.sh`):
  - Runs in the background on Hyprland startup via `hyprland-custom/execs.lua`.
  - Monitors paired mobile devices and triggers network discovery every 30 seconds if a device disconnects, ensuring automatic re-pairing without manual reconnects.
* **Quick Keybindings**:
  - `SUPER + I` / `CTRL + I`: Toggle QuickShell Settings Hub.
  - `SUPER + ALT + Space`: Compact centered window focus mode.
  - `ALT + S`: Gwenview Snip & Annotate.
  - `SUPER + SHIFT + X`: Fast OCR (English + Hindi) to clipboard.

---

[← Back to Main README](../README.md)
