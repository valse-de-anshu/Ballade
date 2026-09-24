#!/usr/bin/env python3
"""
Production Media & Image Converter and Optimizer for Ballade / Quickshell.
Supports:
- Image to Image conversions: WEBP, PNG, JPEG, PDF, AVIF, GIF, ICO, BMP, TIFF, HEIC, JXL, PSD, TGA, PPM.
- Video to GIF & Video to Video: MP4, WEBM, MKV, MOV, AVI, FLV -> GIF / MP4 / WEBM (with size limits & FPS control).
- Video to Image: Extract high quality frames from any video to PNG / JPG / WEBP / AVIF / etc.
- Frame Sequences (Animation): Compile multiple images -> MP4 Video / Animated GIF (with FPS & size limits).
- Multi-image to PDF: Merge image collections into compressed PDFs.
- Handles strict size limits (e.g. 4KB, 50KB, 200KB, 500KB, 1MB, 2MB, 5MB, 10MB, or custom user limits)
  with smart multi-pass quality optimization, color quantization, and dimension scaling.
"""

import sys
import os
import io
import argparse
import subprocess
import tempfile
import shutil
import re

from PIL import Image

VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".flv", ".wmv", ".m4v"}
MAGICK_FALLBACK_FORMATS = {"HEIC", "JXL", "PSD"}

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r'(\d+)', s)]

def is_video_file(path):
    ext = os.path.splitext(path)[1].lower()
    return ext in VIDEO_EXTS

def convert_video_to_gif(src_path, dst_path, max_bytes=0, fps=15):
    """Converts a video file to an animated GIF using FFmpeg with palettegen/paletteuse."""
    if not os.path.exists(src_path):
        return False

    stages = [
        {"fps": min(fps, 18), "scale": 720, "colors": 256},
        {"fps": min(fps, 15), "scale": 540, "colors": 192},
        {"fps": min(fps, 12), "scale": 420, "colors": 128},
        {"fps": min(fps, 10), "scale": 320, "colors": 96},
        {"fps": min(fps, 8),  "scale": 240, "colors": 64},
        {"fps": 6,            "scale": 180, "colors": 32},
    ]

    if max_bytes <= 0:
        stages = [{"fps": fps, "scale": -1, "colors": 256}]

    tmp_out = dst_path + ".tmp.gif"

    for st in stages:
        f = st["fps"]
        sc = st["scale"]
        col = st["colors"]

        if sc == -1:
            vf = f"fps={f},split[s0][s1];[s0]palettegen=max_colors={col}:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"
        else:
            vf = f"fps={f},scale='min({sc},iw)':-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors={col}:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"

        cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", src_path,
            "-vf", vf,
            tmp_out
        ]

        res = subprocess.run(cmd, capture_output=True)
        if res.returncode == 0 and os.path.exists(tmp_out):
            size = os.path.getsize(tmp_out)
            if max_bytes <= 0 or size <= max_bytes or st == stages[-1]:
                shutil.move(tmp_out, dst_path)
                return True
            try:
                os.remove(tmp_out)
            except Exception:
                pass

    if os.path.exists(tmp_out):
        shutil.move(tmp_out, dst_path)
        return True
    return False

