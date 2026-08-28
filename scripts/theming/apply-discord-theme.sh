#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
THEME_KEY="${1:-purple}"

python3 -c "
import os, sys, base64, json, re
from PIL import Image
import io

script_dir = '$SCRIPT_DIR'
config_dir = '$CONFIG_DIR'
theme_key = '$THEME_KEY'

presets_hsl = {
    'purple':    {'hue': 270, 'sat': '60%', 'light': '40%', 'hex': '#9C5ADB', 'hover': '#BA68C8'},
    'green':     {'hue': 85,  'sat': '50%', 'light': '35%', 'hex': '#7D9726', 'hover': '#93AE38'},
    'golden':    {'hue': 40,  'sat': '75%', 'light': '45%', 'hex': '#F0B849', 'hover': '#FED268'},
    'orange':    {'hue': 25,  'sat': '85%', 'light': '50%', 'hex': '#FF9248', 'hover': '#FFB480'},
    'pink':      {'hue': 330, 'sat': '50%', 'light': '48%', 'hex': '#D4659A', 'hover': '#F298C4'},
    'red':       {'hue': 358, 'sat': '55%', 'light': '40%', 'hex': '#BF3F43', 'hover': '#E55353'},
    'blue':      {'hue': 220, 'sat': '80%', 'light': '55%', 'hex': '#7AA2F7', 'hover': '#89B4FA'},
    'grayscale': {'hue': 200, 'sat': '15%', 'light': '50%', 'hex': '#88C0D0', 'hover': '#81A1C1'}
}

p = presets_hsl.get(theme_key, presets_hsl['purple'])

# Read exact active wallpaper
config_path = os.path.expanduser('~/.config/illogical-impulse/config.json')
wall_path = ''

if os.path.exists(config_path):
    try:
        with open(config_path, 'r') as f:
            cfg = json.load(f)
        wall_path = cfg.get('appearance', {}).get('wallpaperPath', '')
        if not wall_path:
            wall_path = cfg.get('background', {}).get('wallpaperPath', '')
    except Exception as e:
        print(f'Error reading config.json: {e}', file=sys.stderr)

