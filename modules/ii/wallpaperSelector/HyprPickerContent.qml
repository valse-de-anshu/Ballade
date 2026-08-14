import QtQuick
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

// Dock-style wallpaper picker — hyprquickpaper UI embedded in ballade
Item {
    id: root

    focus: true
    signal dismissed()

    Component.onCompleted: {
        list.forceActiveFocus();
        cacheProc.running = true;
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Left:  case Qt.Key_K: list.moveSelection(-1); break;
        case Qt.Key_Right: case Qt.Key_J: list.moveSelection(1);  break;
        case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: list.activateCurrent(); break;
        case Qt.Key_Escape: root.dismissed(); break;
        default: return;
        }
        event.accepted = true;
    }

    // ---- Tunables ----
    property int   animDuration  : 200
    property int   scrollSpeed   : 6000
    property real  zoomScale     : 0.88
    property real  edgeScale     : 0.50
    property int   baseSpacing   : 18
    property int   visibleTiles  : 5
    property real  slantFactor   : -0.12   // Cinematic anime slant shear
    // ------------------

    // Thumbnail cache — reuse hyprquickpaper's own cache (simple filenames)
    readonly property string thumbCacheDir: FileUtils.trimFileProtocol(
        Directories.home + "/.cache/quickshell/hyprquickpaper/thumbs/"
    )

    // Keep thumbs fresh whenever the wallpaper folder changes
    Process {
        id: cacheProc
        property string shellDir: FileUtils.trimFileProtocol(Directories.config) + "/quickshell/hyprquickpaper"
        command: ["bash", shellDir + "/cache.sh", shellDir]
        running: false
    }

    // Folder model — points at the same directory ballade's Wallpapers service watches
    FolderListModel {
        id: folderModel
        folder: Wallpapers.directory
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
    }

    // --- Top Cyberpunk Header & Counter ---
    Item {
        id: header
        anchors.top: parent.top
        anchors.topMargin: 42
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 80, 480)
        height: 38

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#80121216"
            border.width: 1
            border.color: "#33FFFFFF"
            transform: Shear { xFactor: root.slantFactor }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: "✦"
                color: Appearance.colors.colPrimary
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "WALLPAPERS"
                color: "#EEEEEE"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.letterSpacing: 2.0
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1; height: 14
                color: "#44FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: (list.selectedIndex + 1).toString().padStart(2, '0') + " / " + folderModel.count.toString().padStart(2, '0')
                color: Appearance.colors.colPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // --- Main Carousel ---
    ListView {
        id: list
        anchors.centerIn: parent
        width: parent.width
        height: parent.height * 0.72
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: 0
        clip: false
        cacheBuffer: 600

        property real tileSlotWidth: Math.round(width / Math.max(1, root.visibleTiles))
        property int  selectedIndex : 0

        currentIndex: selectedIndex
        preferredHighlightBegin: (width - tileSlotWidth) / 2
        preferredHighlightEnd:   (width + tileSlotWidth) / 2
        highlightRangeMode:      ListView.StrictlyEnforceRange
        highlightMoveDuration:   180

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }

        function activateCurrent() {
            const path = folderModel.get(selectedIndex, "filePath")
            if (path) Wallpapers.apply(path)
            root.dismissed()
        }

        function moveSelection(delta) {
            selectedIndex = clampIndex(selectedIndex + delta)
        }

        delegate: Item {
            id: tile
            width: list.tileSlotWidth
            height: list.height
            property bool active: index === list.selectedIndex
            property int distFromSelected: Math.abs(index - list.selectedIndex)

            z: active ? 100 : Math.max(1, 50 - distFromSelected)

            property real targetScale: {
                if (distFromSelected === 0) return 1.0;
                if (distFromSelected === 1) return 0.82;
                if (distFromSelected === 2) return 0.68;
                return 0.58;
            }

            property real targetOpacity: {
                if (distFromSelected === 0) return 1.0;
                if (distFromSelected === 1) return 0.90;
                if (distFromSelected === 2) return 0.70;
                return 0.45;
            }

            Item {
                id: content
                anchors.centerIn: parent
                width: parent.width - root.baseSpacing
                height: parent.height * 0.94
                scale: tile.targetScale
                opacity: tile.targetOpacity
                transform: Shear { xFactor: root.slantFactor }

                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }

                Item {
                    id: imageContainer
                    anchors.fill: parent

                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: 18
                        }
                    }

                    Image {
                        id: img
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true
                        opacity: status === Image.Ready ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }

                        source: root.thumbCacheDir.length > 0
                            ? ("file://" + root.thumbCacheDir + fileName)
                            : ""

                        sourceSize.width: 500
                        sourceSize.height: 700

                        Timer {
                            id: retryTimer
                            interval: 1200; repeat: false
                            onTriggered: { const s = img.source; img.source = ""; img.source = s }
                        }
                        onStatusChanged: {
                            if (status === Image.Error) retryTimer.start()
                        }
                    }
                }

                // Active Futuristic Border
                Rectangle {
                    z: 10
                    anchors.fill: parent
                    radius: 18
                    visible: tile.active
                    color: "transparent"
                    border.width: 3
                    border.color: Appearance.colors.colPrimary
                }

                // Inner Accent Line on top
                Rectangle {
                    z: 11
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 4
                    height: 3
                    radius: 2
                    visible: tile.active
                    color: "#CCFFFFFF"
                }

                // Filename chip at bottom — only on active tile
                Rectangle {
                    z: 12
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 14
                    width: Math.min(parent.width - 20, nameLabel.implicitWidth + 28)
                    height: 30
                    radius: 10
                    color: "#E0101014"
                    border.width: 1
                    border.color: "#40FFFFFF"
                    opacity: tile.active ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        id: nameLabel
                        anchors.centerIn: parent
                        text: fileName
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.letterSpacing: 0.5
                        elide: Text.ElideMiddle
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        transform: Shear { xFactor: -root.slantFactor } // Keep text straight & readable
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.selectedIndex = index
                onClicked:  list.activateCurrent()
                onWheel: function(wheel) {
                    list.moveSelection(wheel.angleDelta.y < 0 ? 1 : -1)
                    wheel.accepted = true
                }
            }
        }

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Left:  case Qt.Key_K: moveSelection(-1);    break
            case Qt.Key_Right: case Qt.Key_J: moveSelection(1);     break
            case Qt.Key_Space: case Qt.Key_Return: activateCurrent(); break
            case Qt.Key_Escape: root.dismissed();                    break
            default: return
            }
            event.accepted = true
        }
    }
}
