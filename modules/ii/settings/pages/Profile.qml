import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models

ContentPage {
    id: page
    property string descriptionMode: {
        if (Config.options.profile.descriptionText === "::uptime::") return "uptime"
        return "distro"
    }
    property string hostnameInput: SystemInfo.hostname
    property string qsThemeFeedbackText: ""

    Timer {
        id: qsThemeFeedbackTimer
        interval: 2200
        repeat: false
        onTriggered: page.qsThemeFeedbackText = ""
    }

    Process {
        id: qsColorPickerProc
        command: ["hyprpicker", "--no-fancy"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = text.trim()
                if (/^#?[0-9A-Fa-f]{6}$/.test(hex)) {
                    page.applyQsAccentColor(hex.startsWith("#") ? hex : ("#" + hex))
                }
            }
        }
    }

    function applyQsAccentColor(hex) {
        if (!hex || hex === "clear" || hex === "") {
            Config.options.appearance.palette.accentColor = ""
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--color", "clear", "--noswitch"])
            page.qsThemeFeedbackText = Translation.tr("Colors synced with wallpaper")
        } else {
            Config.options.appearance.palette.accentColor = hex
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--color", hex, "--noswitch"])
            page.qsThemeFeedbackText = Translation.tr("Applied accent color: ") + hex
        }
        qsThemeFeedbackTimer.restart()
    }

    FolderListModel {
        id: avatarFolderModel
        folder: {
            const p = Config.options.profile.avatarPath
            if (!p || p.trim() === "") return ""
            const trimmed = p.trim()
            return trimmed.startsWith("file://") ? trimmed : ("file://" + trimmed)
        }
        showDirs: false
        nameFilters: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.webp"]
    }

    Process {
        id: hostnameSetProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                SystemInfo.refreshHostname()
            }
        }
    }

    function applyHostname() {
        const newName = page.hostnameInput.trim()
        if (newName.length === 0 || newName === SystemInfo.hostname) return
        hostnameSetProc.command = ["hostnamectl", "set-hostname", newName]
        hostnameSetProc.running = true
    }


    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "person"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Avatar")

            GroupedList {
                ConfigTextArea {
                    id: avatarField
                    Layout.fillWidth: true
                    buttonIcon: "folder_open"
                    text: Translation.tr("Avatar path")
                    placeholderText: Translation.tr("Leave empty to use ~/.face, e.g. /home/youruser/Pictures/avatar")
                    value: Config.options.profile.avatarPath
                    onValueChanged: {
                        avatarDebounceTimer.restart()
                    }

                    Timer {
                        id: avatarDebounceTimer
                        interval: 300
                        repeat: false
                        onTriggered: {
                            const trimmed = avatarField.value.trim()
                            Config.options.profile.avatarPath = trimmed
                            Config.save()
                        }
                    }

                    confirmButtonVisible: Config.options.profile.avatarPath !== ""
                    confirmButtonIcon: "add"
                    onConfirmClicked: {
                        GlobalStates.settingsOpen = false
                        if (Config.options.profile.avatarPath !== "") {
                            Quickshell.execDetached(["dolphin", Config.options.profile.avatarPath])
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(72, (Config.options.profile.avatarPath === "" || avatarFolderModel.count === 0) ? placeholderCol.implicitHeight + 20 : avatarFlow.implicitHeight)

                    Flow {
                        id: avatarFlow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Repeater {
                            model: avatarFolderModel
                            delegate: Rectangle {
                                required property string fileName
                                required property string filePath
                                width: 64
                                height: 64
                                radius: width / 2
                                color: Appearance.colors.colLayer2

                                property bool isSelected: FileUtils.trimFileProtocol(filePath.toString()) === FileUtils.trimFileProtocol(Config.options.profile.avatarPicture)

                                Image {
                                    id: avatarImage
                                    anchors.fill: parent
                                    source: filePath
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: avatarImage.width * 2
                                    sourceSize.height: avatarImage.height * 2
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: 64; height: width; radius: width / 2 
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: parent.isSelected
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: 2
                                    anchors.bottomMargin: 2
                                    width: 20
                                    height: width
                                    radius: width / 2
                                    color: Appearance.colors.colPrimary

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "check"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.options.profile.avatarPicture = FileUtils.trimFileProtocol(filePath.toString())
                                        Config.save()
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: placeholderCol
                        visible: Config.options.profile.avatarPath === "" || avatarFolderModel.count === 0
                        anchors.centerIn: parent
                        z: 1
                        spacing: 4

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: Config.options.profile.avatarPath === "" ? "image" : "folder_off"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Config.options.profile.avatarPath === "" ? Translation.tr("Pick a folder above to see avatars here") : Translation.tr("No images found in this folder")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Identity")

                GroupedList {
                    ConfigTextArea {
                        id: displayNameField
                        buttonIcon: "badge"
                        placeholderText: SystemInfo.username
                        text: Translation.tr("Display name")
                        value: Config.options.profile.displayName

                        Timer {
                            id: displayNameDebounceTimer
                            interval: 800
                            running: false
                            onTriggered: {
                                Config.options.profile.displayName = displayNameField.value
                            }
                        }
                        onValueChanged: displayNameDebounceTimer.restart()
                    }

                    ConfigTextArea {
                        id: hostnameField
                        Layout.fillWidth: true
                        buttonIcon: "dns"
                        placeholderText: SystemInfo.hostname
                        text: Translation.tr("Hostname")
                        description: Translation.tr("Requires authentication to change")
                        value: page.hostnameInput
                        onValueChanged: page.hostnameInput = value

                        confirmButtonVisible: page.hostnameInput.trim() !== "" && page.hostnameInput.trim() !== SystemInfo.hostname
                        onConfirmClicked: {
                            page.applyHostname();
                        }
                    }

                    ConfigSelectionArray {
                        text: Translation.tr("Description text")
                        icon: "subtitles"
                        currentValue: page.descriptionMode
                        onSelected: newValue => {
                            page.descriptionMode = newValue
                            if (newValue === "distro") Config.options.profile.descriptionText = "::distro::"
                            if (newValue === "uptime") Config.options.profile.descriptionText = "::uptime::"
                        }
                        options: [
                            { displayName: Translation.tr("Distro"), icon: "deployed_code", value: "distro" },
                            { displayName: Translation.tr("Uptime"), icon: "timelapse",     value: "uptime" },
                        ]
                    }
                }
            }
        }

        ContentSection {
            icon: "palette"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Themes & Presets")

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 10

                Repeater {
                    model: [
                        { key: "green",     name: "Green",        folder: "green",     color: "#7d9726", icon: "forest"         },
                        { key: "pink",      name: "Pink",         folder: "pink",      color: "#d4659a", icon: "local_florist"  },
                        { key: "red",       name: "Red",          folder: "red",       color: "#bf3f43", icon: "whatshot"       },
                        { key: "purple",    name: "Purple",       folder: "purple",    color: "#9c5adb", icon: "nights_stay"    },
                        { key: "blue",      name: "Tokyo Night",  folder: "blue",      color: "#7aa2f7", icon: "location_city"  },
                        { key: "golden",    name: "Golden Amber", folder: "golden",    color: "#f0b849", icon: "wb_sunny"       },
                        { key: "orange",    name: "Sunset Orange",folder: "orange",    color: "#ff9248", icon: "flare"          },
                        { key: "grayscale", name: "Grayscale",    folder: "grayscale", color: "#888899", icon: "invert_colors"  },
                        { key: "catppuccin",name: "Catppuccin",   folder: "Catppuccin",color: "#cba6f7", icon: "palette"        }
                    ]

                    delegate: Item {
                        id: themeCard
                        required property var modelData
                        required property int index

                        readonly property bool isActive: Presets.activeTheme === modelData.key
                        readonly property string wallDir: `${Directories.pictures}/Wallpapers/${modelData.folder}`

                        width: 180
                        height: 248

                        property string savedWallpaper: ""
                        property bool justSaved: false

                        Timer {
                            id: savedTimer
                            interval: 1800
                            repeat: false
                            onTriggered: themeCard.justSaved = false
                        }

                        FileView {
                            id: presetFileView
                            path: `${Directories.userPresetsPath}/${themeCard.modelData.key}.json`
                            watchChanges: true
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const bg = (data && data.background) ? data.background : {}
                                    const rawWallpaper = bg.wallpaperPath || ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    themeCard.savedWallpaper = isVideo ? (bg.thumbnailPath || "") : rawWallpaper
                                } catch (e) {
                                    themeCard.savedWallpaper = ""
                                }
                            }
                        }

                        Connections {
                            target: Presets.folderModel
                            function onCountChanged() {
                                let p = presetFileView.path;
                                presetFileView.path = "";
                                presetFileView.path = p;
                            }
                        }

                        // Auto-find first wallpaper in theme folder as fallback
                        FolderListModel {
                            id: wallModel
                            folder: Qt.resolvedUrl(themeCard.wallDir)
                            showDirs: false
                            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                            sortField: FolderListModel.Name
                        }

                        readonly property string wallPreview: {
                            if (themeCard.savedWallpaper !== "") return themeCard.savedWallpaper;
                            if (wallModel.count > 0) return `${themeCard.wallDir}/${wallModel.get(0, "fileName")}`;
                            return "";
                        }

                        Rectangle {
                            id: cardMask
                            width: themeCard.width
                            height: themeCard.height
                            radius: Appearance.rounding.large
                            visible: false
                        }

                        Rectangle {
                            id: cardBg
                            anchors.fill: parent
                            color: Appearance.colors.colLayer1
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: cardMask
                            }

                            // === Wallpaper Preview (top 160px) ===
                            Item {
                                id: previewArea
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 160
                                clip: true

                                StyledImage {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: themeCard.wallPreview
                                    visible: themeCard.wallPreview !== ""
                                    cache: false
                                    antialiasing: true
                                    sourceSize.width: 360
                                    sourceSize.height: 320
                                }

                                // Fallback: solid color + big icon
                                Rectangle {
                                    anchors.fill: parent
                                    visible: themeCard.wallPreview === ""
                                    color: Qt.darker(themeCard.modelData.color, 2.8)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: themeCard.modelData.icon
                                        iconSize: 56
                                        color: Qt.alpha(themeCard.modelData.color, 0.6)
                                    }
                                }

                                // Bottom gradient fade into card body
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 48
                                    color: "transparent"
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Appearance.colors.colLayer1 }
                                    }
                                }

                                // Active badge (top-right corner)
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 7
                                    anchors.rightMargin: 7
                                    visible: themeCard.isActive
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: themeCard.modelData.color
                                    border.color: "#ffffffcc"
                                    border.width: 1.5

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "check"
                                        iconSize: 13
                                        color: "#ffffff"
                                    }
                                }
                            }

                            // === Info + Buttons (bottom 88px) ===
                            ColumnLayout {
                                anchors.top: previewArea.bottom
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 8
                                anchors.bottomMargin: 10
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                // Color dot + name row
                                RowLayout {
                                    spacing: 6
                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: themeCard.modelData.color
                                    }
                                    StyledText {
                                        text: themeCard.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // Save | Apply button row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    // Save button
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 15
                                        color: themeCard.justSaved
                                            ? Qt.alpha(themeCard.modelData.color, 0.35)
                                            : (saveHover.containsMouse
                                                ? Qt.alpha(themeCard.modelData.color, 0.18)
                                                : Qt.alpha(themeCard.modelData.color, 0.08))
                                        border.color: themeCard.justSaved
                                            ? themeCard.modelData.color
                                            : Qt.alpha(themeCard.modelData.color, 0.35)
                                        border.width: themeCard.justSaved ? 1.5 : 1
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            MaterialSymbol {
                                                text: themeCard.justSaved ? "check" : "save"
                                                iconSize: 13
                                                color: themeCard.justSaved ? "#ffffff" : themeCard.modelData.color
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            StyledText {
                                                text: themeCard.justSaved ? "Saved!" : "Save"
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: themeCard.justSaved ? Font.DemiBold : Font.Medium
                                                color: themeCard.justSaved ? "#ffffff" : themeCard.modelData.color
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }

                                        MouseArea {
                                            id: saveHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const currentWall = ((Config.options.background && Config.options.background.wallpaperPath) || Wallpapers.confirmedPath || "");
                                                if (currentWall && currentWall.length > 0) {
                                                    themeCard.savedWallpaper = currentWall;
                                                }
                                                themeCard.justSaved = true;
                                                savedTimer.restart();
                                                Presets.save(String(themeCard.modelData.key));
                                                Quickshell.execDetached([
                                                    "notify-send",
                                                    "-a", "Presets",
                                                    "-i", "document-save",
                                                    "Preset Saved",
                                                    `Saved current setup to ${themeCard.modelData.name} preset`
                                                ]);
                                            }
                                        }
                                    }

                                    // Apply button
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 15
                                        color: themeCard.isActive
                                            ? Qt.alpha(themeCard.modelData.color, 0.22)
                                            : (applyHover.containsMouse ? themeCard.modelData.color : Qt.alpha(themeCard.modelData.color, 0.75))
                                        border.color: themeCard.isActive ? themeCard.modelData.color : "transparent"
                                        border.width: themeCard.isActive ? 1.5 : 0
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            MaterialSymbol {
                                                text: themeCard.isActive ? "check_circle" : "format_paint"
                                                iconSize: 13
                                                color: "#ffffff"
                                            }
                                            StyledText {
                                                text: themeCard.isActive ? "Active" : "Apply"
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.DemiBold
                                                color: "#ffffff"
                                            }
                                        }

                                        MouseArea {
                                            id: applyHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: themeCard.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (!themeCard.isActive)
                                                    Presets.apply(String(themeCard.modelData.key))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Border overlay (renders on top of the rounded card)
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.large
                            color: "transparent"
                            border.color: themeCard.isActive ? themeCard.modelData.color : Qt.alpha(themeCard.modelData.color, 0.25)
                            border.width: themeCard.isActive ? 2.5 : 1
                            Behavior on border.color { ColorAnimation { duration: 250 } }
                            Behavior on border.width  { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "palette"
            shape: MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("QS Theme")

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: themeFlow.implicitHeight + 24
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                Flow {
                    id: themeFlow
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 10

                    // 1. Auto (Wallpaper)
                    Rectangle {
                        id: autoBall
                        width: 38
                        height: 38
                        radius: 19

                        readonly property bool isCurrent: !Config.options.appearance.palette.accentColor || Config.options.appearance.palette.accentColor === ""

                        color: isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        border.width: autoMouse.containsMouse ? 2 : (isCurrent ? 2 : 1)
                        border.color: isCurrent ? "#ffffff" : (autoMouse.containsMouse ? Appearance.colors.colPrimary : Qt.rgba(1, 1, 1, 0.2))
                        scale: autoMouse.containsMouse ? 1.15 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: autoBall.isCurrent ? "check" : "auto_awesome"
                            iconSize: 18
                            color: autoBall.isCurrent ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                        }

                        MouseArea {
                            id: autoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            StyledToolTip {
                                extraVisibleCondition: false
                                alternativeVisibleCondition: autoMouse.containsMouse
                                text: Translation.tr("Auto (Wallpaper)")
                            }

                            onClicked: {
                                page.applyQsAccentColor("")
                            }
                        }
                    }

                    // 2. Curated Seed Colors
                    Repeater {
                        model: [
                            { name: Translation.tr("Green"), color: "#7D9726" },
                            { name: Translation.tr("Sakura"), color: "#E05688" },
                            { name: Translation.tr("Crimson"), color: "#E53935" },
                            { name: Translation.tr("Amethyst"), color: "#9C27B0" },
                            { name: Translation.tr("Tokyo"), color: "#7AA2F7" },
                            { name: Translation.tr("Sapphire"), color: "#3F51B5" },
                            { name: Translation.tr("Teal"), color: "#009688" },
                            { name: Translation.tr("Cyan"), color: "#00BCD4" },
                            { name: Translation.tr("Amber"), color: "#F0B849" },
                            { name: Translation.tr("Orange"), color: "#FF9248" },
                            { name: Translation.tr("Coral"), color: "#FF7043" },
                            { name: Translation.tr("Lavender"), color: "#B39DDB" },
                            { name: Translation.tr("Slate"), color: "#8892B0" }
                        ]
                        delegate: Rectangle {
                            id: colorCircle
                            required property var modelData
                            width: 38
                            height: 38
                            radius: 19

                            readonly property color cValue: modelData.color
                            readonly property bool isCurrent: {
                                const active = (Config.options.appearance.palette.accentColor || "").toLowerCase();
                                return active === String(cValue).toLowerCase();
                            }

                            color: colorCircle.cValue
                            border.width: cMouse.containsMouse ? 2 : (colorCircle.isCurrent ? 2.5 : 1)
                            border.color: colorCircle.isCurrent ? "#ffffff" : (cMouse.containsMouse ? Appearance.colors.colPrimary : Qt.rgba(1, 1, 1, 0.2))
                            scale: cMouse.containsMouse ? 1.15 : 1.0

                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: colorCircle.isCurrent
                                text: "check"
                                iconSize: 18
                                color: (colorCircle.cValue.hslLightness < 0.5) ? "#ffffff" : "#000000"
                            }

                            MouseArea {
                                id: cMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                StyledToolTip {
                                    extraVisibleCondition: false
                                    alternativeVisibleCondition: cMouse.containsMouse
                                    text: `${colorCircle.modelData.name} (${colorCircle.modelData.color})`
                                }

                                onClicked: {
                                    page.applyQsAccentColor(colorCircle.modelData.color)
                                }
                            }
                        }
                    }

                    // 3. Eyedropper / Custom Picker
                    Rectangle {
                        id: customCircle
                        width: 38
                        height: 38
                        radius: 19
                        color: Appearance.colors.colLayer2
                        border.width: customMouse.containsMouse ? 2 : 1
                        border.color: customMouse.containsMouse ? Appearance.colors.colPrimary : Qt.rgba(1, 1, 1, 0.2)
                        scale: customMouse.containsMouse ? 1.15 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "colorize"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                        }

                        MouseArea {
                            id: customMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            StyledToolTip {
                                extraVisibleCondition: false
                                alternativeVisibleCondition: customMouse.containsMouse
                                text: Translation.tr("Pick Color")
                            }

                            onClicked: {
                                qsColorPickerProc.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}