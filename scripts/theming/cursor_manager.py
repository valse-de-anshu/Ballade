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
        'aliases': ['default', 'arrow', 'left_ptr', 'top_left_arrow'],
        'hotspot': (0.0, 0.0)
    },
    'pointer': {
        'label': 'Link Select',
        'desc': 'Hovering over links and buttons',
        'icon': 'touch_app',
        'aliases': ['pointer', 'pointing_hand', 'hand2', '9d8014430fc793608692d77b36a36282'],
        'hotspot': (0.2, 0.05)
    },
    'grab': {
        'label': 'Grab (Open Hand)',
        'desc': 'Ready to drag an item or canvas',
        'icon': 'pan_tool',
        'aliases': ['grab', 'openhand', 'hand1'],
        'hotspot': (0.5, 0.5)
    },
    'grabbing': {
        'label': 'Grabbing (Closed Hand)',
        'desc': 'Actively dragging an item or window',
        'icon': 'drag_pan',
        'aliases': ['grabbing', 'closedhand', 'dnd-none', 'dnd-move'],
        'hotspot': (0.5, 0.5)
    },
    'text': {
        'label': 'Text Select',
        'desc': 'I-Beam cursor for text editing',
        'icon': 'edit',
        'aliases': ['text', 'xterm', 'ibeam'],
        'hotspot': (0.5, 0.5)
    },
    'move': {
        'label': 'Move / Scroll',
        'desc': 'Moving windows or 4-way scrolling',
        'icon': 'open_with',
        'aliases': ['move', 'all-scroll', 'fleur', '4498f0e0c1937ffe01f96f7836b01145'],
        'hotspot': (0.5, 0.5)
    },
    'crosshair': {
        'label': 'Crosshair',
        'desc': 'Precision targeting and sniping',
        'icon': 'control_camera',
        'aliases': ['crosshair', 'cross', 'target'],
        'hotspot': (0.5, 0.5)
    },
    'not-allowed': {
        'label': 'Unavailable',
        'desc': 'Action is forbidden or unavailable',
        'icon': 'block',
        'aliases': ['not-allowed', 'crossed_circle', 'forbidden', 'circle'],
        'hotspot': (0.5, 0.5)
    },
    'help': {
        'label': 'Help / Question',
        'desc': 'Context help and tooltips',
        'icon': 'help',
        'aliases': ['help', 'question_arrow', 'd9ce0ab605698f320427677b458ad60b'],
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
        'aliases': ['progress', 'left_ptr_watch', '3ecb610c1bf2410f44200f48c40d3599'],
        'hotspot': (0.0, 0.0)
    },
    'ew-resize': {
        'label': 'Horizontal Resize',
        'desc': 'Resizing borders left and right',
        'icon': 'swap_horiz',
        'aliases': ['ew-resize', 'col-resize', 'h_double_arrow', 'size_hor'],
        'hotspot': (0.5, 0.5)
    },
    'ns-resize': {
        'label': 'Vertical Resize',
        'desc': 'Resizing borders top and bottom',
        'icon': 'swap_vert',
        'aliases': ['ns-resize', 'row-resize', 'v_double_arrow', 'size_ver'],
        'hotspot': (0.5, 0.5)
    },
    'nwse-resize': {
        'label': 'Diagonal Resize 1',
        'desc': 'Resizing top-left / bottom-right',
        'icon': 'north_west',
        'aliases': ['nwse-resize', 'size_fdiag', 'bd_double_arrow', 'top_left_corner'],
        'hotspot': (0.5, 0.5)
    },
    'nesw-resize': {
        'label': 'Diagonal Resize 2',
        'desc': 'Resizing top-right / bottom-left',
        'icon': 'north_east',
        'aliases': ['nesw-resize', 'size_bdiag', 'fd_double_arrow', 'top_right_corner'],
        'hotspot': (0.5, 0.5)
    },
    'zoom-in': {
        'label': 'Zoom In',
        'desc': 'Zooming into content',
        'icon': 'zoom_in',
        'aliases': ['zoom-in'],
        'hotspot': (0.35, 0.35)
    },
    'zoom-out': {
        'label': 'Zoom Out',
        'desc': 'Zooming out of content',
        'icon': 'zoom_out',
        'aliases': ['zoom-out'],
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
    Parses Xcursor binary, selects the sharpest image chunk closest to target_size,
    un-premultiplies alpha, and writes a crisp high-res PNG.
    """
    try:
        with open(xcursor_path, 'rb') as f:
            magic = f.read(4)
            if magic != b'Xcur':
                # Might be an already plain image file (e.g. user selected PNG directly)
                f.seek(0)
                try:
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
            if f.read(4) == b'Xcur':
                os.makedirs(os.path.dirname(output_xcursor_path), exist_ok=True)
                shutil.copyfile(input_path, output_xcursor_path)
                return True
    except OSError:
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
        if not v or v == 'Default' or v == base_theme:
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
        aliases = info.get('aliases', [action_key])

        if source.startswith('/') or source.startswith('file://'):
            # Custom file from disk!
            raw_path = os.path.expanduser(source.replace('file://', ''))
            custom_xcur = os.path.join(CUSTOM_CURSORS_DIR, f"{action_key}")
            if create_xcursor_from_image(raw_path, custom_xcur, action_key):
                # Also generate preview PNG
                preview_png = os.path.join(CACHE_DIR, 'custom', f"{action_key}.png")
                extract_cursor_frame_to_png(custom_xcur, preview_png, target_size=48)
                src_file = custom_xcur
            else:
                continue
        else:
            # Installed theme name
            src_dir = find_theme_cursors_dir(source)
            if not src_dir:
                continue
            src_file = None
            for a in aliases:
                p = os.path.join(src_dir, a)
                if os.path.exists(p):
                    src_file = p
                    break
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

    # get-manifest
    p_man = subparsers.add_parser('get-manifest')
    p_man.add_argument('--base', default=None)

    args = parser.parse_args()

    if args.command == 'list-themes':
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