if not wall_path or not os.path.exists(wall_path):
    wall_dir = os.path.expanduser(f'~/Pictures/Wallpapers/{theme_key}')
    if os.path.isdir(wall_dir):
        files = [os.path.join(wall_dir, f) for f in os.listdir(wall_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp'))]
        if files:
            wall_path = sorted(files)[0]

b64_uri = ''
if wall_path and os.path.exists(wall_path):
    try:
        with Image.open(wall_path) as img:
            img = img.convert('RGB')
            img.thumbnail((1600, 900), Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            img.save(buf, format='JPEG', quality=80)
            b64_str = base64.b64encode(buf.getvalue()).decode('utf-8')
            b64_uri = f'data:image/jpeg;base64,{b64_str}'
    except Exception as e:
        print(f'Error encoding image: {e}', file=sys.stderr)

template_path = os.path.expanduser('~/Downloads/DiscordPlus.theme.css')
if not os.path.exists(template_path):
    template_path = os.path.expanduser('~/.config/Vencord/themes/DiscordPlus.theme.css')
if not os.path.exists(template_path):
    repo_fallback = os.path.join(config_dir, 'dotfiles/vencord/DiscordPlus.theme.css')
    if os.path.exists(repo_fallback):
        template_path = repo_fallback

if os.path.exists(template_path):
    with open(template_path, 'r') as f:
        template = f.read()
else:
    template = \"\"\"/**
 * @name Discord+
 * @version 3.4.1
 */
@import url('https://plusinsta.github.io/discord-plus/src/DiscordPlus-source.theme.css');
.theme-dark {
  --dplus-backdrop: url('');
  --dplus-accent-color-hue: 320;
  --dplus-accent-color-saturation: 60%;
  --dplus-accent-color-lightness: 31%;
  --dplus-foreground-color-hue-base: 210;
  --dplus-foreground-color-hue-links: 197;
  --dplus-foreground-color-saturation-amount: 1;
  --dplus-foreground-color-lightness-amount: 1;
  --dplus-background-color-hue: 320;
  --dplus-background-color-saturation-amount: 1;
  --dplus-background-color-lightness-amount: 1;
  --dplus-background-color-alpha: 0.8;
}
\"\"\"

# Update backdrop
updated = re.sub(r'--dplus-backdrop:\s*url\([^)]+\);', f'--dplus-backdrop: url(\"{b64_uri}\");', template)

# Update accent HSL
updated = re.sub(r'--dplus-accent-color-hue:\s*\d+;', f'--dplus-accent-color-hue: {p[\"hue\"]};', updated)
updated = re.sub(r'--dplus-accent-color-saturation:\s*[^;]+;', f'--dplus-accent-color-saturation: {p[\"sat\"]};', updated)
updated = re.sub(r'--dplus-accent-color-lightness:\s*[^;]+;', f'--dplus-accent-color-lightness: {p[\"light\"]};', updated)
updated = re.sub(r'--dplus-background-color-hue:\s*\d+;', f'--dplus-background-color-hue: {p[\"hue\"]};', updated)

# Standardize Discord+ variables
updated = re.sub(r'--dplus-icon-avatar-chat:\s*[^;]+;', '--dplus-icon-avatar-chat: 40px;', updated)
updated = re.sub(r'--dplus-spacing-ui:\s*[^;]+;', '--dplus-spacing-ui: 4px;', updated)
updated = re.sub(r'--dplus-spacing-app:\s*[^;]+;', '--dplus-spacing-app: 4px;', updated)

# Performance & Layout Overrides
aesthetic_overrides = f'''
/* ==========================================================================
 * Clean Stock Discord Message & Avatar Layout
 * ========================================================================== */

/* 1. Fix Top-Left Server Bar Glitch (Direct Messages Icon) */
nav[class*=\"guilds\"] ul[class*=\"tree\"],
nav[class*=\"guilds\"] [class*=\"tutorialContainer\"],
nav[class*=\"guilds\"] [class*=\"unreadMentionsIndicatorTop\"],
nav[class*=\"guilds\"] [class*=\"homeIcon\"],
nav[class*=\"guilds\"] div[class*=\"listItem\"] {{
  background-color: transparent !important;
}}
nav[class*=\"guilds\"] [class*=\"tutorialContainer\"] div[class*=\"wrapper\"] {{
  background-color: rgba(255, 255, 255, 0.05) !important;
}}

/* 2. Normal Stock Discord Message Layout & Crisp Avatars */
/* Reset message container to standard inline flow (not clamped box) */
li[class*=\"messageListItem\"],
div[class*=\"message__\"] {{
  min-height: 44px !important;
}}

/* Standard Discord 40px avatar positioning */
div[class*=\"avatar__\"],
img[class*=\"avatar__\"],
div[class*=\"avatarDecoration__\"] {{
  width: 40px !important;
  height: 40px !important;
  min-width: 40px !important;
  min-height: 40px !important;
  max-width: 40px !important;
  max-height: 40px !important;
  position: static !important;
  margin: 0 !important;
  border-radius: 50% !important;
}}

/* Restore proper left margin for message text next to avatar */
div[class*=\"contents__\"] {{
  margin-left: 0px !important;
  padding-left: 0px !important;
}}

/* Clean message content readability */
div[class*=\"messageContent__\"] {{
  margin-left: 0px !important;
  padding-top: 2px !important;
  line-height: 1.375rem !important;
}}

/* 3. Smooth Chat Input Area */
div[class*=\"channelTextArea_\"], div[class*=\"scrollableContainer_\"], form[class*=\"form_\"] {{
  background: rgba(0, 0, 0, 0.35) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
  border-radius: 8px !important;
}}

/* 4. Sidebar Action Icons (+ Server, Discover) */
[class*=\"circleButton\"], [class*=\"circleIconButton\"],
.circleIconButton__5bc7e, .circleButton__5bc7e {{
  color: {p[\"hex\"]} !important;
  background-color: rgba(255, 255, 255, 0.06) !important;
}}
[class*=\"circleButton\"]:hover, [class*=\"circleIconButton\"]:hover {{
  color: #FFFFFF !important;
  background-color: {p[\"hex\"]} !important;
}}
.circleIconButton__5bc7e svg {{
  fill: currentColor !important;
}}

/* 5. Selected Channel */
[class*=\"modeSelected\"] [class*=\"link_\"],
.modeSelected__2ea32 .link__2ea32 {{
  background: rgba(156, 90, 219, 0.20) !important;
  border-left: 3px solid {p[\"hex\"]} !important;
  border-radius: 6px !important;
}}
'''

full_css = updated + '\n' + aesthetic_overrides

# Target directories
target_dirs = [
    os.path.expanduser('~/.config/Vencord/themes'),
    os.path.expanduser('~/.config/vesktop/themes'),
    os.path.expanduser('~/.config/BetterDiscord/themes')
]

for d in target_dirs:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'DiscordPlus.theme.css'), 'w') as f:
        f.write(full_css)

quick_css_path = os.path.expanduser('~/.config/Vencord/settings/quickCss.css')
os.makedirs(os.path.dirname(quick_css_path), exist_ok=True)
with open(quick_css_path, 'w') as f:
    f.write(full_css)

v_path = os.path.expanduser('~/.config/Vencord/settings/settings.json')
if os.path.exists(v_path):
    try:
        with open(v_path, 'r') as f:
            v_data = json.load(f)
        v_data['useQuickCss'] = True
        v_data['enabledThemes'] = ['DiscordPlus.theme.css']
        with open(v_path, 'w') as f:
            json.dump(v_data, f, indent=4)
    except Exception as e:
        print(e, file=sys.stderr)

print(f'[Discord+] Clean DiscordPlus theme applied with {wall_path}')
"
