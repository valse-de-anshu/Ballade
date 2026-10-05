import qs
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.shapes
import qs.modules.common.functions

// Dock-style wallpaper picker — hyprquickpaper UI embedded in ballade
Item {
    id: root

    focus: true
    signal dismissed()

    property string activeSection: "static" // "static" or "live"
    property string activeStaticFolder: "green"
    property string activeLiveFolder: "green"

    readonly property var staticFolders: [
        "green", "purple", "blue", "golden", "orange", "pink", "red", "grayscale", "Catppuccin"
    ]
    readonly property var liveFolders: [
        "green", "purple", "blue", "golden", "orange", "pink", "red", "grayscale", "Catppuccin"
    ]

    function colorForFolder(name) {
        switch (name.toLowerCase()) {
            case "green":      return "#7D9726"
            case "purple":     return "#9C5ADB"
            case "blue":       return "#7AA2F7"
            case "golden":     return "#F0B849"
            case "orange":     return "#FF9248"
            case "pink":       return "#D4659A"
            case "red":        return "#BF3F43"
            case "grayscale":  return "#888899"
            case "catppuccin":
            case "catpuchin":  return "#CBA6F7"
            default:           return Appearance.colors.colPrimary
        }
    }

    function syncDirectory() {
        let dirPath = "";
        if (root.activeSection === "live") {
            dirPath = `${Directories.pictures}/Wallpapers/live Wallpapers/${root.activeLiveFolder}`;
        } else {
            dirPath = `${Directories.pictures}/Wallpapers/${root.activeStaticFolder}`;
        }
        Wallpapers.setDirectory(dirPath);
        Quickshell.execDetached(["python3", `${Directories.scriptPath}/thumbnails/ensure_wallpaper_thumbnails.py`, "--dir", FileUtils.trimFileProtocol(dirPath)]);
    }

    Component.onCompleted: {
        list.forceActiveFocus();
        const curWall = Config.options.background?.wallpaperPath || "";
        const isLive = curWall.indexOf("live Wallpapers") !== -1 || /\.(mp4|webm|mkv|avi|mov)$/i.test(curWall);
        const activePreset = Config.options.theme?.activePreset ?? "green";
        if (isLive) {
            root.activeSection = "live";
            let matched = root.liveFolders.find(f => curWall.indexOf("/" + f + "/") !== -1);
            root.activeLiveFolder = matched || activePreset || "green";
        } else {
            root.activeSection = "static";
            let matched = root.staticFolders.find(f => curWall.indexOf("/" + f + "/") !== -1);
            root.activeStaticFolder = matched || activePreset || "green";
        }
        root.syncDirectory();
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Left:  case Qt.Key_K: case Qt.Key_H: list.moveSelection(-1); break;
        case Qt.Key_Right: case Qt.Key_J: case Qt.Key_L: list.moveSelection(1);  break;
        case Qt.Key_Tab:
            root.activeSection = (root.activeSection === "static" ? "live" : "static");
            root.syncDirectory();
            break;
        case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: list.activateCurrent(); break;
        case Qt.Key_Escape: root.dismissed(); break;
        default: return;
        }
        event.accepted = true;
    }

    // ---- Settings / Tunables ----
    property string activeBehavior    : Config.options.wallpaperSelector?.behavior ?? "panoramic"
    readonly property bool isPanoramic: activeBehavior === "panoramic"
    property string activeShape       : Config.options.wallpaperSelector?.shape ?? "card"
    readonly property bool isCyberpunk: activeShape === "cyberpunk"
    property int    animDuration      : 180
    property int    scrollSpeed       : 5000

    // Folder model — points at the same directory ballade's Wallpapers service watches
    FolderListModel {
        id: folderModel
        folder: Wallpapers.directory
        showDirs: false
        nameFilters: root.activeSection === "live"
            ? ["*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov"]
            : ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.avif", "*.bmp"]
        sortField: FolderListModel.Name
    }

    // --- Backdrop scrim ---
    Rectangle {
        anchors.fill: parent
        color: Config.options.wallpaperSelector?.showBlurBackground ? "#80000000" : "transparent"
        Behavior on color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            // Absorb clicks so they don't hit underlying apps,
            // but do NOT dismiss. Per requirement: only Esc or choosing a wallpaper will close the UI.
        }
    }

    // --- Unified Floating Header Glass Island ---
    Rectangle {
        id: headerNav
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.05)
        anchors.horizontalCenter: parent.horizontalCenter
        height: 48
        width: headerContentRow.implicitWidth + 24
        radius: 24
        color: "#E614161F" // Frosted obsidian glass
        border.width: 1
        border.color: "#28FFFFFF"
        z: 200

        Row {
            id: headerContentRow
            anchors.centerIn: parent
            spacing: 12

            // Mode Switcher (Wallpapers vs Live)
            Row {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                // Static Wallpapers Tab
                Rectangle {
                    width: staticTabRow.implicitWidth + 20
                    height: 34
                    radius: 17
                    color: root.activeSection === "static" ? Appearance.colors.colPrimary : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: staticTabRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: "image"
                            iconSize: 16
                            color: root.activeSection === "static" ? Appearance.colors.colOnPrimary : "#A6ADC8"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Translation.tr("Wallpapers")
                            color: root.activeSection === "static" ? Appearance.colors.colOnPrimary : "#A6ADC8"
                            font.pixelSize: 12
                            font.weight: root.activeSection === "static" ? Font.DemiBold : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activeSection !== "static") {
                                root.activeSection = "static"
                                root.syncDirectory()
                            }
                        }
                    }
                }

                // Live Wallpapers Tab
                Rectangle {
                    width: liveTabRow.implicitWidth + 20
                    height: 34
                    radius: 17
                    color: root.activeSection === "live" ? Appearance.colors.colPrimary : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: liveTabRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: "movie"
                            iconSize: 16
                            color: root.activeSection === "live" ? Appearance.colors.colOnPrimary : "#A6ADC8"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Translation.tr("Live")
                            color: root.activeSection === "live" ? Appearance.colors.colOnPrimary : "#A6ADC8"
                            font.pixelSize: 12
                            font.weight: root.activeSection === "live" ? Font.DemiBold : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activeSection !== "live") {
                                root.activeSection = "live"
                                root.syncDirectory()
                            }
                        }
                    }
                }
            }

            // Elegant vertical divider
            Rectangle {
                width: 1
                height: 18
                color: "#28FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Theme Color Jewels (Circular Glowing Beads)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Repeater {
                    model: root.activeSection === "live" ? root.liveFolders : root.staticFolders

                    Item {
                        id: jewelItem
                        required property string modelData
                        required property int index

                        readonly property bool isCurrentFolder: root.activeSection === "live" 
                            ? (root.activeLiveFolder === modelData)
                            : (root.activeStaticFolder === modelData)

                        readonly property color beadColor: root.colorForFolder(modelData)

                        width: 28
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter

                        // Outer Selection Halo
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.width: 2
                            border.color: jewelItem.beadColor
                            opacity: jewelItem.isCurrentFolder ? 1.0 : (jewelMouse.containsMouse ? 0.45 : 0.0)
                            scale: jewelItem.isCurrentFolder ? 1.0 : (jewelMouse.containsMouse ? 0.92 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        }

                        // Inner Color Bead
                        Rectangle {
                            anchors.centerIn: parent
                            width: jewelItem.isCurrentFolder ? 15 : 18
                            height: width
                            radius: width / 2
                            color: jewelItem.beadColor
                            scale: jewelMouse.containsMouse && !jewelItem.isCurrentFolder ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }
                            Behavior on width { NumberAnimation { duration: 150 } }

                            // Center core highlight on active
                            Rectangle {
                                anchors.centerIn: parent
                                width: 4
                                height: 4
                                radius: 2
                                color: "#FFFFFF"
                                opacity: jewelItem.isCurrentFolder ? 0.95 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }

                        // Elegant floating tooltip on hover
                        Rectangle {
                            id: jewelTooltip
                            z: 300
                            anchors.top: parent.bottom
                            anchors.topMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: jewelTooltipText.implicitWidth + 14
                            height: 22
                            radius: 11
                            color: "#F0161822"
                            border.width: 1
                            border.color: "#35FFFFFF"
                            opacity: jewelMouse.containsMouse ? 1.0 : 0.0
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Text {
                                id: jewelTooltipText
                                anchors.centerIn: parent
                                text: jewelItem.modelData.charAt(0).toUpperCase() + jewelItem.modelData.slice(1)
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: jewelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeSection === "live") {
                                    root.activeLiveFolder = jewelItem.modelData
                                } else {
                                    root.activeStaticFolder = jewelItem.modelData
                                }
                                root.syncDirectory()
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Main Wallpaper Curved Carousel ---
    ListView {
        id: list
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(460, Math.round(parent.height * 0.46))
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: 10
        clip: false
        cacheBuffer: 50000

        property int selectedIndex: 0
        property bool wheelCooldown: false

        Timer {
            id: wheelCooldownTimer
            interval: 70
            onTriggered: list.wheelCooldown = false
        }

        // Expanded hero width (middle horizontal card)
        readonly property real expandedWidth: Math.min(Math.round(height * 1.55), Math.round(width * 0.48))

        // Vertical card slot width (92px wide, elegant portrait shape)
        readonly property real collapsedWidth: 92
        readonly property real step: collapsedWidth + spacing

        leftMargin: Math.max(0, (width - expandedWidth) / 2)
        rightMargin: leftMargin

        onStepChanged: centerOn(selectedIndex)
        onLeftMarginChanged: centerOn(selectedIndex)

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }

        function centerOn(idx) {
            if (count <= 0) return
            selectedIndex = clampIndex(idx)
            contentX = selectedIndex * step - leftMargin
        }

        function moveSelection(delta) {
            centerOn(selectedIndex + delta)
        }

        function activateCurrent() {
            const path = folderModel.get(selectedIndex, "filePath")
            if (path) {
                const trimmed = FileUtils.trimFileProtocol(path)
                if (GlobalStates.wallpaperSelectorTarget === "lockWall") {
                    Config.options.background.lockWall = trimmed
                } else {
                    Wallpapers.apply(trimmed)
                }
            }
            root.dismissed()
        }

        Behavior on contentX {
            NumberAnimation { duration: 260; easing.type: Easing.OutQuart }
        }

        Connections {
            target: folderModel
            function onCountChanged() {
                if (folderModel.count > 0) {
                    let activePath = Config.options.background?.wallpaperPath;
                    let foundIndex = -1;
                    if (activePath) {
                        for (let i = 0; i < folderModel.count; i++) {
                            let itemPath = FileUtils.trimFileProtocol(folderModel.get(i, "filePath"));
                            if (itemPath === activePath) {
                                foundIndex = i;
                                break;
                            }
                        }
                    }
                    if (foundIndex !== -1) {
                        list.centerOn(foundIndex);
                    } else {
                        list.centerOn(Math.max(0, Math.floor((folderModel.count - 1) / 2)));
                    }
                }
            }
        }

        delegate: Item {
            id: tile
            readonly property int dist: Math.abs(index - list.selectedIndex)
            readonly property bool active: dist === 0
            readonly property string currentFilePath: {
                if (!filePath) return ""
                return FileUtils.trimFileProtocol(filePath)
            }
            readonly property bool isVideo: Boolean(currentFilePath) && /\.(mp4|webm|mkv|avi|mov)$/i.test(currentFilePath)
            readonly property string thumbUri: {
                if (!currentFilePath) return ""
                const encoded = currentFilePath.split("/").map(part => encodeURIComponent(part)).join("/")
                const uri = "file://" + encoded
                const md5Hash = Qt.md5(uri)
                const cacheDir = FileUtils.trimFileProtocol(Directories.genericCache)
                return "file://" + cacheDir + "/thumbnails/x-large/" + md5Hash + ".png"
            }

            width: active ? list.expandedWidth : list.collapsedWidth
            height: list.height
            z: active ? 100 : (60 - Math.min(dist, 40))

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutQuart }
            }

            Item {
                id: content
                anchors.centerIn: parent

                // Smooth vertical curved coverflow silhouette:
                // Height curves down symmetrically on left and right, center is full hero height
                height: {
                    if (dist === 0) return list.height;
                    if (dist === 1) return Math.round(list.height * 0.90);
                    if (dist === 2) return Math.round(list.height * 0.80);
                    if (dist === 3) return Math.round(list.height * 0.70);
                    return Math.round(list.height * 0.60);
                }
                width: parent.width
                scale: active ? 1.0 : Math.max(0.92, 1.0 - dist * 0.02)
                opacity: active ? 1.0 : Math.max(0.48, 1.0 - dist * 0.12)

                Behavior on height {
                    NumberAnimation { duration: 260; easing.type: Easing.OutQuart }
                }
                Behavior on scale {
                    NumberAnimation { duration: 260; easing.type: Easing.OutQuart }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                // Card container with rounded corners and instant image rendering
                Item {
                    id: imageContainer
                    anchors.fill: parent

                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: tile.active ? 20 : 12
                            color: "white"
                        }
                    }

                    // Frosted dark background so cards never flash transparent
                    Rectangle {
                        anchors.fill: parent
                        color: "#181A24"
                    }

                    // High-speed cached image display for rapid spawn
                    Image {
                        id: img
                        anchors.fill: parent
                        visible: !tile.isVideo
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: false
                        retainWhileLoading: true
                        source: tile.thumbUri || (tile.currentFilePath ? ("file://" + tile.currentFilePath) : "")
                        sourceSize: Qt.size(800, 500)
                        onStatusChanged: {
                            if (status === Image.Error && source === tile.thumbUri && tile.currentFilePath) {
                                source = "file://" + tile.currentFilePath
                            }
                        }
                    }

                    // Video thumbnail for live wallpapers
                    ThumbnailImage {
                        anchors.fill: parent
                        visible: tile.isVideo
                        fillMode: Image.PreserveAspectCrop
                        sourcePath: tile.currentFilePath
                        sourceSize: Qt.size(800, 500)
                    }
                }

                // Live wallpaper badge
                Rectangle {
                    z: 11
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: tile.active ? 12 : 6
                    width: tile.active ? (liveBadgeRow.implicitWidth + 14) : 12
                    height: tile.active ? 22 : 12
                    radius: tile.active ? 11 : 6
                    color: "#D0101014"
                    border.width: 1
                    border.color: "#40FFFFFF"
                    visible: tile.isVideo

                    Row {
                        id: liveBadgeRow
                        anchors.centerIn: parent
                        spacing: 4
                        visible: tile.active
                        MaterialSymbol {
                            text: "play_arrow"
                            iconSize: 13
                            color: Appearance.colors.colPrimary
                        }
                        Text {
                            text: "LIVE"
                            color: "#FFFFFF"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                        }
                    }
                }

                // Active Border Highlighter for the hero card
                Rectangle {
                    id: activeHighlight
                    z: 10
                    anchors.fill: parent
                    radius: 20
                    visible: tile.active
                    color: "transparent"
                    border.width: 3
                    border.color: Appearance.colors.colPrimary
                }

                // Minimalist Apply Pill — clean, no raw filenames or clutter!
                Rectangle {
                    z: 12
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 14
                    width: applyRow.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: "#E6101016"
                    border.width: 1
                    border.color: "#35FFFFFF"
                    opacity: tile.active ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Row {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 5

                        MaterialSymbol {
                            text: "check"
                            iconSize: 14
                            color: Appearance.colors.colPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: Translation.tr("Apply")
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (tile.active) {
                        list.activateCurrent()
                    } else {
                        list.centerOn(index)
                    }
                }
                onWheel: function(wheel) {
                    if (!list.wheelCooldown) {
                        list.wheelCooldown = true;
                        wheelCooldownTimer.restart();
                        list.moveSelection(wheel.angleDelta.y < 0 ? 1 : -1);
                    }
                    wheel.accepted = true;
                }
            }
        }

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Left:  case Qt.Key_K: case Qt.Key_H: moveSelection(-1); break;
            case Qt.Key_Right: case Qt.Key_J: case Qt.Key_L: moveSelection(1);  break;
            case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: activateCurrent(); break;
            case Qt.Key_Escape: root.dismissed(); break;
            default: return;
            }
            event.accepted = true;
        }
    }
}
