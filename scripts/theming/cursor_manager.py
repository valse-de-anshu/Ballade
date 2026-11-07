#!/usr/bin/env python3
"""
Ballade Cursor Manager
Handles cursor inspection, high-res PNG preview extraction, custom image conversion,
composed custom themes with Xcursor inheritance, and live desktop application.
"""

import os
import sys
import json
import struct
import shutil
import argparse
import subprocess
from pathlib import Path
from PIL import Image
import numpy as np

ACTIONS = {
    'default': {
        'label': 'Normal Select',
        'desc': 'Standard pointer arrow',
        'icon': 'near_me',
        'aliases': ['default', 'arrow', 'left_ptr', 'top_left_arrow', 'right_ptr'],
        'hotspot': (0.0, 0.0)
    },
    'pointer': {
        'label': 'Link Select',
        'desc': 'Hovering over links and buttons',
        'icon': 'touch_app',
        'aliases': ['pointer', 'pointing_hand', 'hand', 'hand2', 'link', '9d8014430fc793608692d77b36a36282'],
        'hotspot': (0.2, 0.05)
    },
    'grab': {
        'label': 'Grab (Open Hand)',
        'desc': 'Ready to drag an item or canvas',
        'icon': 'pan_tool',
        'aliases': ['grab', 'openhand', 'hand1', 'pan_tool'],
        'hotspot': (0.5, 0.5)
    },
    'grabbing': {
        'label': 'Grabbing (Closed Hand)',
        'desc': 'Actively dragging an item or window',
        'icon': 'drag_pan',
        'aliases': ['grabbing', 'closedhand', 'dnd-none', 'dnd-move', 'dnd-copy', 'dnd-link', 'dnd-ask'],
        'hotspot': (0.5, 0.5)
    },
    'text': {
        'label': 'Text Select',
        'desc': 'I-Beam cursor for text editing',
        'icon': 'edit',
        'aliases': ['text', 'xterm', 'ibeam', 'vertical-text'],
        'hotspot': (0.5, 0.5)
    },
    'move': {
        'label': 'Move / Scroll',
        'desc': 'Moving windows or 4-way scrolling',
        'icon': 'open_with',
        'aliases': ['move', 'all-scroll', 'fleur', 'all-resize', 'size_all', '4498f0e0c1937ffe01f96f7836b01145', '908011447fc01e81120240800b80110e'],
        'hotspot': (0.5, 0.5)
    },
    'crosshair': {
        'label': 'Crosshair',
        'desc': 'Precision targeting and sniping',
        'icon': 'control_camera',
        'aliases': ['crosshair', 'cross', 'target', 'tcross', 'diamond_cross', 'cross_reverse', 'precision'],
        'hotspot': (0.5, 0.5)
    },
    'not-allowed': {
        'label': 'Unavailable',
        'desc': 'Action is forbidden or unavailable',
        'icon': 'block',
        'aliases': ['not-allowed', 'crossed_circle', 'forbidden', 'circle', 'no-drop', '03b6e0fcb3499374a867c041f52298f0'],
        'hotspot': (0.5, 0.5)
    },
    'help': {
        'label': 'Help / Question',
        'desc': 'Context help and tooltips',
        'icon': 'help',
        'aliases': ['help', 'question_arrow', 'whats_this', 'd9ce0ab605698f320427677b458ad60b', '5c6cd98b3f3ebcb01f17d52e08010f1a'],
        'hotspot': (0.0, 0.0)
    },
    'wait': {
        'label': 'Busy / Waiting',
        'desc': 'Application is busy processing',
        'icon': 'hourglass_empty',
        'aliases': ['wait', 'watch', '0426c80cad930e3e80a9e2f700b64f78'],
        'hotspot': (0.5, 0.5)
    },
    'progress': {
        'label': 'Working in Background',
        'desc': 'Busy while remaining interactive',
        'icon': 'hourglass_top',
        'aliases': ['progress', 'left_ptr_watch', 'half-busy', '00000000000000020006000e7e800403', '3ecb610c1bf2410f44200f48c40d3599'],
        'hotspot': (0.0, 0.0)
    },
    'ew-resize': {
        'label': 'Horizontal Resize',
        'desc': 'Resizing borders left and right',
        'icon': 'swap_horiz',
        'aliases': ['ew-resize', 'col-resize', 'h_double_arrow', 'size_hor', 'w-resize', 'e-resize', 'right_side', 'left_side', 'sb_h_double_arrow', '028006030e0e7ebffc7f7070c0600140', '14fef782d02440884392942c11205230'],
        'hotspot': (0.5, 0.5)
    },
    'ns-resize': {
        'label': 'Vertical Resize',
        'desc': 'Resizing borders top and bottom',
        'icon': 'swap_vert',
        'aliases': ['ns-resize', 'row-resize', 'v_double_arrow', 'size_ver', 'n-resize', 's-resize', 'top_side', 'bottom_side', 'sb_v_double_arrow', '00008160000006810000408080010102', '2870a09082c103050810ffdffffe0204'],
        'hotspot': (0.5, 0.5)
    },
    'nwse-resize': {
        'label': 'Diagonal Resize 1',
        'desc': 'Resizing top-left / bottom-right',
        'icon': 'north_west',
        'aliases': ['nwse-resize', 'size_fdiag', 'bd_double_arrow', 'top_left_corner', 'bottom_right_corner', 'nw-resize', 'se-resize', 'c7088f0f3e6c8088236ef8e1e3e70000', '38c9d0d2e642866164250b0d04060a41'],
        'hotspot': (0.5, 0.5)
    },
    'nesw-resize': {
        'label': 'Diagonal Resize 2',
        'desc': 'Resizing top-right / bottom-left',
        'icon': 'north_east',
        'aliases': ['nesw-resize', 'size_bdiag', 'fd_double_arrow', 'top_right_corner', 'bottom_left_corner', 'ne-resize', 'sw-resize', 'fcf1c3c7cd4491d801f1e1c78f100000', '50585d75b494802d0151028115016902'],
        'hotspot': (0.5, 0.5)
    },
    'zoom-in': {
        'label': 'Zoom In',
        'desc': 'Zooming into content',
        'icon': 'zoom_in',
        'aliases': ['zoom-in', 'zoom_in'],
        'hotspot': (0.35, 0.35)
    },
    'zoom-out': {
        'label': 'Zoom Out',
        'desc': 'Zooming out of content',
        'icon': 'zoom_out',
        'aliases': ['zoom-out', 'zoom_out'],
        'hotspot': (0.35, 0.35)
    }
}

