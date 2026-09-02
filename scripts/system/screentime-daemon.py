#!/usr/bin/env python3
"""
Ballade Screen Time Tracking Daemon
====================================
Runs as a systemd user service. Tracks the active Hyprland window in real-time
via socket2 events + 2s polling fallback. Accumulates per-second data across
reboots and restarts. Saves atomically every 5 seconds. Resets at midnight.
"""

import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
from datetime import datetime, date
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
DATA_PATH = Path("/home/valse-de-anshu/.local/state/quickshell/user/screentime.json")

# ── App Name / Icon Mapping ───────────────────────────────────────────────────
def format_app_name(app_id: str) -> str:
    if not app_id or not app_id.strip():
        return "Desktop"
    lower = app_id.lower().strip()
    if "zen" in lower:        return "Zen Browser"
    if "chrome" in lower:     return "Google Chrome"
    if "firefox" in lower:    return "Firefox"
    if "brave" in lower:      return "Brave Browser"
    if "code" in lower or "vscodium" in lower: return "VS Code"
    if "kitty" in lower:      return "Kitty Terminal"
    if "foot" in lower:       return "Foot Terminal"
    if "alacritty" in lower:  return "Alacritty"
    if "obsidian" in lower:   return "Obsidian"
    if "joplin" in lower:     return "Joplin Notes"
    if "spotify" in lower:    return "Spotify"
    if "discord" in lower or "vesktop" in lower: return "Discord"
    if "telegram" in lower:   return "Telegram"
    if "nautilus" in lower or "thunar" in lower or "dolphin" in lower: return "Files"
    if "mpv" in lower or "vlc" in lower:         return "Media Player"
    if "gwenview" in lower:   return "Image Viewer"
    if "okular" in lower:     return "Document Viewer"
    if "libreoffice" in lower or "soffice" in lower: return "LibreOffice"
    if "onlyoffice" in lower: return "ONLYOFFICE"
    if "steam" in lower:      return "Steam"
    if "quickshell" in lower or "ballade" in lower: return "System Shell"
    if "settings" in lower or "control" in lower:   return app_id.strip()
    # Strip reverse DNS (e.g. org.gnome.Calculator → Calculator)
    parts = app_id.split(".")
    last = parts[-1]
    return last[0].upper() + last[1:] if last else app_id


def format_app_icon(app_id: str) -> str:
    if not app_id or not app_id.strip():
        return "desktop_windows"
    lower = app_id.lower().strip()
    if any(k in lower for k in ("zen", "chrome", "firefox", "brave", "browser")):
        return "language"
    if "code" in lower or "vscodium" in lower or "dev" in lower:
        return "code"
    if any(k in lower for k in ("terminal", "kitty", "foot", "alacritty")):
        return "terminal"
    if any(k in lower for k in ("obsidian", "joplin", "notes")):
        return "description"
    if "spotify" in lower or "music" in lower:
        return "music_note"
    if any(k in lower for k in ("discord", "vesktop", "telegram", "chat")):
        return "chat"
    if any(k in lower for k in ("files", "nautilus", "thunar", "dolphin")):
        return "folder"
    if any(k in lower for k in ("mpv", "vlc", "video")):
        return "movie"
    if "gwenview" in lower or "image" in lower:
        return "image"
    if any(k in lower for k in ("okular", "pdf", "document", "office", "soffice")):
        return "menu_book"
    if "settings" in lower or "control" in lower:
        return "settings"
    return "apps"


# ── Atomic file save ──────────────────────────────────────────────────────────
def atomic_save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", dir=str(path.parent), delete=False, suffix=".tmp"
    ) as f:
        json.dump(data, f, indent=2)
        tmp = f.name
    os.replace(tmp, str(path))


# ── Load (merge) existing data ────────────────────────────────────────────────
def load_data() -> dict:
    try:
        with open(DATA_PATH) as f:
            return json.load(f)
    except Exception:
        return {}


