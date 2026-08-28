# 🎨 App Theming & Setup Guide (Discord, Joplin & Obsidian)

This guide shows you how to set up, customize, and get the most out of **Discord**, **Joplin**, and **Obsidian** in the Ballade desktop environment from scratch.

---

## 💬 1. Discord & Discord+ Customization

### Step 1: Install Discord & Vencord
1. **Install official Discord**:
   ```bash
   sudo pacman -S discord
   ```
2. **Install Vencord** (enables custom themes and plugins):
   ```bash
   VencordInstaller -install -branch stable
   ```

### Step 2: Fix Video Playback in Group Chats
On Linux, Discord's default media player doesn't decode some MP4/H.264 formats out of the box.
* **Fix**: Open Discord **User Settings (⚙️)** $\to$ **Voice & Video** $\to$ scroll down to **Video Codec** $\to$ turn **ON** `OpenH264 Video Codec provided by Cisco Systems, Inc.`.

### Step 3: How the Theme Syncs
Whenever you pick a theme preset in QuickShell (e.g. `purple`, `golden`, `green`) or change wallpapers:
1. Ballade automatically grabs your **active desktop wallpaper** and sets it as the backdrop for Discord+.
2. The image is compressed into an inline Data-URI so it renders without security blocks.
3. User avatars are kept at clean, standard `40px` sizes, and sidebar buttons (`+` Add Server, `🧭` Discover) match your theme accent.
4. **To reload Discord with new styles**: Press **`Ctrl + R`** inside Discord.

---

## 📓 2. Joplin Note-Taking Suite

### How It Works
1. **Depth Theming**: Custom styles are written to `~/.config/joplin-desktop/userchrome.css` (app UI) and `userstyle.css` (rendered markdown notes).
2. **Preset Harmony**: All 8 color presets are supported with 3-tier background depths (sidebar, note list, and editor canvas).
3. **Smart Tray Restart**: If Joplin is open when you switch themes in QuickShell, Ballade quietly restarts it minimized to the system tray so you never have to manually close and reopen it. If Joplin is closed, nothing happens.

---

## 💎 3. Obsidian Knowledge Base

### How It Works
1. **CSS Snippet Integration**: Ballade writes custom CSS snippets directly to your Obsidian vaults at `.obsidian/snippets/ballade-theme.css`.
2. **Accent Matching**: Highlight colors, tags, and active note tabs automatically reflect your active preset.
3. **Enabling the Snippet**: In Obsidian **Settings (⚙️)** $\to$ **Appearance** $\to$ scroll to **CSS Snippets** $\to$ toggle **ON** `ballade-theme`.

---

[← Back to Main README](../README.md)
