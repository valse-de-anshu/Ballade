#!/usr/bin/env python3
"""
Ballade Cursor Manager
Handles cursor inspection, per-action PNG extraction, composed custom themes, and live application.
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

ACTIONS = {
    'default': {
        'label': 'Normal Select',
        'desc': 'Standard pointer arrow',
        'icon': 'near_me',
        'aliases': ['default', 'arrow', 'left_ptr', 'top_left_arrow']
    },
    'pointer': {
        'label': 'Link Select',
        'desc': 'Hovering over links and buttons',
        'icon': 'touch_app',
        'aliases': ['pointer', 'pointing_hand', 'hand2', '9d8014430fc793608692d77b36a36282']
    },
    'grab': {
        'label': 'Grab (Open Hand)',
        'desc': 'Ready to drag an item or canvas',
        'icon': 'pan_tool',
        'aliases': ['grab', 'openhand', 'hand1']
    },
    'grabbing': {
        'label': 'Grabbing (Closed Hand)',
        'desc': 'Actively dragging an item or window',
        'icon': 'drag_pan',
        'aliases': ['grabbing', 'closedhand', 'dnd-none', 'dnd-move']
    },
    'text': {
        'label': 'Text Select',
        'desc': 'I-Beam cursor for text editing',
        'icon': 'edit',
        'aliases': ['text', 'xterm', 'ibeam']
    },
    'move': {
        'label': 'Move / Scroll',
        'desc': 'Moving windows or 4-way scrolling',
        'icon': 'open_with',
        'aliases': ['move', 'all-scroll', 'fleur', '4498f0e0c1937ffe01f96f7836b01145']
    },
    'crosshair': {
        'label': 'Crosshair',
        'desc': 'Precision targeting and sniping',
        'icon': 'control_camera',
        'aliases': ['crosshair', 'cross', 'target']
    },
    'not-allowed': {
        'label': 'Unavailable',
        'desc': 'Action is forbidden or unavailable',
        'icon': 'block',
        'aliases': ['not-allowed', 'crossed_circle', 'forbidden', 'circle']
    },
    'help': {
        'label': 'Help / Question',
        'desc': 'Context help and tooltips',
        'icon': 'help',
        'aliases': ['help', 'question_arrow', 'd9ce0ab605698f320427677b458ad60b']
    },
    'wait': {
        'label': 'Busy / Waiting',
        'desc': 'Application is busy processing',
        'icon': 'hourglass_empty',
        'aliases': ['wait', 'watch', '0426c80cad930e3e80a9e2f700b64f78']
    },
    'progress': {
        'label': 'Working in Background',
        'desc': 'Busy while remaining interactive',
        'icon': 'hourglass_top',
        'aliases': ['progress', 'left_ptr_watch', '3ecb610c1bf2410f44200f48c40d3599']
    },
    'ew-resize': {
        'label': 'Horizontal Resize',
        'desc': 'Resizing borders left and right',
        'icon': 'swap_horiz',
        'aliases': ['ew-resize', 'col-resize', 'h_double_arrow', 'size_hor']
    },
    'ns-resize': {
        'label': 'Vertical Resize',
        'desc': 'Resizing borders top and bottom',
        'icon': 'swap_vert',
        'aliases': ['ns-resize', 'row-resize', 'v_double_arrow', 'size_ver']
    },
    'nwse-resize': {
        'label': 'Diagonal Resize 1',
        'desc': 'Resizing top-left / bottom-right',
        'icon': 'north_west',
        'aliases': ['nwse-resize', 'size_fdiag', 'bd_double_arrow', 'top_left_corner']
    },
    'nesw-resize': {
        'label': 'Diagonal Resize 2',
        'desc': 'Resizing top-right / bottom-left',
        'icon': 'north_east',
        'aliases': ['nesw-resize', 'size_bdiag', 'fd_double_arrow', 'top_right_corner']
    },
    'zoom-in': {
        'label': 'Zoom In',
        'desc': 'Zooming into content',
        'icon': 'zoom_in',
        'aliases': ['zoom-in']
    },
    'zoom-out': {
        'label': 'Zoom Out',
        'desc': 'Zooming out of content',
        'icon': 'zoom_out',
        'aliases': ['zoom-out']
    }
}

SEARCH_PATHS = [
    os.path.expanduser('~/.icons'),
    os.path.expanduser('~/.local/share/icons'),
    '/usr/share/icons'
]

CACHE_DIR = os.path.expanduser('~/.cache/ballade/cursor_previews')
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
                    # If this realpath already seen, prefer shorter / cleaner name (e.g. Gloomi_x over Gloomi-x-Cursor-Custom)
                    if rp not in found or len(entry) < len(found[rp]):
                        found[rp] = entry
        except OSError:
            pass
    return sorted(list(found.values()))


def extract_cursor_frame_to_png(xcursor_path, png_out_path):
    """Parses Xcursor binary and extracts the first image frame into a PNG."""
    try:
        with open(xcursor_path, 'rb') as f:
            if f.read(4) != b'Xcur':
                return False
            header = f.read(12)
            _, _, ntoc = struct.unpack('<III', header)
            for _ in range(ntoc):
                t_type, _, t_pos = struct.unpack('<III', f.read(12))
                if t_type == 0xfffd0002:  # XCURSOR_IMAGE_TYPE
                    f.seek(t_pos)
                    img_h = f.read(36)
                    _, _, _, _, w, h, _, _, _ = struct.unpack('<IIIIIIIII', img_h)
                    raw = f.read(w * h * 4)
                    im = Image.frombytes('RGBA', (w, h), raw, 'raw', 'BGRA')
                    os.makedirs(os.path.dirname(png_out_path), exist_ok=True)
                    im.save(png_out_path)
                    return True
    except Exception:
        return False
    return False


def ensure_theme_previews(theme_name):
    """Generates PNG previews for all actions in a theme."""
    cur_dir = find_theme_cursors_dir(theme_name)
    if not cur_dir:
        return {}
    out_dir = os.path.join(CACHE_DIR, theme_name)
    os.makedirs(out_dir, exist_ok=True)

    result = {}
    for action_key, info in ACTIONS.items():
        png_path = os.path.join(out_dir, f'{action_key}.png')
        if os.path.exists(png_path) and os.path.getsize(png_path) > 0:
            result[action_key] = png_path
            continue

        for alias in info['aliases']:
            candidate = os.path.join(cur_dir, alias)
            if os.path.exists(candidate):
                if extract_cursor_frame_to_png(candidate, png_path):
                    result[action_key] = png_path
                    break
    return result


def ensure_all_previews():
    """Generates previews for all installed themes."""
    for theme in get_installed_themes():
        ensure_theme_previews(theme)


def build_and_apply_custom_theme(base_theme, size=24, overrides=None):
    """
    Constructs ~/.icons/Ballade-Custom inheriting from base_theme
    with symlinks for overridden actions, and applies it live.
    """
    if overrides is None:
        overrides = {}

    script_dir = os.path.dirname(os.path.abspath(__file__))
    set_script = os.path.join(script_dir, 'set-cursor-theme.sh')

    # Filter out empty or self-overrides
    clean_overrides = {
        k: v for k, v in overrides.items()
        if v and v != 'Default' and v != base_theme and v in get_installed_themes()
    }

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

    # index.theme
    index_path = os.path.join(CUSTOM_THEME_DIR, 'index.theme')
    with open(index_path, 'w') as f:
        f.write('[Icon Theme]\n')
        f.write('Name=Ballade-Custom\n')
        f.write('Comment=Custom composed cursor theme with per-action overrides\n')
        f.write(f'Inherits={base_theme}\n')

    # Symlink overridden files
    for action_key, source_theme in clean_overrides.items():
        src_dir = find_theme_cursors_dir(source_theme)
        if not src_dir:
            continue
        info = ACTIONS.get(action_key, {})
        aliases = info.get('aliases', [action_key])

        # Find primary source file
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

    # Apply Ballade-Custom
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

    # apply
    p_apply = subparsers.add_parser('apply')
    p_apply.add_argument('--base', required=True)
    p_apply.add_argument('--size', type=int, default=24)
    p_apply.add_argument('--overrides', default='{}')

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
            ensure_theme_previews(args.theme)
            print(json.dumps({'status': 'ok', 'theme': args.theme}))
        else:
            ensure_all_previews()
            print(json.dumps({'status': 'ok', 'all': True}))
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