# ── Idle / lock detection ─────────────────────────────────────────────────────
def is_screen_locked() -> bool:
    """
    Check if the session is locked via loginctl.
    Returns True if locked so tracking should pause.
    """
    try:
        result = subprocess.run(
            ["loginctl", "show-session", "self", "--property=LockedHint"],
            capture_output=True, text=True, timeout=2
        )
        return "LockedHint=yes" in result.stdout
    except Exception:
        pass
    # Fallback: check hyprctl monitors for locked state
    try:
        result = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True, text=True, timeout=2
        )
        monitors = json.loads(result.stdout)
        for m in monitors:
            if m.get("dpmsStatus") is False:
                return True
    except Exception:
        pass
    return False


# ── Get active window via hyprctl ─────────────────────────────────────────────
def get_active_window() -> tuple[str, str]:
    """Returns (class, title) or ('', '') if nothing focused."""
    try:
        result = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            capture_output=True, text=True, timeout=3
        )
        text = result.stdout.strip()
        if not text or text == "{}":
            return "", ""
        win = json.loads(text)
        cls = (win.get("class") or win.get("initialClass") or "").strip()
        title = (win.get("title") or "").strip()
        return cls, title
    except Exception:
        return "", ""


# ── Hyprland socket2 event listener ──────────────────────────────────────────
def get_socket2_path() -> str | None:
    """Find the Hyprland socket2 path."""
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        # Try to discover it
        hypr_dir = Path(xdg_runtime) / "hypr"
        if hypr_dir.exists():
            dirs = sorted(hypr_dir.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True)
            if dirs:
                sig = dirs[0].name
    if sig:
        return str(Path(xdg_runtime) / "hypr" / sig / ".socket2.sock")
    return None


FOCUS_EVENTS = {"activewindow", "activewindowv2", "windowtitle", "windowtitlev2",
                "workspace", "focusedmon"}


