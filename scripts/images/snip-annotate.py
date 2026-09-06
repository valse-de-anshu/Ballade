#!/usr/bin/env python3
"""
snip-annotate.py

Takes a screenshot of a selected region (or accepts an existing region/file),
opens it in Gwenview for annotation/editing, and monitors the file in real-time.
Whenever the image is saved in Gwenview, it automatically updates the Wayland
clipboard (both image data and file path) without duplicates.

Usage:
  snip-annotate.py                     # Prompts region selection via slurp, opens Gwenview
  snip-annotate.py --region "X,Y WxH"  # Uses specified region
  snip-annotate.py --file "/path.png"  # Uses existing screenshot file
"""

import argparse
import hashlib
import os
import subprocess
import sys
import threading
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INTERNAL_COPY_SCRIPT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "clipboard", "copy-image-with-path.py"))
if os.path.isfile(INTERNAL_COPY_SCRIPT):
    COPY_SCRIPT = INTERNAL_COPY_SCRIPT
else:
    COPY_SCRIPT = os.path.expanduser("~/.local/bin/copy-image-with-path.py")

SCREENSHOTS_DIR = os.path.expanduser("~/Pictures/Screenshots")
SLURP_ARGS = ["slurp", "-d", "-b", "00000099", "-c", "89b4faee", "-s", "00000000", "-w", "2"]


def get_file_hash(path: str) -> str:
    if not os.path.isfile(path):
        return ""
    hasher = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def copy_to_clipboard(path: str):
    if not os.path.isfile(path):
        return
    try:
        if os.path.isfile(COPY_SCRIPT):
            subprocess.run([sys.executable, COPY_SCRIPT, path], check=False)
        else:
            # Fallback direct copy: text/plain first, image/png on top
            subprocess.run(["wl-copy", "-t", "text/plain", path], check=False)
            time.sleep(0.04)
            with open(path, "rb") as f:
                img_data = f.read()
            subprocess.run(["wl-copy", "-t", "image/png"], input=img_data, check=False)
    except Exception as e:
        print(f"Clipboard copy error: {e}", file=sys.stderr)


def send_notification(title: str, message: str, icon_path: str = ""):
    cmd = ["notify-send", "-a", "Gwenview"]
    if icon_path and os.path.isfile(icon_path):
        cmd.extend(["-i", icon_path])
    else:
        cmd.extend(["-i", "image-x-generic"])
    cmd.extend([title, message])
    subprocess.run(cmd, check=False)


def capture_region(region: str) -> str:
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d_%H.%M.%S")
    save_path = os.path.join(SCREENSHOTS_DIR, f"screenshot-{timestamp}.png")

    grim_cmd = ["grim", "-g", region, save_path]
    res = subprocess.run(grim_cmd, check=False)
    if res.returncode != 0 or not os.path.isfile(save_path):
        return ""
    return save_path


def select_region() -> str:
    try:
        res = subprocess.run(SLURP_ARGS, capture_output=True, text=True, check=False)
        if res.returncode != 0:
            return ""
        return res.stdout.strip()
    except Exception:
        return ""


def main():
    parser = argparse.ArgumentParser(description="Snip and annotate with Gwenview")
    parser.add_argument("--region", type=str, help="Region geometry (X,Y WxH)")
    parser.add_argument("--file", type=str, help="Existing image file path")
    args = parser.parse_args()

    image_path = ""
    if args.file:
        image_path = os.path.abspath(args.file)
        if not os.path.isfile(image_path):
            print(f"Error: File not found: {image_path}", file=sys.stderr)
            sys.exit(1)
    else:
        region = args.region
        if not region:
            region = select_region()
            if not region:
                # User cancelled selection (e.g. pressed Escape)
                sys.exit(0)

        image_path = capture_region(region)
        if not image_path:
            print("Error: Failed to capture screenshot", file=sys.stderr)
            sys.exit(1)

    initial_hash = get_file_hash(image_path)
    last_hash = initial_hash
    was_saved = False

    # Launch Gwenview
    try:
        proc = subprocess.Popen(["gwenview", image_path])
        # Auto-trigger Annotate mode (Shift+A) once Gwenview window is active
        def auto_open_annotate():
            start_wait = time.time()
            opened = False
            while time.time() - start_wait < 3.5:
                time.sleep(0.1)
                try:
                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, check=False)
                    if "gwenview" in res.stdout.lower():
                        time.sleep(0.25)
                        for key_cmd in [
                            ["wtype", "-M", "shift", "-k", "a", "-m", "shift"],
                            ["ydotool", "key", "-d", "15", "42:1", "30:1", "30:0", "42:0"],
                        ]:
                            try:
                                r = subprocess.run(key_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                                if r.returncode == 0:
                                    opened = True
                                    break
                            except Exception:
                                pass
                        if opened:
                            break
                except Exception:
                    pass

        threading.Thread(target=auto_open_annotate, daemon=True).start()
    except FileNotFoundError:
        print("Error: gwenview is not installed", file=sys.stderr)
        copy_to_clipboard(image_path)
        sys.exit(1)

    # Monitor file for saves while Gwenview is running
    last_mtime = os.path.getmtime(image_path) if os.path.isfile(image_path) else 0

    while proc.poll() is None:
        time.sleep(0.35)
        try:
            if os.path.isfile(image_path):
                current_mtime = os.path.getmtime(image_path)
                if current_mtime != last_mtime:
                    last_mtime = current_mtime
                    current_hash = get_file_hash(image_path)
                    if current_hash and current_hash != last_hash:
                        last_hash = current_hash
                        was_saved = True
                        copy_to_clipboard(image_path)
                        send_notification(
                            "Screenshot Saved & Copied",
                            "Edited image updated in clipboard",
                            image_path,
                        )
        except Exception:
            pass

    # Final check after Gwenview closes
    if os.path.isfile(image_path):
        final_hash = get_file_hash(image_path)
        if final_hash != last_hash:
            copy_to_clipboard(image_path)
            send_notification(
                "Screenshot Saved & Copied",
                "Edited image updated in clipboard",
                image_path,
            )
        elif not was_saved:
            # Gwenview closed without saving any edits; copy original screenshot
            copy_to_clipboard(image_path)
            send_notification(
                "Screenshot Copied",
                "Image copied to clipboard",
                image_path,
            )


if __name__ == "__main__":
    main()
