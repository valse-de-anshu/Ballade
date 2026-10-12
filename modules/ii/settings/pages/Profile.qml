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

            component ColorBall: Item {
                id: ballRoot
                required property var modelData
                property bool justCopied: false

                width: 48
                height: 58

                Timer {
                    id: copiedTimer
                    interval: 1500
                    repeat: false
                    onTriggered: ballRoot.justCopied = false
                }

                readonly property bool isCurrentPreset: Boolean(modelData?.preset && Presets.activeTheme === modelData.preset)
                readonly property color ballColor: (modelData && modelData.color) ? modelData.color : "transparent"

                Rectangle {
                    id: ball
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    height: 36
                    radius: width / 2
                    color: ballRoot.ballColor
                    border.width: ballMouseArea.containsMouse ? 2 : (ballRoot.isCurrentPreset ? 2.5 : 1.2)
                    border.color: {
                        if (ballRoot.isCurrentPreset) return Appearance.colors.colPrimary
                        if (ballMouseArea.containsMouse) return Appearance.colors.colPrimary
                        return Qt.rgba(1, 1, 1, 0.22)
                    }
                    scale: ballMouseArea.containsMouse ? 1.18 : 1.0

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: ballRoot.justCopied || ballRoot.isCurrentPreset
                        text: ballRoot.justCopied ? "done" : "check"
                        iconSize: 16
                        color: {
                            try {
                                return (ballRoot.ballColor.hslLightness < 0.5) ? "#ffffff" : "#000000"
                            } catch (e) {
                                return "#ffffff"
                            }
                        }
                    }
                }

                StyledText {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: (modelData && (modelData.shortName || modelData.name)) ? (modelData.shortName || modelData.name) : ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: ballMouseArea.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: ballMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: ballMouseArea.containsMouse
                        text: `${ballRoot.modelData?.name ?? ""}\n${ballRoot.ballColor}`
                    }

                    onClicked: {
                        const hex = ballRoot.ballColor.toString();
                        if (ballRoot.modelData?.preset) {
                            Presets.apply(ballRoot.modelData.preset);
                            page.qsThemeFeedbackText = Translation.tr("Applied theme preset: ") + ballRoot.modelData.name;
                        } else {
                            Quickshell.clipboardText = hex;
                            page.qsThemeFeedbackText = Translation.tr("Copied ") + hex + ` (${ballRoot.modelData?.name ?? ""})`;
                        }
                        ballRoot.justCopied = true;
                        copiedTimer.restart();
                        qsThemeFeedbackTimer.restart();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: qsThemeContainerCol.implicitHeight + 24
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: qsThemeContainerCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 14
                    }
                    spacing: 16

                    // Header bar with status and clipboard feedback
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: page.qsThemeFeedbackText !== "" ? "check_circle" : "palette"
                            iconSize: 18
                            color: page.qsThemeFeedbackText !== "" ? Appearance.m3colors.m3success : Appearance.colors.colPrimary
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: page.qsThemeFeedbackText !== ""
                                ? page.qsThemeFeedbackText
                                : Translation.tr("All renderable theme color balls in QuickShell. Click any ball to copy its HEX code or apply a preset.")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: page.qsThemeFeedbackText !== "" ? Appearance.m3colors.m3success : Appearance.colors.colSubtext
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // 1. Theme Presets (9 balls)
                    ContentSubsection {
                        title: Translation.tr("Theme Presets")
                        tooltip: Translation.tr("Pre-configured system color themes. Click a ball to apply instantly.")

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "Green (Atelier)", shortName: "Green", preset: "green", color: "#7D9726" },
                                    { name: "Sakura", shortName: "Pink", preset: "pink", color: "#E05688" },
                                    { name: "Crimson", shortName: "Red", preset: "red", color: "#D32F2F" },
                                    { name: "Amethyst", shortName: "Purple", preset: "purple", color: "#9C27B0" },
                                    { name: "Tokyo Night", shortName: "Tokyo", preset: "blue", color: "#7AA2F7" },
                                    { name: "Golden Amber", shortName: "Gold", preset: "golden", color: "#F0B849" },
                                    { name: "Sunset Orange", shortName: "Orange", preset: "orange", color: "#FF9248" },
                                    { name: "Nord B&W", shortName: "Gray", preset: "grayscale", color: "#8892B0" },
                                    { name: "Catppuccin", shortName: "Mocha", preset: "catppuccin", color: "#CBA6F7" }
                                ]
                                delegate: ColorBall {}
                            }
                        }
                    }

                    // 2. Material 3 Core Accent Roles (21 balls)
                    ContentSubsection {
                        title: Translation.tr("Material 3 Accents & Containers")
                        tooltip: Translation.tr("Dynamic M3 primary, secondary, tertiary, error, and success colors and containers.")

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "Primary", shortName: "Pri", color: Appearance.m3colors.m3primary },
                                    { name: "On Primary", shortName: "OnPri", color: Appearance.m3colors.m3onPrimary },
                                    { name: "Primary Container", shortName: "PriCon", color: Appearance.m3colors.m3primaryContainer },
                                    { name: "On Primary Container", shortName: "OnPC", color: Appearance.m3colors.m3onPrimaryContainer },
                                    { name: "Inverse Primary", shortName: "InvPri", color: Appearance.m3colors.m3inversePrimary },
                                    { name: "Secondary", shortName: "Sec", color: Appearance.m3colors.m3secondary },
                                    { name: "On Secondary", shortName: "OnSec", color: Appearance.m3colors.m3onSecondary },
                                    { name: "Secondary Container", shortName: "SecCon", color: Appearance.m3colors.m3secondaryContainer },
                                    { name: "On Secondary Container", shortName: "OnSC", color: Appearance.m3colors.m3onSecondaryContainer },
                                    { name: "Tertiary", shortName: "Ter", color: Appearance.m3colors.m3tertiary },
                                    { name: "On Tertiary", shortName: "OnTer", color: Appearance.m3colors.m3onTertiary },
                                    { name: "Tertiary Container", shortName: "TerCon", color: Appearance.m3colors.m3tertiaryContainer },
                                    { name: "On Tertiary Container", shortName: "OnTC", color: Appearance.m3colors.m3onTertiaryContainer },
                                    { name: "Error", shortName: "Err", color: Appearance.m3colors.m3error },
                                    { name: "On Error", shortName: "OnErr", color: Appearance.m3colors.m3onError },
                                    { name: "Error Container", shortName: "ErrCon", color: Appearance.m3colors.m3errorContainer },
                                    { name: "On Error Container", shortName: "OnEC", color: Appearance.m3colors.m3onErrorContainer },
                                    { name: "Success", shortName: "Succ", color: Appearance.m3colors.m3success },
                                    { name: "On Success", shortName: "OnSuc", color: Appearance.m3colors.m3onSuccess },
                                    { name: "Success Container", shortName: "SucCon", color: Appearance.m3colors.m3successContainer },
                                    { name: "On Success Container", shortName: "OnSucC", color: Appearance.m3colors.m3onSuccessContainer }
                                ]
                                delegate: ColorBall {}
                            }
                        }
                    }

                    // 3. Material 3 Fixed Roles (9 balls)
                    ContentSubsection {
                        title: Translation.tr("Material 3 Fixed Tones")
                        tooltip: Translation.tr("Consistent fixed accents that do not shift between light and dark surfaces.")

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "Primary Fixed", shortName: "PriFix", color: Appearance.m3colors.m3primaryFixed },
                                    { name: "Primary Fixed Dim", shortName: "PriDim", color: Appearance.m3colors.m3primaryFixedDim },
                                    { name: "On Primary Fixed", shortName: "OnPF", color: Appearance.m3colors.m3onPrimaryFixed },
                                    { name: "Secondary Fixed", shortName: "SecFix", color: Appearance.m3colors.m3secondaryFixed },
                                    { name: "Secondary Fixed Dim", shortName: "SecDim", color: Appearance.m3colors.m3secondaryFixedDim },
                                    { name: "On Secondary Fixed", shortName: "OnSF", color: Appearance.m3colors.m3onSecondaryFixed },
                                    { name: "Tertiary Fixed", shortName: "TerFix", color: Appearance.m3colors.m3tertiaryFixed },
                                    { name: "Tertiary Fixed Dim", shortName: "TerDim", color: Appearance.m3colors.m3tertiaryFixedDim },
                                    { name: "On Tertiary Fixed", shortName: "OnTF", color: Appearance.m3colors.m3onTertiaryFixed }
                                ]
                                delegate: ColorBall {}
                            }
                        }
                    }

                    // 4. Surfaces, Outlines & Shell Layers (21 balls)
                    ContentSubsection {
                        title: Translation.tr("Surfaces, Outlines & Elevation Layers")
                        tooltip: Translation.tr("Container hierarchy, background surfaces, outlines, and QuickShell layers 0-4.")

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "Background", shortName: "Bg", color: Appearance.m3colors.m3background },
                                    { name: "On Background", shortName: "OnBg", color: Appearance.m3colors.m3onBackground },
                                    { name: "Surface", shortName: "Surf", color: Appearance.m3colors.m3surface },
                                    { name: "Surface Dim", shortName: "Dim", color: Appearance.m3colors.m3surfaceDim },
                                    { name: "Surface Bright", shortName: "Bright", color: Appearance.m3colors.m3surfaceBright },
                                    { name: "Surface Lowest", shortName: "Lowest", color: Appearance.m3colors.m3surfaceContainerLowest },
                                    { name: "Surface Low", shortName: "Low", color: Appearance.m3colors.m3surfaceContainerLow },
                                    { name: "Surface Container", shortName: "Cont", color: Appearance.m3colors.m3surfaceContainer },
                                    { name: "Surface High", shortName: "High", color: Appearance.m3colors.m3surfaceContainerHigh },
                                    { name: "Surface Highest", shortName: "Highest", color: Appearance.m3colors.m3surfaceContainerHighest },
                                    { name: "Surface Variant", shortName: "Variant", color: Appearance.m3colors.m3surfaceVariant },
                                    { name: "On Surface", shortName: "OnSurf", color: Appearance.m3colors.m3onSurface },
                                    { name: "On Surface Variant", shortName: "OnVar", color: Appearance.m3colors.m3onSurfaceVariant },
                                    { name: "Outline", shortName: "Outline", color: Appearance.m3colors.m3outline },
                                    { name: "Outline Variant", shortName: "OutVar", color: Appearance.m3colors.m3outlineVariant },
                                    { name: "Inverse Surface", shortName: "InvSurf", color: Appearance.m3colors.m3inverseSurface },
                                    { name: "Inverse On Surface", shortName: "InvOnS", color: Appearance.m3colors.m3inverseOnSurface },
                                    { name: "Layer 0", shortName: "Layer 0", color: Appearance.colors.colLayer0Base },
                                    { name: "Layer 1", shortName: "Layer 1", color: Appearance.colors.colLayer1Base },
                                    { name: "Layer 2", shortName: "Layer 2", color: Appearance.colors.colLayer2Base },
                                    { name: "Layer 3", shortName: "Layer 3", color: Appearance.colors.colLayer3Base },
                                    { name: "Layer 4", shortName: "Layer 4", color: Appearance.colors.colLayer4Base }
                                ]
                                delegate: ColorBall {}
                            }
                        }
                    }

                    // 5. Terminal ANSI Palette (16 balls)
                    ContentSubsection {
                        title: Translation.tr("Terminal ANSI Palette")
                        tooltip: Translation.tr("16 terminal colors (term0 to term15) rendered by QuickShell.")

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: [
                                    { name: "Term 0 (Black)", shortName: "T0", color: Appearance.m3colors.term0 },
                                    { name: "Term 1 (Red)", shortName: "T1", color: Appearance.m3colors.term1 },
                                    { name: "Term 2 (Green)", shortName: "T2", color: Appearance.m3colors.term2 },
                                    { name: "Term 3 (Yellow)", shortName: "T3", color: Appearance.m3colors.term3 },
                                    { name: "Term 4 (Blue)", shortName: "T4", color: Appearance.m3colors.term4 },
                                    { name: "Term 5 (Magenta)", shortName: "T5", color: Appearance.m3colors.term5 },
                                    { name: "Term 6 (Cyan)", shortName: "T6", color: Appearance.m3colors.term6 },
                                    { name: "Term 7 (White)", shortName: "T7", color: Appearance.m3colors.term7 },
                                    { name: "Term 8 (Bright Black)", shortName: "T8", color: Appearance.m3colors.term8 },
                                    { name: "Term 9 (Bright Red)", shortName: "T9", color: Appearance.m3colors.term9 },
                                    { name: "Term 10 (Bright Green)", shortName: "T10", color: Appearance.m3colors.term10 },
                                    { name: "Term 11 (Bright Yellow)", shortName: "T11", color: Appearance.m3colors.term11 },
                                    { name: "Term 12 (Bright Blue)", shortName: "T12", color: Appearance.m3colors.term12 },
                                    { name: "Term 13 (Bright Magenta)", shortName: "T13", color: Appearance.m3colors.term13 },
                                    { name: "Term 14 (Bright Cyan)", shortName: "T14", color: Appearance.m3colors.term14 },
                                    { name: "Term 15 (Bright White)", shortName: "T15", color: Appearance.m3colors.term15 }
                                ]
                                delegate: ColorBall {}
                            }
                        }
                    }
                }
            }
        }
    }
}