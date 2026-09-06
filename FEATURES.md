<div align="center">

# 🌟 Ballade Desktop Shell — Technical Architecture & Feature Specification

[![Back to Main README](https://img.shields.io/badge/⬅️_Back_to-Main_README-blue?style=for-the-badge)](README.md)

<br/>

**Document Version:** 3.5  
**Target Environment:** Linux / Wayland (Hyprland & Niri)  
**Core Framework:** Quickshell (Qt 6.9+ / QML), Wayland Layer Shell Protocol  
**Theming Engine:** Material Design 3 (M3) with Matugen Color Generation  
**Base Layer:** `illogical-impulse` (`dots-hyprland`)

</div>

---

## 🧭 Table of Contents
1. [Core Architecture & Entry Point](#core-architecture--entry-point)
2. [Panel Families (Desktop Paradigms)](#panel-families-desktop-paradigms)
3. [Desktop Background Widgets & Context Menu](#desktop-background-widgets--context-menu)
4. [Left Sidebar: Media, AI & Intelligence](#left-sidebar-media-ai--intelligence)
5. [Right Sidebar: Control Center & Productivity](#right-sidebar-control-center--productivity)
6. [Wallpaper Engine, Shaders & Material You Theming](#wallpaper-engine-shaders--material-you-theming)
7. [Screen Snip, Annotation & Custom Region Selector](#screen-snip-annotation--custom-region-selector)
8. [Ballade Script Suite & Deployed Machine Utilities](#ballade-script-suite--deployed-machine-utilities)
9. [Overlays, Gaming & Productivity Tools](#overlays-gaming--productivity-tools)
10. [Productivity Hub: Focus Journal & Screen Time Daemon](#productivity-hub-focus-journal--screen-time-daemon)
11. [Lock Screen, Session & Audio Engine](#lock-screen-session--audio-engine)
12. [Backend Services Reference (QML)](#backend-services-reference-qml)
13. [Architecture Evolution & Cleaned Legacy Artifacts](#architecture-evolution--cleaned-legacy-artifacts)
14. [Bundled Dotfiles & App Configurations](#bundled-dotfiles--app-configurations)
15. [Internationalization (i18n)](#internationalization-i18n)
16. [Configuration & Customization Files](#configuration--customization-files)

---

<a id="core-architecture--entry-point"></a>
## 1. Core Architecture & Entry Point

Ballade operates as an asynchronous, event-driven desktop environment shell. All windows, bars, sidebars, desktop widgets, and overlays are rendered as hardware-accelerated Wayland Layer Shell surfaces.

### 1.1 Root Coordination Files
* **`shell.qml`**: Root entry point. Initializes global focus grabbers, registers compositor event listeners, monitors monitor hotplugging, and dynamically instantiates the active panel family.
* **`GlobalStates.qml`**: Global singleton managing modal visibility, overlay active states, drawer animations, desktop popup positioning, and inter-widget communication.
* **`modules/common/Config.qml`**: Schema validator and live JSON watcher synchronized with `~/.config/illogical-impulse/config.json`.
* **`modules/common/Appearance.qml`**: Centralized design token repository defining typography, corner radiuses (`round`, `slanted`, `superellipse`, `cookie`), padding metrics, and color mappings.

---

<a id="panel-families-desktop-paradigms"></a>
## 2. Panel Families (Desktop Paradigms)

Ballade supports two fully modular layout families switchable via configuration:

### 2.1 Illogical Impulse Family (`panelFamilies/IllogicalImpulseFamily.qml`)
* **Top Status Bar (`modules/ii/bar/`)**: Floating status bar housing workspaces, media controls, hardware telemetry, weather, and system tray.
* **Dynamic Magnification Dock (`modules/ii/dock/`)**: macOS-inspired magnification dock with pinned favorites, active task indicators, and multi-window grouping.
* **Vertical Bar (`modules/ii/verticalBar/`)**: Minimalist vertical edge bar for fast workspace navigation and system load visualization.
* **Left & Right Drawers (`modules/ii/sidebarLeft/`, `modules/ii/sidebarRight/`)**: Layered flyout control centers with gesture support.
* **Dropover Shelf (`modules/ii/dropover/`)**: Temporary drag-and-drop file staging area with live counter badges.

### 2.2 Waffle Family (`panelFamilies/WaffleFamily.qml`)
* **Taskbar (`modules/waffle/bar/`)**: Pinned bottom taskbar with grouped application icons and status indicators.
* **Start Menu (`modules/waffle/startMenu/`)**: Windows 11-style centered launcher featuring a categorized pinned application grid, search indexing, and recent files.
* **Action Center (`modules/waffle/actionCenter/`)**: Unified flyout containing quick toggles, slider controls, battery status, and notifications.
* **Task View (`modules/waffle/taskView/`)**: Virtual desktop switcher and active client tile viewer.

---

<a id="desktop-background-widgets--context-menu"></a>
## 3. Desktop Background Widgets & Context Menu

Ballade features an interactive desktop layer (`modules/ii/background/Background.qml`) hosting a suite of 11 modular desktop widgets and a modern right-click context menu.

### 3.1 Desktop Context Menu (`modules/ii/desktopMenu/DesktopMenu.qml`)
Right-clicking anywhere on the desktop wallpaper or on background widgets opens the Ballade Desktop Menu:
* **Quick Wallpaper Carousel**: Interactive horizontal preview carousel displaying recent and random wallpapers from the active collection for instant switching.
* **Wallpaper & Style Submenu (`WallpaperSubmenu.qml`)**:
  * **9 Material Design 3 Palette Schemes**: `Auto`, `Content`, `Expressive`, `Fidelity`, `Fruit Salad`, `Monochrome`, `Neutral`, `Rainbow`, and `Tonal Spot`.
  * **Desktop Blur Toggle**: Instant one-click toggle for Ballade's hardware fast blur (`Config.options.background.showBlur`).
  * **Centered Wallpaper Geometries**: Toggle centered backdrop display, lock-screen-only mode, custom geometric shapes (`Circle`, `Square`, `Cookie12Sided`, `Clover4Leaf`, `Pill`, `Heart`), color tokens, and size scaling.
  * **10 GPU Transition Shaders**: Direct picker for transition animations (`None`, `Magic`, `Dissolve`, `Shatter`, `Ripple`, `Glitch`, `CRT`, `Doom`, `Stripes`, `Random`).
* **Widgets Submenu (`WidgetsSubmenu.qml`)**:
  * **Lock Widget Positions**: Master lock toggle preventing accidental drag-and-drop repositioning (`widgetsLocked`).
  * **11 Independent Desktop Widget Toggles**: Granular visibility switches for all active desktop components.
* **Wallpaper Selector Launcher**: Direct trigger for Ballade's native 3D panoramic wallpaper carousel (`GlobalStates.wallpaperSelectorOpen = true`).
* **DropShelf Launcher**: Opens the floating file staging shelf at the exact cursor coordinates with dynamic staged-item counter badge.
* **Live Wallpaper Launcher**: Dedicated picker for looping video wallpapers via fallback file dialog.
* **Settings Hub**: Instant shortcut to Ballade's full graphical settings center (`GlobalStates.settingsOpen = true`).

### 3.2 The 11 Desktop Background Widgets (`modules/ii/background/widgets/`)
All widgets support free dragging across monitors with coordinate persistence in `config.json`:
1. **Clock Widget (`clock/ClockWidget.qml`)**: Analog cookie clock with configurable sides, custom hands (fill, thin, medium, bold), numeral indicators, sine cookie waves, or modern Google Sans Flex digital typography.
2. **Goals & Notes Widget (`goals/GoalsWidget.qml`)**: Signature multi-horizon goal planner tracking Daily, Weekly, Monthly, Yearly, and Life goals, milestone checklist, wellbeing tracker, and integrated markdown scratchpad tool.
3. **Calendar Widget (`calendar/CalendarWidget.qml`)**: 2x2 grid calendar displaying active month dates, day headers, and Indian holiday / national festival highlights.
4. **Weather Widget (`weather/WeatherWidget.qml`)**: Live weather telemetry with meteorological icon, condition description, high/low temperature curves, and precipitation probability.
5. **Media Widget (`media/MediaWidget.qml`)**: MPRIS media controller featuring live album artwork, track title/artist typography, playback controls, and synchronized lyrics overlay.
6. **Visualizer Widget (`visualizer/VisualizerWidget.qml`)**: Real-time audio spectrum analyzer with dual rendering modes (rendered above wallpaper when blur is off, or positioned behind frosted blur when blur is on).
7. **Resources Widget (`resources/ResourcesWidget.qml`)**: Hardware telemetry monitor with live CPU percentage, RAM consumption, and disk utilization meters.
8. **World Clock Widget (`worldclock/WorldClockWidget.qml`)**: Multi-timezone clock displaying user-selected global cities and time differences.
9. **User Card Widget (`usercard/UserCardWidget.qml`)**: Profile card displaying user avatar, system username, time-aware greeting, and custom quote.
10. **Custom Image & Extra Images (`CustomImage.qml`, `ExtraCustomImage.qml`)**: Pinned desktop picture frames supporting geometric shape masking (`Cookie4Sided`, `Gem`, `Circle`) and infinite animation loops.
11. **Image Converter Widget (`images/ImageConverterWidget.qml`)**: On-desktop drag-and-drop image conversion tool allowing instant conversion between PNG, JPEG, WebP, and other formats.

---

<a id="left-sidebar-media-ai--intelligence"></a>
## 4. Left Sidebar: Media, AI & Intelligence

Located in `modules/ii/sidebarLeft/`:

### 4.1 AI Chat Assistant (`AiChat.qml`, `services/Ai.qml`)
* **Streaming Architecture**: Direct Server-Sent Events (SSE) streaming using Google Gemini API (`gemini-2.5-flash`, `gemini-1.5-pro`, `gemini-1.5-flash`) over secure HTTPS.
* **Local Fallback Worker**: `scripts/ai/ai_query.py` provides a resilient CLI bridge for token generation and proxying.
* **Rendering Engine**: Formatted markdown parser supporting syntax-highlighted code blocks, line numbering, token stream animations, and copy-to-clipboard actions.
* **Session Persistence**: Persistent local conversation history with custom system prompt templates.

### 4.2 Anime & Booru Gallery (`Anime.qml`, `services/Booru.qml`)
* **Multi-Provider Engine**:
  * **Wallhaven API**: Support for anime categories (`categories=010`), multi-page pagination, purity toggles (SFW, Sketchy, NSFW), and encrypted user API keys via `KeyringStorage`.
  * **Safebooru / Danbooru**: Filtered anime illustration discovery.
  * **Gelbooru**: High-resolution image scraping with tag filters.
  * **Waifu.im**: Tag-based anime image delivery with dynamic random batching.
  * **Alcy (`t.alcy.cc`)**: Random anime image endpoints with category fallbacks.
* **Infinite Scroll Pagination**: Continuous scroll trigger dynamically requesting subsequent batches without UI thread locks or delegate height voids.
* **Aspect-Preserved Display**: Full uncropped (`PreserveAspectFit`) rendering displaying the complete artwork across all aspect ratios.
* **Image Action Drawer**: Single-click image downloading with automatic NSFW directory routing (`~/Pictures/Wallpapers/Anime/NSFW/` vs `~/Pictures/Wallpapers/Anime/`).

### 4.3 Screen & Text Translator (`screenTranslator/`, `translator/`)
* **Wayland OCR Screen Capture**: Uses `slurp` and `tesseract` to extract on-screen text from user-selected regions and translates immediately into target languages.
* **Interactive Translator**: Side-by-side translation tool with auto-language detection, character counters, and clipboard synchronization.

### 4.4 Live Lyrics & YouTube Caption Streamer (`scripts/lyrics/lyrics.py`)
* **Timed Lyrics**: Fetches and synchronizes `.lrc` lyrics with active MPRIS media players (Spotify, MPD, browser audio).
* **YouTube Live Subtitles**: Real-time caption extractor streaming synchronized subtitles directly from active YouTube video playback via `yt-dlp`.

---

<a id="right-sidebar-control-center--productivity"></a>
## 5. Right Sidebar: Control Center & Productivity

Located in `modules/ii/sidebarRight/`:

### 5.1 Notification Center (`notifications/`, `services/Notifications.qml`)
* **Freedesktop D-Bus Server**: Implements `org.freedesktop.Notifications` with notification history, grouped app stacks, actionable buttons, inline reply inputs, and dismiss gestures.
* **Do Not Disturb (DND)**: Global notification silencer with badge counters.

### 5.2 Calendar & Indian Festival Dataset (`calendar/`)
* **Interactive Matrix**: Month and Year navigation with lunar phase calculations.
* **Comprehensive Holiday Dataset**: Pre-compiled database of national gazetted holidays, restricted observances, and moon-sighting indicators.

### 5.3 Quick Toggles (`quickToggles/`)
* **Wi-Fi Manager (`services/network/Network.qml`)**: NetworkManager D-Bus client with live AP scanning, signal quality meters, and password prompts.
* **Bluetooth Manager (`services/Bluetooth.qml`)**: BlueZ D-Bus integration for device discovery, pairing, connection states, and battery telemetry.
* **Night Light**: Gamma temperature transition manager via Hyprland shader IPC / Gammastep.
* **Performance Toggles**: Game Mode scheduler and anti-flashbang screen filter toggles.

### 5.4 Task Management & Focus Timer (`todo/`, `pomodoro/`)
* **Notes & To-Do**: Multi-category task lists with checklist items, markdown scratchpad, and local JSON storage.
* **Pomodoro Focus Engine**: Customizable work and break intervals with audio alarms and background tracking.

### 5.5 PipeWire Per-App Volume Mixer (`volumeMixer/`, `services/Audio.qml`)
* **Stream Routing**: Real-time per-application volume sliders, stream muting, and default sink/source switching via WirePlumber IPC.

---

<a id="wallpaper-engine-shaders--material-you-theming"></a>
## 6. Wallpaper Engine, Shaders & Material You Theming

Located in `scripts/colors/`, `scripts/theming/`, and `modules/ii/wallpaperSelector/`:

### 6.1 Matugen Color Extraction & Dynamic Synchronization
* Extracts dominant and harmonized Material You color palettes from any wallpaper image.
* **Dynamic App Synchronization**:
  * **Kitty & Konsole**: Updates terminal color schemes live without restarting shells.
  * **CAVA Audio Visualizer**: Live-generates matching gradient visualizer bars.
  * **rmpc (MPD)**: Themes music player controls and album view.
  * **Kvantum & GTK**: Synchronizes Qt SVG widgets and GTK theme colors.
  * **Discord & Joplin**: Injects matching translucent frosted themes.

### 6.2 3D Panoramic Wallpaper Carousel (`HyprPickerContent.qml`)
* **Panoramic Dock Carousel**: Smooth horizontal cover-flow picker featuring center-tile zoom scaling (`0.94`), edge tile shrinkage (`0.48`), and dynamic spacing.
* **Shape Masking**: Renders wallpaper previews inside geometric cutout shapes (`cyberpunk`, `cookie`, `slanted`, `superellipse`).
* **Dual Target Switching**: One-click selection for desktop wallpaper or lock-screen background (`lockWall`).
* **Full Keyboard Navigation**: Left/Right or H/L for navigation, Enter/Space to apply, Escape to dismiss.

### 6.3 Hardware Wallpaper FastBlur & Transition Shaders
* **Independent Hardware FastBlur**: Blurs the desktop wallpaper in pure QML shaders without compositor dependencies (`showBlur`).
* **Split Blur & Gradient Mask**: Configurable split amount (`25%`, `50%`, `100%`) with horizontal directional opacity gradient masks (`Left` vs `Right`).
* **10 Real-Time GPU Transition Shaders**:
  * `magic`: Fluid radial reveal transition.
  * `dissolve`: Smooth cross-fade dissolve shader (`dissolve.frag.qsb`).
  * `shatter`: Dynamic glass-fracture shattering transition (`shatter.frag.qsb`).
  * `ripple`: Expanding circular wave distortion.
  * `glitch`: Digital signal interference transition.
  * `crt`: Retro scanline distortion transition.
  * `Doom`: Classic melting curtain transition.
  * `stripes`: Linear horizontal curtain transition.
  * `pixelate`: Retro mosaic pixel down-sampling transition.
  * `Peel` / `circlePit` / `circleSelect`: Page peel and circular geometry shaders.
* **Live Video Wallpapers**: Smooth looping video wallpapers (MP4/WebM) via embedded MPV backend.

### 6.4 Wallpaper Directory Configuration & Theme Organization
Ballade seamlessly synchronizes wallpaper collections with active color themes. Wallpapers can be arranged into subfolders matching your theme preset names (e.g. `Catppuccin`, `blue`, `pink`, `purple`, etc.), allowing automatic theme filtering and instant switching from the Desktop Menu or Panoramic Carousel.

Configure both directory locations easily in **Settings (`SUPER + I`) -> Appearance / Background -> Wallpaper Folders**:
* **Image Wallpapers Folder**: Points to your static wallpapers root (default: `~/Pictures/Wallpapers`)
* **Live Wallpapers Folder**: Points to your video wallpapers root (default: `~/Pictures/Wallpapers/live Wallpapers`)

#### Recommended Wallpaper Directory Structure:
```text
~/Pictures/Wallpapers/
├── Catppuccin/             # Static wallpapers for Catppuccin theme preset (.png, .jpg, .webp)
├── blue/                   # Static wallpapers for Blue theme preset
├── golden/                 # Static wallpapers for Golden theme preset
├── grayscale/              # Static wallpapers for Grayscale theme preset
├── green/                  # Static wallpapers for Green theme preset
├── orange/                 # Static wallpapers for Orange theme preset
├── pink/                   # Static wallpapers for Pink theme preset
├── purple/                 # Static wallpapers for Purple theme preset
├── red/                    # Static wallpapers for Red theme preset
├── live Wallpapers/        # Animated/Video wallpapers root (.mp4, .webm, .mkv)
│   ├── Catppuccin/         # Looping live videos for Catppuccin theme
│   ├── blue/               # Looping live videos for Blue theme
│   ├── golden/             # Looping live videos for Golden theme
│   ├── grayscale/          # Looping live videos for Grayscale theme
│   ├── green/              # Looping live videos for Green theme
│   ├── orange/             # Looping live videos for Orange theme
│   ├── pink/               # Looping live videos for Pink theme
│   ├── purple/             # Looping live videos for Purple theme
│   └── red/                # Looping live videos for Red theme
├── nsfw/                   # Optional NSFW filtered collection
└── orginal/                # Unprocessed/original source wallpapers
```
> [!TIP]
> Each theme subfolder can contain multiple wallpapers. Ballade automatically builds preview thumbnails and matches the wallpaper color palette dynamically to your desktop interface and terminal colors via `matugen`.

---

<a id="screen-snip-annotation--custom-region-selector"></a>
## 7. Screen Snip, Annotation & Custom Region Selector

Located in `modules/ii/regionSelector/` and `scripts/images/snip-annotate.py`:

* **Dual Snip Keybindings**:
  * **`Win + Shift + S`**: Interactive region selector overlay offering instant actions for Screenshot Copy, Edit/Annotate, OCR Text Recognition, Visual Search, and Screen Recording.
  * **`Alt + S`**: Direct Region Snip-and-Annotate pipeline. Opens the custom crosshair selection guide, immediately captures the selected region, copies the result to the clipboard, and launches Gwenview in annotation mode with real-time file save monitoring.
* **Custom Cursor Target & UI Guide**:
  * Precision animated crosshair guide with live selection coordinate dimensions.
  * Specialized cursor assets (`assets/cursor/`) providing a clean, targeted snipping experience.
* **Smart Clipboard Synchronization (`copy-image-with-path.py`)**:
  * Wayland clipboard integration concurrently publishing both raw image pixel data (`image/png`) and the plain-text file URI (`text/plain`), ensuring seamless compatibility across Discord, Telegram, file managers, and terminal editors without duplicate clipboard entries.

---

<a id="ballade-script-suite--deployed-machine-utilities"></a>
## 8. Ballade Script Suite & Deployed Machine Utilities

Ballade includes a modular script collection inside [`scripts/`](scripts/) and deploys core helper utilities directly to the user's `~/.local/bin/` during initialization.

### 8.1 CLI Utilities Deployed to User System (`~/.local/bin/`)
When [`setup.sh`](setup.sh) runs, it installs and symlinks the following utilities into `~/.local/bin/`:

* **`power-audio-executor.sh`**: Master power and session orchestrator. Intercepts `poweroff`, `reboot`, `shutdown`, `suspend`, and `lock` commands to execute smooth audio feedback, volume normalization, and deduplication before forwarding actions to systemd.
* **`poweroff` / `reboot` / `shutdown`**: Symlinks pointing to `power-audio-executor.sh` allowing direct CLI power management without syntax errors under strict shell environments.
* **`systemctl-wrapper` / `loginctl-wrapper`**: Safe wrapper proxies intercepting system power calls to ensure audio feedback plays reliably without modifying host binary packages.
* **`snip-annotate.py`**: Automated screenshot capture, Gwenview annotation launcher, and file-watch clipboard sync daemon.
* **`fastfetch`**: Custom Fastfetch launcher that dynamically selects a random graphic from the `assets/` deck on every terminal launch.
* **`rmpc-run` / `rmpc-fetch-lyrics` / `rmpc-launch`**: Runner suite for the `rmpc` MPD client that establishes daemon connections, displays album covers, and extracts synchronized `.lrc` lyrics.
* **`clipboard-image-transformer.py`**: Wayland clipboard daemon watching for image copy events to optimize, format, and prepare image payloads for instant pasting into chats.
* **`copy-image-with-path.py`**: Multi-format clipboard utility that simultaneously copies both raw image pixel data (`image/png`) and the plain-text file path (`text/plain`).
* **`random-greeting.sh`**: Time-aware shell greeter that plays localized audio announcements and notifications on terminal startup.

### 8.2 Theming & Color Dispatchers (`scripts/colors/`, `scripts/theming/`)
* **`switchwall.sh`**: Master wallpaper switcher invoking `matugen` to extract Material Design 3 palettes, compute image brightness, generate color tokens, and broadcast theme updates.
* **`applycolor.sh`**: Central dispatcher that propagates generated Material You colors to Kitty, Konsole, Discord, CAVA, rmpc, Joplin, and Kvantum.
* **`apply-theme-preset.sh`**: Applies any of the 9 handcrafted color presets (`green`, `pink`, `red`, `purple`, `blue`, `golden`, `orange`, `grayscale`, `catppuccin`).
* **`apply-discord-theme.sh`**: Generates and links frosted glass CSS variables into Vencord / BetterDiscord.
* **`apply-cava-theme.sh`**: Computes an 8-step color gradient for CAVA based on dominant and secondary wallpaper hues.
* **`apply-rmpc-theme.sh`**: Generates themes for the `rmpc` MPD player.
* **`apply-micro-theme.sh`**: Injects syntax highlighting colors into the Micro terminal editor.
* **`apply-fastfetch-theme.sh` / `fastfetch-wrapper.sh`**: Updates telemetry accent colors in Fastfetch.
* **`apply-obsidian-theme.sh`**: Synchronizes CSS theme tokens for Obsidian markdown vaults.
* **`apply-code-theme.sh` / `material-code-set-color.sh`**: Sets editor UI accents for VS Code and Antigravity.
* **`apply-joplin-theme.sh` / `restart-joplin.py`**: Updates Joplin custom userstyles and restarts background workers.
* **`set-gtk-theme.sh` / `set-icon-theme.sh` / `set-cursor-theme.sh`**: Synchronizes system GTK themes, Tela circle icon themes, and Gloomi cursor themes.

### 8.3 AI, Intelligence & Media Processing (`scripts/ai/`, `scripts/lyrics/`)
* **`ai_query.py`**: Python worker handling streaming HTTPS communication with Google Gemini API models.
* **`gemini-translate.sh`**: Quick terminal translation utility powered by Gemini LLMs.
* **`gemini-categorize-wallpaper.sh`**: Image analysis tool classifying wallpapers by subject and visual tone.
* **`show-installed-ollama-models.sh`**: Queries local Ollama daemons for offline LLM support.
* **`lyrics.py`**: Real-time timed subtitle streamer parsing MPRIS player positions and YouTube caption streams.
* **`recognize-music.sh`**: Queries ACRCloud / Shazam APIs to identify music playing on the system.

### 8.4 Hyprland Compositor Automation (`scripts/hyprland/`, `hyprland-custom/scripts/`)
* **`__restore_video_wallpaper.sh`**: Automatically restores active MPV video wallpaper loops on boot.
* **`compact_window.sh`**: Centers and resizes the focused window for single-window focus sessions.
* **`restore_settings.sh`**: Re-applies compositor configuration from `config.json`.
* **`autostart.py`**: Spawns polkit agents, audio daemons, and background services on compositor launch.
* **`get_keybinds.py`**: Parses Hyprland and Niri configuration files on the fly for the on-screen cheat sheet.
* **`hyprconfigurator.py`**: IPC utility modifying Hyprland configuration variables dynamically at runtime.

---

<a id="overlays-gaming--productivity-tools"></a>
## 9. Overlays, Gaming & Productivity Tools

Located in `modules/ii/overlay/`:

* **Custom Gaming Crosshair (`crosshair/`)**: On-screen overlay reticle with configurable geometric shapes (dot, cross, circle, box), thickness, dynamic colors, and center gap for games without native HUDs.
* **Dynamic FPS Limiter (`fpsLimiter/`)**: Direct Hyprland display refresh rate toggle switching between low-power modes (60Hz) and high-refresh gaming modes (144Hz/165Hz).
* **Floating Reference Image (`floatingImage/`)**: On-screen pinned image canvas with opacity fader, scale zoom, rotation, and click-through mode for designers and artists.
* **Dropover Shelf (`modules/ii/dropover/`)**: Floating drag-and-drop staging shelf to hold multiple files temporarily while organizing folders or uploading.
* **Screen Recorder (`recorder/`)**: GPU-accelerated Wayland screen recorder supporting region selection, mic audio capture, and GIF/MP4 export.
* **Keybinding Cheat Sheet (`modules/ii/cheatsheet/`)**: Searchable overlay that dynamically parses active Hyprland and Niri configuration files.

---

<a id="productivity-hub-focus-journal--screen-time-daemon"></a>
## 10. Productivity Hub: Focus Journal & Screen Time Daemon

Located in `modules/ii/overlay/resources/`, `services/ScreenTime.qml`, and `scripts/system/screentime-daemon.py`:

* **Persistent Systemd Watchdog Daemon (`screentime-daemon.py`)**: Runs as a persistent user service (`ballade-screentime.service`) completely independent of QuickShell. Monitors Hyprland `socket2` real-time events (`activewindow`, `activewindowv2`, `windowtitle`) with a 1-second active tick and polling fallbacks.
* **Continuous 24-Hour Aggregation**: Accumulates per-second usage across shell reloads, crashes, and reboots. Never resets mid-day; automatically archives and rolls over cleanly at midnight.
* **Atomic State Persistence**: Writes to `~/.local/state/quickshell/user/screentime.json` via atomic temporary-file renames, guaranteeing data integrity without write races.
* **Intelligent Idle & Lock Pausing**: Automatically pauses tracking when the session is locked or when no client window is focused.
* **Multi-Horizon Analytics Engine**:
  * Switch between Day, Week, Month, and Year statistics with uptime meters and hourly bar charts.
  * Per-application drilldown with exact seconds, application category, and detailed window titles visited.
  * Interactive historical calendar matrix allowing users to inspect journal entries and screen time for any past date.

---

<a id="lock-screen-session--audio-engine"></a>
## 11. Lock Screen, Session & Audio Engine

Located in `modules/ii/lock/` & `modules/ii/sessionScreen/`:

* **Lock Screen (`Lock.qml`)**: Biometric PAM fingerprint / password authentication with active media player widget and color-matched background blur.
* **Session Screen (`SessionScreen.qml`)**: Radial and grid power menu for Power Off, Reboot, Suspend, Hibernate, Lock Session, and Logout.
* **Power Audio Deduplication**: `power-audio-executor.sh` acquires `/tmp/ballade_power_audio.lock` to prevent overlapping sound effects, normalizes audio volume, and plays localized shutdown sounds prior to executing system power actions.

---

<a id="backend-services-reference-qml"></a>
## 12. Backend Services Reference (QML)

Located in `services/`:

| Service QML | Core Responsibility |
| :--- | :--- |
| **`Audio.qml`** | PipeWire / WirePlumber IPC, volume faders, default sink routing. |
| **`Ai.qml`** | Google Gemini API SSE stream client and prompt dispatcher. |
| **`Booru.qml`** | Multi-provider anime image fetcher, tag parser, pagination manager. |
| **`Bluetooth.qml`** | BlueZ D-Bus discovery, pairing, and battery status monitor. |
| **`Cliphist.qml`** | Clipboard history caching, search indexing, and paste injection. |
| **`DateTime.qml`** | System clock, uptime calculator, and time formatting provider. |
| **`Goals.qml`** | Multi-horizon goals, milestones, to-do items, and persistence engine. |
| **`KeyringStorage.qml`** | Encrypted credential store for private API keys. |
| **`LyricsService.qml`** | MPRIS synchronized `.lrc` and YouTube subtitle stream coordinator. |
| **`MprisController.qml`** | MPRIS media player state, track metadata, and position seeker. |
| **`Network.qml`** | NetworkManager D-Bus Wi-Fi scanning and connection manager. |
| **`Notifications.qml`** | Native Freedesktop notification daemon server. |
| **`ResourceUsage.qml`** | CPU, RAM, GPU, and disk hardware metric sampler. |
| **`ScreenTime.qml`** | Reactive data provider reading `screentime.json` for dashboard analytics. |
| **`SystemInfo.qml`** | Host distro, kernel, CPU, GPU, and package telemetry. |
| **`Translation.qml`** | Internationalization (i18n) translator with dynamic locale switching. |
| **`Updates.qml`** | System package update checker (Arch / Pacman / Yay). |
| **`Wallpapers.qml`** | Wallpaper collection watcher, thumbnail dispatcher, and apply engine. |
| **`Weather.qml`** | GPS geocoding and Open-Meteo weather forecast caching. |
| **`WorldClock.qml`** | Global timezone time difference and DST calculator. |

---

<a id="architecture-evolution--cleaned-legacy-artifacts"></a>
## 13. Architecture Evolution & Cleaned Legacy Artifacts

Ballade originally evolved from a combination of `illogical-impulse` (`ii`) and `end4-pC`. To achieve stability and independence, all obsolete and brittle legacy behaviors have been systematically eliminated:

* **Notes Unification**: The standalone, unmaintained `notes` widget was removed and fully integrated into `GoalsWidget` (`goals.enable`), unifying Goal Setting, Milestones, To-Dos, and Notes into a single cohesive productivity surface.
* **Native Wallpaper Selector**: The legacy button invoking Zenity/fallback file dialogs in the desktop popup was replaced with Ballade's native 3D panoramic carousel (`GlobalStates.wallpaperSelectorOpen = true`).
* **Desktop Menu Cleanup**: Fixed copy-paste bugs inherited from `end4-pC` (such as `DropShelf.items.length === 0` hiding the Live Wallpaper chevron) and localized all context menu labels.
* **Ballade IPC Routing**: Replaced hardcoded `end4-pC` IPC commands in `Session.qml` (`lock`) with native `qs -c ballade ipc call`.
* **Safe Updater Pipeline**: Replaced the destructive script in `About.qml` (which wiped and re-cloned `end4-pC`) with a safe Git pull and reload procedure tailored strictly for Ballade.

---

<a id="bundled-dotfiles--app-configurations"></a>
## 14. Bundled Dotfiles & App Configurations

Located in `dotfiles/`:

* **`cava/config`**: Audio visualizer bar counts, smoothing, and gradient colors.
* **`fastfetch/config.jsonc`**: System telemetry layout with dynamic random art deck shuffler.
* **`kitty/kitty.conf`**: GPU terminal configuration with auto-included theme tokens.
* **`micro/`**: Terminal text editor syntax highlighters and key bindings.
* **`rmpc/config.ron`**: Terminal MPD music player configuration and album art layout.
* **`starship/starship.toml`**: Multi-shell prompt configuration.
* **`wlogout/`**: Wayland power menu layout and stylesheet.

---

<a id="internationalization-i18n"></a>
## 15. Internationalization (i18n)

Ballade supports 14 complete localizations located in `translations/`:
`en_US`, `es_MX`, `ru_RU`, `id_ID`, `he_HE`, `fr_FR`, `uk_UA`, `ja_JP`, `vi_VN`, `pt_BR`, `zh_CN`, `it_IT`, `de_DE`, `tr_TR`.

---

<a id="configuration--customization-files"></a>
## 16. Configuration & Customization Files

* **User Configuration**: `~/.config/illogical-impulse/config.json`
* **Schema Definition**: `modules/common/Config.qml`
* **Settings Hub GUI**: `settings.qml` (Launchable via `qs -c ballade settings.qml` or `SUPER + I`)

<br/>

<div align="center">

[![Back to Main README](https://img.shields.io/badge/⬅️_Back_to-Main_README-blue?style=for-the-badge)](README.md)

</div>
