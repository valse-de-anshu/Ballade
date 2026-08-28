#!/usr/bin/env bash
# ==============================================================================
# Ballade VS Code / Code-OSS / Antigravity / Cursor Exhaustive Themer
# 100% UI Coverage: Empty Editor, Watermarks, Tabs, Sidebars, Popups, Peek Views
# ==============================================================================

THEME_KEY="${1:-green}"

case "$THEME_KEY" in
    green|atelier|everforest)
        PRESET="green"
        BG="#18211e"; BG_DARK="#121917"; BG_LIGHT="#202c28"; BG_HOVER="#25352f"
        FG="#e7e6df"; FG_MUTED="#929181"; ACCENT="#7d9726"; ACCENT_BRIGHT="#568203"
        SEL="#264f78"; BORDER="#2a3833"; STRINGS="#81c784"; NUMS="#d19a66"; KEYWORDS="#ba6236"
        FUNCS="#5f9182"; TYPES="#5f9182"; COMMENTS="#6c6b5a"
        BRACKET1="#7d9726"; BRACKET2="#d19a66"; BRACKET3="#5f9182"; BRACKET4="#81c784"; BRACKET5="#ba6236"
        ;;
    pink|sakura)
        PRESET="pink"
        BG="#181216"; BG_DARK="#120c10"; BG_LIGHT="#261922"; BG_HOVER="#351e2e"
        FG="#fce4ec"; FG_MUTED="#b388a4"; ACCENT="#e05688"; ACCENT_BRIGHT="#f06292"
        SEL="#4a2840"; BORDER="#3d2134"; STRINGS="#f48fb1"; NUMS="#ffd54f"; KEYWORDS="#ff4081"
        FUNCS="#ff80ab"; TYPES="#e05688"; COMMENTS="#7a5068"
        BRACKET1="#f06292"; BRACKET2="#ffd54f"; BRACKET3="#ba68c8"; BRACKET4="#ff80ab"; BRACKET5="#ff4081"
        ;;
    purple|amethyst)
        PRESET="purple"
        BG="#15111e"; BG_DARK="#0e0a15"; BG_LIGHT="#241c33"; BG_HOVER="#322547"
        FG="#ede7f6"; FG_MUTED="#b39ddb"; ACCENT="#9c27b0"; ACCENT_BRIGHT="#ba68c8"
        SEL="#483266"; BORDER="#39294f"; STRINGS="#ce93d8"; NUMS="#ffd740"; KEYWORDS="#ab47bc"
        FUNCS="#e040fb"; TYPES="#ba68c8"; COMMENTS="#6b5887"
        BRACKET1="#ba68c8"; BRACKET2="#ffd740"; BRACKET3="#7aa2f7"; BRACKET4="#ce93d8"; BRACKET5="#e040fb"
        ;;
    red|crimson)
        PRESET="red"
        BG="#1a1112"; BG_DARK="#120a0b"; BG_LIGHT="#291819"; BG_HOVER="#3b1e20"
        FG="#ffebee"; FG_MUTED="#ef9a9a"; ACCENT="#d32f2f"; ACCENT_BRIGHT="#ff1744"
        SEL="#4d2225"; BORDER="#421f22"; STRINGS="#ef9a9a"; NUMS="#ffb74d"; KEYWORDS="#d32f2f"
        FUNCS="#ff5252"; TYPES="#e57373"; COMMENTS="#7a4548"
        BRACKET1="#ff5252"; BRACKET2="#ffb74d"; BRACKET3="#e57373"; BRACKET4="#ef9a9a"; BRACKET5="#d32f2f"
        ;;
    blue|tokyo_night|tokyonight)
        PRESET="blue"
        BG="#1a1b26"; BG_DARK="#16161e"; BG_LIGHT="#24283b"; BG_HOVER="#2f3549"
        FG="#c0caf5"; FG_MUTED="#565f89"; ACCENT="#7aa2f7"; ACCENT_BRIGHT="#7dcfff"
        SEL="#283457"; BORDER="#292e42"; STRINGS="#9ece6a"; NUMS="#ff9e64"; KEYWORDS="#bb9af7"
        FUNCS="#7aa2f7"; TYPES="#7dcfff"; COMMENTS="#565f89"
        BRACKET1="#7aa2f7"; BRACKET2="#ff9e64"; BRACKET3="#bb9af7"; BRACKET4="#9ece6a"; BRACKET5="#7dcfff"
        ;;
    grayscale|nord|monochrome|bw)
        PRESET="grayscale"
        BG="#242933"; BG_DARK="#1e222a"; BG_LIGHT="#2e3440"; BG_HOVER="#3b4252"
        FG="#eceff4"; FG_MUTED="#4c566a"; ACCENT="#88c0d0"; ACCENT_BRIGHT="#81a1c1"
        SEL="#434c5e"; BORDER="#3b4252"; STRINGS="#a3be8c"; NUMS="#d08770"; KEYWORDS="#81a1c1"
        FUNCS="#88c0d0"; TYPES="#8fbcbb"; COMMENTS="#4c566a"
        BRACKET1="#88c0d0"; BRACKET2="#ebcb8b"; BRACKET3="#81a1c1"; BRACKET4="#a3be8c"; BRACKET5="#b48ead"
        ;;
    golden|gold|amber|yellow)
        PRESET="golden"
        BG="#1c1810"; BG_DARK="#14110b"; BG_LIGHT="#262016"; BG_HOVER="#362c1e"
        FG="#ebd8a0"; FG_MUTED="#7a6744"; ACCENT="#f0b849"; ACCENT_BRIGHT="#fed268"
        SEL="#3d3019"; BORDER="#2e2414"; STRINGS="#a8b340"; NUMS="#e0ad4f"; KEYWORDS="#f0b849"
        FUNCS="#f0b849"; TYPES="#ffd268"; COMMENTS="#7a6744"
        BRACKET1="#f0b849"; BRACKET2="#fed268"; BRACKET3="#a8b340"; BRACKET4="#cbb06d"; BRACKET5="#e0ad4f"
        ;;
    orange|sunset|tangerine)
        PRESET="orange"
        BG="#1c1512"; BG_DARK="#140e0c"; BG_LIGHT="#291e1a"; BG_HOVER="#382923"
        FG="#e8dcd5"; FG_MUTED="#7a594c"; ACCENT="#ff9248"; ACCENT_BRIGHT="#f7bb63"
        SEL="#452c22"; BORDER="#2f201a"; STRINGS="#9fb865"; NUMS="#f7a26d"; KEYWORDS="#ff9248"
        FUNCS="#ff9248"; TYPES="#f7bb63"; COMMENTS="#7a594c"
        BRACKET1="#ff9248"; BRACKET2="#f7bb63"; BRACKET3="#9fb865"; BRACKET4="#d49a7a"; BRACKET5="#f7a26d"
        ;;
    *)
        PRESET="green"
        BG="#18211e"; BG_DARK="#121917"; BG_LIGHT="#202c28"; BG_HOVER="#25352f"
        FG="#e7e6df"; FG_MUTED="#929181"; ACCENT="#7d9726"; ACCENT_BRIGHT="#568203"
        SEL="#264f78"; BORDER="#2a3833"; STRINGS="#81c784"; NUMS="#d19a66"; KEYWORDS="#ba6236"
        FUNCS="#5f9182"; TYPES="#5f9182"; COMMENTS="#6c6b5a"
        BRACKET1="#7d9726"; BRACKET2="#d19a66"; BRACKET3="#5f9182"; BRACKET4="#81c784"; BRACKET5="#ba6236"
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

