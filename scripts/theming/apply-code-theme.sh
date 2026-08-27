#!/usr/bin/env bash
# ==============================================================================
# Ballade VS Code / Code-OSS / Antigravity / Cursor Ultra-Detailed Themer
# Full Workbench UI Customizations + Rich Syntax Token Highlighting
# ==============================================================================

THEME_KEY="${1:-green}"

case "$THEME_KEY" in
    green|atelier|everforest)
        PRESET="green"
        BG="#18211e"; BG_DARK="#121917"; BG_LIGHT="#202c28"; BG_HOVER="#25352f"
        FG="#e7e6df"; FG_MUTED="#929181"; ACCENT="#7d9726"; ACCENT_BRIGHT="#568203"
        SEL="#264f78"; BORDER="#2a3833"; STRINGS="#81c784"; NUMS="#d19a66"; KEYWORDS="#ba6236"
        FUNCS="#5f9182"; TYPES="#5f9182"; COMMENTS="#6c6b5a"
        ;;
    pink|sakura)
        PRESET="pink"
        BG="#181216"; BG_DARK="#120c10"; BG_LIGHT="#261922"; BG_HOVER="#351e2e"
        FG="#fce4ec"; FG_MUTED="#b388a4"; ACCENT="#e05688"; ACCENT_BRIGHT="#f06292"
        SEL="#4a2840"; BORDER="#3d2134"; STRINGS="#f48fb1"; NUMS="#ffd54f"; KEYWORDS="#ff4081"
        FUNCS="#ff80ab"; TYPES="#e05688"; COMMENTS="#7a5068"
        ;;
    purple|amethyst)
        PRESET="purple"
        BG="#15111e"; BG_DARK="#0e0a15"; BG_LIGHT="#241c33"; BG_HOVER="#322547"
        FG="#ede7f6"; FG_MUTED="#b39ddb"; ACCENT="#9c27b0"; ACCENT_BRIGHT="#ba68c8"
        SEL="#483266"; BORDER="#39294f"; STRINGS="#ce93d8"; NUMS="#ffd740"; KEYWORDS="#ab47bc"
        FUNCS="#e040fb"; TYPES="#ba68c8"; COMMENTS="#6b5887"
        ;;
    red|crimson)
        PRESET="red"
        BG="#1a1112"; BG_DARK="#120a0b"; BG_LIGHT="#291819"; BG_HOVER="#3b1e20"
        FG="#ffebee"; FG_MUTED="#ef9a9a"; ACCENT="#d32f2f"; ACCENT_BRIGHT="#ff1744"
        SEL="#4d2225"; BORDER="#421f22"; STRINGS="#ef9a9a"; NUMS="#ffb74d"; KEYWORDS="#d32f2f"
        FUNCS="#ff5252"; TYPES="#e57373"; COMMENTS="#7a4548"
        ;;
    blue|tokyo_night|tokyonight)
        PRESET="blue"
        BG="#1a1b26"; BG_DARK="#16161e"; BG_LIGHT="#24283b"; BG_HOVER="#2f3549"
        FG="#c0caf5"; FG_MUTED="#565f89"; ACCENT="#7aa2f7"; ACCENT_BRIGHT="#7dcfff"
        SEL="#283457"; BORDER="#292e42"; STRINGS="#9ece6a"; NUMS="#ff9e64"; KEYWORDS="#bb9af7"
        FUNCS="#7aa2f7"; TYPES="#7dcfff"; COMMENTS="#565f89"
        ;;
    grayscale|nord|monochrome|bw)
        PRESET="grayscale"
        BG="#242933"; BG_DARK="#1e222a"; BG_LIGHT="#2e3440"; BG_HOVER="#3b4252"
        FG="#eceff4"; FG_MUTED="#4c566a"; ACCENT="#88c0d0"; ACCENT_BRIGHT="#81a1c1"
        SEL="#434c5e"; BORDER="#3b4252"; STRINGS="#a3be8c"; NUMS="#d08770"; KEYWORDS="#81a1c1"
        FUNCS="#88c0d0"; TYPES="#8fbcbb"; COMMENTS="#4c566a"
        ;;
    *)
        PRESET="green"
        BG="#18211e"; BG_DARK="#121917"; BG_LIGHT="#202c28"; BG_HOVER="#25352f"
        FG="#e7e6df"; FG_MUTED="#929181"; ACCENT="#7d9726"; ACCENT_BRIGHT="#568203"
        SEL="#264f78"; BORDER="#2a3833"; STRINGS="#81c784"; NUMS="#d19a66"; KEYWORDS="#ba6236"
        FUNCS="#5f9182"; TYPES="#5f9182"; COMMENTS="#6c6b5a"
        ;;
esac

python3 - << PYEOF
import json, os

bg = "$BG"
bg_dark = "$BG_DARK"
bg_light = "$BG_LIGHT"
bg_hover = "$BG_HOVER"
fg = "$FG"
fg_muted = "$FG_MUTED"
accent = "$ACCENT"
accent_bright = "$ACCENT_BRIGHT"
sel = "$SEL"
border = "$BORDER"

strings = "$STRINGS"
nums = "$NUMS"
keywords = "$KEYWORDS"
funcs = "$FUNCS"
types = "$TYPES"
comments = "$COMMENTS"

