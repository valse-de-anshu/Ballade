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

## 🌐 External Dependencies, Daemons & Tools Used

Ballade interacts with the following system backends, daemons, D-Bus interfaces, and CLI tools:

### 1. Compositor & Display Protocol
- **`hyprland`**: Manages window tiling, workspace states, animations, blur shaders, and window opacity rules via socket IPC (`HyprlandCore` / `HyprlandData.qml`).
- **`hyprsunset`**: Background blue-light filter daemon controlling screen color temperature/gamma via D-Bus (`Hyprsunset.qml`).
- **`hyprpicker`**: Wayland color picker utility for desktop pixel sampling (`RegionSelection.qml`).
- **`ydotool`**: Virtual input generator for synthetic keypresses and automation (`Ydotool.qml`).

### 2. Audio & Media Subsystem
- **`pipewire` & `wireplumber`**: Core sound server and session manager for live volume scaling, device routing, and volume spike protection (`Audio.qml`).
- **`playerctl` & MPRIS (D-Bus)**: Native media player controller capturing track metadata, playback states, and album artwork from Spotify, browsers, MPD, etc. (`MprisController.qml`).
- **`pw-play` / `paplay` / `mpv` / `canberra-gtk-play`**: Low-latency multi-backend audio players for system sounds (USB, startup, shutdown, lock).
- **`easyeffects`**: PipeWire DSP audio effects manager for equalizer and noise suppression presets (`EasyEffects.qml`).
- **`songrec`**: Open-source Shazam client for recognizing music playing from any desktop audio stream (`SongRec.qml`).

### 3. Dynamic Theming & Color Engine
- **`matugen` / Python `material-color-utilities`**: Extracts Material Design 3 palettes (Primary, Secondary, Tertiary, Surface, Container tones) directly from wallpaper images.
- **`plasma-apply-colorscheme` & `kdeglobals`**: Synchronizes KDE Plasma apps (Dolphin, Kate, Gwenview) with the active wallpaper/preset.
- **`kitty` (`current-theme.conf`)**: Automatically live-reloaded via `SIGUSR1` to apply matching 16-color ANSI palettes.
- **`konsole` (`Quickshell.colorscheme`)**: Dynamically writes matching RGB color schemes for Konsole and Dolphin's embedded terminal.
- **`kvantum` (`adwsvg.py` / `adwsvgDark.py`)**: Regenerates Kvantum theme SVGs for Qt application styling.
- **`gsettings`**: Synchronizes GTK 3/4 theme colors and `Tela-circle-*` icon themes.
- **`starship`**: Replaces `~/.config/starship.toml` presets to match the terminal theme.

### 4. AI Models, Cloud APIs & LaTeX
- **Google Gemini API (`@google/genai`)**: Cloud-powered conversational AI and translation inside the sidebar (`Ai.qml`).
- **Ollama (Local LLM Daemon)**: Connects to local models (e.g. `llama3`, `mistral`, `deepseek`) over `http://localhost:11434`.
- **OpenAI API**: ChatGPT endpoints for chat and text assistance.
- **LaTeX / MicroTeX (`latex-render.sh`)**: Compiles and renders math formulas directly within AI responses.

### 5. OCR & Real-Time Screen Translation
- **`tesseract` & `tesseract-data-*`**: OCR engine extracting text from selected screen regions (`ScreenTranslator.qml`).
- **Google Translate / DeepL Engines**: Translates extracted OCR text and sidebar translator input.

### 6. System Utilities & Daemons
- **`jq`**: JSON processor used across shell scripts to read/write `~/.config/illogical-impulse/config.json`.
- **`cliphist` & `wl-clipboard`**: Manages clipboard history (`wl-copy`, `wl-paste`) with image/text thumbnail preview (`Cliphist.qml`).
- **`nmcli` (NetworkManager)**: Scans Wi-Fi SSIDs, checks signal strength, and handles connections (`Network.qml`).
- **`bluetoothctl` (BlueZ)**: Handles Bluetooth device pairing, connecting, disconnecting, and battery reporting (`BluetoothStatus.qml`).
- **`brightnessctl` / `ddcutil`**: Hardware backlight control for laptop screens and external DDC/CI monitors (`Brightness.qml`).
- **`upower` & `/sys/class/power_supply`**: Reads battery level, charging status, and low-battery alerts (`Battery.qml`).
- **`wttr.in`**: Weather telemetry provider returning temperatures, humidity, weather icons, and city coordinates (`Weather.qml`).
- **`checkupdates` / `pacman`**: Tracks pending Arch Linux system upgrades (`Updates.qml`).
- **`systemd` (User Services)**: Manages audio daemons (`power-audio-executor.sh` and `usb-audio@.service`).

