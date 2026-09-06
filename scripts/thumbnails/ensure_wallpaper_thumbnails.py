#!/usr/bin/env python3
"""
ensure_wallpaper_thumbnails.py
High-speed, robust thumbnail generator & cache validator for Ballade wallpapers.
Complies with Freedesktop Thumbnail Spec (URI MD5 in ~/.cache/thumbnails/x-large/).
Handles:
- Replacing files with the same name (fingerprint check via mtime:size:inode)
- Renamed, shifted, or deleted files (cleans stale cache)
- Instant fast-seeking frame capture for live video wallpapers
- Multi-threaded batch scanning for directories
"""

import os
import sys
import hashlib
import pathlib
import subprocess
import argparse
from concurrent.futures import ThreadPoolExecutor

CACHE_DIR = os.path.expanduser("~/.cache/thumbnails")
SIZE_DIMS = {
    "normal": 128,
    "large": 256,
    "x-large": 512,
    "xx-large": 1024
}

def get_thumbnail_path(file_path: str, size: str = "x-large") -> str:
    uri = pathlib.Path(file_path).resolve().as_uri()
    md5 = hashlib.md5(uri.encode("utf-8")).hexdigest()
    return os.path.join(CACHE_DIR, size, f"{md5}.png")

def get_fingerprint(file_path: str) -> str:
    try:
        st = os.stat(file_path)
        return f"{st.st_mtime_ns}:{st.st_size}:{st.st_ino}"
    except OSError:
        return ""

def is_video(path: str) -> bool:
    ext = os.path.splitext(path)[1].lower()
    return ext in [".mp4", ".webm", ".mkv", ".avi", ".mov"]

def is_image(path: str) -> bool:
    ext = os.path.splitext(path)[1].lower()
    return ext in [".png", ".jpg", ".jpeg", ".webp", ".avif", ".bmp"]

def update_thumbnail(file_path: str, size: str = "x-large") -> bool:
    file_path = os.path.abspath(file_path)
    if not os.path.exists(file_path):
        # File deleted or shifted — remove obsolete thumbnail cache
        for s in SIZE_DIMS.keys():
            t = get_thumbnail_path(file_path, s)
            meta = t + ".meta"
            for p in [t, meta]:
                if os.path.exists(p):
                    try: os.remove(p)
                    except OSError: pass
        return True

    thumb_path = get_thumbnail_path(file_path, size)
    meta_path = thumb_path + ".meta"
    current_fp = get_fingerprint(file_path)
    if not current_fp:
        return False

    # Check fingerprint against saved metadata
    if os.path.exists(thumb_path) and os.path.exists(meta_path):
        try:
            with open(meta_path, "r") as f:
                saved_fp = f.read().strip()
            if saved_fp == current_fp and os.path.getsize(thumb_path) > 0:
                return False  # Already 100% fresh and matching
        except OSError:
            pass

    os.makedirs(os.path.dirname(thumb_path), exist_ok=True)
    tmp_path = thumb_path + f".tmp.{os.getpid()}_{abs(hash(file_path))}.png"
    dim = SIZE_DIMS.get(size, 512)
    success = False

    if is_video(file_path):
        # Fast input seeking (-ss before -i) extracts frame in ~0.02s
        cmd = [
            "ffmpeg", "-y", "-nostdin", "-loglevel", "error",
            "-ss", "00:00:00.5", "-i", file_path,
            "-update", "1", "-vframes", "1", "-an", "-sn", "-threads", "2",
            "-vf", f"scale={dim}:{dim}:force_original_aspect_ratio=decrease",
            "-pix_fmt", "rgb24",
            tmp_path
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode == 0 and os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
            success = True
        else:
            # Fallback to beginning of video
            cmd_fallback = [
                "ffmpeg", "-y", "-nostdin", "-loglevel", "error",
                "-i", file_path,
                "-update", "1", "-vframes", "1", "-an", "-sn", "-threads", "2",
                "-vf", f"scale={dim}:{dim}:force_original_aspect_ratio=decrease",
                "-pix_fmt", "rgb24",
                tmp_path
            ]
            res2 = subprocess.run(cmd_fallback, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if res2.returncode == 0 and os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                success = True

    elif is_image(file_path):
        try:
            from PIL import Image
            with Image.open(file_path) as im:
                im.thumbnail((dim, dim), Image.Resampling.LANCZOS)
                if im.mode in ("RGBA", "P"):
                    im.save(tmp_path, "PNG")
                else:
                    im.convert("RGB").save(tmp_path, "PNG")
            success = True
        except Exception:
            cmd = ["magick", file_path, "-thumbnail", f"{dim}x{dim}", tmp_path]
            res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if res.returncode == 0 and os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                success = True

    if success:
        os.replace(tmp_path, thumb_path)
        try:
            with open(meta_path, "w") as f:
                f.write(current_fp)
        except OSError:
            pass
        return True
    else:
        if os.path.exists(tmp_path):
            try: os.remove(tmp_path)
            except OSError: pass
        return False

def scan_directory(dir_path: str, size: str = "x-large", workers: int = 4):
    dir_path = os.path.abspath(dir_path)
    if not os.path.isdir(dir_path):
        return
    files = []
    for item in os.listdir(dir_path):
        p = os.path.join(dir_path, item)
        if os.path.isfile(p) and (is_video(p) or is_image(p)):
            files.append(p)
    if not files:
        return
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(update_thumbnail, f, size) for f in files]
        for fut in futures:
            fut.result()

def scan_all_wallpapers(base_dir: str = None, size: str = "x-large", workers: int = 6):
    if not base_dir:
        base_dir = os.path.expanduser("~/Pictures/Wallpapers")
    if not os.path.isdir(base_dir):
        return
    files = []
    for root, dirs, filenames in os.walk(base_dir):
        for f in filenames:
            p = os.path.join(root, f)
            if is_video(p) or is_image(p):
                files.append(p)
    print(f"Ensuring thumbnails for {len(files)} files in {base_dir} (size={size})...")
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(update_thumbnail, f, size) for f in files]
        updated = sum(1 for fut in futures if fut.result())
    print(f"Thumbnail check completed. Updated/generated: {updated}/{len(files)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ensure wallpaper thumbnails")
    parser.add_argument("--single", type=str, help="Single file path to update")
    parser.add_argument("--dir", type=str, help="Directory to scan")
    parser.add_argument("--all", action="store_true", help="Scan entire ~/Pictures/Wallpapers")
    parser.add_argument("--size", type=str, default="x-large", choices=["normal", "large", "x-large", "xx-large"])
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()

    if args.single:
        changed = update_thumbnail(args.single, args.size)
        sys.exit(1 if changed else 0)
    elif args.dir:
        scan_directory(args.dir, args.size, args.workers)
    elif args.all:
        scan_all_wallpapers(size=args.size, workers=args.workers)
    else:
        scan_all_wallpapers(size=args.size, workers=args.workers)
