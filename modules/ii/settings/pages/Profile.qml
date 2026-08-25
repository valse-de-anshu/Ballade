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

    FolderListModel {
        id: avatarFolderModel
        folder: Config.options.profile.avatarPath !== "" ? Qt.resolvedUrl(Config.options.profile.avatarPath) : ""
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
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            Config.options.profile.avatarPath = avatarField.value
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
                    implicitHeight: Config.options.profile.avatarPath === "" ? placeholderCol.implicitHeight : avatarFlow.implicitHeight

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

                                property bool isSelected: FileUtils.trimFileProtocol(filePath.toString()) === Config.options.profile.avatarPicture

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
                                    onClicked: Config.options.profile.avatarPicture = FileUtils.trimFileProtocol(filePath.toString())
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: placeholderCol
                        visible: Config.options.profile.avatarPath === ""
                        anchors.centerIn: parent
                        z: 1
                        spacing: 4

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "image"
                            iconSize: 32
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("Pick a folder above to see avatars here")
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
                        { key: "green",     name: "Green",      folder: "green",     color: "#7d9726", icon: "forest"         },
                        { key: "pink",      name: "Pink",       folder: "pink",      color: "#d4659a", icon: "local_florist"  },
                        { key: "red",       name: "Red",        folder: "red",       color: "#bf3f43", icon: "whatshot"       },
                        { key: "purple",    name: "Purple",     folder: "purple",    color: "#9c5adb", icon: "nights_stay"    },
                        { key: "blue",      name: "Tokyo Night",folder: "blue",      color: "#7aa2f7", icon: "location_city"  },
                        { key: "grayscale", name: "Grayscale",  folder: "grayscale", color: "#888899", icon: "invert_colors"  }
                    ]

                    delegate: Item {
                        id: themeCard
                        required property var modelData
                        required property int index

                        readonly property bool isActive: Presets.activeTheme === modelData.key
                        readonly property string wallDir: `${Directories.pictures}/Wallpapers/${modelData.folder}`

                        width: 180
                        height: 248

                        // Auto-find first wallpaper in theme folder
                        FolderListModel {
                            id: wallModel
                            folder: Qt.resolvedUrl(themeCard.wallDir)
                            showDirs: false
                            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                            sortField: FolderListModel.Name
                        }

                        readonly property string wallPreview: wallModel.count > 0
                            ? `${themeCard.wallDir}/${wallModel.get(0, "fileName")}`
                            : ""

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.large
                            color: Appearance.colors.colLayer1
                            clip: true
                            border.color: themeCard.isActive ? themeCard.modelData.color : Qt.alpha(themeCard.modelData.color, 0.25)
                            border.width: themeCard.isActive ? 2.5 : 1

                            Behavior on border.color { ColorAnimation { duration: 250 } }
                            Behavior on border.width  { NumberAnimation { duration: 150 } }

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
                                    cache: true
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
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: -6
                                anchors.bottomMargin: 10
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 7

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
                                        color: Appearance.colors.colText
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
                                        color: saveHover.containsMouse
                                            ? Qt.alpha(themeCard.modelData.color, 0.18)
                                            : Qt.alpha(themeCard.modelData.color, 0.08)
                                        border.color: Qt.alpha(themeCard.modelData.color, 0.35)
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 3
                                            MaterialSymbol {
                                                text: "save"
                                                iconSize: 13
                                                color: themeCard.modelData.color
                                            }
                                            StyledText {
                                                text: "Save"
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.Medium
                                                color: themeCard.modelData.color
                                            }
                                        }

                                        MouseArea {
                                            id: saveHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Presets.save(themeCard.modelData.key)
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
                                                    Presets.apply(themeCard.modelData.key)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Custom Snapshots sub-section ──────────────────────
            StyledText {
                Layout.topMargin: 8
                text: Translation.tr("Snapshots")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colSubtext
                letterSpacing: 1
            }

            GroupedList {
                ConfigTextArea {
                    id: presetNameField
                    Layout.fillWidth: true
                    fieldWidth: 300
                    buttonIcon: "newsmode"
                    text: Translation.tr("New")
                    placeholderText: Translation.tr("Name, description (optional)")

                    confirmButtonVisible: presetNameField.value.trim() !== ""
                    confirmButtonIcon: "save"
                    onConfirmClicked: {
                        Presets.save(presetNameField.value)
                        presetNameField.value = ""
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 20
                visible: (Presets.folderModel ? Presets.folderModel.count : 0) === 0
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No saved snapshots yet")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            Flow {
                Layout.topMargin: 10
                Layout.fillWidth: true
                width: parent.width
                spacing: 12
                visible: Boolean(Presets.folderModel && Presets.folderModel.count > 0)

                Repeater {
                    model: Presets.folderModel
                    delegate: PresetsCard {
                        id: presetDelegate
                        required property string fileName
                        required property string filePath

                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: presetDelegate.filePath
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const bg = (data && data.background) ? data.background : {}
                                    const rawWallpaper = bg.wallpaperPath || ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    presetDelegate.presetWallpaper = isVideo
                                        ? (bg.thumbnailPath || "")
                                        : rawWallpaper
                                    const meta = (data && data._presetMeta) ? data._presetMeta : {}
                                    presetDelegate.presetDescription = meta.description || ""
                                } catch (e) {
                                    console.log("Failed to parse preset:", e)
                                }
                            }
                        }

                        imageSource: presetDelegate.presetWallpaper
                        title: presetDelegate.presetName
                        description: presetDelegate.presetDescription !== "" ? presetDelegate.presetDescription : Translation.tr("Saved preset")
                        onApply: () => Presets.apply(presetDelegate.presetName)
                        onRemove: () => Presets.remove(presetDelegate.presetName)
                    }
                }
            }
        }
    }
}