SEARCH_PATHS = [
    os.path.expanduser('~/.icons'),
    os.path.expanduser('~/.local/share/icons'),
    '/usr/share/icons'
]

CACHE_DIR = os.path.expanduser('~/.cache/ballade/cursor_previews')
CUSTOM_CURSORS_DIR = os.path.expanduser('~/.cache/ballade/custom_cursors')
CUSTOM_THEME_DIR = os.path.expanduser('~/.icons/Ballade-Custom')


def find_theme_cursors_dir(theme_name):
    """Finds the 'cursors' folder for a given theme name."""
    for base in SEARCH_PATHS:
        p = os.path.join(base, theme_name, 'cursors')
        if os.path.isdir(p):
            return p
    return None


def get_installed_themes():
    """Lists all valid cursor themes found on the system, deduplicated by realpath."""
    found = {}
    for base in SEARCH_PATHS:
        if not os.path.isdir(base):
            continue
        try:
            for entry in os.listdir(base):
                if entry in ('default', 'hicolor', 'Ballade-Custom'):
                    continue
                full = os.path.join(base, entry, 'cursors')
                if os.path.isdir(full):
                    rp = os.path.realpath(os.path.join(base, entry))
                    # Prefer cleaner/shorter name if realpath is already recorded
                    if rp not in found or len(entry) < len(found[rp]):
                        found[rp] = entry
        except OSError:
            pass
    return sorted(list(found.values()))