---

## 💎 Complete Feature Matrix of Ballade

### 1. Top Status Bar (`modules/ii/bar/`)
- **Workspace Indicator**: Dynamic morphing dot indicators tracking active, occupied, and empty workspaces across multi-monitor setups.
- **Active Window Title**: Displays current focused window title and application class name.
- **Audio Waveform Visualizer**: Animated sound visualizer synced with playing audio. Left-click opens track controls popup; right-click toggles play/pause.
- **Hardware Resource Monitors**: Live CPU %, RAM %, Swap %, and CPU Temperature meters formatted with tabular figures (`tnum`) to eliminate number jitter. Swap automatically reveals itself when swap memory is actively in use (`> 0%`).
- **System Tray**: Wayland status notifier tray with application icons, context menus, and tooltips.
- **Status Icons**: Real-time indicators for Wi-Fi SSID/Ethernet, Bluetooth, Battery percentage with charging states, and Volume level.
- **Updates Counter**: Pending system update counter with a 1-click terminal launcher.
- **Clock & Date**: Formatted time/date with click-to-open calendar popup and world timezone clock.
- **Vertical Bar Mode (`modules/ii/verticalBar/`)**: Full alternative side-docked bar orientation.

### 2. Left Sidebar (`modules/ii/sidebarLeft/`)
- **Conversational AI Assistant**: Chat interface supporting Google Gemini, Ollama local LLMs, and OpenAI ChatGPT with Markdown rendering, code highlighting, and chat history.
- **Full-Featured Translator**: Side-by-side source and translated text panels with auto-detection, character counter, copy/search buttons, and a compact modal language selector (`SelectionDialog.qml`) with pinned languages.
- **Real-Time Synchronized Lyrics (`scripts/lyrics/`)**: Live music lyrics engine supporting English, Hindi, and YouTube synced captions.
- **Sidebar Music Controller**: Album art preview, metadata, seekable wavy slider with a circular knob handle, play/next/previous, and master volume buttons that trigger instant OSD HUD visual feedback.
- **Booru Wallpaper Explorer**: Search and browse anime/art wallpapers directly from image boards with a 1-click "Set as Wallpaper" action.

### 3. Right Sidebar / Control Center (`modules/ii/sidebarRight/`)
- **Quick-Toggle Tiles**: 1-click toggles for Wi-Fi, Bluetooth, Night Light Gamma, Anti-Flashbang Shader, Audio Sink Router, and Pomodoro Timer.
- **Master QuickSliders**: Smooth touch- and mouse-friendly sliders for System Output Volume, Microphone Input Gain, and Display Brightness.
- **Audio Sink/Source Selector**: Expandable audio router to switch playback between Headphones, Speakers, Bluetooth, and HDMI outputs on the fly.
- **Network & Bluetooth Dialogs**: Wi-Fi connection manager with password prompt and Bluetooth device pairing/connecting manager.
- **Pomodoro Focus Timer**: Customizable work/break focus timer with notification audio cues.
- **Notification History Center**: Grouped notification cards with action buttons and clear-all functionality.

### 4. Panoramic Wallpaper Selector (`modules/ii/wallpaperSelector/`)
- **Panoramic 3D Cover-Flow View**: Displays all wallpapers in the active folder simultaneously across the entire screen without horizontal scrolling.
- **Center Scale on Hover**: Smooth zoom and border highlight on hovered wallpapers.
- **Dynamic Material Adaptation**: Selecting a wallpaper instantly triggers `switchwall.sh` to extract a new Material You color palette and re-theme the entire desktop environment.