b1 = "$BRACKET1"
b2 = "$BRACKET2"
b3 = "$BRACKET3"
b4 = "$BRACKET4"
b5 = "$BRACKET5"

workbench_colors = {
    "focusBorder": accent,
    "foreground": fg,
    "selection.background": sel,
    "scrollbar.shadow": "#00000044",
    
    # Activity Bar
    "activityBar.background": bg_dark,
    "activityBar.foreground": "#ffffff",
    "activityBar.inactiveForeground": fg_muted,
    "activityBar.activeBorder": accent_bright,
    "activityBarBadge.background": accent_bright,
    "activityBarBadge.foreground": "#ffffff",
    
    # Side Bar
    "sideBar.background": bg,
    "sideBar.foreground": fg,
    "sideBar.border": border,
    "sideBarSectionHeader.background": bg_dark,
    "sideBarSectionHeader.foreground": fg,
    "sideBarSectionHeader.border": border,
    "sideBarTitle.foreground": fg,
    "sideBar.dropBackground": bg_light,
    
    # Lists & Trees
    "list.activeSelectionBackground": accent_bright + "44",
    "list.activeSelectionForeground": "#ffffff",
    "list.inactiveSelectionBackground": bg_light,
    "list.inactiveSelectionForeground": fg,
    "list.hoverBackground": bg_hover,
    "list.hoverForeground": fg,
    "list.focusBackground": bg_light,
    "list.highlightForeground": accent_bright,
    "list.dropBackground": bg_light,
    
    # Status Bar
    "statusBar.background": bg_dark,
    "statusBar.foreground": fg,
    "statusBar.border": border,
    "statusBar.debuggingBackground": bg_light,
    "statusBar.debuggingForeground": fg,
    "statusBar.noFolderBackground": bg_dark,
    "statusBar.noFolderForeground": fg,
    "statusBarItem.hoverBackground": bg_light,
    "statusBarItem.prominentBackground": accent + "44",
    "statusBarItem.prominentHoverBackground": accent + "66",
    "statusBarItem.remoteBackground": accent,
    "statusBarItem.remoteForeground": "#ffffff",
    "statusBarItem.errorBackground": "#ff5252",
    "statusBarItem.errorForeground": "#ffffff",
    "statusBarItem.warningBackground": "#ffd740",
    "statusBarItem.warningForeground": "#000000",
    "statusBarItem.activeBackground": accent + "44",
    
    # Title Bar & Menus
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
    "menu.border": border,
    "menubar.selectionForeground": "#ffffff",
    "menubar.selectionBackground": bg_hover,
    
    # Buttons & Inputs
    "button.background": accent,
    "button.foreground": "#ffffff",
    "button.hoverBackground": accent_bright,
    "button.secondaryBackground": bg_light,
    "button.secondaryForeground": fg,
    "button.secondaryHoverBackground": bg_hover,
    "input.background": bg_light,
    "input.foreground": fg,
    "input.border": border,
    "input.placeholderForeground": fg_muted,
    "inputOption.activeBorder": accent_bright,
    "inputOption.activeBackground": accent + "44",
    "dropdown.background": bg_light,
    "dropdown.foreground": fg,
    "dropdown.border": border,
    "checkbox.background": bg_light,
    "checkbox.foreground": fg,
    "checkbox.border": border,
    
    # Editor Base & Empty Area
    "editor.background": bg,
    "editor.foreground": fg,
    "editorPane.background": bg,
    "editorGroup.emptyBackground": bg,
    "editorGroup.focusedEmptyBorder": accent,
    "editorGroup.border": border,
    "editorGroup.dropBackground": bg_light,
    "editorGroupHeader.tabsBackground": bg_dark,
    "editorGroupHeader.tabsBorder": border,
    "editorGroupHeader.noTabsBackground": bg_dark,
    "editorWatermark.foreground": fg_muted,
    "keybindingLabel.background": bg_light,
    "keybindingLabel.foreground": fg,
    "keybindingLabel.border": border,
    "keybindingLabel.bottomBorder": accent,
    
    # Editor Visuals
    "editor.selectionBackground": sel,
    "editor.inactiveSelectionBackground": sel + "66",
    "editor.selectionHighlightBackground": accent + "22",
    "editor.selectionHighlightBorder": accent,
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
    
    # Editor Minimap
    "minimap.background": bg,
    "minimap.selectionHighlight": sel,
    "minimap.findMatchHighlight": accent_bright,
    "minimap.errorHighlight": "#ff5252",
    "minimap.warningHighlight": "#ffd740",
    "minimapSlider.background": accent + "33",
    "minimapSlider.hoverBackground": accent + "55",
    "minimapSlider.activeBackground": accent_bright + "77",
    "minimapGutter.addedBackground": "#81c784",
    "minimapGutter.modifiedBackground": accent,
    "minimapGutter.deletedBackground": "#ff5252",
    
    # Editor Gutter & Overview Ruler
    "editorGutter.background": bg,
    "editorGutter.addedBackground": "#81c784",
    "editorGutter.modifiedBackground": accent,
    "editorGutter.deletedBackground": "#ff5252",
    "editorOverviewRuler.border": border,
    "editorOverviewRuler.findMatchForeground": accent_bright,
    "editorOverviewRuler.selectionHighlightForeground": sel,
    "editorOverviewRuler.modifiedForeground": accent,
    "editorOverviewRuler.addedForeground": "#81c784",
    "editorOverviewRuler.deletedForeground": "#ff5252",
    "editorOverviewRuler.errorForeground": "#ff5252",
    "editorOverviewRuler.warningForeground": "#ffd740",
    "editorOverviewRuler.infoForeground": accent_bright,
    
    # Tabs
    "tab.activeBackground": bg,
    "tab.activeForeground": "#ffffff",
    "tab.activeBorder": accent_bright,
    "tab.activeBorderTop": accent_bright,
    "tab.inactiveBackground": bg_dark,
    "tab.inactiveForeground": fg_muted,
    "tab.hoverBackground": bg_hover,
    "tab.hoverForeground": "#ffffff",
    "tab.border": border,
    "tab.unfocusedActiveBackground": bg,
    "tab.unfocusedActiveForeground": fg_muted,
    "tab.unfocusedInactiveBackground": bg_dark,
    "tab.unfocusedInactiveForeground": fg_muted + "88",
    
    # Widgets, Suggest Box & Hover
    "editorWidget.background": bg_dark,
    "editorWidget.foreground": fg,
    "editorWidget.border": border,
    "editorSuggestWidget.background": bg_dark,
    "editorSuggestWidget.foreground": fg,
    "editorSuggestWidget.border": border,
    "editorSuggestWidget.selectedBackground": bg_hover,
    "editorSuggestWidget.highlightForeground": accent_bright,
    "editorHoverWidget.background": bg_dark,
    "editorHoverWidget.foreground": fg,
    "editorHoverWidget.border": border,
    "pickerGroup.border": border,
    "pickerGroup.foreground": accent_bright,
    
    # Peek Views
    "peekView.border": accent,
    "peekViewEditor.background": bg_dark,
    "peekViewEditorGutter.background": bg_dark,
    "peekViewEditor.matchHighlightBackground": accent + "44",
    "peekViewResult.background": bg_dark,
    "peekViewResult.fileForeground": "#ffffff",
    "peekViewResult.lineForeground": fg_muted,
    "peekViewResult.selectionBackground": accent + "44",
    "peekViewTitle.background": bg_dark,
    "peekViewTitleLabel.foreground": "#ffffff",
    
    # Diff & Merge
    "diffEditor.insertedTextBackground": "#81c78433",
    "diffEditor.removedTextBackground": "#ff525233",
    "diffEditor.border": border,
    
    # Panel & Terminal
    "panel.background": bg,
    "panel.border": border,
    "panelTitle.activeBorder": accent_bright,
    "panelTitle.activeForeground": "#ffffff",
    "panelTitle.inactiveForeground": fg_muted,
    "panelSection.border": border,
    "terminal.background": bg,
    "terminal.foreground": fg,
    "terminal.selectionBackground": sel,
    "terminalCursor.foreground": accent_bright,
    "terminal.border": border,
    
    # Notifications & Toasts
    "notifications.background": bg_dark,
    "notifications.foreground": fg,
    "notifications.border": border,
    "notificationToast.border": accent_bright,
    "notificationCenter.border": border,
    "notificationCenterHeader.background": bg_dark,
    "notificationCenterHeader.foreground": fg,
    "notificationsInfoIcon.foreground": accent_bright,
    "notificationsWarningIcon.foreground": "#ffd740",
    "notificationsErrorIcon.foreground": "#ff5252",
    
    # Git Decorations
    "gitDecoration.addedResourceForeground": "#81c784",
    "gitDecoration.modifiedResourceForeground": accent,
    "gitDecoration.deletedResourceForeground": "#ff5252",
    "gitDecoration.untrackedResourceForeground": "#81c784",
    "gitDecoration.ignoredResourceForeground": fg_muted,
    
    # Rainbow Brackets
    "editorBracketHighlight.foreground1": b1,
    "editorBracketHighlight.foreground2": b2,
    "editorBracketHighlight.foreground3": b3,
    "editorBracketHighlight.foreground4": b4,
    "editorBracketHighlight.foreground5": b5,
    
    # Scrollbars & Badges
    "scrollbarSlider.background": border + "88",
    "scrollbarSlider.hoverBackground": accent + "66",
    "scrollbarSlider.activeBackground": accent_bright + "99",
    "breadcrumb.background": bg,
    "breadcrumb.foreground": fg_muted,
    "breadcrumb.focusForeground": fg,
    "breadcrumb.activeSelectionForeground": "#ffffff",
    "badge.background": accent,
    "badge.foreground": "#ffffff",
    "progressBar.background": accent_bright,
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
    parent_dir = os.path.dirname(p)
    if os.path.exists(parent_dir):
        try:
            data = {}
            if os.path.exists(p) and os.path.getsize(p) > 0:
                with open(p, "r") as f:
                    try:
                        data = json.load(f)
                    except json.JSONDecodeError:
                        data = {}
            data["workbench.colorCustomizations"] = workbench_colors
            data["editor.tokenColorCustomizations"] = token_customizations
            data["material-code.primaryColor"] = accent
            with open(p, "w") as f:
                json.dump(data, f, indent=4)
            print(f"[VSCode Themer] Successfully updated 100% theme in {p}")
        except Exception as e:
            print(f"[VSCode Themer] Error updating {p}: {e}")
PYEOF