workbench_colors = {
    "focusBorder": accent,
    "foreground": fg,
    "selection.background": sel,
    "scrollbar.shadow": "#00000044",
    "activityBar.background": bg_dark,
    "activityBar.foreground": "#ffffff",
    "activityBar.inactiveForeground": fg_muted,
    "activityBar.activeBorder": accent_bright,
    "activityBarBadge.background": accent_bright,
    "activityBarBadge.foreground": "#ffffff",
    "sideBar.background": bg,
    "sideBar.foreground": fg,
    "sideBar.border": border,
    "sideBarSectionHeader.background": bg_dark,
    "sideBarSectionHeader.foreground": fg,
    "sideBarSectionHeader.border": border,
    "sideBarTitle.foreground": fg,
    "list.activeSelectionBackground": accent_bright + "44",
    "list.activeSelectionForeground": "#ffffff",
    "list.inactiveSelectionBackground": bg_light,
    "list.inactiveSelectionForeground": fg,
    "list.hoverBackground": bg_hover,
    "list.hoverForeground": fg,
    "list.focusBackground": bg_light,
    "list.highlightForeground": accent_bright,
    "statusBar.background": bg_dark,
    "statusBar.foreground": fg,
    "statusBar.border": border,
    "statusBarItem.remoteBackground": accent,
    "statusBarItem.remoteForeground": "#ffffff",
    "statusBarItem.hoverBackground": bg_light,
    "titleBar.activeBackground": bg_dark,
    "titleBar.activeForeground": fg,
    "titleBar.inactiveBackground": bg_dark,
    "titleBar.inactiveForeground": fg_muted,
    "titleBar.border": border,
    "menu.background": bg_dark,
    "menu.foreground": fg,
    "menu.selectionBackground": accent_bright,
    "menu.selectionForeground": "#ffffff",
    "menu.separatorBackground": border,
    "button.background": accent,
    "button.foreground": "#ffffff",
    "button.hoverBackground": accent_bright,
    "input.background": bg_light,
    "input.foreground": fg,
    "input.border": border,
    "inputOption.activeBorder": accent_bright,
    "editor.background": bg,
    "editor.foreground": fg,
    "editor.selectionBackground": sel,
    "editor.lineHighlightBackground": bg_light + "55",
    "editor.lineHighlightBorder": "#00000000",
    "editorCursor.foreground": accent_bright,
    "editorLineNumber.foreground": fg_muted,
    "editorLineNumber.activeForeground": accent_bright,
    "editorWhitespace.foreground": border,
    "editorIndentGuide.background1": border,
    "editorIndentGuide.activeBackground1": accent,
    "editorRuler.foreground": border,
    "editorBracketMatch.background": accent + "33",
    "editorBracketMatch.border": accent_bright,
    "editorGutter.background": bg,
    "editorGutter.addedBackground": "#81c784",
    "editorGutter.modifiedBackground": accent,
    "editorGutter.deletedBackground": "#ff5252",
    "tab.activeBackground": bg,
    "tab.activeForeground": "#ffffff",
    "tab.activeBorderTop": accent_bright,
    "tab.inactiveBackground": bg_dark,
    "tab.inactiveForeground": fg_muted,
    "tab.border": border,
    "editorGroupHeader.tabsBackground": bg_dark,
    "editorGroupHeader.tabsBorder": border,
    "panel.background": bg,
    "panel.border": border,
    "panelTitle.activeBorder": accent_bright,
    "panelTitle.activeForeground": "#ffffff",
    "panelTitle.inactiveForeground": fg_muted,
    "terminal.background": bg,
    "terminal.foreground": fg,
    "terminal.selectionBackground": sel,
    "terminalCursor.foreground": accent_bright,
    "terminal.border": border,
    "breadcrumb.background": bg,
    "breadcrumb.foreground": fg_muted,
    "breadcrumb.focusForeground": fg,
    "badge.background": accent,
    "badge.foreground": "#ffffff",
}

token_customizations = {
    "comments": comments,
    "strings": strings,
    "numbers": nums,
    "keywords": keywords,
    "functions": funcs,
    "types": types,
    "variables": fg,
    "textMateRules": [
        {
            "scope": ["comment", "punctuation.definition.comment"],
            "settings": {"foreground": comments, "fontStyle": "italic"}
        },
        {
            "scope": ["string", "string.quoted"],
            "settings": {"foreground": strings}
        },
        {
            "scope": ["constant.numeric", "constant.language", "constant.other"],
            "settings": {"foreground": nums}
        },
        {
            "scope": ["keyword", "storage.type", "storage.modifier"],
            "settings": {"foreground": keywords}
        },
        {
            "scope": ["entity.name.function", "support.function"],
            "settings": {"foreground": funcs}
        },
        {
            "scope": ["entity.name.type", "entity.name.class", "support.type", "support.class"],
            "settings": {"foreground": types}
        },
        {
            "scope": ["variable", "variable.other"],
            "settings": {"foreground": fg}
        },
        {
            "scope": ["entity.name.tag", "punctuation.definition.tag"],
            "settings": {"foreground": accent_bright}
        }
    ]
}

paths = [
    os.path.expanduser("~/.config/Code/User/settings.json"),
    os.path.expanduser("~/.config/Code - OSS/User/settings.json"),
    os.path.expanduser("~/.config/VSCodium/User/settings.json"),
    os.path.expanduser("~/.config/Cursor/User/settings.json"),
    os.path.expanduser("~/.config/Antigravity/User/settings.json"),
    os.path.expanduser("~/.config/Windsurf/User/settings.json"),
]

for p in paths:
    if os.path.exists(p):
        try:
            with open(p, "r") as f:
                data = json.load(f)
            data["workbench.colorCustomizations"] = workbench_colors
            data["editor.tokenColorCustomizations"] = token_customizations
            data["material-code.primaryColor"] = accent
            with open(p, "w") as f:
                json.dump(data, f, indent=4)
            print(f"[VSCode Themer] Successfully updated rich theme in {p}")
        except Exception as e:
            print(f"[VSCode Themer] Error updating {p}: {e}")
PYEOF