class ScreenTimeDaemon:
    def __init__(self):
        self.data: dict = {}
        self.today_str: str = ""
        self.current_app: str = ""
        self.current_title: str = ""
        self._lock = threading.Lock()
        self._running = True
        self._dirty = False  # data changed since last save
        self._last_save = 0.0

    # ── Data helpers ──────────────────────────────────────────────────────────
    def _today(self) -> str:
        return date.today().isoformat()

    def _ensure_today(self, today: str) -> None:
        """Make sure today's key exists with correct structure."""
        if today not in self.data:
            self.data[today] = {
                "totalSeconds": 0,
                "hourly": [0] * 24,
                "apps": {}
            }
        else:
            day = self.data[today]
            if not isinstance(day.get("hourly"), list) or len(day["hourly"]) != 24:
                day["hourly"] = [0] * 24
            if not isinstance(day.get("apps"), dict):
                day["apps"] = {}
            if "totalSeconds" not in day:
                day["totalSeconds"] = 0

    def record_second(self) -> None:
        """Add 1 second to the currently focused app."""
        app_id = self.current_app
        title = self.current_title

        # Ignore empty / desktop
        if not app_id or app_id.lower() == "desktop":
            return

        today = self._today()
        hour = datetime.now().hour

        with self._lock:
            # Detect midnight rollover — load fresh if date changed
            if self.today_str and today != self.today_str:
                print(f"[screentime] Midnight rollover: {self.today_str} → {today}", flush=True)
                # Re-load from disk (it may have prior days already)
                self.data = load_data()

            self.today_str = today
            self._ensure_today(today)

            day = self.data[today]
            day["totalSeconds"] = (day["totalSeconds"] or 0) + 1
            day["hourly"][hour] = (day["hourly"][hour] or 0) + 1

            # App entry
            if app_id not in day["apps"]:
                day["apps"][app_id] = {
                    "name": format_app_name(app_id),
                    "icon": format_app_icon(app_id),
                    "seconds": 1,
                    "titles": {}
                }
            else:
                day["apps"][app_id]["seconds"] = (day["apps"][app_id].get("seconds") or 0) + 1

            # Title tracking
            if title:
                titles = day["apps"][app_id].setdefault("titles", {})
                key = title[:160]  # cap key length
                titles[key] = (titles.get(key) or 0) + 1
                # Prune to 50 most-seen titles
                if len(titles) > 50:
                    min_key = min(titles, key=lambda k: titles[k])
                    del titles[min_key]

            self._dirty = True

    def save_if_needed(self) -> None:
        now = time.monotonic()
        if self._dirty and (now - self._last_save) >= 5.0:
            with self._lock:
                if not self._dirty:
                    return
                snapshot = json.loads(json.dumps(self.data))  # deep copy under lock
                self._dirty = False
            try:
                atomic_save(DATA_PATH, snapshot)
                self._last_save = now
                print(f"[screentime] Saved → {DATA_PATH}", flush=True)
            except Exception as e:
                print(f"[screentime] Save error: {e}", flush=True)
                self._dirty = True  # retry

    # ── Active window update ──────────────────────────────────────────────────
    def update_active_window(self) -> None:
        cls, title = get_active_window()
        self.current_app = cls
        self.current_title = title

    # ── Hyprland socket2 listener thread ─────────────────────────────────────
    def socket_listener(self) -> None:
        while self._running:
            sock_path = get_socket2_path()
            if not sock_path or not Path(sock_path).exists():
                print("[screentime] Waiting for Hyprland socket2...", flush=True)
                time.sleep(3)
                continue

            print(f"[screentime] Connecting to socket2: {sock_path}", flush=True)
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                    sock.connect(sock_path)
                    sock.settimeout(5)
                    buf = ""
                    while self._running:
                        try:
                            chunk = sock.recv(4096).decode("utf-8", errors="replace")
                            if not chunk:
                                break
                            buf += chunk
                            while "\n" in buf:
                                line, buf = buf.split("\n", 1)
                                line = line.strip()
                                if ">>" in line:
                                    event_name = line.split(">>")[0]
                                    if event_name in FOCUS_EVENTS:
                                        self.update_active_window()
                        except socket.timeout:
                            continue
                        except Exception as e:
                            print(f"[screentime] Socket read error: {e}", flush=True)
                            break
            except Exception as e:
                print(f"[screentime] Socket connect error: {e}", flush=True)
            if self._running:
                print("[screentime] Socket disconnected, reconnecting in 3s...", flush=True)
                time.sleep(3)

    # ── Poll fallback thread (every 2s) ───────────────────────────────────────
    def poll_thread(self) -> None:
        while self._running:
            self.update_active_window()
            time.sleep(2)

    # ── 1-second tracking + 5s save ticker ────────────────────────────────────
    def tick_thread(self) -> None:
        while self._running:
            # Check lock state every 10 ticks (every ~10s) to reduce overhead
            start = time.monotonic()

            if is_screen_locked():
                # Pause tracking, still save pending data
                self.save_if_needed()
                time.sleep(1)
                continue

            self.record_second()
            self.save_if_needed()

            elapsed = time.monotonic() - start
            sleep_for = max(0, 1.0 - elapsed)
            time.sleep(sleep_for)

    # ── Startup ───────────────────────────────────────────────────────────────
    def start(self) -> None:
        # Load existing data first (merge)
        self.data = load_data()
        self.today_str = self._today()
        print(f"[screentime] Loaded {len(self.data)} day(s) of data from {DATA_PATH}", flush=True)

        # Do an immediate window fetch
        self.update_active_window()
        print(f"[screentime] Starting — current app: {self.current_app!r}", flush=True)

        # Start socket listener thread
        t_sock = threading.Thread(target=self.socket_listener, daemon=True, name="socket")
        t_sock.start()

        # Start poll fallback thread
        t_poll = threading.Thread(target=self.poll_thread, daemon=True, name="poll")
        t_poll.start()

        # Signals for graceful shutdown
        def handle_signal(signum, frame):
            print(f"\n[screentime] Received signal {signum}, shutting down...", flush=True)
            self._running = False

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        # Run tick in main thread
        try:
            self.tick_thread()
        finally:
            # Final save on exit
            print("[screentime] Final save on shutdown...", flush=True)
            try:
                with self._lock:
                    snapshot = json.loads(json.dumps(self.data))
                atomic_save(DATA_PATH, snapshot)
                print("[screentime] Final save complete.", flush=True)
            except Exception as e:
                print(f"[screentime] Final save error: {e}", flush=True)


if __name__ == "__main__":
    daemon = ScreenTimeDaemon()
    daemon.start()