def convert_video_to_video(src_path, dst_path, max_bytes=0, fps=0):
    """Converts/compresses a video file to MP4 with multi-stage size reduction."""
    stages = [
        {"crf": 20, "scale": None},
        {"crf": 26, "scale": 1280},
        {"crf": 32, "scale": 854},
        {"crf": 38, "scale": 640}
    ] if max_bytes > 0 else [{"crf": 20, "scale": None}]

    tmp_out = dst_path + ".tmp.mp4"
    for st in stages:
        vf_parts = []
        if fps and fps > 0:
            vf_parts.append(f"fps={fps}")
        if st["scale"]:
            vf_parts.append(f"scale='min({st['scale']},trunc(iw/2)*2)':-2")
        else:
            vf_parts.append("scale=trunc(iw/2)*2:trunc(ih/2)*2")
        vf = ",".join(vf_parts)

        cmd = [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", src_path,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-crf", str(st["crf"]),
            "-preset", "medium",
            "-vf", vf,
            "-c:a", "aac", "-b:a", "128k",
            "-movflags", "+faststart",
            tmp_out
        ]
        res = subprocess.run(cmd, capture_output=True)
        if res.returncode == 0 and os.path.exists(tmp_out):
            if max_bytes <= 0 or os.path.getsize(tmp_out) <= max_bytes or st == stages[-1]:
                shutil.move(tmp_out, dst_path)
                return True
            try:
                os.remove(tmp_out)
            except Exception:
                pass
    if os.path.exists(tmp_out):
        shutil.move(tmp_out, dst_path)
        return True
    return False

def convert_frames_to_animation(frame_paths, dst_path, target_fmt="mp4", fps=24, max_bytes=0):
    """Compiles multiple image frames into a video (MP4/WEBM) or animated GIF/WEBP."""
    if not frame_paths:
        return False

    # Sort frames naturally
    frames = sorted(frame_paths, key=natural_sort_key)

    # Create temporary directory with symlinked / numbered frames for ffmpeg
    with tempfile.TemporaryDirectory() as tmp_dir:
        for idx, src in enumerate(frames):
            ext = os.path.splitext(src)[1] or ".png"
            dest_name = os.path.join(tmp_dir, f"frame_{idx:06d}{ext}")
            try:
                os.symlink(os.path.abspath(src), dest_name)
            except Exception:
                shutil.copyfile(src, dest_name)

        input_pattern = os.path.join(tmp_dir, f"frame_%06d{os.path.splitext(frames[0])[1] or '.png'}")
        target_fmt = target_fmt.lower()

        if target_fmt in ("gif",):
            # Compile to GIF
            stages = [
                {"scale": -1, "colors": 256},
                {"scale": 640, "colors": 192},
                {"scale": 480, "colors": 128},
                {"scale": 320, "colors": 64}
            ] if max_bytes > 0 else [{"scale": -1, "colors": 256}]

            for st in stages:
                sc = st["scale"]
                col = st["colors"]
                if sc == -1:
                    vf = f"split[s0][s1];[s0]palettegen=max_colors={col}[p];[s1][p]paletteuse=dither=bayer"
                else:
                    vf = f"scale='min({sc},iw)':-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors={col}[p];[s1][p]paletteuse=dither=bayer"

                cmd = [
                    "ffmpeg", "-y", "-loglevel", "error",
                    "-framerate", str(fps),
                    "-i", input_pattern,
                    "-vf", vf,
                    dst_path
                ]
                res = subprocess.run(cmd, capture_output=True)
                if res.returncode == 0 and os.path.exists(dst_path):
                    if max_bytes <= 0 or os.path.getsize(dst_path) <= max_bytes or st == stages[-1]:
                        return True
            return os.path.exists(dst_path)

        else:
            # Compile to MP4 / Video with size limit stages
            stages = [
                {"crf": 20, "scale": None},
                {"crf": 26, "scale": 1280},
                {"crf": 32, "scale": 854},
                {"crf": 38, "scale": 640}
            ] if max_bytes > 0 else [{"crf": 20, "scale": None}]

            tmp_out = dst_path + ".tmp.mp4"
            for st in stages:
                vf = f"scale='min({st['scale']},trunc(iw/2)*2)':-2" if st["scale"] else "scale=trunc(iw/2)*2:trunc(ih/2)*2"
                cmd = [
                    "ffmpeg", "-y", "-loglevel", "error",
                    "-framerate", str(fps),
                    "-i", input_pattern,
                    "-c:v", "libx264",
                    "-pix_fmt", "yuv420p",
                    "-crf", str(st["crf"]),
                    "-preset", "medium",
                    "-vf", vf,
                    "-movflags", "+faststart",
                    tmp_out
                ]
                res = subprocess.run(cmd, capture_output=True)
                if res.returncode == 0 and os.path.exists(tmp_out):
                    if max_bytes <= 0 or os.path.getsize(tmp_out) <= max_bytes or st == stages[-1]:
                        shutil.move(tmp_out, dst_path)
                        return True
                    try:
                        os.remove(tmp_out)
                    except Exception:
                        pass
            if os.path.exists(tmp_out):
                shutil.move(tmp_out, dst_path)
                return True
            return os.path.exists(dst_path)

