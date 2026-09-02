<div align="center">

# 🌟 Ballade Desktop Shell — Technical Architecture & Feature Specification

[![Back to Main README](https://img.shields.io/badge/⬅️_Back_to-Main_README-blue?style=for-the-badge)](README.md)

<br/>

**Document Version:** 3.4  
**Target Environment:** Linux / Wayland (Hyprland & Niri)  
**Core Framework:** Quickshell (Qt 6.9+ / QML), Wayland Layer Shell Protocol  
**Theming Engine:** Material Design 3 (M3) with Matugen Color Generation  
**Base Layer:** `illogical-impulse` (`dots-hyprland`)

</div>

---

## 🧭 Table of Contents
1. [Core Architecture & Entry Point](#core-architecture--entry-point)
2. [Panel Families (Desktop Paradigms)](#panel-families-desktop-paradigms)
3. [Left Sidebar: Media, AI & Intelligence](#left-sidebar-media-ai--intelligence)
4. [Right Sidebar: Control Center & Productivity](#right-sidebar-control-center--productivity)
5. [Wallpaper Engine & Material You Theming](#wallpaper-engine--material-you-theming)
6. [Ballade Script Suite & Deployed Machine Utilities](#ballade-script-suite--deployed-machine-utilities)
7. [Overlays, Gaming & Productivity Tools](#overlays-gaming--productivity-tools)
8. [Productivity Hub: Focus Journal & Screen Time](#productivity-hub-focus-journal--screen-time)
9. [Lock Screen, Session & Audio Engine](#lock-screen-session--audio-engine)
10. [Backend Services Reference (QML)](#backend-services-reference-qml)
11. [Bundled Dotfiles & App Configurations](#bundled-dotfiles--app-configurations)
12. [Internationalization (i18n)](#internationalization-i18n)
13. [Configuration & Customization Files](#configuration--customization-files)

---

<a id="core-architecture--entry-point"></a>
## 1. Core Architecture & Entry Point

Ballade operates as an asynchronous, event-driven desktop environment shell. All windows, bars, sidebars, and overlays are rendered as hardware-accelerated Wayland Layer Shell surfaces.

### 1.1 Root Coordination Files
* **`shell.qml`**: Root entry point. Initializes global focus grabbers, registers compositor event listeners, monitors monitor hotplugging, and dynamically instantiates the active panel family.
* **`GlobalStates.qml`**: Global singleton managing modal visibility, overlay active states, drawer animations, and inter-widget communication.
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
* **Dropover Shelf (`modules/ii/dropover/`)**: Temporary drag-and-drop file staging area.

### 2.2 Waffle Family (`panelFamilies/WaffleFamily.qml`)
* **Taskbar (`modules/waffle/bar/`)**: Pinned bottom taskbar with grouped application icons and status indicators.
* **Start Menu (`modules/waffle/startMenu/`)**: Windows 11-style centered launcher featuring a categorized pinned application grid, search indexing, and recent files.
* **Action Center (`modules/waffle/actionCenter/`)**: Unified flyout containing quick toggles, slider controls, battery status, and notifications.
* **Task View (`modules/waffle/taskView/`)**: Virtual desktop switcher and active client tile viewer.

---

<a id="left-sidebar-media-ai--intelligence"></a>
## 3. Left Sidebar: Media, AI & Intelligence

Located in `modules/ii/sidebarLeft/`:

### 3.1 AI Chat Assistant (`AiChat.qml`, `services/Ai.qml`)
* **Streaming Architecture**: Direct Server-Sent Events (SSE) streaming using Google Gemini API (`gemini-2.5-flash`, `gemini-1.5-pro`, `gemini-1.5-flash`) over secure HTTPS.
* **Local Fallback Worker**: `scripts/ai/ai_query.py` provides a resilient CLI bridge for token generation and proxying.
* **Rendering Engine**: Formatted markdown parser supporting syntax-highlighted code blocks, line numbering, token stream animations, and copy-to-clipboard actions.
* **Session Persistence**: Persistent local conversation history with custom system prompt templates.

### 3.2 Anime & Booru Gallery (`Anime.qml`, `services/Booru.qml`)
* **Multi-Provider Engine**:
  * **Wallhaven API**: Support for anime categories (`categories=010`), multi-page pagination, purity toggles (SFW, Sketchy, NSFW), and encrypted user API keys via `KeyringStorage`.
  * **Safebooru / Danbooru**: Filtered anime illustration discovery.
  * **Gelbooru**: High-resolution image scraping with tag filters.
  * **Waifu.im**: Tag-based anime image delivery with dynamic random batching.
  * **Alcy (`t.alcy.cc`)**: Random anime image endpoints with category fallbacks.
* **Infinite Scroll Pagination**: Continuous scroll trigger dynamically requesting subsequent batches without UI thread locks or delegate height voids.
* **Aspect-Preserved Display**: Full uncropped (`PreserveAspectFit`) rendering displaying the complete artwork across all aspect ratios.
* **Image Action Drawer**: Single-click image downloading with automatic NSFW directory routing (`~/Pictures/Wallpapers/Anime/NSFW/` vs `~/Pictures/Wallpapers/Anime/`).

### 3.3 Screen & Text Translator (`screenTranslator/`, `translator/`)
* **Wayland OCR Screen Capture**: Uses `slurp` and `tesseract` to extract on-screen text from user-selected regions and translates immediately into target languages.
* **Interactive Translator**: Side-by-side translation tool with auto-language detection, character counters, and clipboard synchronization.

### 3.4 Live Lyrics & YouTube Caption Streamer (`scripts/lyrics/lyrics.py`)
* **Timed Lyrics**: Fetches and synchronizes `.lrc` lyrics with active MPRIS media players (Spotify, MPD, browser audio).
* **YouTube Live Subtitles**: Real-time caption extractor streaming synchronized subtitles directly from active YouTube video playback via `yt-dlp`.

---

<a id="right-sidebar-control-center--productivity"></a>
## 4. Right Sidebar: Control Center & Productivity

Located in `modules/ii/sidebarRight/`:

### 4.1 Notification Center (`notifications/`, `services/Notifications.qml`)
* **Freedesktop D-Bus Server**: Implements `org.freedesktop.Notifications` with notification history, grouped app stacks, actionable buttons, inline reply inputs, and dismiss gestures.
* **Do Not Disturb (DND)**: Global notification silencer with badge counters.

### 4.2 Calendar & Indian Festival Dataset (`calendar/`)
* **Interactive Matrix**: Month and Year navigation with lunar phase calculations.
* **Comprehensive Holiday Dataset**: Pre-compiled database of national gazetted holidays, restricted observances, and moon-sighting indicators.

### 4.3 Quick Toggles (`quickToggles/`)
* **Wi-Fi Manager (`services/network/Network.qml`)**: NetworkManager D-Bus client with live AP scanning, signal quality meters, and password prompts.
* **Bluetooth Manager (`services/Bluetooth.qml`)**: BlueZ D-Bus integration for device discovery, pairing, connection states, and battery telemetry.
* **Night Light**: Gamma temperature transition manager via Hyprland shader IPC / Gammastep.
* **Performance Toggles**: Game Mode scheduler and anti-flashbang screen filter toggles.

### 4.4 Task Management & Focus Timer (`todo/`, `pomodoro/`)
* **Notes & To-Do**: Multi-category task lists with checklist items, markdown scratchpad, and local JSON storage.
* **Pomodoro Focus Engine**: Customizable work and break intervals with audio alarms and background tracking.

### 4.5 PipeWire Per-App Volume Mixer (`volumeMixer/`, `services/Audio.qml`)
* **Stream Routing**: Real-time per-application volume sliders, stream muting, and default sink/source switching via WirePlumber IPC.

---

<a id="wallpaper-engine--material-you-theming"></a>
## 5. Wallpaper Engine & Material You Theming

Located in `scripts/colors/` & `scripts/theming/`:

* **Matugen Color Extraction**: Extracts dominant and harmonized Material You color palettes from any wallpaper image.
* **Dynamic App Synchronization**:
  * **Kitty & Konsole**: Updates terminal color schemes live without restarting shells.
  * **CAVA Audio Visualizer**: Live-generates matching gradient visualizer bars.
  * **rmpc (MPD)**: Themes music player controls and album view.
  * **Kvantum & GTK**: Synchronizes Qt SVG widgets and GTK theme colors.
  * **Discord & Joplin**: Injects matching translucent frosted themes.
* **In-QML Home Screen Wallpaper Blur**:
  * **Independent Hardware FastBlur**: Blurs the desktop wallpaper in pure QML shaders without compositor dependencies (`showBlur`).
  * **Split Blur & Gradient Mask**: Configurable split amount (`25%`, `50%`, `100%`) with horizontal directional opacity gradient masks (`Left` vs `Right`).
  * **Centered Shape Staging**: Displays wallpapers within interactive `MaterialShape` geometries (`cookie`, `slanted`, `superellipse`, `round`) with dynamic background backdrops.
* **Wallpaper Engines & Shaders Supported**:
  * Static images (PNG, JPG, WebP) with auto-blur caching.
  * Real-time GPU transition shaders (`magic`, `Doom`, `crt`, `glitch`, `ripple`, `dissolve`, `shatter`, `stripes`, `pixelate`, `Peel`, `circlePit`, `circleSelect`).
  * Real-time animated GLSL shader wallpapers (ripples, starry sky, matrix).
  * Smooth looping video wallpapers (MP4/WebM) via MPV.

---

<a id="ballade-script-suite--deployed-machine-utilities"></a>
## 6. Ballade Script Suite & Deployed Machine Utilities

Ballade includes a rich collection of modular scripts housed inside [`scripts/`](scripts/) and deploys core helper utilities directly to the user's `~/.local/bin/` during initialization.

### 6.1 CLI Utilities Deployed to User System (`~/.local/bin/`)
When [`setup.sh`](setup.sh) runs, it installs and symlinks the following utilities into `~/.local/bin/`:

* **`power-audio-executor.sh`**: Master power and session orchestrator. Intercepts `poweroff`, `reboot`, `shutdown`, `suspend`, and `lock` commands to execute smooth audio feedback, volume normalization, and deduplication before forwarding actions to systemd.
* **`poweroff` / `reboot` / `shutdown`**: Symlinks pointing to `power-audio-executor.sh` allowing direct CLI power management without syntax errors under strict shell environments.
* **`systemctl` / `loginctl`**: Interceptor wrappers capturing system power calls to ensure audio feedback plays reliably.
* **`fastfetch`**: Custom Fastfetch launcher that dynamically selects a random graphic from the `assets/` deck on every terminal launch.
* **`rmpc-run` / `rmpc-fetch-lyrics` / `rmpc-launch`**: Runner suite for the `rmpc` MPD client that establishes daemon connections, displays album covers, and extracts synchronized `.lrc` lyrics.
* **`clipboard-image-transformer.py`**: Wayland clipboard daemon watching for image copy events to optimize, format, and prepare image payloads for instant pasting into chats.
* **`copy-image-with-path.py`**: Multi-format clipboard utility that simultaneously copies both raw image pixel data (`image/png`) and the plain-text file path (`text/plain`).
* **`random-greeting.sh`**: Time-aware shell greeter that plays localized audio announcements and notifications on terminal startup.

### 6.2 Theming & Color Dispatchers (`scripts/colors/`, `scripts/theming/`)
* **`switchwall.sh`**: Master wallpaper switcher. Invokes `matugen` to extract Material Design 3 palettes, computes image brightness, generates color tokens, and broadcasts theme updates.
* **`applycolor.sh`**: Central dispatcher that propagates generated Material You colors to Kitty, Konsole, Discord, CAVA, rmpc, Joplin, and Kvantum.
* **`apply-theme-preset.sh`**: Applies any of the 8 handcrafted color presets (`green`, `pink`, `red`, `purple`, `blue`, `golden`, `orange`, `grayscale`).
* **`apply-discord-theme.sh`**: Generates and links frosted glass CSS variables into Vencord / BetterDiscord.
* **`apply-cava-theme.sh`**: Computes an 8-step color gradient for CAVA based on the dominant and secondary wallpaper hues.
* **`apply-rmpc-theme.sh`**: Generates themes for the `rmpc` MPD player.
* **`apply-micro-theme.sh`**: Injects syntax highlighting colors into the Micro terminal editor.
* **`apply-fastfetch-theme.sh` / `fastfetch-wrapper.sh`**: Updates telemetry accent colors in Fastfetch.
* **`apply-obsidian-theme.sh`**: Synchronizes CSS theme tokens for Obsidian markdown vaults.
* **`apply-code-theme.sh` / `material-code-set-color.sh`**: Sets editor UI accents for VS Code and Antigravity.
* **`apply-joplin-theme.sh` / `restart-joplin.py`**: Updates Joplin custom userstyles and restarts background workers.
* **`set-gtk-theme.sh` / `set-icon-theme.sh` / `set-cursor-theme.sh`**: Synchronizes system GTK themes, Tela circle icon themes, and Gloomi cursor themes.
* **`generate_colors_material.py` / `scheme_for_image.py`**: Python backend invoking Matugen color generation algorithms.
* **`random_osu_wall.sh` / `random_konachan_wall.sh`**: Downloads random anime wallpapers into local theme folders.

### 6.3 AI, Intelligence & Media Processing (`scripts/ai/`, `scripts/lyrics/`)
* **`ai_query.py`**: Python worker handling streaming HTTPS communication with Google Gemini API models.
* **`gemini-translate.sh`**: Quick terminal translation utility powered by Gemini LLMs.
* **`gemini-categorize-wallpaper.sh`**: Image analysis tool classifying wallpapers by subject and visual tone.
* **`show-installed-ollama-models.sh`**: Queries local Ollama daemons for offline LLM support.
* **`lyrics.py`**: Real-time timed subtitle streamer parsing MPRIS player positions and YouTube caption streams.
* **`recognize-music.sh`**: Queries ACRCloud / Shazam APIs to identify music playing on the system.

### 6.4 Image Analysis & Computer Vision (`scripts/images/`, `scripts/thumbnails/`)
* **`find_regions.py` / `least_busy_region.py`**: Analyzes wallpaper density to find low-contrast coordinates for placing desktop widgets.
* **`text_color.py`**: Determines whether light or dark text provides optimal readability against wallpaper regions.
* **`thumbgen.py` / `generate-thumbnails-magick.sh`**: Generates cached aspect-preserved thumbnails for the 3D cover-flow wallpaper carousel.

### 6.5 Qt & Kvantum Engine (`scripts/kvantum/`)
* **`materialQT.sh` / `changeAdwColors.py` / `adwsvg.py` / `adwsvgDark.py`**: Generates and compiles Kvantum SVG assets to enforce dynamic Material Design themes across Qt5 and Qt6 applications.

### 6.6 Hyprland Compositor Automation (`scripts/hyprland/`, `hyprland-custom/scripts/`)
* **`__restore_video_wallpaper.sh`**: Automatically restores active MPV video wallpaper loops on boot.
* **`compact_window.sh`**: Centers and resizes the focused window for single-window focus sessions.
* **`restore_settings.sh`**: Re-applies compositor configuration from `config.json`.
* **`autostart.py`**: Spawns polkit agents, audio daemons, and background services on compositor launch.
* **`get_keybinds.py`**: Parses Hyprland and Niri configuration files on the fly for the on-screen cheat sheet.
* **`hyprconfigurator.py`**: IPC utility modifying Hyprland configuration variables dynamically at runtime.

### 6.7 Security, Sound & Hardware Services (`scripts/keyring/`, `scripts/system/`)
* **`unlock.sh` / `is_unlocked.sh` / `try_lookup.sh`**: Keyring tools securely managing private API tokens.
* **`setup-system-sounds.sh` / `play-audio.sh`**: Installs audio event services and plays feedback sounds.
* **`play-usb-audio.sh`**: Triggers sound feedback on USB connect/disconnect events via udev rules.
* **`record.sh`**: GPU-accelerated screen recorder wrapping `wf-recorder`.
* **`test-resource-usage.sh`**: Diagnostic profiler benchmarking QuickShell CPU and memory utilization.

---

<a id="overlays-gaming--productivity-tools"></a>
## 7. Overlays, Gaming & Productivity Tools

Located in `modules/ii/overlay/`:

* **Custom Gaming Crosshair (`crosshair/`)**: On-screen overlay reticle with configurable geometric shapes (dot, cross, circle, box), thickness, dynamic colors, and center gap for games without native HUDs.
* **Dynamic FPS Limiter (`fpsLimiter/`)**: Direct Hyprland display refresh rate toggle switching between low-power modes (60Hz) and high-refresh gaming modes (144Hz/165Hz).
* **Floating Reference Image (`floatingImage/`)**: On-screen pinned image canvas with opacity fader, scale zoom, rotation, and click-through mode for designers and artists.
* **Dropover Shelf (`modules/ii/dropover/`)**: Floating drag-and-drop staging shelf to hold multiple files temporarily while organizing folders or uploading.
* **Screen Recorder (`recorder/`)**: GPU-accelerated Wayland screen recorder supporting region selection, mic audio capture, and GIF/MP4 export.
* **Keybinding Cheat Sheet (`modules/ii/cheatsheet/`)**: Searchable overlay that dynamically parses active Hyprland and Niri configuration files.

---

<a id="productivity-hub-focus-journal--screen-time"></a>
## 8. Productivity Hub: Focus Journal & Screen Time

Located in `modules/ii/overlay/resources/`:

* **24-Hour Watchdog Daemon (`screentime-daemon.py`)**: Persistent systemd user background service (`ballade-screentime.service`) operating independently of QuickShell. Monitors Hyprland socket2 real-time events (`activewindow`, `windowtitle`) with polling fallbacks, logging exact app focus, multi-window events, and window titles without resetting on shell reloads, crashes, or reboots.
* **Continuous 24h Aggregation**: Tracks non-stop for the current calendar day until midnight rollover; state is preserved atomically (`screentime.json`) and instantly rehydrated.
* **Multi-Horizon Analytics**: Switch between Day, Week, Month, and Year statistics with uptime meters and usage graphs.
* **Per-App Activity Drilldown**: Inspect detailed timelines of visited websites, files, documents, and unique window titles per application.
* **Historical Calendar Jump**: Interactive calendar matrix allowing users to review journaling and screen time data for any historical date.
* **5-Horizon Goal Setting**: Custom goal tracking with progress rings.

---

<a id="lock-screen-session--audio-engine"></a>
## 9. Lock Screen, Session & Audio Engine

Located in `modules/ii/lock/` & `modules/ii/sessionScreen/`:

* **Lock Screen (`Lock.qml`)**: Biometric PAM fingerprint / password authentication with active media player widget and color-matched background blur.
* **Session Screen (`SessionScreen.qml`)**: Radial and grid power menu for Power Off, Reboot, Suspend, Hibernate, Lock Session, and Logout.
* **Power Audio Deduplication**: Prevents overlapping sound effects and handles volume normalization across power commands.

---

<a id="backend-services-reference-qml"></a>
## 10. Backend Services Reference (QML)

Located in `services/`:

| Service QML | Core Responsibility |
| :--- | :--- |
| **`Audio.qml`** | PipeWire / WirePlumber IPC, volume faders, default sink routing. |
| **`Booru.qml`** | Multi-provider anime image fetcher, tag parser, pagination manager. |
| **`Ai.qml`** | Google Gemini API SSE stream client and prompt dispatcher. |
| **`Bluetooth.qml`** | BlueZ D-Bus discovery, pairing, and battery status monitor. |
| **`Network.qml`** | NetworkManager D-Bus Wi-Fi scanning and connection manager. |
| **`Weather.qml`** | GPS geocoding and Open-Meteo weather forecast caching. |
| **`Notifications.qml`** | Native Freedesktop notification daemon server. |
| **`Mpris.qml`** | MPRIS media player state, track metadata, and position seeker. |
| **`KeyringStorage.qml`** | Encrypted credential store for private API keys. |

---

<a id="bundled-dotfiles--app-configurations"></a>
## 11. Bundled Dotfiles & App Configurations

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
## 12. Internationalization (i18n)

Ballade supports 14 complete localizations located in `translations/`:
`en_US`, `es_MX`, `ru_RU`, `id_ID`, `he_HE`, `fr_FR`, `uk_UA`, `ja_JP`, `vi_VN`, `pt_BR`, `zh_CN`, `it_IT`, `de_DE`, `tr_TR`.

---

<a id="configuration--customization-files"></a>
## 13. Configuration & Customization Files

* **User Configuration**: `~/.config/illogical-impulse/config.json`
* **Schema Definition**: `modules/common/Config.qml`
* **Settings Hub GUI**: `settings.qml` (Launchable via `qs -c ballade settings.qml` or `SUPER + I`)

<br/>

<div align="center">

[![Back to Main README](https://img.shields.io/badge/⬅️_Back_to-Main_README-blue?style=for-the-badge)](README.md)

</div>
