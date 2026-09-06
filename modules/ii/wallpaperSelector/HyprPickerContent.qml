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
            case "grayscale":  return "#88C0D0"
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

    // --- Backdrop scrim & click-to-dismiss ---
    Rectangle {
        anchors.fill: parent
        color: Config.options.wallpaperSelector?.showBlurBackground ? "#80000000" : "transparent"
        Behavior on color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    // --- Header Navigation Bar (Section Switcher & Category Pills) ---
    ColumnLayout {
        id: headerNav
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.05)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        z: 200

        // Main Section Switcher (Wallpapers vs Live Wallpapers)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: sectionRow.implicitWidth + 8
            height: 46
            radius: 23
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            Row {
                id: sectionRow
                anchors.centerIn: parent
                spacing: 4

                // Static Wallpapers Tab
                Rectangle {
                    width: staticTabRow.implicitWidth + 24
                    height: 38
                    radius: 19
                    color: root.activeSection === "static" ? Appearance.colors.colPrimary : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: staticTabRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "image"
                            iconSize: 18
                            color: root.activeSection === "static" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                        Text {
                            text: Translation.tr("Wallpapers")
                            color: root.activeSection === "static" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                            font.pixelSize: 13
                            font.weight: root.activeSection === "static" ? Font.DemiBold : Font.Normal
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeSection = "static"
                            root.syncDirectory()
                        }
                    }
                }

                // Live Wallpapers Tab
                Rectangle {
                    width: liveTabRow.implicitWidth + 24
                    height: 38
                    radius: 19
                    color: root.activeSection === "live" ? Appearance.colors.colPrimary : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: liveTabRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "video_library"
                            iconSize: 18
                            color: root.activeSection === "live" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                        Text {
                            text: Translation.tr("Live Wallpapers")
                            color: root.activeSection === "live" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                            font.pixelSize: 13
                            font.weight: root.activeSection === "live" ? Font.DemiBold : Font.Normal
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeSection = "live"
                            root.syncDirectory()
                        }
                    }
                }
            }
        }

        // Category / Folder Theme Pills
        Row {
            id: folderPillsRow
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: root.activeSection === "live" ? root.liveFolders : root.staticFolders

                Rectangle {
                    id: pill
                    required property string modelData
                    required property int index

                    readonly property bool isCurrentFolder: root.activeSection === "live" 
                        ? (root.activeLiveFolder === modelData)
                        : (root.activeStaticFolder === modelData)

                    width: pillRow.implicitWidth + 20
                    height: 30
                    radius: 15
                    color: isCurrentFolder 
                        ? Appearance.colors.colSecondaryContainer 
                        : (pillMouse.containsMouse ? Appearance.colors.colLayer2 : Appearance.colors.colLayer0)
                    border.width: 1
                    border.color: isCurrentFolder ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Color dot for theme color
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.colorForFolder(pill.modelData)
                            visible: pill.modelData !== "CozyPixels"
                        }

                        Text {
                            text: pill.modelData.charAt(0).toUpperCase() + pill.modelData.slice(1)
                            color: pill.isCurrentFolder ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                            font.pixelSize: 11
                            font.weight: pill.isCurrentFolder ? Font.DemiBold : Font.Normal
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activeSection === "live") {
                                root.activeLiveFolder = pill.modelData
                            } else {
                                root.activeStaticFolder = pill.modelData
                            }
                            root.syncDirectory()
                        }
                    }
                }
            }
        }
    }

    // --- Main Wallpaper Carousel ---
    ListView {
        id: list
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(480, Math.round(parent.height * 0.44))
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: root.isPanoramic ? 6 : 14
        clip: false
        cacheBuffer: 3000

        property int selectedIndex: 0

        // Dynamically adapted to settings:
        // 1. Selector layout behavior:
        //    - "panoramic": squeezed down vertical lines (32px) on left/right, 1 expanded box in middle
        //    - "standard": rounded cards (180px) on left/right, expanded center card
        // 2. Card Shape:
        //    - "cyberpunk": angled shear geometry
        //    - "card": clean rectangular geometry
        readonly property real expandedWidth: root.isPanoramic
            ? Math.min(Math.round(height * 1.60), Math.round(width * 0.55))
            : Math.min(Math.round(height * 1.50), Math.round(width * 0.50))

        readonly property real collapsedWidth: root.isPanoramic
            ? 32
            : Math.max(160, Math.round(expandedWidth * 0.28))

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
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
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
            readonly property bool active: index === list.selectedIndex
            width: active ? list.expandedWidth : list.collapsedWidth
            height: list.height
            z: active ? 100 : 1

            Behavior on width {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            property bool isVideo: Boolean(filePath) && /\.(mp4|webm|mkv|avi|mov)$/i.test(filePath)

            Item {
                id: content
                anchors.fill: parent

                // Card Shape setting: "cyberpunk" shears the cards; "card" keeps them straight
                transform: Shear {
                    xFactor: root.isCyberpunk ? (tile.active ? -0.04 : -0.08) : 0.0
                    Behavior on xFactor { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }

                Item {
                    id: imageContainer
                    anchors.fill: parent
                    opacity: 1.0 // 100% opaque

                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: root.isCyberpunk
                                ? (root.isPanoramic ? (tile.active ? 14 : 4) : (tile.active ? 16 : 10))
                                : (root.isPanoramic ? (tile.active ? 20 : 6) : (tile.active ? 24 : 18))
                        }
                    }

                    Loader {
                        anchors.fill: parent
                        sourceComponent: tile.isVideo ? videoComponent : imageComponent
                    }

                    Component {
                        id: imageComponent
                        Image {
                            id: img
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                            mipmap: false
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation { duration: 100 }
                            }

                            source: "file://" + FileUtils.trimFileProtocol(filePath)
                            sourceSize: Qt.size(800, 480)

                            Timer {
                                id: retryTimer
                                interval: 800; repeat: false
                                onTriggered: { const s = img.source; img.source = ""; img.source = s }
                            }
                            onStatusChanged: {
                                if (status === Image.Error) retryTimer.start()
                            }
                        }
                    }

                    Component {
                        id: videoComponent
                        ThumbnailImage {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            sourcePath: FileUtils.trimFileProtocol(filePath)
                            sourceSize: Qt.size(800, 480)
                        }
                    }
                }

                // Live wallpaper badge
                Rectangle {
                    z: 11
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: tile.active ? 12 : 4
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

                // Active Border Highlighter for the expanded box
                Rectangle {
                    id: activeHighlight
                    z: 10
                    anchors.fill: parent
                    radius: root.isCyberpunk
                        ? (root.isPanoramic ? 14 : 16)
                        : (root.isPanoramic ? 20 : 24)
                    visible: tile.active
                    color: "transparent"
                    border.width: 3.5
                    border.color: Appearance.colors.colPrimary
                }

                // Filename & Apply chip at bottom — only on expanded box
                Rectangle {
                    z: 12
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 14
                    width: Math.min(parent.width - 24, infoRow.implicitWidth + 28)
                    height: 32
                    radius: 16
                    color: "#E6101016"
                    border.width: 1
                    border.color: "#40FFFFFF"
                    opacity: tile.active ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Row {
                        id: infoRow
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: tile.isVideo ? "movie" : "wallpaper"
                            iconSize: 15
                            color: Appearance.colors.colPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: nameLabel
                            text: fileName
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            font.letterSpacing: 0.3
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                            anchors.verticalCenter: parent.verticalCenter
                            transform: Shear { xFactor: root.isCyberpunk ? 0.04 : 0.0 }
                        }

                        Rectangle {
                            width: 1
                            height: 14
                            color: "#30FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: Translation.tr("↵ Apply")
                            color: Appearance.colors.colPrimary
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
                    list.moveSelection(wheel.angleDelta.y < 0 ? 1 : -1)
                    wheel.accepted = true
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