def convert_video_to_image(src_path, dst_path, target_fmt="png"):
    """Extracts the first frame from a video file into the target image format."""
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-ss", "00:00:00.100",
        "-i", src_path,
        "-vframes", "1",
        dst_path
    ]
    res = subprocess.run(cmd, capture_output=True)
    return res.returncode == 0 and os.path.exists(dst_path)

def convert_with_magick(src_path, dst_path, target_fmt, max_bytes=0):
    """Fallback to ImageMagick for formats like HEIC, JXL, PSD."""
    target_fmt = target_fmt.upper()
    
    if max_bytes <= 0:
        cmd = ["magick", src_path, dst_path]
        res = subprocess.run(cmd, capture_output=True)
        return res.returncode == 0 and os.path.exists(dst_path) and os.path.getsize(dst_path) > 0

    # Fast 3-stage compression check
    cmd = ["magick", src_path]
    if target_fmt in ("HEIC", "JXL"):
        cmd.extend(["-quality", "75"])
    cmd.append(dst_path)
    subprocess.run(cmd, capture_output=True)
    if os.path.exists(dst_path) and os.path.getsize(dst_path) <= max_bytes:
        return True

    cmd = ["magick", src_path, "-resize", "70%"]
    if target_fmt in ("HEIC", "JXL"):
        cmd.extend(["-quality", "50"])
    cmd.append(dst_path)
    subprocess.run(cmd, capture_output=True)
    if os.path.exists(dst_path) and os.path.getsize(dst_path) <= max_bytes:
        return True

    cmd = ["magick", src_path, "-resize", "45%"]
    if target_fmt in ("HEIC", "JXL"):
        cmd.extend(["-quality", "30"])
    cmd.append(dst_path)
    res = subprocess.run(cmd, capture_output=True)
    return res.returncode == 0 and os.path.exists(dst_path)