### 5. Desktop & Home Screen Widgets (`modules/ii/background/`)
- **Desktop Music Player Widget**: Floating desktop widget with frosted glass blur, album artwork, track info, and a wavy progress bar.
- **Digital & Analog Clock Widgets**: Multiple clock widget styles including Cookie Clock and Pixel Clock.
- **Live Weather & World Dot-Map Widget**: Displays temperature, city name, weather icons, and projects the user's geographic coordinates with a target ring onto a world dot-map.
- **Sticky Notes & To-Do Widgets**: Interactive desktop note pads that automatically persist tasks and text to local storage.
- **Custom Profile & Image Cards**: Customizable pinned photos and system profile banners.

### 6. Overlays, Hubs & Popups
- **App Launcher / Overview (`modules/ii/overview/`)**: Full-screen fuzzy app search, math calculator, command execution, and window switcher.
- **Session & Power Screen (`modules/ii/sessionScreen/`)**: Fullscreen power menu with Lock, Logout, Suspend, Hibernate, Reboot, and Shutdown triggers.
- **Screen Region Translator (`modules/ii/screenTranslator/`)**: Snip any region on your screen to perform real-time OCR text extraction and translation.
- **On-Screen Display HUD (`modules/ii/onScreenDisplay/`)**: Non-intrusive overlays for Volume percentage, Brightness level, and Night Light Gamma.
- **Virtual On-Screen Keyboard (`modules/ii/onScreenKeyboard/`)**: Touch-friendly virtual keyboard for 2-in-1s and tablets.
- **Hyprland Keybindings Cheatsheet (`modules/ii/cheatsheet/`)**: Searchable overlay listing all configured Hyprland shortcuts.
- **Lock Screen (`modules/common/panels/lock/`)**: Frosted glass lockscreen with PAM authentication, password input, media controls, and battery status.

### 7. Audio Events & System Sound Cues (`scripts/` & `assets/`)
- **Bundled Sound Library**: Built-in audio cues for Startup, Shutdown, Lock session, Logout, Sleep, Battery Low, and USB connect/disconnect.
- **Volume Steppers & Previews**: Dedicated volume sliders and test-audio preview buttons in the settings UI.
- **Low-Latency Player Fallback**: Automatic fallback pipeline (`pw-play` ➔ `paplay` ➔ `mpv` ➔ `canberra-gtk-play`).

### 8. Handcrafted Theme Presets (`scripts/theming/`)
- **6 Handcrafted Presets**:
  - **`green`**: Atelier Estuary Forest Dark (Green/Sage commands and paths).
  - **`pink`**: Sakura Neon Pink (Deep Rose commands `#E05688`, Pastel Orchid parameters `#F48FB1`, and Crimson error `#FF1744`).
  - **`red`**: Crimson Scarlet (Scarlet commands `#D32F2F`, Salmon Rose parameters `#FF8A80`, and Pure Error Red `#FF1744`).
  - **`purple`**: Amethyst Cyberpunk (Rich Violet commands `#9C27B0` and Lavender parameters `#CE93D8`).
  - **`blue`**: Tokyo Night / Deep Blue.
  - **`grayscale`**: Nord Monochrome Slate.
- **Unified Multi-App Sync**: Synchronizes QuickShell, Kitty (`current-theme.conf`), Konsole (`Quickshell.colorscheme`), KDE Plasma (`kdeglobals`), GTK icons, and Starship prompt in one go.

### 9. Master Settings Overlay (`SUPER + Escape` / `modules/ii/settings/`)
- **8 Comprehensive Configuration Pages**: Quick Config, Bar Configuration, Interface & Corner Shapes (`round`, `slanted`, `superellipse`, `cookie`), Desktop Widgets, Profile Info, Hyprland Rules, Services & Audio Steppers, and General Options.
- **Auto-Saving**: All changes write directly to `~/.config/illogical-impulse/config.json`.

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

## 📁 Portability

All scripts use self-resolving dynamic paths. You can copy the entire `ballade` folder directly to `~/.config/quickshell/ballade` on any device and launch immediately.

---

## 💡 Troubleshooting & Tips

- **Live Reload QuickShell:** Press **`Ctrl + Shift + R`** while focusing the bar, or run:
  ```bash
  kill -SIGUSR1 $(pidof quickshell)
  ```
- **Inspect Logs:** Run `qs log` or view `/run/user/1000/quickshell/by-id/*/log.qslog`.
- **Audio Feedback Not Showing:** Ensure `wireplumber` is running and the volume buttons in the left sidebar or keybindings invoke `Audio.incrementVolume()` / `Audio.decrementVolume()`.
