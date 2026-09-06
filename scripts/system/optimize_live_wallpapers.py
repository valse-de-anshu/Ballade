#!/usr/bin/env python3
"""
Live Wallpaper Downscaler & Hardware Optimizer for Ballade.
Downscales 4K / 1440p / ultrawide video wallpapers to 1920x1080 (1080p).
Applies optimal H.264 High profile, faststart header for instant zero-latency loops,
strips dead audio tracks, and utilizes NVIDIA NVENC hardware encoder with libx264 fallback.
"""

import subprocess
import glob
import json
import os
import sys
import time

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers/live Wallpapers")

def probe_video(fpath):
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_streams", "-show_format", fpath
    ]
    try:
        out = subprocess.check_output(cmd).decode()
        data = json.loads(out)
        video = next((s for s in data.get("streams", []) if s.get("codec_type") == "video"), None)
        if not video:
            return None
        w = int(video.get("width", 0))
        h = int(video.get("height", 0))
        codec = video.get("codec_name", "")
        bitrate = int(data.get("format", {}).get("bit_rate", 0))
        return {"width": w, "height": h, "codec": codec, "bitrate": bitrate}
    except Exception as e:
        print(f"Error probing {fpath}: {e}")
        return None

def optimize_file(fpath, info):
    w, h = info["width"], info["height"]
    bitrate = info["bitrate"]

    # Needs optimization if resolution > 1080p or bitrate > 7000k
    needs_opt = (w > 1920 or h > 1080 or bitrate > 7500000)
    if not needs_opt:
        return False, "Already optimal (<=1080p)"

    orig_size = os.path.getsize(fpath) / (1024 * 1024)
    tmp_out = fpath + ".tmp.mp4"

    # 1080p letterbox / scale
    vf = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"

    # Try NVENC first
    cmd = [
        "ffmpeg", "-y", "-hwaccel", "cuda",
        "-i", fpath,
        "-vf", vf,
        "-c:v", "h264_nvenc", "-preset", "p4", "-cq", "26",
        "-b:v", "4500k", "-maxrate", "6000k", "-bufsize", "8000k",
        "-an", "-movflags", "+faststart",
        tmp_out
    ]

    res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if res.returncode != 0 or not os.path.exists(tmp_out) or os.path.getsize(tmp_out) == 0:
        # Fallback to software libx264
        cmd = [
            "ffmpeg", "-y",
            "-i", fpath,
            "-vf", vf,
            "-c:v", "libx264", "-preset", "fast", "-crf", "23",
            "-b:v", "4500k", "-maxrate", "6000k", "-bufsize", "8000k",
            "-an", "-movflags", "+faststart",
            tmp_out
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

    if res.returncode == 0 and os.path.exists(tmp_out) and os.path.getsize(tmp_out) > 0:
        new_size = os.path.getsize(tmp_out) / (1024 * 1024)
        os.replace(tmp_out, fpath)
        saved = orig_size - new_size
        return True, f"{w}x{h} -> 1920x1080 ({orig_size:.1f}MB -> {new_size:.1f}MB, saved {saved:.1f}MB)"
    else:
        if os.path.exists(tmp_out):
            try: os.remove(tmp_out)
            except: pass
        return False, "Encoding failed"

def main():
    files = sorted(glob.glob(os.path.join(WALLPAPER_DIR, "*/*")))
    video_files = [f for f in files if f.lower().endswith((".mp4", ".webm", ".mkv"))]

    print(f"Found {len(video_files)} live wallpapers. Checking for resolution > 1080p...")
    total_saved_mb = 0
    optimized_count = 0

    for idx, fpath in enumerate(video_files, 1):
        rel = os.path.relpath(fpath, WALLPAPER_DIR)
        info = probe_video(fpath)
        if not info:
            continue

        if info["width"] > 1920 or info["height"] > 1080 or info["bitrate"] > 7500000:
            print(f"[{idx}/{len(video_files)}] Optimizing {rel} ({info['width']}x{info['height']})...", flush=True)
            orig_sz = os.path.getsize(fpath) / (1024 * 1024)
            success, msg = optimize_file(fpath, info)
            if success:
                new_sz = os.path.getsize(fpath) / (1024 * 1024)
                total_saved_mb += (orig_sz - new_sz)
                optimized_count += 1
                print(f"  ✓ {msg}", flush=True)
            else:
                print(f"  ✗ {msg}", flush=True)
        else:
            print(f"[{idx}/{len(video_files)}] Already optimal: {rel} ({info['width']}x{info['height']})")

    print(f"\nDone! Optimized {optimized_count} live wallpapers to 1920x1080.")
    print(f"Total disk/bandwidth footprint saved: {total_saved_mb:.1f} MB.")

if __name__ == "__main__":
    main()
