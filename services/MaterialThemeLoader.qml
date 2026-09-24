pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
        const txt = themeFileView.text()
        if (txt && txt.length > 0) {
            root.applyColors(txt)
        }
        delayedFileRead.restart()
    }

    function applyColors(fileContent) {
        if (!fileContent || fileContent.trim().length === 0) return;
        try {
            const json = JSON.parse(fileContent)
            for (const key in json) {
                if (json.hasOwnProperty(key)) {
                    // Convert snake_case to CamelCase
                    const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                    const m3Key = `m3${camelCaseKey}`
                    Appearance.m3colors[m3Key] = json[key]
                }
            }
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
        } catch (e) {
            console.warn("[MaterialThemeLoader] Failed to parse colors.json:", e)
        }
    }

    Connections {
        target: Config.options?.appearance?.palette ?? null
        function onAccentColorChanged() {
            reloadDelayTimer.restart()
        }
        function onTypeChanged() {
            reloadDelayTimer.restart()
        }
    }

    Connections {
        target: Config.options?.background ?? null
        function onWallpaperPathChanged() {
            reloadDelayTimer.restart()
        }
    }

    Timer {
        id: reloadDelayTimer
        interval: 150
        repeat: false
        onTriggered: root.reapplyTheme()
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    FileView { 
        id: themeFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.restart()
        }
        onLoadedChanged: {
            if (loaded) {
                root.applyColors(themeFileView.text())
            }
        }
        onLoadFailed: {
            reloadDelayTimer.restart()
        }
    }

    function toggleLightDark() {
        const currentlyDark = Appearance.m3colors.darkmode;
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", currentlyDark ? "light" : "dark", "--noswitch"]);
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"

        onPressed: {
            root.toggleLightDark();
        }
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }
        function reapplyTheme(): void {
            root.reapplyTheme();
        }
        function reload(): void {
            root.reapplyTheme();
        }
    }
}
