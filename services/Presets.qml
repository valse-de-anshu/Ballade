
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
pragma Singleton

Singleton {
    id: root

    property alias folderModel: presetsFolderModel
    readonly property string activeTheme: (Config.options.theme && Config.options.theme.activePreset) ? Config.options.theme.activePreset : "green"

    readonly property var themePresets: [
        {
            key: "green",
            name: Translation.tr("Green (Atelier)"),
            subtitle: Translation.tr("Atelier Estuary & Nature"),
            color: "#7D9726",
            icon: "eco",
            telaIcon: "Tela-circle-manjaro-dark",
            folder: "green"
        },
        {
            key: "pink",
            name: Translation.tr("Sakura"),
            subtitle: Translation.tr("Cherry Blossom & Neon"),
            color: "#E05688",
            icon: "local_florist",
            telaIcon: "Tela-circle-pink-dark",
            folder: "pink"
        },
        {
            key: "red",
            name: Translation.tr("Crimson"),
            subtitle: Translation.tr("Scarlet & Flame"),
            color: "#D32F2F",
            icon: "whatshot",
            telaIcon: "Tela-circle-red-dark",
            folder: "red"
        },
        {
            key: "purple",
            name: Translation.tr("Amethyst"),
            subtitle: Translation.tr("Cyberpunk & Velvet"),
            color: "#9C27B0",
            icon: "auto_awesome",
            telaIcon: "Tela-circle-purple-dark",
            folder: "purple"
        },
        {
            key: "blue",
            name: Translation.tr("Tokyo Night"),
            subtitle: Translation.tr("Midnight & Indigo"),
            color: "#7AA2F7",
            icon: "nights_stay",
            telaIcon: "Tela-circle-blue-dark",
            folder: "blue"
        },
        {
            key: "grayscale",
            name: Translation.tr("Nord B&W"),
            subtitle: Translation.tr("Monochrome & Frost"),
            color: "#8892B0",
            icon: "contrast",
            telaIcon: "Tela-circle-nord-dark",
            folder: "grayscale"
        }
    ]

    function applyThemePreset(key) {
        if (!key) return
        if (Config.options.theme) {
            Config.options.theme.activePreset = key
        } else {
            Config.setNestedValue("theme.activePreset", key)
        }
        const themeDir = `${Directories.pictures}/Wallpapers/${key}`
        if (Config.options.wallpaperSelector) {
            Config.options.wallpaperSelector.userPath = themeDir
        }
        Wallpapers.setDirectory(themeDir)
        
        Quickshell.execDetached([
            "bash",
            `${Directories.scriptPath}/theming/apply-theme-preset.sh`,
            key
        ])

        // Reload quickshell colors
        MaterialThemeLoader.reapplyTheme()
    }

    FolderListModel {
        id: presetsFolderModel
        folder: Qt.resolvedUrl(Directories.userPresetsPath)
        showDirs: false
        nameFilters: ["*.json"]
    }

    function refresh() {
        const current = presetsFolderModel.folder
        presetsFolderModel.folder = ""
        presetsFolderModel.folder = current
    }

    Process {
        id: saveProc
        onExited: root.refresh()
    }

    Process {
        id: deleteProc
        onExited: root.refresh()
    }

    function save(rawInput) {
        const raw = rawInput.trim()
        if (raw.length === 0) return

        const commaIndex = raw.indexOf(",")
        let name = raw
        let description = ""

        if (commaIndex !== -1) {
            name = raw.substring(0, commaIndex).trim()
            description = raw.substring(commaIndex + 1).trim()
        }

        name = name.replace(/\s/g, "_")
        if (name.length === 0) return

        saveProc.command = ["bash", Directories.presetsScriptPath, "--save", name, description]
        saveProc.running = true
    }

    function apply(name) {
        GlobalStates.settingsOpen = false
        Wallpapers.confirmedPath = ""
        Wallpapers.previewPath = ""
        Quickshell.execDetached(["bash", Directories.presetsScriptPath, "--apply", name])
    }

    function remove(name) {
        deleteProc.command = ["bash", Directories.presetsScriptPath, "--remove", name]
        deleteProc.running = true
    }
}