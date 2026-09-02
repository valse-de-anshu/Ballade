#!/usr/bin/env python3
import subprocess
import urllib.parse
import os
import sys

def get_mime_types():
    try:
        res = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True, timeout=2)
        return [line.strip() for line in res.stdout.splitlines() if line.strip()]
    except Exception:
        return []

def get_uri_list():
    try:
        res = subprocess.run(["wl-paste", "--type", "text/uri-list"], capture_output=True, text=True, timeout=2)
        return res.stdout
    except Exception:
        return ""

def get_text_plain():
    try:
        res = subprocess.run(["wl-paste", "--type", "text/plain"], capture_output=True, text=True, timeout=2)
        return res.stdout
    except Exception:
        return ""

last_signature = None

def process_clipboard():
    global last_signature
    types = get_mime_types()
    if "text/uri-list" not in types:
        return

    raw_uris = get_uri_list()
    if not raw_uris:
        return

    paths = []
    image_paths = []
    IMAGE_EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.svg', '.avif', '.tiff', '.tif'}

    for line in raw_uris.splitlines():
        line = line.strip()
        if line.startswith("file://"):
            url_path = line[7:]
            local_path = urllib.parse.unquote(url_path)
            if os.path.isfile(local_path):
                paths.append(local_path)
                ext = os.path.splitext(local_path)[1].lower()
                if ext in IMAGE_EXTS:
                    image_paths.append(local_path)

    if not image_paths:
        return

    signature = "\n".join(paths)
    if signature == last_signature:
        return

    # Check if text/plain already matches clean paths
    current_plain = get_text_plain().strip()
    if current_plain == signature.strip():
        last_signature = signature
        return

    last_signature = signature

    # 1. Format clean readable text file paths
    clean_text = "\n".join(paths)
    subprocess.run(["wl-copy", "-t", "text/plain", clean_text])

    # 2. For each image file copied, copy image data to wl-copy/cliphist
    for img_path in image_paths:
        ext = os.path.splitext(img_path)[1].lower()
        img_type = "image/png"
        if ext in ['.jpg', '.jpeg']:
            img_type = "image/jpeg"
        elif ext == '.webp':
            img_type = "image/webp"
        elif ext == '.gif':
            img_type = "image/gif"
        elif ext == '.svg':
            img_type = "image/svg+xml"

        try:
            with open(img_path, "rb") as f:
                img_data = f.read()
            subprocess.run(["wl-copy", "-t", img_type], input=img_data)
        except Exception:
            pass

def main():
    proc = subprocess.Popen(["wl-paste", "--watch", sys.executable, __file__, "--once"])
    proc.wait()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--once":
        process_clipboard()
    else:
        main()