def extract_cursor_frame_to_png(xcursor_path, png_out_path, target_size=48):
    """
    Parses Xcursor binary, .cur, or .ani, selects the sharpest image chunk closest to target_size,
    un-premultiplies alpha, and writes a crisp high-res PNG.
    """
    try:
        with open(xcursor_path, 'rb') as f:
            magic = f.read(4)
            if magic != b'Xcur':
                # Might be an .ani, .cur, or standard image file
                f.seek(0)
                data = f.read()
                if data[:4] == b'RIFF' and data[8:12] == b'ACON':
                    frames = parse_cur_or_ani_data(data)
                    if frames:
                        os.makedirs(os.path.dirname(png_out_path), exist_ok=True)
                        frames[0][0].save(png_out_path, 'PNG')
                        return True
                elif data[:4] == b'\x00\x00\x02\x00':
                    frames = parse_cur_or_ani_data(data)
                    if frames:
                        os.makedirs(os.path.dirname(png_out_path), exist_ok=True)
                        frames[0][0].save(png_out_path, 'PNG')
                        return True
                try:
                    f.seek(0)
                    im = Image.open(f).convert('RGBA')
                    os.makedirs(os.path.dirname(png_out_path), exist_ok=True)
                    im.save(png_out_path, 'PNG')
                    return True
                except Exception:
                    return False

            header = f.read(12)
            _, _, ntoc = struct.unpack('<III', header)
            best_chunk = None
            best_diff = 999999

            for _ in range(ntoc):
                t_type, subtype, t_pos = struct.unpack('<III', f.read(12))
                if t_type == 0xfffd0002:  # XCURSOR_IMAGE_TYPE
                    diff = abs(subtype - target_size)
                    # Severely penalize tiny thumbnail sizes (<24px) when a larger size exists
                    if subtype < 24 and target_size >= 24:
                        diff += 100
                    if diff < best_diff:
                        best_diff = diff
                        best_chunk = (t_pos, subtype)

            if not best_chunk:
                return False

            f.seek(best_chunk[0])
            img_h = f.read(36)
            _, _, _, _, w, h, _, _, _ = struct.unpack('<IIIIIIIII', img_h)
            raw = f.read(w * h * 4)
            if len(raw) != w * h * 4:
                return False

            # Un-premultiply alpha so semi-transparent edges don't show dark fringes
            arr = np.frombuffer(raw, dtype=np.uint8).reshape((h, w, 4)).copy()
            b = arr[:, :, 0].astype(np.float32)
            g = arr[:, :, 1].astype(np.float32)
            r = arr[:, :, 2].astype(np.float32)
            a = arr[:, :, 3].astype(np.float32)

            mask = a > 0
            r[mask] = np.clip((r[mask] * 255.0) / a[mask], 0, 255)
            g[mask] = np.clip((g[mask] * 255.0) / a[mask], 0, 255)
            b[mask] = np.clip((b[mask] * 255.0) / a[mask], 0, 255)

            rgba = np.stack([r, g, b, a], axis=-1).astype(np.uint8)
            im = Image.fromarray(rgba, 'RGBA')
            os.makedirs(os.path.dirname(png_out_path), exist_ok=True)
            im.save(png_out_path, 'PNG')
            return True
    except Exception as e:
        print(f"Error extracting cursor frame {xcursor_path}: {e}", file=sys.stderr)
        return False


INF_ACTION_MAP = {
    'pointer': 'default',
    'arrow': 'default',
    'link': 'pointer',
    'hand': 'zoom-in',
    'working': 'progress',
    'busy': 'wait',
    'wait': 'wait',
    'precision': 'crosshair',
    'cross': 'crosshair',
    'text': 'text',
    'ibeam': 'text',
    'move': 'move',
    'sizeall': 'move',
    'help': 'help',
    'unavailable': 'not-allowed',
    'no': 'not-allowed',
    'horz': 'ew-resize',
    'sizewe': 'ew-resize',
    'horizontal': 'ew-resize',
    'vert': 'ns-resize',
    'sizens': 'ns-resize',
    'vertical': 'ns-resize',
    'dgn1': 'nwse-resize',
    'sizenwse': 'nwse-resize',
    'diagonal1': 'nwse-resize',
    'dgn2': 'nesw-resize',
    'sizenesw': 'nesw-resize',
    'diagonal2': 'nesw-resize',
    'alternate': 'grab',
    'pin': 'grabbing',
    'person': 'zoom-out'
}


