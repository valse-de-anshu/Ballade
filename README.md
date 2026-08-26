# 🎼 Ballade

A modular [QuickShell](https://quickshell.outfoxxed.me/) desktop shell for [Hyprland](https://hyprland.org/), built upon the foundation of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (**Illogical Impulse / `ii`**).

`ballade` combines the frosted-glass aesthetic of `ii` with the feature-rich modules of `end4-pC` (sidebars, AI translation, panoramic wallpaper picker, and desktop widgets).

---

## 🚀 Running Alongside `ii`

`ballade` lives standalone in `~/.config/quickshell/ballade` and shares user preferences via `~/.config/illogical-impulse/config.json`.

- **Run Ballade:**
  ```bash
  qs -c ballade
  ```
- **Run Standard ii:**
  ```bash
  qs -c ii
  ```
- **Set as default in Hyprland (`~/.config/hypr/custom/env.lua`):**
  ```lua
  hl.env("qsConfig", "ballade")
  ```

---

## 📦 Dependencies

Ensure these packages are installed:

- **Shell & Compositor:** `quickshell`, `hyprland`, `qt6-declarative`, `qt6-5compat`, `qt6-svg`
- **Audio & Media:** `pipewire`, `wireplumber`, `playerctl`, `canberra-gtk-play`, `mpv`, `pw-play`
- **Theming & Presets:** `matugen`, `kitty`, `konsole`, `plasma-apply-colorscheme`, `tela-circle-icon-theme-git`
- **Utilities & OCR:** `jq`, `wl-clipboard`, `cliphist`, `tesseract`, `hyprpicker`, `hyprsunset`

---

## ⌨️ Common IPC Commands

Trigger modules via keybindings or terminal:

```bash
qs -c ballade ipc call sidebarLeft toggle        # Left Sidebar (AI, Translator, Music)
qs -c ballade ipc call sidebarRight toggle       # Right Sidebar (Control Center, Audio)
qs -c ballade ipc call overview toggle           # App Launcher / Window Overview
qs -c ballade ipc call wallpaperSelector toggle  # Panoramic Wallpaper Picker
qs -c ballade ipc call mediaControls toggle      # Music Player Track Popup
qs -c ballade ipc call sessionScreen toggle      # Lock / Logout / Power Menu
qs -c ballade ipc call osdVolume trigger         # Volume OSD HUD
```

---

## 📁 Portability

All scripts use self-resolving dynamic paths. You can copy the entire `ballade` folder directly to `~/.config/quickshell/ballade` on any device and launch immediately.
