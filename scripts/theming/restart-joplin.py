#!/usr/bin/env python3
"""
restart-joplin.py
Restarts Joplin if it is already running. Does nothing if it's not.
"""

import subprocess
import time
import os
import signal
import sys

def get_bwrap_pid():
    r = subprocess.run(["pgrep", "-f", "bwrap.*joplin-desktop"],
                       capture_output=True, text=True)
    pids = r.stdout.strip().split("\n")
    return int(pids[0]) if pids[0] else None

# If Joplin is not running, do nothing
pid = get_bwrap_pid()
if not pid:
    sys.exit(0)

# Gracefully kill the bwrap parent
os.kill(pid, signal.SIGTERM)

# Wait up to 6 seconds for it to exit
for _ in range(60):
    if get_bwrap_pid() is None:
        break
    time.sleep(0.1)

# Force kill if still alive
if get_bwrap_pid() is not None:
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    time.sleep(0.5)

# Wait for singleton lock release
time.sleep(0.5)

# Relaunch fully detached (startMinimized=true in settings.json keeps it in tray)
subprocess.Popen(
    ["flatpak", "run", "net.cozic.joplin_desktop"],
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    start_new_session=True   # fully detaches from this process
)