def decode_cur_icon_bytes(icon_bytes):
    """
    Decodes Windows .cur / .ico bytes into a PIL.Image RGBA with AND mask transparency
    properly applied to eliminate black backgrounds.
    """
    import io
    try:
        im = Image.open(io.BytesIO(icon_bytes))
    except Exception:
        return None, 0, 0

    xhot, yhot = 0, 0
    if len(icon_bytes) > 14 and icon_bytes[2:4] == b'\x02\x00':
        xhot, yhot = struct.unpack('<HH', icon_bytes[10:14])

    im_rgba = im.convert('RGBA')
    arr = np.array(im_rgba)

    # If alpha is completely opaque (255), decode the 1-bit AND mask from the DIB
    if np.all(arr[:, :, 3] == 255):
        try:
            offset = 0
            if len(icon_bytes) > 22 and icon_bytes[:4] in (b'\x00\x00\x01\x00', b'\x00\x00\x02\x00'):
                offset = struct.unpack('<I', icon_bytes[18:22])[0]

            dib = icon_bytes[offset:]
            if len(dib) >= 40:
                biSize, biWidth, biHeight, biPlanes, biBitCount, biCompression = struct.unpack('<IIIHHH', dib[:18])
                real_h = biHeight // 2 if biHeight > biWidth else biHeight
                w = biWidth

                if real_h == arr.shape[0] and w == arr.shape[1] and biBitCount in (1, 4, 8):
                    pal_colors = 1 << biBitCount
                    pal_size = pal_colors * 4
                    xor_offset = biSize + pal_size
                    xor_stride = ((w * biBitCount + 31) // 32) * 4
                    and_offset = xor_offset + (xor_stride * real_h)
                    and_stride = ((w + 31) // 32) * 4

                    if len(dib) >= and_offset + (and_stride * real_h):
                        for y in range(real_h):
                            row_start = and_offset + (real_h - 1 - y) * and_stride
                            row_bytes = dib[row_start:row_start + and_stride]
                            bits = ''.join(f'{b:08b}' for b in row_bytes)[:w]
                            for x in range(w):
                                if bits[x] == '1':
                                    arr[y, x, 3] = 0
                        im_rgba = Image.fromarray(arr, 'RGBA')
        except Exception:
            pass

    return im_rgba, xhot, yhot


def parse_cur_or_ani_data(data):
    """Parses binary data of Windows .ani or .cur file into [(PIL.Image, xhot, yhot, delay_ms)]."""
    import io
    if data[:4] == b'RIFF' and data[8:12] == b'ACON':
        pos = data.find(b'anih')
        if pos == -1:
            return []
        size = struct.unpack('<I', data[pos+4:pos+8])[0]
        anih = data[pos+8:pos+8+size]
        n_frames, n_steps, width, height, bpp, planes, jif_rate, flags = struct.unpack('<IIIIIIII', anih[4:36])
        delay_ms = max(16, int(round(jif_rate * 1000.0 / 60.0))) if jif_rate else 60

        frames = []
        idx = 0
        while True:
            icon_pos = data.find(b'icon', idx)
            if icon_pos == -1:
                break
            i_size = struct.unpack('<I', data[icon_pos+4:icon_pos+8])[0]
            icon_bytes = data[icon_pos+8:icon_pos+8+i_size]

            im_rgba, xhot, yhot = decode_cur_icon_bytes(icon_bytes)
            if im_rgba:
                frames.append((im_rgba, xhot, yhot, delay_ms))
            idx = icon_pos + 8 + i_size
        return frames
    elif data[:4] == b'\x00\x00\x02\x00':
        im_rgba, xhot, yhot = decode_cur_icon_bytes(data)
        if im_rgba:
            return [(im_rgba, xhot, yhot, 50)]
        return []
    else:
        try:
            im = Image.open(io.BytesIO(data)).convert('RGBA')
            return [(im, 0, 0, 50)]
        except Exception:
            return []


def parse_cur_or_ani(file_path):
    with open(file_path, 'rb') as f:
        return parse_cur_or_ani_data(f.read())


def write_multi_frame_xcursor(frames, out_path, sizes=None):
    """
    Writes an Xcursor binary containing multi-resolution frames (24, 32, 48, 64px)
    and animation delays, allowing Hyprland to smoothly scale the cursor up/down.
    """
    if not frames:
        return False

    if sizes is None:
        sizes = [24, 32, 48, 64]

    orig_w, orig_h = frames[0][0].size
    total_entries = len(sizes) * len(frames)
    toc_entries = []
    chunks = []
    header_size = 16
    toc_size = total_entries * 12
    current_offset = header_size + toc_size

    for sz in sizes:
        scale_x = sz / float(orig_w) if orig_w > 0 else 1.0
        scale_y = sz / float(orig_h) if orig_h > 0 else 1.0

        for im, xhot, yhot, delay in frames:
            resized = im.resize((sz, sz), Image.Resampling.LANCZOS)
            sxhot = max(0, min(sz - 1, int(round(xhot * scale_x))))
            syhot = max(0, min(sz - 1, int(round(yhot * scale_y))))

            arr = np.array(resized, dtype=np.float32)
            r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
            alpha = a / 255.0
            r_pre = np.clip(r * alpha, 0, 255).astype(np.uint8)
            g_pre = np.clip(g * alpha, 0, 255).astype(np.uint8)
            b_pre = np.clip(b * alpha, 0, 255).astype(np.uint8)
            a_u8 = a.astype(np.uint8)
            bgra = np.stack([b_pre, g_pre, r_pre, a_u8], axis=-1).tobytes()

            chunk_header = struct.pack('<IIIIIIIII', 36, 0xfffd0002, sz, 1, sz, sz, sxhot, syhot, delay)
            chunk_data = chunk_header + bgra

            toc_entries.append(struct.pack('<III', 0xfffd0002, sz, current_offset))
            chunks.append(chunk_data)
            current_offset += len(chunk_data)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        f.write(struct.pack('<IIII', 0x72756358, 16, 1, total_entries))
        for t in toc_entries:
            f.write(t)
        for c in chunks:
            f.write(c)
    return True


def import_windows_pack(src_path, theme_name=None):
    """
    Imports a Windows cursor pack directory (containing .ani, .cur, and/or install.inf)
    into ~/.icons/<theme_name>/ as a full native Linux Xcursor theme.
    """
    import re
    src_path = os.path.expanduser(src_path)
    if os.path.isfile(src_path):
        src_dir = os.path.dirname(src_path)
    else:
        src_dir = src_path

    if not os.path.isdir(src_dir):
        return None

    # Determine theme name if not provided
    if not theme_name:
        # Check install.inf for SCHEME_NAME
        inf_path = os.path.join(src_dir, 'install.inf')
        if os.path.exists(inf_path):
            with open(inf_path, 'r', errors='ignore') as f:
                for line in f:
                    m = re.match(r'SCHEME_NAME\s*=\s*\"?([^\"]+)\"?', line.strip(), re.IGNORECASE)
                    if m:
                        theme_name = m.group(1).strip().replace(' ', '-')
                        break
        if not theme_name:
            theme_name = os.path.basename(os.path.normpath(src_dir))

    dest_theme = os.path.expanduser(f'~/.icons/{theme_name}')
    cursors_dest = os.path.join(dest_theme, 'cursors')
    os.makedirs(cursors_dest, exist_ok=True)

    # Read install.inf if present
    mapping = {}
    inf_path = os.path.join(src_dir, 'install.inf')
    if os.path.exists(inf_path):
        with open(inf_path, 'r', errors='ignore') as f:
            for line in f:
                m = re.match(r'([a-zA-Z0-9_]+)\s*=\s*\"?([^\"]+)\"?', line.strip())
                if m:
                    k = m.group(1).lower()
                    v = m.group(2).strip()
                    if k in INF_ACTION_MAP:
                        mapping[INF_ACTION_MAP[k]] = v

    # Also scan directory for .ani / .cur files directly
    for f in os.listdir(src_dir):
        base, ext = os.path.splitext(f)
        b_low = base.lower()
        if ext.lower() in ('.ani', '.cur'):
            if b_low in INF_ACTION_MAP and INF_ACTION_MAP[b_low] not in mapping:
                mapping[INF_ACTION_MAP[b_low]] = f

    if not mapping:
        return None

    for action, filename in mapping.items():
        src_file = os.path.join(src_dir, filename)
        if not os.path.exists(src_file):
            continue
        frames = parse_cur_or_ani(src_file)
        if not frames:
            continue
        primary_file = os.path.join(cursors_dest, action)
        write_multi_frame_xcursor(frames, primary_file)

        # Link aliases
        aliases = ACTIONS.get(action, {}).get('aliases', [])
        for alias in aliases:
            if alias != action:
                dst = os.path.join(cursors_dest, alias)
                if os.path.exists(dst) or os.path.islink(dst):
                    try:
                        os.remove(dst)
                    except OSError:
                        pass
                try:
                    os.symlink(action, dst)
                except OSError:
                    pass

    # index.theme
    with open(os.path.join(dest_theme, 'index.theme'), 'w') as f:
        f.write('[Icon Theme]\n')
        f.write(f'Name={theme_name}\n')
        f.write(f'Comment={theme_name} cursor theme converted from Windows pack\n')
        f.write('Inherits=Gloomi_x\n')

    # Ensure previews are generated
    ensure_theme_previews(theme_name, force=True)
    return theme_name


def create_xcursor_from_image(input_path, output_xcursor_path, action_key='default'):
    """
    Converts any image (PNG, SVG, JPG, WebP) into an Xcursor binary with multiple
    nominal sizes (24, 32, 48, 64) and calculated hotspots.
    If input_path is already an Xcursor binary, copies it directly.
    """
    input_path = os.path.expanduser(input_path)
    if not os.path.exists(input_path):
        return False

    # Check if input is already an Xcursor binary
    try:
        with open(input_path, 'rb') as f:
            magic4 = f.read(4)
            if magic4 == b'Xcur':
                os.makedirs(os.path.dirname(output_xcursor_path), exist_ok=True)
                shutil.copyfile(input_path, output_xcursor_path)
                return True
            elif magic4 == b'RIFF' or magic4 == b'\x00\x00\x02\x00':
                frames = parse_cur_or_ani(input_path)
                if frames:
                    return write_multi_frame_xcursor(frames, output_xcursor_path)
    except Exception:
        pass

    # Open image with Pillow
    try:
        im = Image.open(input_path).convert('RGBA')
    except Exception as e:
        print(f"Error opening image {input_path}: {e}", file=sys.stderr)
        return False

    info = ACTIONS.get(action_key, {})
    hx_ratio, hy_ratio = info.get('hotspot', (0.0, 0.0))

    sizes = [24, 32, 48, 64]
    toc_entries = []
    chunks = []
    header_size = 16
    toc_size = len(sizes) * 12
    current_offset = header_size + toc_size

    for sz in sizes:
        resized = im.resize((sz, sz), Image.Resampling.LANCZOS)
        scaled_xhot = max(0, min(sz - 1, int(round(hx_ratio * sz))))
        scaled_yhot = max(0, min(sz - 1, int(round(hy_ratio * sz))))

        # Premultiplied BGRA bytes for Xcursor
        arr = np.array(resized, dtype=np.float32)
        r = arr[:, :, 0]
        g = arr[:, :, 1]
        b = arr[:, :, 2]
        a = arr[:, :, 3]

        alpha_factor = a / 255.0
        r_pre = np.clip(r * alpha_factor, 0, 255).astype(np.uint8)
        g_pre = np.clip(g * alpha_factor, 0, 255).astype(np.uint8)
        b_pre = np.clip(b * alpha_factor, 0, 255).astype(np.uint8)
        a_u8 = a.astype(np.uint8)

        bgra = np.stack([b_pre, g_pre, r_pre, a_u8], axis=-1).tobytes()

        chunk_header = struct.pack('<IIIIIIIII', 36, 0xfffd0002, sz, 1, sz, sz, scaled_xhot, scaled_yhot, 50)
        chunk_data = chunk_header + bgra

        toc_entries.append(struct.pack('<III', 0xfffd0002, sz, current_offset))
        chunks.append(chunk_data)
        current_offset += len(chunk_data)

    header = struct.pack('<IIII', 0x72756358, 16, 1, len(sizes))
    os.makedirs(os.path.dirname(output_xcursor_path), exist_ok=True)
    with open(output_xcursor_path, 'wb') as f:
        f.write(header)
        for t in toc_entries:
            f.write(t)
        for c in chunks:
            f.write(c)

    return True


def ensure_theme_previews(theme_name, force=False):
    """Generates crisp 48px PNG previews for all 17 actions of a theme."""
    cur_dir = find_theme_cursors_dir(theme_name)
    if not cur_dir:
        return {}
    out_dir = os.path.join(CACHE_DIR, theme_name)
    os.makedirs(out_dir, exist_ok=True)

    result = {}
    for action_key, info in ACTIONS.items():
        png_path = os.path.join(out_dir, f'{action_key}.png')
        if not force and os.path.exists(png_path) and os.path.getsize(png_path) > 0:
            result[action_key] = png_path
            continue

        for alias in info['aliases']:
            candidate = os.path.join(cur_dir, alias)
            if os.path.exists(candidate):
                if extract_cursor_frame_to_png(candidate, png_path, target_size=48):
                    result[action_key] = png_path
                    break
    return result


def ensure_all_previews(force=False):
    """Generates previews for all installed themes."""
    for theme in get_installed_themes():
        ensure_theme_previews(theme, force=force)


def build_and_apply_custom_theme(base_theme, size=24, overrides=None):
    """
    Constructs ~/.icons/Ballade-Custom inheriting from base_theme
    with symlinks for overridden actions (from themes or custom disk files),
    and applies it live.
    """
    if overrides is None:
        overrides = {}

    script_dir = os.path.dirname(os.path.abspath(__file__))
    set_script = os.path.join(script_dir, 'set-cursor-theme.sh')
    installed = get_installed_themes()

    clean_overrides = {}
    for k, v in overrides.items():
        if not v or v == 'Default':
            continue
        # If it's a theme:action override matching base_theme's own action (e.g. Shorekeeper:pointer when base is Shorekeeper)
        if v == base_theme or v == f"{base_theme}:{k}":
            continue
        # Check theme:action syntax (e.g. "Shorekeeper:crosshair")
        if ':' in v and not v.startswith('file://'):
            t_name = v.split(':', 1)[0]
            if t_name in installed:
                clean_overrides[k] = v
                continue
        # Allow installed themes, or direct file paths (starting with / or file://)
        if v in installed or v.startswith('/') or v.startswith('file://') or os.path.exists(os.path.expanduser(v.replace('file://', ''))):
            clean_overrides[k] = v

    if not clean_overrides:
        # No overrides -> use base theme directly
        if os.path.exists(CUSTOM_THEME_DIR):
            shutil.rmtree(CUSTOM_THEME_DIR, ignore_errors=True)
        subprocess.run(['bash', set_script, base_theme, str(size)], check=False)
        return {
            'active_theme': base_theme,
            'is_custom': False,
            'overrides_count': 0
        }

    # Overrides active -> build Ballade-Custom
    cursors_dir = os.path.join(CUSTOM_THEME_DIR, 'cursors')
    if os.path.exists(CUSTOM_THEME_DIR):
        shutil.rmtree(CUSTOM_THEME_DIR, ignore_errors=True)
    os.makedirs(cursors_dir, exist_ok=True)
    os.makedirs(CUSTOM_CURSORS_DIR, exist_ok=True)

    # 1. Populate ALL cursors from base theme first, so Ballade-Custom is a 100% complete theme!
    src_base_dir = find_theme_cursors_dir(base_theme)
    if not src_base_dir:
        src_base_dir = find_theme_cursors_dir('Gloomi_x') or find_theme_cursors_dir('Adwaita')

    if src_base_dir and os.path.isdir(src_base_dir):
        for entry in os.listdir(src_base_dir):
            src_entry = os.path.join(src_base_dir, entry)
            dst_entry = os.path.join(cursors_dir, entry)
            try:
                real_target = os.path.realpath(src_entry)
                if os.path.exists(real_target):
                    os.symlink(real_target, dst_entry)
            except OSError:
                pass

    # index.theme with inheritance
    index_path = os.path.join(CUSTOM_THEME_DIR, 'index.theme')
    with open(index_path, 'w') as f:
        f.write('[Icon Theme]\n')
        f.write('Name=Ballade-Custom\n')
        f.write('Comment=Custom composed cursor theme with per-action overrides\n')
        f.write(f'Inherits={base_theme}\n')

    # Apply overridden files
    for action_key, source in clean_overrides.items():
        info = ACTIONS.get(action_key, {})
        aliases = list(set(info.get('aliases', []) + [action_key]))

        if source.startswith('/') or source.startswith('file://'):
            # Custom file from disk!
            raw_path = os.path.expanduser(source.replace('file://', ''))
            custom_xcur = os.path.join(CUSTOM_CURSORS_DIR, f"{action_key}")
            if create_xcursor_from_image(raw_path, custom_xcur, action_key):
                # Also generate preview PNG
                preview_png = os.path.join(CACHE_DIR, 'custom', f"{action_key}.png")
                extract_cursor_frame_to_png(custom_xcur, preview_png, target_size=48)
                src_file = os.path.realpath(custom_xcur)
            else:
                continue
        else:
            # Installed theme name or theme:action
            if ':' in source and not source.startswith('file://'):
                src_theme, src_action = source.split(':', 1)
            else:
                src_theme = source
                src_action = action_key

            src_dir = find_theme_cursors_dir(src_theme)
            if not src_dir:
                continue

            src_info = ACTIONS.get(src_action, {})
            src_aliases = list(set(src_info.get('aliases', []) + [src_action]))

            src_file = None
            for a in src_aliases:
                p = os.path.join(src_dir, a)
                if os.path.exists(p):
                    src_file = os.path.realpath(p)
                    break
            if not src_file:
                p = os.path.join(src_dir, src_action)
                if os.path.exists(p):
                    src_file = os.path.realpath(p)

            if not src_file:
                continue

        for a in aliases:
            dst = os.path.join(cursors_dir, a)
            if os.path.exists(dst) or os.path.islink(dst):
                try:
                    os.remove(dst)
                except OSError:
                    pass
            try:
                os.symlink(src_file, dst)
            except OSError:
                pass

    # Apply Ballade-Custom live
    subprocess.run(['bash', set_script, 'Ballade-Custom', str(size)], check=False)

    return {
        'active_theme': 'Ballade-Custom',
        'is_custom': True,
        'overrides_count': len(clean_overrides)
    }


def main():
    parser = argparse.ArgumentParser(description='Ballade Cursor Manager')
    subparsers = parser.add_subparsers(dest='command')

    # list-themes
    subparsers.add_parser('list-themes')

    # list-actions
    subparsers.add_parser('list-actions')

    # ensure-previews [theme]
    p_prev = subparsers.add_parser('ensure-previews')
    p_prev.add_argument('theme', nargs='?', default=None)
    p_prev.add_argument('--force', action='store_true', default=False)

    # apply
    p_apply = subparsers.add_parser('apply')
    p_apply.add_argument('--base', required=True)
    p_apply.add_argument('--size', type=int, default=24)
    p_apply.add_argument('--overrides', default='{}')

    # set-custom
    p_setcustom = subparsers.add_parser('set-custom')
    p_setcustom.add_argument('--action', required=True)
    p_setcustom.add_argument('--file', required=True)

    # import-pack
    p_imp = subparsers.add_parser('import-pack')
    p_imp.add_argument('path', help='Directory or install.inf file to import')
    p_imp.add_argument('--name', default=None, help='Target theme name')

    # get-manifest
    p_man = subparsers.add_parser('get-manifest')
    p_man.add_argument('--base', default=None)

    args = parser.parse_args()

    if args.command == 'import-pack':
        imported = import_windows_pack(args.path, args.name)
        if imported:
            print(json.dumps({'status': 'ok', 'theme': imported}))
        else:
            print(json.dumps({'status': 'error', 'message': 'No valid cursor files or install.inf found'}), file=sys.stderr)
            sys.exit(1)
    elif args.command == 'list-themes':
        print(json.dumps(get_installed_themes()))
    elif args.command == 'list-actions':
        action_list = []
        for k, v in ACTIONS.items():
            action_list.append({
                'key': k,
                'label': v['label'],
                'desc': v['desc'],
                'icon': v['icon'],
            })
        print(json.dumps(action_list))
    elif args.command == 'ensure-previews':
        if args.theme:
            ensure_theme_previews(args.theme, force=args.force)
            print(json.dumps({'status': 'ok', 'theme': args.theme}))
        else:
            ensure_all_previews(force=args.force)
            print(json.dumps({'status': 'ok', 'all': True}))
    elif args.command == 'set-custom':
        custom_xcur = os.path.join(CUSTOM_CURSORS_DIR, f"{args.action}")
        success = create_xcursor_from_image(args.file, custom_xcur, args.action)
        if success:
            preview_png = os.path.join(CACHE_DIR, 'custom', f"{args.action}.png")
            extract_cursor_frame_to_png(custom_xcur, preview_png, target_size=48)
            print(json.dumps({'status': 'ok', 'preview': preview_png, 'xcursor': custom_xcur}))
        else:
            print(json.dumps({'status': 'error', 'message': 'Failed to process cursor image'}), file=sys.stderr)
            sys.exit(1)
    elif args.command == 'apply':
        try:
            overrides = json.loads(args.overrides) if args.overrides else {}
        except json.JSONDecodeError:
            overrides = {}
        res = build_and_apply_custom_theme(args.base, args.size, overrides)
        print(json.dumps(res))
    elif args.command == 'get-manifest':
        themes = get_installed_themes()
        base = args.base if args.base else (themes[0] if themes else 'default')
        ensure_theme_previews(base)
        actions = []
        for k, v in ACTIONS.items():
            png = os.path.join(CACHE_DIR, base, f'{k}.png')
            actions.append({
                'key': k,
                'label': v['label'],
                'desc': v['desc'],
                'icon': v['icon'],
                'preview': png if os.path.exists(png) else ''
            })
        manifest = {
            'themes': themes,
            'base': base,
            'actions': actions
        }
        print(json.dumps(manifest))
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
