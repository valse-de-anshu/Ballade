<div align="center">

# 🎼 Ballade
### A Feature-Rich, Modern Wayland Desktop Shell for Hyprland

[![Hyprland](https://img.shields.io/badge/hyprland-00B0FF?style=for-the-badge&logo=archlinux&logoColor=white)](https://hyprland.org/)
[![QuickShell](https://img.shields.io/badge/quickshell-7C4DFF?style=for-the-badge)](https://quickshell.outfoxxed.me/)
[![Wayland](https://img.shields.io/badge/wayland-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://wayland.freedesktop.org/)
[![Material Design](https://img.shields.io/badge/material--design--3-FF4081?style=for-the-badge)](https://m3.material.io/)
[![Qt6](https://img.shields.io/badge/Qt6_QML-41CD52?style=for-the-badge&logo=qt&logoColor=white)](https://www.qt.io/)

<br/>


**Ballade** is a complete, modular desktop shell and widget suite for **Hyprland**, built using **QuickShell** and Qt6 QML.  
It brings a refined frosted-glass look, dynamic Material Design 3 theming, full-featured utility sidebars, an AI assistant, real-time synchronized music lyrics, 3D panoramic wallpaper picking, and desktop home widgets into a seamless Wayland desktop experience.

<br/>

---

### 📸 Screenshots

| 🌲 Forest Green Theme & Widgets | 🔮 Amethyst Purple Theme |
| :---: | :---: |
| <img src="assets/screenshots/home-green.png" width="460" alt="Home Green" /> | <img src="assets/screenshots/theme-purple.png" width="460" alt="Theme Purple" /> |

| 🔴 Crimson Red Theme & YouTube Subtitles `[CC]` | 🌌 Tokyo Night Blue, rmpc & Animated GIFs |
| :---: | :---: |
| <img src="assets/screenshots/theme-red-ytcc.png" width="460" alt="Red Theme YouTube CC" /> | <img src="assets/screenshots/theme-blue-rmpc-gifs.png" width="460" alt="Blue Theme rmpc GIFs" /> |

| 🌌 3D Panoramic Wallpaper Picker | 🌸 Sakura Pink Theme & Sidebar |
| :---: | :---: |
| <img src="assets/screenshots/wallpaper-picker.png" width="460" alt="Wallpaper Picker" /> | <img src="assets/screenshots/theme-pink.png" width="460" alt="Theme Pink" /> |

| 🎵 Music Player & Synced Lyrics | ⚙️ Themes & Settings Hub |
| :---: | :---: |
| <img src="assets/screenshots/widgets-lyrics.png" width="460" alt="Music and Lyrics" /> | <img src="assets/screenshots/settings-presets.png" width="460" alt="Settings Presets" /> |

---

</div>

<br/>

## 🧭 Table of Contents
- [⚡ Quick Start](#-quick-start)
- [✨ Key Features & Modules](#-key-features--modules)
- [🎨 Dynamic Theming & Multi-App Engine](#-dynamic-theming--multi-app-configuration-engine)
- [⌨️ IPC & Keybinding Shortcuts](#️-ipc--keybinding-shortcuts)
- [📦 System Prerequisites](#-system-prerequisites--dependencies)
- [📂 Directory Anatomy](#-directory-anatomy)
- [💖 Credits & Upstream](#-credits--upstream)

---

## ⚡ 60-Second Quick Start

Ballade is fully standalone. It can coexist alongside any other shell configuration without touching your personal files.

### 1. Install Runtime Dependencies (Arch Linux / CachyOS)
```bash
sudo pacman -S --needed quickshell hyprland qt6-declarative qt6-5compat qt6-svg qt6-wayland \
    pipewire wireplumber playerctl canberra-gtk-play mpv yt-dlp jq wl-clipboard cliphist \
    tesseract tesseract-data-eng hyprpicker hyprsunset kitty
```

### 2. Clone into QuickShell Directory
```bash
git clone https://github.com/valse-de-anshu/Ballade.git ~/.config/quickshell/ballade
```

### 3. Initialize & Launch
```bash
cd ~/.config/quickshell/ballade
./setup.sh
qs -c ballade
```

### 4. Auto-Start with Hyprland
- **Using `dots-hyprland` (`~/.config/hypr/custom/env.lua` or `~/.config/hypr/custom/variables.lua`):**
  ```lua
  hl.env("qsConfig", "ballade")
  ```
- **Or in `~/.config/hypr/hyprland/variables.lua`:**
  ```lua
  hl.env("qsConfig", "ballade")
  ```
- **Using standard `hyprland.conf`:**
  ```ini
  exec-once = qs -c ballade
  ```

---

## ✨ Key Features & Modules

### 🌲 1. Top Status Bar (Ditto `ii` Bar + `end4-pC` Visualizer)
* **Living Workspaces**: Dynamic morphing dot indicators tracking active, occupied, and empty virtual desktops across single and multi-monitor setups.
* **Active Window Information**: Live window title display and application class detection.
* **Audio Waveform Visualizer**: Animated sound wave visualizer reacting to audio in real-time. Left-click opens track preview & controls (`MediaControls.qml`); right-click toggles play/pause.
* **Jitter-Free Hardware Telemetry**: CPU %, RAM %, Swap %, and Temp meters locked with OpenType tabular figures (`tnum`) to eliminate number twitching. Swap automatically reveals itself when swap memory is actively in use (`> 0%`).
* **Interactive System Tray & Quick Icons**: Wayland status notifier tray, Wi-Fi SSID / Ethernet status, Bluetooth, Battery percentage with charging states, and Volume indicators.
* **Update Tracker & Calendar**: Pending system updates counter with a 1-click terminal launcher, plus formatted time/date with click-to-open calendar popup and world timezone clock.
* **Vertical Bar Mode (`modules/ii/verticalBar/`)**: Full alternative side-docked bar orientation.

### 🧠 2. Intelligent Left Sidebar (`end4-pC` + `ballade`)
* **Conversational AI Companion**: Direct chat client supporting Google Gemini API, local Ollama models (`llama3`, `deepseek`), and OpenAI ChatGPT with Markdown rendering, code highlighting, and chat history.
* **Live Side-by-Side Translator**: Full translator (Google Translate / DeepL) with auto-detection, character counter, quick copy/search buttons, and a compact modal language selector (`SelectionDialog.qml`).
* **Acoustic Player & Synced Lyrics**: Seekable wavy progress slider with an ergonomic circular knob handle, track cover preview, and real-time timed subtitle streaming for English, Hindi, and LRC lyrics.
* **YouTube Subtitle Streaming (`[CC]` Button)**: Dedicated **`[CC]`** caption button that instantly fetches and streams real-time YouTube subtitles/captions via `yt-dlp` directly on your desktop.
* **Sidebar Master Volume Controls**: Dedicated volume up/down/mute buttons connected to master PipeWire volume with instant On-Screen Display (OSD) HUD feedback.
* **Booru Art Explorer**: Search and browse anime art and wallpaper boards with tag search and a 1-click "Apply as Wallpaper" shortcut.

### 🎚️ 3. Tactile Right Sidebar / Control Center (`end4-pC`)
* **Quick-Toggle Tiles**: 1-click toggles for Wi-Fi, Bluetooth, Night Light (Gamma temperature), Anti-Flashbang shader, Audio Sink Router, and Pomodoro Timer.
* **Master QuickSliders**: Smooth touch- and mouse-friendly sliders for Master Volume, Microphone Input Gain, and Display Brightness.
* **Live Audio Sink/Source Router**: Expandable output selector to redirect playback between Headphones, Speakers, Bluetooth headsets, and HDMI outputs on the fly.
* **Network & Bluetooth Dialogs**: Wi-Fi network scanner with password prompt and Bluetooth device pairing/connecting manager.
* **Pomodoro Focus Timer**: Customizable work/break focus timer with notification audio cues.
* **Notification History Center**: Grouped notifications with actionable buttons, timestamps, and one-click clear.

### 🌌 4. 3D Panoramic Cover-Flow Wallpaper Picker (`ballade`)
* **Panoramic 3D Cover-Flow View**: Displays every wallpaper in the active preset directory across the screen in an uninterrupted panoramic arc without horizontal pagination clipping.
* **Interactive Center Scale**: Fluid zoom and border highlight on hovered wallpapers with keyboard arrow navigation and instant Material You color extraction.

### 🖥️ 5. Desktop Home Widgets & Mascot GIFs (`end4-pC` + `ballade`)
* **Frosted Desktop Music Player**: Floating music card with wavy progress tracks, lyrics, and YouTube `[CC]` toggle.
* **Unlimited Desktop Mascot GIFs & Stickers**: Place, scale, and layer unlimited animated GIF mascots, stickers, and pixel pets directly on your desktop canvas.
* **`rmpc` Music Client Integration**: Synchronized styling and color-matching for the `rmpc` (Rust Music Player Client) terminal music player.
* **World Telemetry & Clocks**: Live weather telemetry from `wttr.in`, geographic dot-map locator projection, and customizable digital, analog, and pixel clocks.
* **Persistent Desktop Notes & Tasks**: Auto-saving sticky notes and to-do checklists.

### 🪟 6. Overlays, Hubs & System Screens (`end4-pC`)
* **App Launcher / Overview (`modules/ii/overview/`)**: Full-screen fuzzy app search, math calculator, command execution, and window switcher.
* **Session & Power Screen (`modules/ii/sessionScreen/`)**: Fullscreen power menu with Lock, Logout, Suspend, Hibernate, Reboot, and Shutdown triggers.
* **Screen Region Translator (`modules/ii/screenTranslator/`)**: Snip any region on your screen to perform real-time OCR text extraction and translation.
* **On-Screen Display HUD (`modules/ii/onScreenDisplay/`)**: Non-intrusive overlays for Volume percentage, Brightness level, and Night Light Gamma.
* **Virtual On-Screen Keyboard & Cheatsheet**: Touch-friendly virtual keyboard for 2-in-1s and searchable Hyprland keybindings cheatsheet.
* **Lock Screen (`modules/common/panels/lock/`)**: Frosted glass lockscreen with PAM authentication, password input, media controls, and battery status.

### ⚙️ 7. Master Settings Overlay (`SUPER + I` or `SUPER + Escape` / `modules/ii/settings/`)
* **8 Comprehensive Configuration Pages**: Quick Config, Bar Configuration, Interface & Corner Shapes (`round`, `slanted`, `superellipse`, `cookie`), Desktop Widgets, Profile Info, Hyprland Rules, Services & Audio Steppers, and General Options.
* **Auto-Saving**: All changes write directly to `~/.config/illogical-impulse/config.json`.

### 🔊 8. Audio Events & System Sound Cues (`scripts/` & `assets/`)
* **Bundled Sound Library**: Built-in audio cues for Startup, Shutdown, Lock session, Logout, Sleep, Battery Low, and USB connect/disconnect.
* **Low-Latency Player Fallback**: Automatic multi-backend audio pipeline (`pw-play` ➔ `paplay` ➔ `mpv` ➔ `canberra-gtk-play`).

### 🪟 9. Bundled Hyprland Custom Configuration (`hyprland-custom/`)
Ballade includes full Hyprland override configs inside `hyprland-custom/` that get installed to `~/.config/hypr/custom/`:
* **Frosted Glass Blur (`general.lua`)**: `size = 16`, `passes = 4`, `contrast = 1.0`, `vibrancy = 0.35`.
* **Window Transparency Rules (`rules.lua`)**: `opacity = "0.93 0.88"` for all application windows.
* **Keybinding Integrations (`keybinds.lua`)**:
  - `SUPER + I` or `SUPER + ESC`: Toggle Settings Overlay
  - `CTRL + SUPER + T`: Toggle 3D Panoramic Wallpaper Picker
  - `SUPER + ALT + Space`: Toggle Compact Centered Window
* **Cursor Restoration (`execs.lua`)**: Sets `Gloomi_x` cursor automatically on startup.

---

## 🎨 Dynamic Theming & Multi-App Configuration Engine

Ballade features a dual-tier automated theming pipeline: **Material Design 3 extraction** from any wallpaper, plus **6 handcrafted cohesive theme presets**:

| Preset | Accent Hue | Command Palette | Philosophy |
| :--- | :--- | :--- | :--- |
| **`green`** | `#4CAF50` | Forest Sage / Olive | Atelier Estuary calm, natural focus |
| **`purple`**| `#9C27B0` | Amethyst Violet / Lavender | Cyberpunk midnight with glowing accents |
| **`pink`**  | `#E05688` | Deep Rose / Pastel Orchid | Sakura vibrant anime aesthetic |
| **`red`**   | `#D32F2F` | Scarlet / Salmon Rose | High-energy crimson with pure error alerts |
| **`blue`**  | `#2196F3` | Cyan / Midnight Navy | Tokyo Night deep ocean tranquility |
| **`grayscale`** | `#78909C` | Nord Slate / Charcoal | Distraction-free monochrome productivity |

### 🛠️ What Our Scripts Automate Across Your System:
When you apply a preset (`scripts/theming/apply-theme-preset.sh`) or switch a wallpaper (`scripts/colors/switchwall.sh`), Ballade automatically writes and synchronizes configurations across your entire desktop environment:
- 🐱 **Kitty Terminal**: Applies matching 16-color ANSI templates to `~/.config/kitty/current-theme.conf` and sends `SIGUSR1` for instant live reloading.
- 💻 **Konsole & Dolphin Terminal**: Dynamically writes native RGB color maps to `~/.local/share/konsole/Quickshell.colorscheme` and registers it in `~/.config/konsolerc`.
- 🐬 **KDE Plasma & Dolphin**: Applies matching colorschemes via `plasma-apply-colorscheme` and updates `kdeglobals`.
- 🎨 **Kvantum Qt Engine**: Generates and compiles Material theme SVGs via `scripts/kvantum/materialQT.sh`.
- 🏷️ **GTK & Icons**: Updates `gsettings` to synchronize GTK 3/4 theme colors and `Tela-circle-*` icon packs.
- 🚀 **Starship Prompt**: Synchronizes prompt accent colors in `~/.config/starship.toml`.
- 🪟 **Hyprland Compositor**: Enforces frosted glass blur (`passes = 4`, `size = 16`) and window opacities (`0.93 0.88`) via `hyprland-custom/`.

---

## ⌨️ IPC & Keybinding Shortcuts

Control shell modules from Hyprland keybindings or terminal scripts:

```bash
qs -c ballade ipc call sidebarLeft toggle        # Left Sidebar (AI, Translator, Music)
qs -c ballade ipc call sidebarRight toggle       # Right Sidebar (Control Center, Sliders)
qs -c ballade ipc call overview toggle           # App Launcher & Window Overview
qs -c ballade ipc call wallpaperSelector toggle  # 3D Panoramic Wallpaper Carousel (CTRL+SUPER+T)
qs -c ballade ipc call settings toggle           # Master Settings Hub (SUPER+I or SUPER+ESC)
qs -c ballade ipc call mediaControls toggle      # Music Player Popup & Seek
qs -c ballade ipc call sessionScreen toggle      # Power & Session Menu (Lock/Shutdown)
qs -c ballade ipc call osdVolume trigger         # Volume On-Screen Display HUD
qs -c ballade ipc call cheatsheet toggle         # Keybindings Cheatsheet
qs -c ballade ipc call cliphist toggle           # Clipboard History Manager
```

---

## 📦 System Prerequisites & Dependencies

| Domain | Required Packages | Purpose |
| :--- | :--- | :--- |
| **Compositor & Shell** | `hyprland`, `quickshell`, `qt6-declarative`, `qt6-5compat`, `qt6-svg`, `qt6-wayland` | Wayland compositing and QML widget rendering |
| **Audio Server & Media** | `pipewire`, `wireplumber`, `playerctl`, `canberra-gtk-play`, `mpv`, `pw-play` | PipeWire volume scaling, MPRIS player controls, sound events |
| **Media & Lyrics Engine** | `yt-dlp`, `playerctl`, `mpv` | Real-time YouTube CC caption extraction and media streaming |
| **Dynamic Theming** | `matugen`, `kitty`, `konsole`, `plasma-apply-colorscheme`, `tela-circle-icon-theme-git` | Material You color extraction, Kitty/Konsole terminal palettes |
| **Utilities & OCR** | `jq`, `wl-clipboard`, `cliphist`, `tesseract`, `tesseract-data-eng`, `hyprpicker`, `hyprsunset` | Clipboard manager, screen OCR translation, night light gamma |
| **Hardware & Sensors** | `brightnessctl`, `ddcutil`, `upower`, `acpi`, `nmcli`, `bluetoothctl` | Backlight brightness, battery telemetry, Wi-Fi & Bluetooth |
| **Python Ecosystem** | `python-tqdm`, `faster-whisper`, `google-generativeai` | Synchronized lyrics streaming, offline transcription, Gemini AI |

---

## 📂 Directory Anatomy

```text
ballade/
├── assets/                  # High-res icons, bundled sound effects (USB, power), and screenshots
├── hyprland-custom/         # Custom Hyprland overrides (blur rules, opacities, keybinds, compact window)
├── modules/
│   ├── common/              # Shared components (MaterialShape, StyledSlider, SelectionDialog, Config)
│   ├── ii/                  # Illogical Impulse UI panels (bar, sidebars, overview, settings, wallpapers)
│   └── waffle/              # Alternative panel components
├── panelFamilies/           # Panel family definitions (IllogicalImpulseFamily.qml)
├── scripts/
│   ├── colors/              # switchwall.sh, applycolor.sh, generate_colors_material.py
│   ├── theming/             # apply-theme-preset.sh and handcrafted kitty-themes/
│   ├── kvantum/             # Material Kvantum / Qt widget theme generators
│   ├── lyrics/              # Real-time multi-language synchronized lyrics engine
│   └── play-usb-audio.sh    # Low-latency USB hardware event player
├── services/                # Reactive singletons (Audio.qml, MprisController.qml, Wallpapers.qml)
├── translations/            # Localization dictionary files (en_US, zh_CN, etc.)
├── GlobalStates.qml         # Central state manager for modal visibility
├── setup.sh                 # 1-Click environment initializer & permissions setup
└── shell.qml                # Root entrypoint
```

---

## 💖 Credits & Upstream

- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)**: The original **Illogical Impulse (`ii`)** — base architecture, frosted glass styling, and top bar design.
- **[pctrade/end4-pC](https://github.com/pctrade/end4-pC)**: The custom fork that contributed the sidebar modules, AI chat, translator, and settings overlay.
- **[outfoxxed/quickshell](https://github.com/outfoxxed/quickshell)**: The QML desktop shell engine for Wayland.
- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor.


---

<div align="center">

Crafted with passion by **[Anshu (valse-de-anshu)](https://github.com/valse-de-anshu)**  
*Elevate your desktop experience.*

</div>
