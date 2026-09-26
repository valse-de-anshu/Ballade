# 🎵 Complete `rmpc` + `mpd` Custom Ecosystem Guide

This document is a comprehensive guide to this machine's custom `rmpc` terminal music player setup. If you were starting from a fresh Linux install with just `mpd` and `rmpc`, this document explains every dependency, service, script, and configuration required to recreate this exact environment.

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

## 📂 3. The Dual-Drive Directory Architecture

To support seamless switching between internal laptop storage and an external portable drive, we use a strict directory structure.

```text
📁 ~/Music/                          (MPD Root Directory)
├── 📁 internal_music/               (Songs stored on laptop)
│   └── 📁 lyrics/                   (Internal .lrc files)
│
└── 🔗 portable_music/               (Symlink to external drive)
    -> /mnt/storage/portable_music/
       ├── Song.flac
       └── 📁 lyrics/                (Portable .lrc files)
```

### The "Lyrics Hub" Routing Trick
`rmpc` only allows setting a single `lyrics_dir` in its config. To make it find lyrics for *both* drives simultaneously, we created a routing hub at `~/.local/share/rmpc/lyrics`.
Inside this hub, we place symlinks that exactly match the MPD directory names:
- `internal_music -> ~/Music/internal_music/lyrics`
- `portable_music -> /mnt/storage/portable_music/lyrics`

When a song plays from `portable_music/Song.flac`, `rmpc` checks `~/.local/share/rmpc/lyrics/portable_music/Song.lrc`, which routes directly to the external drive!

---

## 📜 4. Custom Automation Scripts

We use two custom scripts stored in `~/.local/bin/` to automate the entire ecosystem.

### `rmpc-run` (The Master Launcher)
You should always launch the player using `rmpc-run`. On execution, it:
1. Kills any stale `mpDris2` processes and deletes old `/tmp/mpd.fifo` files.
2. Auto-creates all necessary directory structures and symlinks (self-healing).
3. Restarts `mpd.service` cleanly.
4. Triggers an `rmpc rescan` so the database immediately detects new or deleted songs.
5. Launches `mpDris2` in the background.
6. Finally, launches the `rmpc` TUI. When you quit the UI, a `trap` catches the exit and cleanly shuts down all background daemons.

### `rmpc-fetch-lyrics` (The Silent Downloader)
Linked in `config.ron` via `on_song_change: ["~/.local/bin/rmpc-fetch-lyrics"]` (or dynamically configured by `setup.sh`).
- Written in pure Python.
- Reads the current playing song from `rmpc song`.
- Queries the `lrclib.net` API for synced `.lrc` lyrics.
- Saves the file directly into the correct `lyrics/` subfolder (Internal or Portable) based on the song's path.
- Designed to be bulletproof: it handles network timeouts and missing metadata gracefully and *always* exits with code `0` to prevent `rmpc` from throwing errors.

---

## 🎨 5. Configurations & UI

- **`mpd.conf`**: Configured to follow symlinks (`follow_outside_symlinks "yes"`).
- **`config.ron`**: 
  - 10 custom color themes (catppuccin, tokyo_night, etc.).
  - Square album art rendering.
  - Custom single-key keybindings (`p` for pause, `j`/`k` for navigation, `=` / `-` for volume, `u` for rescan).

---

## ⚠️ 6. Past Mistakes & Lessons Learned

1. **The `music_symlink` MPD Duplicate Bug**
   - *Mistake*: We created a folder called `music_symlink/` inside `~/Music` to hold external drive shortcuts. 
   - *Result*: MPD indexed it alongside the actual symlinks, creating duplicate tracks with broken paths like `music_symlink/portable_music/Song.flac`. This broke the lyrics routing because `rmpc` tried to look for a `music_symlink` folder.
   - *Fix*: Deleted `music_symlink`. MPD must only see direct top-level folders (`internal_music`, `portable_music`).

2. **Lyrics Resolution vs `walkdir` Symlink Ignorance**
   - *Mistake*: Expected `rmpc lyricsindex` to scan the symlinked folders in the Lyrics Hub.
   - *Result*: Rust's `walkdir` library does not follow symlinks by default, so the index remained completely empty.
   - *Fix*: Realized the index isn't strictly necessary. Because our symlink names *exactly* match the MPD directory prefixes, `rmpc`'s fallback direct-path lookup finds the lyrics flawlessly.

3. **"External Command Failed" Popups**
   - *Mistake*: The original bash-based lyrics fetcher crashed if a song had missing metadata or if `curl` failed.
   - *Result*: `rmpc` would show an annoying "External command failed" popup on the screen.
   - *Fix*: Rewrote the fetcher in Python with strict `try/except` blocks to guarantee it never crashes `rmpc`.
