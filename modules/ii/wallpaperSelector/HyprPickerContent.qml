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

    // ---- Tunables ----
    property int    animDuration  : 200
    property int    scrollSpeed   : 6000
    property real   zoomScale     : 0.88
    property real   edgeScale     : 0.50
    property int    baseSpacing   : 18
    property int    visibleTiles  : 5
    property string activeShape   : Config.options.wallpaperSelector.shape || "cyberpunk"
    property string activeBehavior: Config.options.wallpaperSelector.behavior || "standard"
    readonly property bool isPanoramic: activeBehavior === "panoramic"
    // ------------------


    // Folder model — points at the same directory ballade's Wallpapers service watches
    FolderListModel {
        id: folderModel
        folder: Wallpapers.directory
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
    }

    // --- Main Carousel ---
    ListView {
        id: list
        anchors.centerIn: parent
        width: parent.width
        height: parent.height * 0.78
        focus: true

        model: folderModel
        orientation: ListView.Horizontal
        spacing: 0
        clip: false
        cacheBuffer: 600

        property bool isPanoramic  : root.activeBehavior === "panoramic"
        property real tileSlotWidth : Math.round(width / 5.0) // Standardize slot width to prevent massive gaps
        property int  selectedIndex : 0
        property bool _initializedIndex: false

        Connections {
            target: folderModel
            function onCountChanged() {
                if (!list._initializedIndex && folderModel.count > 0) {
                    list._initializedIndex = true;
                    
                    let activePath = Config.options.background.wallpaperPath;
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
                }
            }
        }

        // Center all items if they don't fill the screen, otherwise allow normal scrolling
        property real totalContentWidth: folderModel.count * tileSlotWidth
        leftMargin: totalContentWidth < width ? (width - totalContentWidth) / 2 : width / 2
        rightMargin: leftMargin

        currentIndex: selectedIndex
        preferredHighlightBegin: (width - tileSlotWidth) / 2
        preferredHighlightEnd:   (width + tileSlotWidth) / 2
        highlightRangeMode:      ListView.StrictlyEnforceRange
        highlightMoveDuration:   180
        interactive:             true

        function clampIndex(i) { return Math.max(0, Math.min(i, count - 1)) }

        function activateCurrent() {
            const path = folderModel.get(selectedIndex, "filePath")
            if (path) Wallpapers.apply(FileUtils.trimFileProtocol(path))
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
            property int deltaIndex: index - list.selectedIndex

            // ONLY calculate continuous physical distance for NON-PANORAMIC (scrolling modes)
            property real itemCenter: x + width / 2
            property real viewCenter: list.contentX + list.width / 2
            property real continuousDelta: list.isPanoramic ? deltaIndex : ((itemCenter - viewCenter) / list.tileSlotWidth)
            property real distFromCenter: Math.abs(continuousDelta)

            z: 100 - Math.round(distFromCenter * 10)

            property real targetScale: {
                if (list.isPanoramic) {
                    if (distFromSelected === 0) return 1.15;
                    return Math.max(0.50, 0.85 - ((distFromSelected - 1) * 0.03));
                } else {
                    return 0.88 + Math.max(0, (1.0 - distFromCenter)) * 0.20;
                }
            }

            property real targetY: {
                if (list.isPanoramic) {
                    if (distFromSelected === 0) return -40;
                    return Math.min(100, (distFromSelected - 1) * 5);
                } else {
                    return -20 * Math.max(0, (1.0 - distFromCenter));
                }
            }

            property real targetXOffset: {
                if (list.isPanoramic) {
                    if (distFromSelected === 0) return 0;
                    let push = 30; // Reduced from 160 to fix massive gap
                    return deltaIndex < 0 ? -push : push;
                }
                return 0;
            }

            // Keep opaque for all 3 modes
            property real targetOpacity: 1.0

            Behavior on targetScale { enabled: list.isPanoramic; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on targetY { enabled: list.isPanoramic; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on targetXOffset { enabled: list.isPanoramic; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Item {
                id: content
                x: parent.width / 2 - width / 2 + tile.targetXOffset
                y: parent.height / 2 - height / 2 + tile.targetY
                
                // For panoramic, visual card is large and overlaps tightly packed slots
                width: list.isPanoramic ? 320 : parent.width - root.baseSpacing
                height: parent.height * 0.94
                
                scale: tile.targetScale
                opacity: tile.targetOpacity
                transform: Shear { xFactor: root.activeShape === "cyberpunk" ? -0.12 : 0.0 }


                Item {
                    id: imageContainer
                    anchors.fill: parent

                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: 20
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

                // Active Border Highlighter (Clean 20px radius card border, zero bleed!)
                Rectangle {
                    id: activeHighlight
                    z: 10
                    anchors.fill: parent
                    radius: 20
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
                    anchors.bottomMargin: 14
                    width: Math.min(parent.width - 16, nameLabel.implicitWidth + 28)
                    height: 30
                    radius: 15
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
                        transform: Shear { xFactor: root.activeShape === "cyberpunk" ? 0.12 : 0.0 }
                    }
                }
            }
            MouseArea {
                anchors.fill: content
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
