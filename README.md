# 🎼 Ballade

A modular, high-performance [QuickShell](https://quickshell.outfoxxed.me/) desktop shell suite for [Hyprland](https://hyprland.org/), built upon the foundation of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (**Illogical Impulse / `ii`**).

`ballade` combines the signature frosted-glass aesthetic of `ii` with the expanded modular capabilities of `end4-pC` (feature-rich sidebars, AI translation, panoramic wallpaper selector, and desktop widgets).

---

## 🚀 Running Alongside `ii`

`ballade` lives standalone in `~/.config/quickshell/ballade/` and shares user preferences with `~/.config/illogical-impulse/config.json`.

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

Ensure these packages are installed on your system:

- **Shell & Compositor:** `quickshell`, `hyprland`, `qt6-declarative`, `qt6-5compat`, `qt6-svg`, `qt6-wayland`
- **Audio & Media:** `pipewire`, `wireplumber`, `playerctl`, `canberra-gtk-play`, `mpv`, `pw-play` (or `paplay`)
- **Theming & Presets:** `matugen`, `kitty`, `konsole`, `plasma-apply-colorscheme`, `tela-circle-icon-theme-git`
- **Utilities & OCR:** `jq`, `wl-clipboard`, `cliphist`, `tesseract`, `tesseract-data-*`, `hyprpicker`, `hyprsunset`

---

## ⌨️ Common IPC Commands

Trigger shell modules via Hyprland keybindings or terminal scripts using `qs -c ballade ipc call <target> <method>`:

```bash
qs -c ballade ipc call sidebarLeft toggle        # Left Sidebar (AI Assistant, Translator, Music Player)
qs -c ballade ipc call sidebarRight toggle       # Right Sidebar (Control Center, Audio/WiFi/Bluetooth)
qs -c ballade ipc call overview toggle           # App Launcher & Active Window Overview
qs -c ballade ipc call wallpaperSelector toggle  # 3D Panoramic Wallpaper Picker
qs -c ballade ipc call mediaControls toggle      # Music Player Track & Seek Popup
qs -c ballade ipc call sessionScreen toggle      # Lock / Logout / Reboot / Power Menu
qs -c ballade ipc call osdVolume trigger         # Volume On-Screen Display HUD
qs -c ballade ipc call cheatsheet toggle         # Hyprland Keybindings Cheatsheet
qs -c ballade ipc call cliphist toggle           # Wayland Clipboard History Manager
```

---

## 🏗️ Architecture & Component Breakdown

```mermaid
graph TD
    subgraph Compositor ["Hyprland Compositor (Wayland)"]
        HL_IPC["Hyprland Socket IPC"]
        HL_ENV["~/.config/hypr/custom/env.lua (qsConfig = ballade)"]
        HL_RULES["~/.config/hypr/custom/rules.lua (Opacity & Blur)"]
    end

    subgraph Shell ["QuickShell (ballade)"]
        ROOT["shell.qml"] --> ILLOGICAL["panelFamilies/IllogicalImpulseFamily.qml"]
        
        ILLOGICAL --> BAR["modules/ii/bar/ - Top Status Bar"]
        ILLOGICAL --> SIDE_L["modules/ii/sidebarLeft/ - Left Sidebar (AI, Translator, Music)"]
        ILLOGICAL --> SIDE_R["modules/ii/sidebarRight/ - Right Sidebar (Control Center)"]
        ILLOGICAL --> WALL_PICKER["modules/ii/wallpaperSelector/ - Panoramic Picker"]
        ILLOGICAL --> DESKTOP["modules/ii/background/ - Desktop Music & Clock Widgets"]
        ILLOGICAL --> OVERLAY["modules/ii/overview/ - Launcher & App Search"]
        ILLOGICAL --> OSD["modules/ii/onScreenDisplay/ - Volume & Brightness HUD"]
        ILLOGICAL --> SETTINGS["modules/ii/settings/ - Master Settings Overlay"]

        SETTINGS -->|Auto-Saves Options| CONFIG["modules/common/Config.qml"]
        CONFIG -->|JSON Adapter| JSON_STORE[("~/.config/illogical-impulse/config.json")]
    end

    subgraph Services ["Reactive Singletons (services/)"]
        AUDIO_SRV["Audio.qml (PipeWire Sound Server)"]
        MPRIS_SRV["MprisController.qml (Media Player Controller)"]
        WALL_SRV["Wallpapers.qml (Dynamic Wallpaper Scanner)"]
        GLOBAL_SRV["GlobalStates.qml (Visibility & Navigation State)"]
    end

    HL_IPC --> BAR
    AUDIO_SRV --> OSD
    AUDIO_SRV --> SIDE_L
    MPRIS_SRV --> BAR
    MPRIS_SRV --> DESKTOP
    WALL_SRV --> WALL_PICKER
```

### 1. Top Status Bar (`modules/ii/bar/`)
- **Workspaces & Windows:** Active workspace dots with smooth transition animations and current window title display.
- **Audio Visualizer & Media:** Real-time audio waveform visualizer. Left-clicking opens the track popup (`MediaControls.qml`); right-clicking toggles play/pause.
- **Hardware Metrics:** CPU, RAM, Swap, and CPU Temp indicators locked with tabular figures (`tnum`) to eliminate number jitter. Swap automatically appears whenever swap is in use (`> 0%`).
- **System Tray & Quick Status:** Network status, battery level, volume icons, updates counter, and live clock.

### 2. Left Sidebar (`modules/ii/sidebarLeft/`)
- **AI Assistant:** Direct conversational client supporting Google Gemini API, Ollama (local LLMs), and OpenAI models.
- **Translator & OCR:** Side-by-side source and translated textboxes with full copy/search actions, character counter, and compact language selector dialog (`SelectionDialog.qml`).
- **Music Player & Volume Controls:** Integrated track artwork, title, artist, seek bar, play/next/previous, and volume up/down/mute buttons connected to master PipeWire volume with instant OSD HUD feedback.
- **Booru Viewer:** Anime wallpaper and image board search tool.

### 3. Right Sidebar (`modules/ii/sidebarRight/`)
- **Control Center:** Quick-toggle tiles for WiFi, Bluetooth, Night Light (Gamma), Anti-Flashbang shader, Audio Sinks, and Pomodoro focus timer.
- **Master QuickSliders:** Touch/mouse-friendly sliders for System Volume, Microphone Gain, and Display Brightness.
- **Audio Device Switcher:** Expandable sink/source router allowing one-click output switching between headphones, speakers, and HDMI.
- **Notification History Center:** Dismissable notifications list with application icons, timestamps, and actionable buttons.

### 4. Panoramic Wallpaper Selector (`modules/ii/wallpaperSelector/`)
- **3D Cover-Flow View:** Displays every wallpaper from the active theme folder simultaneously across the entire screen in a smooth panoramic arc without horizontal pagination clipping.
- **Interactive Center Scale:** Wallpapers scale up fluidly on hover, with keyboard arrow navigation and single-click application.
- **Live Theme Adaptation:** Applying a wallpaper triggers `switchwall.sh`, extracting a Material You palette and instantly synchronizing the entire desktop environment.

### 5. Desktop & Home Widgets (`modules/ii/background/`)
- **Desktop Music Player Widget:** Floating desktop widget featuring album cover art, title/artist metadata, and a modern wavy progress bar with a circular handle.
- **Clock & Weather Widgets:** Customizable analog/digital clocks, location forecast telemetry from `wttr.in`, and dynamic world dot-map location projection.

---

## 🎨 Dynamic Theming & Color Engine

`ballade` features a two-tiered theming pipeline:

### 1. Wallpaper Palette Generation (`scripts/colors/`)
When a wallpaper is selected:
1. `switchwall.sh` processes the image using `matugen` (or Python `material-color-utilities`).
2. Extracts Primary, Secondary, Tertiary, Surface, and Container colors according to Material Design 3 guidelines.
3. Generates `material_colors.scss` and invokes `applycolor.sh`.
4. Updates QuickShell UI colors live, synchronizes the GTK/Kvantum theme, and writes the color scheme to Kitty terminal (`current-theme.conf`) and Konsole (`Quickshell.colorscheme`).

### 2. Handcrafted Theme Presets (`scripts/theming/`)
You can switch to handcrafted, cohesive color presets using `apply-theme-preset.sh <preset>`:
- **`green`**: Atelier Estuary Forest Dark (Green/Sage commands and paths).
- **`pink`**: Sakura Neon Pink (Deep Rose commands `#E05688`, Pastel Orchid parameters `#F48FB1`, and Crimson error `#FF1744`).
- **`red`**: Crimson Scarlet (Scarlet commands `#D32F2F`, Salmon Rose parameters `#FF8A80`, and Pure Error Red `#FF1744`).
- **`purple`**: Amethyst Cyberpunk (Rich Violet commands `#9C27B0` and Lavender parameters `#CE93D8`).
- **`blue`**: Tokyo Night / Deep Blue.
- **`grayscale`**: Nord Monochrome Slate.

---

## ⚙️ Configuration & Customization

All user configuration is stored in `~/.config/illogical-impulse/config.json`.

### Settings Overlay
Press **`SUPER + Escape`** (or run `qs -c ballade ipc call settings toggle`) to open the settings interface:
- **Bar Configuration:** Adjust bar height, vertical/horizontal mode, widget arrangement, and visibility.
- **Appearance & Shapes:** Select card corner geometry (`round`, `slanted`, `superellipse`, `cookie`) and adjust frosted glass blur.
- **Audio & Sound Events:** Configure volume levels and custom sound files for startup, USB plug/unplug, battery low, shutdown, and lock events.
- **AI & Services:** Set Gemini/OpenAI API keys, select default weather location, and configure network user-agents.

### Hyprland Blur & Opacity Overrides
To customize Hyprland's frosted glass blur or window transparency, edit:
- **`~/.config/hypr/custom/general.lua`**: Blur passes, radius, vibrancy, and shadows.
- **`~/.config/hypr/custom/rules.lua`**: Window opacity rules (`opacity = "0.93 0.88"`).
- **`~/.config/hypr/custom/env.lua`**: Environment variables and default QuickShell selection (`qsConfig`).

---

## 📂 Directory Structure

```text
ballade/
├── assets/                  # Icons, bundled audio effects (USB, power, battery), and SVGs
├── modules/
│   ├── common/              # Shared widgets (MaterialShape, StyledSlider, SelectionDialog, Config.qml)
│   ├── ii/                  # Illogical Impulse UI panels (bar, sidebars, overview, settings, wallpaperSelector)
│   └── waffle/              # Alternative panel components
├── panelFamilies/           # Panel family definitions (IllogicalImpulseFamily.qml)
├── scripts/
│   ├── colors/              # switchwall.sh, applycolor.sh, generate_colors_material.py
│   ├── theming/             # apply-theme-preset.sh and handcrafted kitty-themes/
│   ├── kvantum/             # Material Kvantum / Qt widget theme generators
│   ├── lyrics/              # Live synchronized lyrics fetcher (English, Hindi, YouTube)
│   └── play-usb-audio.sh    # Low-latency USB sound event trigger
├── services/                # Reactive singletons (Audio.qml, MprisController.qml, Wallpapers.qml, DateTime.qml)
├── translations/            # Localization dictionary files (en_US, zh_CN, etc.)
├── GlobalStates.qml         # Central state manager for modal visibility and navigation
├── ReloadPopup.qml          # Live hot-reload indicator
└── shell.qml                # Shell root entrypoint
```

---

## 💡 Troubleshooting & Tips

- **Live Reload QuickShell:** Press **`Ctrl + Shift + R`** while focusing the bar, or run:
  ```bash
  kill -SIGUSR1 $(pidof quickshell)
  ```
- **Inspect Logs:** Run `qs log` or view `/run/user/1000/quickshell/by-id/*/log.qslog`.
- **Audio Feedback Not Showing:** Ensure `wireplumber` is running and the volume buttons in the left sidebar or keybindings invoke `Audio.incrementVolume()` / `Audio.decrementVolume()`.
- **Multi-Device Portability:** The entire `ballade` folder is self-resolving and contains zero hardcoded user paths. It can be cloned or pasted directly onto any Arch/Hyprland system running `quickshell`.
