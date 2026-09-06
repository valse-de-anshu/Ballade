#!/usr/bin/env python3
"""
Ballade Screen Time & Daily Uptime Tracking Daemon
===================================================
Runs as a user service. Tracks the active Hyprland window in real-time
via socket2 events + 1s active tick. Accumulates per-second active used time
across reboots, restarts, and logouts.
Saves atomically every 3 seconds. Resets at midnight (24-hour cycle).
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
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
DATA_PATH = STATE_DIR / "quickshell" / "user" / "screentime.json"

# ── App Name / Icon Mapping ───────────────────────────────────────────────────
def format_app_name(app_id: str) -> str:
    if not app_id or not app_id.strip() or app_id.lower() in ("desktop", "system"):
        return "Desktop & Shell"
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
    if not app_id or not app_id.strip() or app_id.lower() in ("desktop", "system"):
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
            d = json.load(f)
            if isinstance(d, dict):
                return d
    except Exception:
        pass
    return {}


# ── Hyprland discovery & active window ────────────────────────────────────────
def get_hyprland_signature() -> str | None:
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if sig:
        return sig
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    hypr_dir = Path(xdg_runtime) / "hypr"
    if hypr_dir.exists():
        dirs = sorted(hypr_dir.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True)
        if dirs:
            return dirs[0].name
    return None


def get_socket2_path() -> str | None:
    sig = get_hyprland_signature()
    if sig:
        os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = sig
        xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        return str(Path(xdg_runtime) / "hypr" / sig / ".socket2.sock")
    return None


def is_screen_locked() -> bool:
    """Check if lockscreen is active or all monitors are DPMS off."""
    # 1. Lockscreen binary check
    try:
        res = subprocess.run(
            ["pidof", "hyprlock", "swaylock", "gtklock", "waylock"],
            capture_output=True, timeout=1
        )
        if res.returncode == 0:
            return True
    except Exception:
        pass

    # 2. Monitors DPMS off check
    try:
        res = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True, text=True, timeout=2
        )
        if res.stdout:
            monitors = json.loads(res.stdout)
            if monitors and all(m.get("dpmsStatus") is False for m in monitors):
                return True
    except Exception:
        pass

    return False


def get_active_window() -> tuple[str, str]:
    """Returns (class, title) or ('desktop', 'Desktop') if nothing focused."""
    sig = get_hyprland_signature()
    if sig:
        os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = sig

    try:
        result = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            capture_output=True, text=True, timeout=2
        )
        text = result.stdout.strip()
        if not text or text == "{}":
            return "desktop", "Desktop"
        win = json.loads(text)
        cls = (win.get("class") or win.get("initialClass") or "").strip()
        title = (win.get("title") or win.get("initialTitle") or "").strip()
        if not cls:
            return "desktop", "Desktop"
        return cls, title if title else cls
    except Exception:
        return "desktop", "Desktop"


FOCUS_EVENTS = {
    "activewindow", "activewindowv2", "windowtitle", "windowtitlev2",
    "workspace", "focusedmon", "openwindow", "closewindow"
}


# ── ScreenTime Daemon ─────────────────────────────────────────────────────────
class ScreenTimeDaemon:
    def __init__(self):
        self.data: dict = {}
        self.today_str: str = ""
        self.current_app: str = "desktop"
        self.current_title: str = "Desktop"
        self._lock = threading.Lock()
        self._running = True
        self._dirty = False
        self._last_save = 0.0

    def _today(self) -> str:
        return date.today().isoformat()

    def _ensure_today(self, today: str) -> None:
        """Make sure today's record exists without wiping existing accumulated data."""
        if today not in self.data or not isinstance(self.data[today], dict):
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
            if "totalSeconds" not in day or not isinstance(day["totalSeconds"], (int, float)):
                day["totalSeconds"] = sum(day["hourly"])

    def record_second(self) -> None:
        """Add 1 second to the day's active used time and to the currently focused app & title."""
        today = self._today()
        hour = datetime.now().hour

        with self._lock:
            # Detect midnight rollover
            if self.today_str and today != self.today_str:
                print(f"[screentime] Midnight rollover: {self.today_str} → {today}", flush=True)
                # Cap previous day at 86400 (24h)
                if self.today_str in self.data:
                    self.data[self.today_str]["totalSeconds"] = min(86400, self.data[self.today_str].get("totalSeconds", 0))
                # Re-load from disk to merge any external day records
                disk_data = load_data()
                disk_data.update(self.data)
                self.data = disk_data

            self.today_str = today
            self._ensure_today(today)

            app_id = (self.current_app or "desktop").strip().lower()
            title = (self.current_title or "").strip()

            day = self.data[today]
            # Max 24 hours (86400s) per day
            day["totalSeconds"] = min(86400, (day.get("totalSeconds") or 0) + 1)
            day["hourly"][hour] = min(3600, (day["hourly"][hour] or 0) + 1)

            # App tracking
            apps = day["apps"]
            if app_id not in apps:
                apps[app_id] = {
                    "name": format_app_name(app_id),
                    "icon": format_app_icon(app_id),
                    "seconds": 1,
                    "titles": {}
                }
            else:
                apps[app_id]["seconds"] = (apps[app_id].get("seconds") or 0) + 1

            # Window / Tab Title tracking
            if title:
                titles = apps[app_id].setdefault("titles", {})
                key = title[:140].strip()
                if key:
                    titles[key] = (titles.get(key) or 0) + 1
                    # Prune to top 60 most active titles
                    if len(titles) > 60:
                        min_key = min(titles, key=lambda k: titles[k])
                        del titles[min_key]

            self._dirty = True

    def save_if_needed(self, force: bool = False) -> None:
        now = time.monotonic()
        if (self._dirty and (now - self._last_save) >= 3.0) or (force and self._dirty):
            with self._lock:
                if not self._dirty:
                    return
                snapshot = json.loads(json.dumps(self.data))
                self._dirty = False
            try:
                atomic_save(DATA_PATH, snapshot)
                self._last_save = now
            except Exception as e:
                print(f"[screentime] Save error: {e}", flush=True)
                self._dirty = True

    def update_active_window(self) -> None:
        cls, title = get_active_window()
        self.current_app = cls
        self.current_title = title

    def socket_listener(self) -> None:
        """Hyprland socket2 real-time event listener."""
        while self._running:
            sock_path = get_socket2_path()
            if not sock_path or not Path(sock_path).exists():
                time.sleep(2)
                continue

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
                        except Exception:
                            break
            except Exception:
                pass
            if self._running:
                time.sleep(2)

    def tick_thread(self) -> None:
        """Main 1-second active tracking ticker."""
        while self._running:
            start = time.monotonic()

            if is_screen_locked():
                self.save_if_needed()
                time.sleep(1)
                continue

            # Periodic active window refresh
            self.update_active_window()
            self.record_second()
            self.save_if_needed()

            elapsed = time.monotonic() - start
            sleep_for = max(0, 1.0 - elapsed)
            time.sleep(sleep_for)

    def start(self) -> None:
        # Load existing data on startup (persists across reboots/logouts)
        self.data = load_data()
        self.today_str = self._today()
        self._ensure_today(self.today_str)
        today_secs = self.data[self.today_str].get("totalSeconds", 0)
        print(f"[screentime] Initialized. Today ({self.today_str}): {today_secs}s active already recorded.", flush=True)

        self.update_active_window()

        # Start socket listener
        t_sock = threading.Thread(target=self.socket_listener, daemon=True, name="socket")
        t_sock.start()

        # Signal handlers for clean shutdown
        def handle_signal(signum, frame):
            print(f"\n[screentime] Received signal {signum}, saving and exiting...", flush=True)
            self._running = False

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        try:
            self.tick_thread()
        finally:
            print("[screentime] Saving final snapshot...", flush=True)
            self.save_if_needed(force=True)
            print("[screentime] Shutdown complete.", flush=True)


if __name__ == "__main__":
    daemon = ScreenTimeDaemon()
    daemon.start()
