pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

/**
 * System theming: icon/GTK/cursor themes + matugen app templates.
 * Theme lists come from the standard theme dirs; apply goes through
 * scripts/theming/*.sh (ported from the rofi settings-menu).
 * Matugen templates are parsed at runtime from the user's own
 * config.toml.orig (backed up once from config.toml on first run —
 * it stays the source of truth). ~/.config/matugen/config.toml is then
 * regenerated from it, skipping templates listed in
 * Config.options.appearance.matugenDisabled.
 */
Singleton {
    id: root

    readonly property string scriptDir: FileUtils.trimFileProtocol(`${Directories.scriptPath}/theming`)
    readonly property string matugenConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/matugen/config.toml`)

    property list<string> iconThemes: []
    property list<string> gtkThemes: []
    property list<string> cursorThemes: []
    property string currentIconTheme: ""
    property string currentGtkTheme: ""
    property string currentCursorTheme: ""
    property int currentCursorSize: 24

    // Parsed from config.toml.orig: everything before the first [templates.*]
    // header (the [config] section etc.), kept verbatim
    property string matugenPreamble: ""
    // [{name, block}] — block is the raw TOML text of that template, verbatim
    property list<var> matugenTemplates: []

    function templateEnabled(name) {
        return !Config.options.appearance.matugenDisabled.includes(name)
    }

    function setTemplateEnabled(name, on) {
        const disabled = Config.options.appearance.matugenDisabled
        if (on === !disabled.includes(name)) return
        Config.options.appearance.matugenDisabled = on
            ? disabled.filter(n => n !== name)
            : disabled.concat([name])
        root.regenerateMatugenConfig()
    }

    function refresh() {
        scanProc.running = true
    }

    function applyIconTheme(theme) {
        root.currentIconTheme = theme
        Quickshell.execDetached(["bash", `${root.scriptDir}/set-icon-theme.sh`, theme])
    }

    function applyGtkTheme(theme) {
        root.currentGtkTheme = theme
        Quickshell.execDetached(["bash", `${root.scriptDir}/set-gtk-theme.sh`, theme])
    }

    // Fast-path: updates cursor size across all sinks in ~3ms without rebuilding overrides
    function setCursorSize(size) {
        root.currentCursorSize = size
        Config.options.appearance.cursor.size = size
        if (typeof NiriConfig !== "undefined" && NiriConfig.options && NiriConfig.options.cursor) {
            NiriConfig.options.cursor.size = size
        }
        const hasOverrides = Config.options.appearance?.cursor?.overrides && Object.keys(Config.options.appearance.cursor.overrides).some(k => Config.options.appearance.cursor.overrides[k] && Config.options.appearance.cursor.overrides[k] !== "Default")
        const activeTheme = hasOverrides ? "Ballade-Custom" : (root.currentCursorTheme || "Gloomi_x")
        Quickshell.execDetached([
            "bash",
            `${root.scriptDir}/set-cursor-theme.sh`,
            activeTheme,
            String(size)
        ])
    }

    // Writes every cursor sink: gsettings + ~/.icons/default + niri + hyprland (composed with overrides)
    function applyCursorTheme(theme, size) {
        root.currentCursorTheme = theme
        root.currentCursorSize = size
        Config.options.appearance.cursor.theme = theme
        Config.options.appearance.cursor.size = size
        if (typeof NiriConfig !== "undefined" && NiriConfig.options && NiriConfig.options.cursor) {
            NiriConfig.options.cursor.theme = theme
            NiriConfig.options.cursor.size = size
        }
        root.applyComposedCursor()
    }

    readonly property list<var> cursorActions: [
        { key: "default",      shortLabel: Translation.tr("Normal"),       label: Translation.tr("Normal Select"),         desc: Translation.tr("Standard pointer arrow"),            icon: "near_me" },
        { key: "pointer",      shortLabel: Translation.tr("Link"),         label: Translation.tr("Link Select"),           desc: Translation.tr("Hovering links and buttons"),         icon: "touch_app" },
        { key: "grab",         shortLabel: Translation.tr("Grab"),         label: Translation.tr("Grab (Open Hand)"),      desc: Translation.tr("Ready to drag an item or canvas"),    icon: "pan_tool" },
        { key: "grabbing",     shortLabel: Translation.tr("Grabbing"),     label: Translation.tr("Grabbing (Closed Hand)"),desc: Translation.tr("Actively dragging or moving"),        icon: "drag_pan" },
        { key: "text",         shortLabel: Translation.tr("Text"),         label: Translation.tr("Text Select"),           desc: Translation.tr("I-Beam text editing and selection"),  icon: "edit" },
        { key: "move",         shortLabel: Translation.tr("Move"),         label: Translation.tr("Move / Scroll"),         desc: Translation.tr("Moving windows or 4-way scrolling"),  icon: "open_with" },
        { key: "crosshair",    shortLabel: Translation.tr("Crosshair"),    label: Translation.tr("Crosshair"),             desc: Translation.tr("Precision targeting and selection"),  icon: "control_camera" },
        { key: "not-allowed",  shortLabel: Translation.tr("Forbidden"),    label: Translation.tr("Unavailable"),           desc: Translation.tr("Forbidden or disabled action"),       icon: "block" },
        { key: "help",         shortLabel: Translation.tr("Help"),         label: Translation.tr("Help / Question"),       desc: Translation.tr("Context help and tooltips"),          icon: "help" },
        { key: "wait",         shortLabel: Translation.tr("Busy"),         label: Translation.tr("Busy / Waiting"),        desc: Translation.tr("System or application busy"),         icon: "hourglass_empty" },
        { key: "progress",     shortLabel: Translation.tr("Progress"),     label: Translation.tr("Working in Background"), desc: Translation.tr("Loading while still interactive"),    icon: "hourglass_top" },
        { key: "ew-resize",    shortLabel: Translation.tr("Resize H"),     label: Translation.tr("Horizontal Resize"),     desc: Translation.tr("Resizing borders left / right"),      icon: "swap_horiz" },
        { key: "ns-resize",    shortLabel: Translation.tr("Resize V"),     label: Translation.tr("Vertical Resize"),       desc: Translation.tr("Resizing borders top / bottom"),      icon: "swap_vert" },
        { key: "nwse-resize",  shortLabel: Translation.tr("Diagonal 1"),   label: Translation.tr("Diagonal Resize 1"),     desc: Translation.tr("Resizing top-left to bottom-right"),  icon: "north_west" },
        { key: "nesw-resize",  shortLabel: Translation.tr("Diagonal 2"),   label: Translation.tr("Diagonal Resize 2"),     desc: Translation.tr("Resizing top-right to bottom-left"),  icon: "north_east" },
        { key: "zoom-in",      shortLabel: Translation.tr("Zoom In"),      label: Translation.tr("Zoom In"),               desc: Translation.tr("Magnifying content view"),           icon: "zoom_in" },
        { key: "zoom-out",     shortLabel: Translation.tr("Zoom Out"),     label: Translation.tr("Zoom Out"),              desc: Translation.tr("Demagnifying content view"),         icon: "zoom_out" }
    ]

    property int cursorPreviewVersion: 1

    function getCursorPreview(theme, action, animated = false) {
        const home = FileUtils.trimFileProtocol(Directories.home)
        const ext = animated ? "gif" : "png"
        if (!theme || theme === "Default" || theme === "") {
            theme = root.currentCursorTheme || "Shorekeeper"
        }
        if (typeof theme === "string" && (theme.startsWith("/") || theme.startsWith("file://") || theme === "custom")) {
            return `file://${home}/.cache/ballade/cursor_previews/custom/${action}.${ext}`
        }
        return `file://${home}/.cache/ballade/cursor_previews/${theme}/${action}.${ext}`
    }

    function getOverridePreview(overrideValue, defaultActionKey, animated = false) {
        const home = FileUtils.trimFileProtocol(Directories.home)
        const ext = animated ? "gif" : "png"
        if (!overrideValue || overrideValue === "Default" || overrideValue === "") {
            const baseTheme = root.currentCursorTheme || "Shorekeeper"
            return `file://${home}/.cache/ballade/cursor_previews/${baseTheme}/${defaultActionKey}.${ext}`
        }
        if (typeof overrideValue === "string") {
            if (overrideValue.startsWith("/") || overrideValue.startsWith("file://") || overrideValue === "custom") {
                return `file://${home}/.cache/ballade/cursor_previews/custom/${defaultActionKey}.${ext}`
            }
            if (overrideValue.indexOf(":") !== -1) {
                const parts = overrideValue.split(":")
                return `file://${home}/.cache/ballade/cursor_previews/${parts[0]}/${parts[1]}.${ext}`
            }
            return `file://${home}/.cache/ballade/cursor_previews/${overrideValue}/${defaultActionKey}.${ext}`
        }
        return `file://${home}/.cache/ballade/cursor_previews/${root.currentCursorTheme || "Shorekeeper"}/${defaultActionKey}.${ext}`
    }

    function setCustomCursorFile(actionKey, filePath) {
        if (!filePath) return
        let clean = FileUtils.trimFileProtocol(filePath)
        let current = Object.assign({}, Config.options.appearance?.cursor?.overrides || {})
        current[actionKey] = clean
        Config.options.appearance.cursor.overrides = current
        root.cursorPreviewVersion++
        root.applyComposedCursor()
    }

    function applyComposedCursor() {
        const base = root.currentCursorTheme || "Gloomi_x"
        const size = root.currentCursorSize || 24
        const overrides = Config.options.appearance?.cursor?.overrides || {}
        Quickshell.execDetached([
            "python3",
            `${root.scriptDir}/cursor_manager.py`,
            "apply",
            "--base", base,
            "--size", String(size),
            "--overrides", JSON.stringify(overrides)
        ])
        root.cursorPreviewVersion++
    }

    function setCursorOverride(actionKey, sourceTheme) {
        let current = Object.assign({}, Config.options.appearance?.cursor?.overrides || {})
        if (!sourceTheme || sourceTheme === "Default" || sourceTheme === root.currentCursorTheme || sourceTheme === (root.currentCursorTheme + ":" + actionKey)) {
            delete current[actionKey]
        } else {
            current[actionKey] = sourceTheme
        }
        Config.options.appearance.cursor.overrides = current
        root.applyComposedCursor()
    }

    function resetCursorOverride(actionKey) {
        let current = Object.assign({}, Config.options.appearance?.cursor?.overrides || {})
        delete current[actionKey]
        Config.options.appearance.cursor.overrides = current
        root.applyComposedCursor()
    }

    function resetAllCursorOverrides() {
        Config.options.appearance.cursor.overrides = {}
        root.applyComposedCursor()
    }

    function regenerateMatugenConfig() {
        if (root.matugenTemplates.length === 0) return // orig not parsed (yet) — never clobber
        let toml = "# ! AUTO-GENERATED by the shell settings app — do not edit, changes will be overwritten\n"
        toml += "# Edit config.toml.orig instead (source of truth), toggle templates in Settings > Interface.\n\n"
        toml += root.matugenPreamble.trim() + "\n\n"
        for (const tpl of root.matugenTemplates) {
            if (!root.templateEnabled(tpl.name)) continue
            toml += tpl.block.trim() + "\n\n"
        }
        matugenConfigFile.setText(toml)
    }

    // Re-run matugen + color generation with the current wallpaper
    function regenerateColors() {
        Quickshell.execDetached(["bash", Directories.wallpaperSwitchScriptPath, "--noswitch"])
    }

    FileView {
        id: matugenConfigFile
        path: root.matugenConfigPath
    }

    // Backs up config.toml -> config.toml.orig once, then emits the orig
    // for parsing. The .orig stays the user's hand-written source of truth.
    Process {
        id: matugenSourceProc
        running: true
        command: ["bash", "-c", `
            cfg='${root.matugenConfigPath}'
            [ -f "$cfg" ] && [ ! -f "$cfg.orig" ] && cp "$cfg" "$cfg.orig"
            cat "$cfg.orig" 2>/dev/null || true
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const templates = []
                let preambleLines = []
                let current = null
                for (const line of text.split("\n")) {
                    const header = line.match(/^\s*\[templates\.([^\]]+)\]/)
                    if (header) {
                        current = { name: header[1].replace(/["']/g, ""), lines: [line] }
                        templates.push(current)
                    } else if (/^\s*\[/.test(line)) { // some other [section]
                        current = null
                        preambleLines.push(line)
                    } else if (current) {
                        current.lines.push(line)
                    } else {
                        preambleLines.push(line)
                    }
                }
                root.matugenPreamble = preambleLines.join("\n")
                root.matugenTemplates = templates.map(t => ({ name: t.name, block: t.lines.join("\n") }))
            }
        }
    }

    function rescanThemes() {
        scanProc.running = true
    }

    Process {
        id: scanProc
        running: true
        command: ["bash", "-c", `
            echo :::ICON
            find /usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -r -n1 basename | sort -u | grep -Evx 'hicolor|default'
            echo :::GTK
            find /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -r -n1 basename | sort -u
            echo :::CURSOR
            python3 "${root.scriptDir}/cursor_manager.py" list-themes 2>/dev/null | tr -d '[]" ' | tr ',' '\n' | grep -v '^$'
            echo :::CURRENT
            (gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo) | tr -d "'"
            (gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo) | tr -d "'"
            (gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo) | tr -d "'"
            gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo 24
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = { ICON: [], GTK: [], CURSOR: [], CURRENT: [] }
                let bucket = ""
                for (const rawLine of text.split("\n")) {
                    const line = rawLine.trim()
                    if (line.startsWith(":::")) {
                        bucket = line.slice(3)
                        continue
                    }
                    if (bucket && bucket in data) data[bucket].push(line)
                }
                root.iconThemes = data.ICON.filter(l => l !== "")
                root.gtkThemes = data.GTK.filter(l => l !== "")
                root.cursorThemes = data.CURSOR.filter(l => l !== "")
                root.currentIconTheme = data.CURRENT[0] ?? ""
                root.currentGtkTheme = data.CURRENT[1] ?? ""
                root.currentCursorTheme = Config.options.appearance?.cursor?.theme || data.CURRENT[2] || "Gloomi_x"
                root.currentCursorSize = Config.options.appearance?.cursor?.size || parseInt(data.CURRENT[3]) || 24
            }
        }
    }

    IpcHandler {
        target: "systemTheming"
        function rescanThemes(): void { root.rescanThemes(); }
    }
}
