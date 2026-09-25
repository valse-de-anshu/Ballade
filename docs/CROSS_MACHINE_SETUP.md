[← Back to Main README](../README.md)

# 🌐 Cross-Machine Setup & Portability Guide

This document explains how **QuickShell Ballade** is structured to deploy smoothly across multiple Linux machines without breaking paths, configurations, or permissions.

---

## 🚀 One-Click Automated Deployment (`setup.sh`)

When deploying Ballade on a new machine:

```bash
# 1. Clone into your local quickshell directory
git clone https://github.com/valse-de-anshu/Ballade.git ~/.config/quickshell/ballade

# 2. Run the environment initializer
cd ~/.config/quickshell/ballade
chmod +x setup.sh
./setup.sh
```

### What `setup.sh` Automates
1. **Script Permissions**:
   - Recursively marks all shell (`.sh`) and Python (`.py`) scripts in `scripts/` and `hyprland-custom/scripts/` executable.
2. **Directory & Preset Initialization**:
   - Creates wallpaper directories (`~/Pictures/Wallpapers/<preset>`) and live wallpaper folders.
   - Populates initial wallpapers if empty.
   - Creates `~/.config/illogical-impulse/presets/` and expands all `__HOME__` template placeholders to the machine's actual `$HOME`.
3. **Hyprland Custom Integrations**:
   - Copies blur rules, keybindings, and autostart scripts to `~/.config/hypr/custom/`.
   - Preserves user backups (`.bak`) if existing overrides differ.
   - Automatically marks custom Hyprland scripts (including KDE Connect reconnect watcher) as executable.
4. **Application Dotfiles**:
   - **Fastfetch**: Dynamically replaces hardcoded home paths with the local `$HOME`.
   - **rmpc**: Dynamically adapts `lyrics_dir` and script triggers in `config.ron` to the local `$HOME`.
   - **mpv**: Copies shaders, configuration, and ensures `ziggy-linux` (uosc binary) is executable.
   - **Vencord / Vesktop**: Installs both `DiscordPlus.theme.css` and `ballade-theme.css` (Frosted Glass).
   - **Micro**: Installs `bindings.json`, `settings.json`, `init.lua`, and all 11 colorschemes.
   - **Kitty, Konsole, Starship, CAVA, btop, Joplin, Kvantum, KDE**: Configures theme links and profiles.
5. **CLI Helpers & Daemons**:
   - Installs wrappers (`rmpc-run`, `rmpc-fetch-lyrics`, `snip-annotate.py`, `clipboard-image-transformer.py`, `random-greeting.sh`) into `~/.local/bin/`.
   - Installs and starts the `ballade-screentime.service` systemd user service.
6. **Theme Harmonization**:
   - Applies the default theme preset (`green`) across all 16 supported subsystems.

---

## 📂 Portability Architecture Principles

1. **`__HOME__` Placeholder**:
   - Preset JSON files in `dotfiles/illogical-impulse/presets/*.json` use `__HOME__` instead of hardcoded paths like `/home/username`.
   - `setup.sh` expands `__HOME__` to `${HOME}` on install.
2. **Dynamic Shell & Python Path Expansion**:
   - Scripts rely on `$HOME`, `os.path.expanduser("~")`, or `XDG_CONFIG_HOME` rather than hardcoded usernames.
3. **Safe Git Storage**:
   - Runtime cache directories (e.g. `mpvpaper_thumbnails/`, runtime generated scripts) are excluded via `.gitignore` to prevent repository bloat.

---

[← Back to Main README](../README.md)
