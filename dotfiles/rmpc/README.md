# 🎵 Complete `rmpc` + `mpd` Custom Ecosystem Guide

This document explains the comprehensive custom `rmpc` terminal music player setup bundled with Ballade. If you are starting fresh with `mpd` and `rmpc`, this guide explains every dependency, service, script, and configuration required to recreate this environment.

---

## 📦 1. Prerequisites & Dependencies

To make everything work (audio playback, media keys, visualizers, auto-lyrics), the following packages are required:
- **`rmpc`**: The terminal UI client.
- **`mpd`**: Music Player Daemon (the actual audio engine).
- **`mpDris2`**: Bridge that connects MPD to the Linux MPRIS D-Bus (enables laptop media keys and lockscreen playback controls).
- **`cava`**: Terminal audio visualizer.
- **`python3`**: Used for our robust lyrics fetcher script.
- **`python-mutagen`**: Used for reading/sanitizing audio tags (FLAC, MP3, etc.).
- **`curl` & `jq`**: Network and JSON parsing utilities.

---

## ⚙️ 2. Core Services & Daemons

The setup relies on background services running harmoniously:
1. **`mpd.service`**: Runs as a systemd user service (`systemctl --user start mpd`). It reads `~/.config/mpd/mpd.conf`.
   - **Audio Output 1**: Plays audio through PipeWire/PulseAudio.
   - **Audio Output 2**: Pipes raw audio data to `/tmp/mpd.fifo`. `cava` reads this FIFO file to draw the audio visualizer inside `rmpc`.
2. **`mpDris2`**: Runs quietly in the background, listening to MPD and broadcasting its state to the desktop environment.
3. **`rmpc`**: The frontend that connects to `mpd` via `127.0.0.1:6600`.

---

## 📂 3. The Directory Architecture & Lyrics Routing

To support seamless switching between internal storage and an external portable drive (if you have one), the `rmpc` config expects a strict directory structure.

```text
📁 ~/Music/                          (MPD Root Directory)
├── 📁 internal_music/               (Songs stored on laptop)
│   └── 📁 lyrics/                   (Internal .lrc files)
│
└── 🔗 portable_music/               (Optional: Symlink to external drive)
    -> /mnt/storage/portable_music/
       ├── Song.flac
       └── 📁 lyrics/                (Portable .lrc files)
```

> **⚠️ IMPORTANT SYSTEM TWEAKS FOR YOU:**
> If you don't use a portable drive, you can just store all your music in `~/Music/internal_music/`.
> If your external drive is mounted differently, you **must** update the hardcoded `/mnt/storage` paths inside `~/.local/bin/rmpc-run` and `~/.local/bin/rmpc-fetch-lyrics` to match your system.

### The "Lyrics Hub" Routing Trick
`rmpc` only allows setting a single `lyrics_dir` in its config. To make it find lyrics for *both* drives simultaneously, the `rmpc-run` script creates a routing hub at `~/.local/share/rmpc/lyrics`.
Inside this hub, it places symlinks that exactly match the MPD directory names:
- `internal_music -> ~/Music/internal_music/lyrics`
- `portable_music -> /mnt/storage/portable_music/lyrics`

When a song plays from `portable_music/Song.flac`, `rmpc` checks `~/.local/share/rmpc/lyrics/portable_music/Song.lrc`, which routes directly to the correct drive!

---

## 📜 4. Custom Automation Scripts

Ballade installs two custom scripts to `~/.local/bin/` to automate the entire ecosystem.

### `rmpc-run` (The Master Launcher)
You should **always** launch the player using `rmpc-run` instead of just `rmpc`. On execution, it:
1. Kills any stale `mpDris2` processes and deletes old `/tmp/mpd.fifo` files.
2. Auto-creates all necessary directory structures and symlinks (self-healing).
3. Restarts `mpd.service` cleanly.
4. Triggers an `rmpc rescan` so the database immediately detects new or deleted songs.
5. Launches `mpDris2` in the background.
6. Finally, launches the `rmpc` TUI. When you quit the UI, a `trap` catches the exit and cleanly shuts down all background daemons.

### `rmpc-fetch-lyrics` (The Silent Downloader)
Linked in `~/.config/rmpc/config.ron` via `on_song_change: ["~/.local/bin/rmpc-fetch-lyrics"]`.
- Written in pure Python.
- Reads the current playing song from `rmpc song`.
- Queries the `lrclib.net` API for synced `.lrc` lyrics.
- Saves the file directly into the correct `lyrics/` subfolder (Internal or Portable) based on the song's path.
- Designed to be bulletproof: it handles network timeouts and missing metadata gracefully and *always* exits with code `0` to prevent `rmpc` from throwing errors.

---

## 🎨 5. Configurations & UI

- **`mpd.conf`**: Configured to follow symlinks (`follow_outside_symlinks "yes"`).
- **`config.ron`**: 
  - 8 custom color themes matching Ballade presets.
  - Square album art rendering.
  - Custom single-key keybindings (`p` for pause, `j`/`k` for navigation, `+` / `-` for volume, `u` for rescan).
