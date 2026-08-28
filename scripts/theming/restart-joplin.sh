#!/usr/bin/env bash
# ============================================================
# restart-joplin.sh
# Only restarts Joplin if it is already running.
# If Joplin is NOT running, does absolutely nothing.
# ============================================================

LOG="/tmp/joplin-restart.log"
echo "=============================="                                    >> "$LOG"
echo "[$(date)] restart-joplin.sh started"                              >> "$LOG"

# Find the bwrap parent process that wraps Joplin
# (inner /app/joplin-desktop/joplin is inside sandbox, unreachable from outside)
BWRAP_PID=$(pgrep -f "bwrap.*joplin-desktop" | head -1)

if [[ -z "$BWRAP_PID" ]]; then
    echo "[$(date)] Joplin NOT running - nothing to do"                 >> "$LOG"
    exit 0
fi

echo "[$(date)] Joplin running (bwrap PID=$BWRAP_PID) - restarting..." >> "$LOG"

# Kill bwrap parent in background so we don't block
kill -TERM "$BWRAP_PID" 2>/dev/null &
echo "[$(date)] SIGTERM sent"                                           >> "$LOG"

# Wait up to 6 seconds for full exit
for i in {1..60}; do
    if ! pgrep -f "bwrap.*joplin-desktop" > /dev/null 2>&1; then
        echo "[$(date)] Joplin exited after ${i}x100ms"                 >> "$LOG"
        break
    fi
    sleep 0.1
done

# Force kill if still alive
if pgrep -f "bwrap.*joplin-desktop" > /dev/null 2>&1; then
    echo "[$(date)] Still alive - SIGKILL"                              >> "$LOG"
    kill -KILL "$BWRAP_PID" 2>/dev/null &
    sleep 0.5
fi

sleep 0.5
echo "[$(date)] Relaunching Joplin (tray)..."                          >> "$LOG"

# Relaunch - startMinimized=true in settings.json keeps it in tray
nohup flatpak run net.cozic.joplin_desktop </dev/null >>/tmp/joplin-launch.log 2>&1 &
NEW_PID=$!
disown $NEW_PID
echo "[$(date)] Launched PID=$NEW_PID"                                 >> "$LOG"

# Confirm startup
sleep 3
RUNNING=$(pgrep -f "bwrap.*joplin-desktop" | head -1)
if [[ -n "$RUNNING" ]]; then
    echo "[$(date)] SUCCESS - bwrap PID=$RUNNING"                      >> "$LOG"
else
    echo "[$(date)] FAILED - Joplin did not start"                     >> "$LOG"
    cat /tmp/joplin-launch.log                                          >> "$LOG" 2>/dev/null
fi
echo "=============================="                                    >> "$LOG"
