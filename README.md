# 🎼 Ballade

A modular, high-performance [QuickShell](https://quickshell.outfoxxed.me/) desktop shell suite for [Hyprland](https://hyprland.org/).

`ballade` is a custom **hybrid rice** crafted by merging the design strengths of two major configurations, enriched with unique personal tweaks and overhauls:

1. **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** (The original, official **Illogical Impulse / `ii`** by `end-4`):
   - Foundation for the iconic **Frosted-Glass Blur aesthetic**, window opacity balance, clean bar geometry, and desktop architecture.
2. **[pctrade/end4-pC](https://github.com/pctrade/end4-pC)** (A feature-rich custom fork of Illogical Impulse by `pctrade`):
   - Provided the expanded modular ecosystem: AI conversational assistant, multi-engine translator, animated audio waveform visualizer, comprehensive sidebars, and desktop settings overlay.
3. **Personal Innovations & Custom Ballade Tweaks**:
   - **3D Panoramic Cover-Flow Wallpaper Picker (`HyprPickerContent.qml`)**: Overhauled to display all wallpapers in the active folder simultaneously across the entire screen without horizontal pagination clipping.
   - **Modern Music Slider Design (`StyledSlider.qml`)**: Redesigned wavy progress track with thicker stroke and an interactive circular knob handle head across all media widgets.
   - **Sidebar Master Volume Feedback**: Direct PipeWire volume control with instant On-Screen Display (OSD) HUD triggers from the left sidebar buttons.
   - **Harmonized Multi-App Theme Presets**: Handcrafted, cohesive 16-color palettes (Crimson Red, Sakura Pink, Amethyst Purple, Forest Green, Tokyo Night, Nord) synchronized across QuickShell, Kitty (`current-theme.conf`), Konsole (`Quickshell.colorscheme`), GTK icons, and KDE Plasma.
   - **Multi-Language Synchronized Lyrics (`scripts/lyrics/`)**: Fast lyrics streaming supporting English, Hindi, and YouTube timed subtitles.
   - **Standalone Portability Engine**: Converted all scripts to dynamically self-resolve their root paths, eliminating hardcoded user paths for seamless drop-in multi-device deployment.

---

## ⚡ Quick Navigation

- 🚀 [Quick Start (How to Install & Run)](#-quick-start-how-to-install--run)
- 📦 [Dependencies](#-dependencies)
- ⌨️ [Common IPC Commands](#️-common-ipc-commands)
- 🌐 [External Tools & Daemons Used](#-external-dependencies-daemons--tools-used)
- 💎 [Complete Feature Matrix](#-complete-feature-matrix-of-ballade)
- 🏗️ [Architecture & Component Breakdown](#️-architecture--component-breakdown)
- 🎨 [Dynamic Theming & Presets](#-dynamic-theming--color-engine)
- ⚙️ [Configuration & Customization](#️-configuration--customization)
- 📂 [Directory Structure](#-directory-structure)
- 💡 [Troubleshooting & Tips](#-troubleshooting--tips)
- 💖 [Credits & Acknowledgements](#-credits--acknowledgements)

---

## 🚀 Quick Start: How to Install & Run

Follow these simple steps to get Ballade running on your system:

### Step 1: Install Required Packages
On Arch Linux / CachyOS, install the necessary runtime dependencies:
```bash
sudo pacman -S --needed quickshell hyprland qt6-declarative qt6-5compat qt6-svg qt6-wayland \
    pipewire wireplumber playerctl canberra-gtk-play mpv jq wl-clipboard cliphist \
    tesseract tesseract-data-eng hyprpicker hyprsunset kitty
```

### Step 2: Place Ballade in QuickShell Config Directory
Clone or copy the `ballade` folder directly into your QuickShell configurations folder:
```bash
# Target path: ~/.config/quickshell/ballade
git clone https://github.com/valse-de-anshu/ballade.git ~/.config/quickshell/ballade
```

### Step 3: Run 1-Click Environment Initializer (Optional)
Ballade includes an automated setup script that creates wallpaper folders, sound hooks, and permissions:
```bash
cd ~/.config/quickshell/ballade
./setup.sh
```

### Step 4: Run Ballade
To test and launch Ballade immediately from your terminal:
```bash
qs -c ballade
```

### Step 5: Set as Default Shell in Hyprland (Auto-Start)
To make Ballade start automatically every time you log into Hyprland:

- **If using dots-hyprland (`~/.config/hypr/custom/env.lua`):**
  Add the following line to your custom environment config:
  ```lua
  hl.env("qsConfig", "ballade")
  ```

- **Or directly in `~/.config/hypr/hyprland.conf`:**
  ```ini
  exec-once = qs -c ballade
  ```

### Step 6: Dual Coexistence (Switching between `ballade` and `ii`)
`ballade` does not overwrite standard `ii`. You can switch anytime:
- **Run Ballade:** `qs -c ballade`
- **Run Standard ii:** `qs -c ii`
- Both setups read and write to `~/.config/illogical-impulse/config.json` seamlessly.

---

## 🛠️ Automated Initialization vs Manual Steps

To make migration to any new PC completely painless, Ballade handles directory creation automatically, but here is what is automated vs what you can customize manually:

### ✅ What Ballade Creates Automatically:
When you launch Ballade (or run `./setup.sh`), it automatically creates:
- `~/Pictures/Wallpapers/` and all 6 preset subdirectories (`green`, `purple`, `pink`, `red`, `blue`, `grayscale`).
- Starter fallback wallpapers in empty preset folders so the wallpaper selector is never blank.
- `~/.config/illogical-impulse/` and `~/.config/illogical-impulse/presets/` for persistent settings.
- `~/.local/share/konsole/` and `~/.config/kitty/` for terminal theme synchronization.
- `~/.cache/illogical-impulse/` and `/tmp/quickshell/` for cover art, favicons, and OCR temporary buffers.

### 📝 What You Must Do Manually:
1. **Drop in Your Wallpapers**:
   - Add your favorite wallpapers into `~/Pictures/Wallpapers/<preset>/` matching each color theme (e.g., place anime/pink wallpapers in `~/Pictures/Wallpapers/pink`, nature wallpapers in `~/Pictures/Wallpapers/green`, neon wallpapers in `~/Pictures/Wallpapers/purple`).
2. **Configure Weather Location**:
   - Open Settings (**`SUPER + Escape`**) ➔ **Services** ➔ enter your city name (e.g., `London`, `Tokyo`, `New York`) for live `wttr.in` forecast telemetry.
3. **Set Gemini AI API Key (Optional)**:
   - If using Google Gemini in the Left Sidebar AI Chat, generate a free API key from [Google AI Studio](https://aistudio.google.com/) and paste it into **Settings** ➔ **Services** ➔ **Gemini API Key**.
4. **USB Hardware Sound Detection (Optional)**:
   - If you want physical USB plug/unplug audio chimes, copy the udev rule with sudo:
     ```bash
     sudo cp ~/.config/quickshell/ballade/scripts/system/99-usb-audio.rules /etc/udev/rules.d/
     sudo udevadm control --reload-rules && sudo udevadm trigger
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

![Panoramic 3D Wallpaper Selector](assets/screenshots/wallpaper-picker.png)

### 5. Desktop & Home Screen Widgets (`modules/ii/background/`)
- **Desktop Music Player Widget**: Floating desktop widget with frosted glass blur, album artwork, track info, and a wavy progress bar.
- **Digital & Analog Clock Widgets**: Multiple clock widget styles including Cookie Clock and Pixel Clock.
- **Live Weather & World Dot-Map Widget**: Displays temperature, city name, weather icons, and projects the user's geographic coordinates with a target ring onto a world dot-map.
- **Sticky Notes & To-Do Widgets**: Interactive desktop note pads that automatically persist tasks and text to local storage.
- **Custom Profile & Image Cards**: Customizable pinned photos and system profile banners.

![Desktop Home Screen & Widgets (Forest Green Theme)](assets/screenshots/home-green.png)
![Left Sidebar Music & Lyrics with Desktop Widgets](assets/screenshots/widgets-lyrics.png)

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

## 🎨 Dynamic Theming & Presets Showcase

Ballade features a dual-engine theming system: **Material Design 3 dynamic color generation** from any wallpaper, and **6 handcrafted presets** with multi-app synchronization across QuickShell, terminals, and desktop managers:

| Theme Preset | Color Highlight | Accent Palette | Aesthetic |
| :--- | :--- | :--- | :--- |
| **`green`** | `#4CAF50` (Forest Green) | Sage, Olive, Dark Pine | Atelier Estuary calm nature vibe |
| **`purple`** | `#9C27B0` (Amethyst) | Lavender, Deep Violet, Indigo | Cyberpunk night with neon accents |
| **`pink`** | `#E05688` (Sakura Pink) | Pastel Orchid, Rose, Ruby | Vibrant anime aesthetic |
| **`red`** | `#D32F2F` (Crimson Scarlet) | Salmon Rose, Peach, Bright Red | High-intensity scarlet with pure error red |
| **`blue`** | `#2196F3` (Tokyo Night) | Cyan, Midnight Navy, Sky Blue | Deep ocean nocturnal theme |
| **`grayscale`** | `#78909C` (Nord Slate) | Charcoal, Ash, Frost White | Distraction-free monochrome |

### 📸 Visual Gallery

#### 🌲 1. Forest Green Preset — Desktop Home Screen & Widgets
> *Featuring live weather telemetry, multi-timezone analog clocks, sticky notes, and frosted glass desktop music player.*
![Desktop Home Screen & Widgets (Forest Green Theme)](assets/screenshots/home-green.png)

#### 🌌 2. 3D Panoramic Cover-Flow Wallpaper Picker
> *Displays every wallpaper in the active folder simultaneously across the entire screen with fluid center scaling on hover.*
![Panoramic 3D Wallpaper Selector](assets/screenshots/wallpaper-picker.png)

#### 🔮 3. Amethyst Purple Theme Preset
> *Demonstrating Material You dynamic color adaptation across clock widgets, calendar, and music progress bars.*
![Amethyst Purple Theme Preset](assets/screenshots/theme-purple.png)

#### 🌸 4. Sakura Pink Theme Preset & Anime Explorer
> *Left Sidebar Booru image search and Right Sidebar Control Center with QuickSliders.*
![Sakura Pink Theme Preset & Anime Explorer](assets/screenshots/theme-pink.png)

#### 🎵 5. Music Controller & Synchronized Lyrics Engine
> *Real-time English, Hindi, and YouTube synced lyrics streaming alongside the wavy progress slider.*
![Left Sidebar Music & Lyrics with Desktop Widgets](assets/screenshots/widgets-lyrics.png)

#### ⚙️ 6. Master Settings Overlay — Themes & Presets Manager (`SUPER + Escape`)
> *One-click switching and live saving between color presets, corner shapes, and blur profiles.*
![Master Settings Overlay - Themes & Presets Manager](assets/screenshots/settings-presets.png)

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

---

## 💖 Credits & Acknowledgements

Ballade is built upon the incredible work of the Hyprland and QuickShell communities:

- **[end-4](https://github.com/end-4)**: Creator of **[dots-hyprland (Illogical Impulse)](https://github.com/end-4/dots-hyprland)** — the core foundation, aesthetic vision, and architectural base of this setup.
- **[pctrade](https://github.com/pctrade)**: Creator of **[end4-pC](https://github.com/pctrade/end4-pC)** — whose extensive modular expansions (AI integration, audio visualizer, sidebars, and settings overlay) inspired Ballade's feature set.
- **[Outfoxxed](https://github.com/outfoxxed)**: Creator of **[QuickShell](https://quickshell.outfoxxed.me/)** — the powerful, next-generation QML desktop shell engine for Wayland.
- **[Vaxry](https://github.com/vaxerski)** & the **[Hyprland Team](https://hyprland.org/)**: For creating the most fluid, feature-rich dynamic tiling compositor for Linux.

