#!/usr/bin/env bash
# KDE Connect Auto-Starter & 30-Second Reconnection Watcher
# Keeps KDE Connect running in the background and in the system tray.
# Every 30 seconds, if the device is unreachable/disconnected, it refreshes
# network discovery so the phone re-pairs and reappears in the tray automatically.

# Ensure single instance of this watcher script
LOCK_FILE="/tmp/kdeconnect_watcher.lock"
if [ -e "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"

trap 'rm -f "$LOCK_FILE"; exit 0' SIGINT SIGTERM EXIT

# 1. Ensure daemon and tray indicator are running
ensure_running() {
    if ! pgrep -x kdeconnectd >/dev/null 2>&1; then
        if [ -x /usr/lib/kdeconnectd ]; then
            /usr/lib/kdeconnectd &
        elif [ -x /usr/libexec/kdeconnectd ]; then
            /usr/libexec/kdeconnectd &
        else
            kdeconnectd &
        fi
        sleep 1
    fi

    if ! pgrep -x kdeconnect-indicator >/dev/null 2>&1; then
        kdeconnect-indicator &
        sleep 1
    fi
}

ensure_running

# 2. Infinite watcher loop: checks connection every 30 seconds
while true; do
    ensure_running

    # Check if any paired device is reachable
    DEVICE_OUTPUT=$(kdeconnect-cli -l 2>/dev/null)

    if echo "$DEVICE_OUTPUT" | grep -qi "paired and reachable"; then
        # Device is connected and active
        :
    else
        # Device is disconnected or unreachable - broadcast and attempt reconnection
        kdeconnect-cli --refresh >/dev/null 2>&1
    fi

    sleep 30
done