def optimize_single_image(src_path, dst_path, target_fmt, max_bytes=0, fps=15):
    target_fmt = target_fmt.upper()
    if target_fmt in ("JPG", "JPE"):
        target_fmt = "JPEG"

    # Check if input is a video
    if is_video_file(src_path):
        if target_fmt in ("GIF",):
            return convert_video_to_gif(src_path, dst_path, max_bytes=max_bytes, fps=fps)
        elif target_fmt in ("MP4", "WEBM", "ANIMATE"):
            return convert_video_to_video(src_path, dst_path, max_bytes=max_bytes, fps=fps)
        else:
            # Video to static image (extract frame)
            return convert_video_to_image(src_path, dst_path, target_fmt.lower())

    # If target is video format but input is single image
    if target_fmt in ("MP4", "ANIMATE"):
        return convert_frames_to_animation([src_path], dst_path, target_fmt="mp4", fps=fps, max_bytes=max_bytes)

    # Use ImageMagick for special formats
    if target_fmt in MAGICK_FALLBACK_FORMATS:
        return convert_with_magick(src_path, dst_path, target_fmt, max_bytes)

    try:
        img = Image.open(src_path)
    except Exception:
        # If Pillow cannot open (e.g. source is HEIC/PSD), try magick first to temporary png
        tmp_png = dst_path + ".tmp.png"
        res = subprocess.run(["magick", src_path, tmp_png], capture_output=True)
        if res.returncode == 0 and os.path.exists(tmp_png):
            img = Image.open(tmp_png)
            try:
                os.remove(tmp_png)
            except Exception:
                pass
        else:
            return False

    # Handle format-specific requirements
    if target_fmt == "ICO":
        if img.width > 256 or img.height > 256:
            img.thumbnail((256, 256), Image.Resampling.LANCZOS)
        if img.mode not in ("RGBA", "RGB"):
            img = img.convert("RGBA")

    elif target_fmt in ("JPEG", "BMP", "PPM", "TGA"):
        if target_fmt in ("JPEG", "BMP", "PPM") and img.mode in ("RGBA", "LA", "P"):
            bg = Image.new("RGB", img.size, (255, 255, 255))
            if img.mode == "P":
                img = img.convert("RGBA")
            bg.paste(img, mask=img.split()[-1] if len(img.split()) > 3 else None)
            img = bg
        elif img.mode != "RGB" and target_fmt in ("JPEG", "BMP", "PPM"):
            img = img.convert("RGB")

    elif target_fmt == "GIF":
        if img.mode != "P":
            img = img.convert("P", palette=Image.Palette.ADAPTIVE)

    elif target_fmt in ("WEBP", "PNG", "AVIF"):
        if img.mode not in ("RGB", "RGBA"):
            img = img.convert("RGBA")

    # If no size limit, save directly with optimal quality
    if max_bytes <= 0:
        save_kwargs = {}
        if target_fmt in ("JPEG", "WEBP", "AVIF"):
            save_kwargs["optimize"] = True
            save_kwargs["quality"] = 92
        elif target_fmt == "PNG":
            save_kwargs["optimize"] = True
        elif target_fmt == "ICO":
            save_kwargs["sizes"] = [(min(256, img.width), min(256, img.height))]

        try:
            img.save(dst_path, format=target_fmt, **save_kwargs)
            return True
        except Exception:
            return convert_with_magick(src_path, dst_path, target_fmt, max_bytes)

    # Strict size limit enforcement
    best_buf = None
    orig_w, orig_h = img.size

    for scale_pass in range(10):
        factor = (0.85) ** scale_pass
        nw = max(16, int(orig_w * factor))
        nh = max(16, int(orig_h * factor))

        cur_img = img if scale_pass == 0 else img.resize((nw, nh), Image.Resampling.LANCZOS)

        if target_fmt in ("JPEG", "WEBP", "AVIF"):
            low, high = 5, 95
            pass_best = None
            while low <= high:
                mid = (low + high) // 2
                buf = io.BytesIO()
                try:
                    cur_img.save(buf, format=target_fmt, quality=mid, optimize=True)
                    if buf.tell() <= max_bytes:
                        pass_best = buf.getvalue()
                        low = mid + 1
                    else:
                        high = mid - 1
                except Exception:
                    break
            if pass_best is not None:
                best_buf = pass_best
                break
        elif target_fmt == "GIF":
            buf = io.BytesIO()
            q_img = cur_img.convert("P", palette=Image.Palette.ADAPTIVE, colors=max(16, 256 // (scale_pass + 1)))
            q_img.save(buf, format="GIF", optimize=True)
            if buf.tell() <= max_bytes:
                best_buf = buf.getvalue()
                break
        else: # PNG, BMP, TIFF, ICO, TGA, PPM
            buf = io.BytesIO()
            cur_img.save(buf, format=target_fmt)
            if buf.tell() <= max_bytes:
                best_buf = buf.getvalue()
                break
            if target_fmt == "PNG":
                q_img = cur_img.quantize(colors=max(16, 256 // (scale_pass + 1)), method=Image.Quantize.MEDIANCUT)
                buf = io.BytesIO()
                q_img.save(buf, format="PNG", optimize=True)
                if buf.tell() <= max_bytes:
                    best_buf = buf.getvalue()
                    break

    if best_buf is None:
        buf = io.BytesIO()
        s_img = img.resize((max(16, orig_w // 4), max(16, orig_h // 4)), Image.Resampling.BOX)
        if target_fmt in ("JPEG", "WEBP", "AVIF"):
            s_img.save(buf, format=target_fmt, quality=10, optimize=True)
        else:
            s_img.save(buf, format=target_fmt)
        best_buf = buf.getvalue()

    with open(dst_path, "wb") as f:
        f.write(best_buf)
    return True

def convert_to_pdf(input_paths, output_path, max_bytes=0):
    images = []
    for p in input_paths:
        try:
            im = Image.open(p)
            if im.mode != "RGB":
                bg = Image.new("RGB", im.size, (255, 255, 255))
                if im.mode in ("RGBA", "LA"):
                    bg.paste(im, mask=im.split()[-1])
                else:
                    bg.paste(im.convert("RGB"))
                im = bg
            images.append(im)
        except Exception:
            continue

    if not images:
        return False

    first = images[0]
    rest = images[1:]

    if max_bytes <= 0:
        first.save(output_path, "PDF", save_all=True, append_images=rest, resolution=100.0)
        return True

    for scale_pass in range(6):
        factor = (0.8) ** scale_pass
        scaled_images = []
        for im in images:
            if scale_pass == 0:
                scaled_images.append(im)
            else:
                nw = max(64, int(im.width * factor))
                nh = max(64, int(im.height * factor))
                scaled_images.append(im.resize((nw, nh), Image.Resampling.BILINEAR))
        buf = io.BytesIO()
        scaled_images[0].save(buf, "PDF", save_all=True, append_images=scaled_images[1:], quality=75, optimize=True)
        if buf.tell() <= max_bytes or scale_pass == 5:
            with open(output_path, "wb") as f:
                f.write(buf.getvalue())
            return True
    return True

def main():
    parser = argparse.ArgumentParser(description="Media Converter & Compressor")
    parser.add_argument("--input", "-i", type=str, help="Input file path")
    parser.add_argument("--output", "-o", type=str, help="Output file path")
    parser.add_argument("--format", "-f", type=str, default="", help="Target format")
    parser.add_argument("--max-bytes", "-m", type=int, default=0, help="Maximum file size in bytes (0 for unlimited)")
    parser.add_argument("--fps", type=int, default=24, help="FPS for video / animation conversion")
    parser.add_argument("--pdf", type=str, help="Output PDF path for multiple inputs")
    parser.add_argument("--animate", type=str, help="Output video/animation path for multiple frame inputs")
    parser.add_argument("extra_inputs", nargs="*", help="Extra inputs for PDF or Animation conversion")

    args = parser.parse_args()

    if args.pdf:
        all_inputs = []
        if args.input:
            all_inputs.append(args.input)
        all_inputs.extend(args.extra_inputs)
        if not all_inputs:
            sys.stderr.write("No input images provided for PDF conversion.\n")
            sys.exit(1)
        success = convert_to_pdf(all_inputs, args.pdf, args.max_bytes)
        sys.exit(0 if success else 1)

    if args.animate:
        all_inputs = []
        if args.input:
            all_inputs.append(args.input)
        all_inputs.extend(args.extra_inputs)
        if not all_inputs:
            sys.stderr.write("No input frames provided for animation.\n")
            sys.exit(1)
        target_fmt = "gif" if args.animate.lower().endswith(".gif") else "mp4"
        success = convert_frames_to_animation(all_inputs, args.animate, target_fmt=target_fmt, fps=args.fps, max_bytes=args.max_bytes)
        sys.exit(0 if success else 1)

    if not args.input or not args.output:
        sys.stderr.write("Both --input and --output are required.\n")
        sys.exit(1)

    target_fmt = args.format
    if not target_fmt:
        ext = os.path.splitext(args.output)[1].lstrip(".").lower()
        target_fmt = ext if ext else "webp"

    try:
        success = optimize_single_image(args.input, args.output, target_fmt, args.max_bytes, fps=args.fps)
        sys.exit(0 if success else 1)
    except Exception as e:
        sys.stderr.write(f"Conversion error: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
