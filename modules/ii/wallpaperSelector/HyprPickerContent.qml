import qs
import QtQuick
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

    Component.onCompleted: {
        list.forceActiveFocus();
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

    // ---- Settings / Tunables ----
    property int    animDuration      : 180
    property int    scrollSpeed       : 5000
    property real   zoomScale         : 0.94       // Center tile scale
    property real   edgeScale         : 0.48       // Edge tile scale
    property int    baseSpacing       : 12
    property int    numberOfPictures  : 14         // Target visible tiles across screen width
    property string activeShape       : Config.options.wallpaperSelector.shape || "cyberpunk"
    // ----------------------------

    // Folder model — points at the same directory ballade's Wallpapers service watches
    FolderListModel {
        id: folderModel
        folder: Wallpapers.directory
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
    }

    // --- Main Panoramic Carousel ---
    ListView {
        id: list
        anchors.centerIn: parent
        width: parent.width
        height: Math.round(parent.height * 0.54)
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: root.baseSpacing
        clip: false
        cacheBuffer: 1200

        property int selectedIndex: 0
        property real tileWidth: folderModel.count > 0 
            ? Math.max(50, Math.min(240, (width - (spacing * Math.max(0, folderModel.count - 1))) / folderModel.count))
            : 120
        property real totalContentWidth: folderModel.count * tileWidth + Math.max(0, folderModel.count - 1) * spacing
        leftMargin: totalContentWidth < width ? Math.max(0, (width - totalContentWidth) / 2) : 0
        rightMargin: leftMargin
        property real viewportCenterX: width / 2

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }
        function clampX(x)     { return Math.max(0, Math.min(x, contentWidth - width)) }

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

        function ensureVisible(i) {
            const step = tileWidth + spacing
            const start = i * step
            const end   = start + tileWidth + 20
            if (start < contentX)
                contentX = clampX(start)
            else if (end > contentX + width)
                contentX = clampX(start - (width - step))
        }

        function moveSelection(delta) {
            selectedIndex = clampIndex(selectedIndex + delta)
            ensureVisible(selectedIndex)
        }

        Behavior on contentX {
            SmoothedAnimation { duration: root.animDuration; velocity: root.scrollSpeed }
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
                        list.selectedIndex = foundIndex;
                    } else {
                        list.selectedIndex = Math.max(0, Math.floor((folderModel.count - 1) / 2));
                    }
                    list.ensureVisible(list.selectedIndex);
                }
            }
        }

        delegate: Item {
            id: tile
            width: list.tileWidth
            height: list.height
            property bool active: index === list.selectedIndex

            // Horizontal stretch boost — active tile expands wider
            property real widthBoost: active ? 0.35 : 0.0
            Behavior on widthBoost {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // Vertical boost — active tile also grows slightly taller
            property real selectionBoost: active ? 0.06 : 0.0
            Behavior on selectionBoost {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // Position-based magnification (smoothstep panorama arc)
            property real tileCenterX: list.leftMargin + (index * (list.tileWidth + list.spacing)) - list.contentX + (list.tileWidth / 2)
            property real frac: Math.min(1.0, Math.abs(tileCenterX - list.viewportCenterX) / Math.max(1, list.viewportCenterX))
            property real smoothT: 1.0 - frac * frac * (3.0 - 2.0 * frac)
            property real scaleFactor: root.edgeScale + (root.zoomScale - root.edgeScale) * smoothT + selectionBoost

            z: active ? 100 : Math.round(scaleFactor * 50)

            Item {
                id: content
                anchors.centerIn: parent
                width: parent.width * (1.0 + tile.widthBoost)
                height: parent.height * Math.min(1.0, tile.scaleFactor)
                transform: Shear { xFactor: root.activeShape === "cyberpunk" ? -0.10 : 0.0 }

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

                        source: "file://" + FileUtils.trimFileProtocol(filePath)

                        sourceSize: Qt.size(Math.max(1, Math.round(tile.width * 2.5)), Math.max(1, Math.round(list.height * 1.5)))

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

                // Active Border Highlighter (Clean 18px radius card border)
                Rectangle {
                    id: activeHighlight
                    z: 10
                    anchors.fill: parent
                    radius: 18
                    visible: tile.active
                    color: "transparent"
                    border.width: 3.5
                    border.color: Appearance.colors.colPrimary
                }

                // Filename chip at bottom — only on active card
                Rectangle {
                    z: 12
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 10
                    width: Math.min(parent.width - 12, nameLabel.implicitWidth + 24)
                    height: 28
                    radius: 14
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
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 0.4
                        elide: Text.ElideMiddle
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        transform: Shear { xFactor: root.activeShape === "cyberpunk" ? 0.10 : 0.0 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    list.selectedIndex = index
                    list.ensureVisible(index)
                }
                onClicked: list.activateCurrent()
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
