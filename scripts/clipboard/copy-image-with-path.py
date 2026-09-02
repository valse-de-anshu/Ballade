#!/usr/bin/env python3
"""
copy-image-with-path.py  <image-file-path>

Copies an image file to the Wayland clipboard offering BOTH:
  - image/png (or appropriate image type) — for pasting into image apps
  - text/plain  — the readable file path string

Uses wl-copy under the hood via two subprocess calls with --paste-once
so cliphist picks up both in order (text first, then image on top).
"""

import subprocess
import sys
import os

def copy_image_with_path(img_path: str):
    if not os.path.isfile(img_path):
        print(f"[copy-image-with-path] File not found: {img_path}", file=sys.stderr)
        sys.exit(1)

    ext = os.path.splitext(img_path)[1].lower()
    mime_map = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
        ".gif": "image/gif",
        ".bmp": "image/bmp",
        ".svg": "image/svg+xml",
    }
    img_type = mime_map.get(ext, "image/png")

    # 1. First store text/plain path in cliphist (older entry, will stay below)
    subprocess.run(["wl-copy", "-t", "text/plain", img_path], check=True)

    # Give cliphist a tiny moment to register the text entry before image overwrites
    subprocess.run(["sleep", "0.03"])

    # 2. Then overwrite clipboard with image data (newer entry, shows on top)
    with open(img_path, "rb") as f:
        img_data = f.read()
    subprocess.run(["wl-copy", "-t", img_type], input=img_data, check=True)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <image-file-path>", file=sys.stderr)
        sys.exit(1)
    copy_image_with_path(sys.argv[1])
