#!/usr/bin/env python3
"""
Lenovo Camera Hardware E-Shutter Switch Monitor
Monitors the physical camera switch state via:
 1. V4L2 hardware privacy control (V4L2_CID_PRIVACY ioctl)
 2. Device node presence (/dev/video0)
 3. VPC2004 camera_power sysfs node (if available)

Triggers immediate audio feedback and the QuickShell Feedback HUD pill.
"""

import os
import sys
import time
import struct
import fcntl
import subprocess

LOG_FILE = os.path.expanduser("~/.config/hypr/camera_switch.log")
V4L2_CID_PRIVACY = 0x009a0910
VIDIOC_G_CTRL = 0xc008561b

def log_event(msg):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{ts}] {msg}"
    print(entry, flush=True)
    try:
        with open(LOG_FILE, "a") as f:
            f.write(entry + "\n")
    except Exception:
        pass
    try:
        subprocess.run(["logger", "-t", "hypr-camera", msg], check=False)
    except Exception:
        pass

def get_camera_state():
    """
    Returns True if camera is unblocked and enabled (shutter open).
    Returns False if camera is privacy blocked, shutter closed, or disconnected.
    """
    if not os.path.exists("/dev/video0"):
        return False

    # Check V4L2 privacy control
    try:
        with open("/dev/video0", "r") as fd:
            ctrl = struct.pack("Ii", V4L2_CID_PRIVACY, 0)
            res = fcntl.ioctl(fd, VIDIOC_G_CTRL, ctrl)
            _, val = struct.unpack("Ii", res)
            if val == 1:
                return False  # Privacy shutter active = camera blocked
            return True   # Privacy 0 = camera open
    except Exception:
        pass

    # Check VPC2004 ideapad camera_power if present
    cam_power_path = "/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/camera_power"
    if os.path.exists(cam_power_path):
        try:
            with open(cam_power_path, "r") as f:
                content = f.read().strip()
                if content == "0":
                    return False
        except Exception:
            pass

    return True

def notify_state(is_enabled):
    state_str = "true" if is_enabled else "false"
    desc = "Camera Enabled (Shutter OPEN)" if is_enabled else "Camera Disabled (Shutter CLOSED)"
    log_event(desc)

    # Trigger QuickShell Feedback HUD IPC (bottom middle) which plays the default notification sound
    try:
        res = subprocess.run(
            ["qs", "-c", "ballade", "ipc", "call", "feedbackHud", "showCamera", state_str],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False
        )
        if res.returncode != 0:
            # Fallback to play-audio if quickshell IPC failed
            fallback_sound = "/usr/share/sounds/freedesktop/stereo/message.oga"
            subprocess.Popen(["paplay", fallback_sound], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log_event(f"Error calling QuickShell IPC: {e}")
        fallback_sound = "/usr/share/sounds/freedesktop/stereo/message.oga"
        subprocess.Popen(["paplay", fallback_sound], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    log_event("Camera Hardware Switch monitor started (V4L2 + Sysfs polling)")

    # Read initial state without alerting
    current_state = get_camera_state()
    log_event(f"Initial camera state: {'Enabled (Open)' if current_state else 'Disabled (Closed)'}")

    last_trigger_time = 0.0

    while True:
        try:
            time.sleep(0.2)
            new_state = get_camera_state()
            now = time.time()

            if new_state != current_state and (now - last_trigger_time) > 0.35:
                current_state = new_state
                last_trigger_time = now
                notify_state(current_state)

        except KeyboardInterrupt:
            break
        except Exception as e:
            time.sleep(0.5)

if __name__ == "__main__":
    main()
