import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    hoverEnabled: true

    signal requestReset()

    configEntryName: "media"

    readonly property var playerList: MprisController.players
    property MprisPlayer currentPlayer: MprisController.activePlayer
    property string displayedArtFilePath: MprisController.readyArtFilePath
    property real widgetHeight: 126
    property real artSize: 98
    property real buttonSize: 34
    property real buttonIconSize: 18
    property bool showLyrics: false

    property string sizeMode: root.configEntry.sizeMode ?? "1x3"

    readonly property real singleWidth: 132
    readonly property real snapWidth1: root.singleWidth
    readonly property real snapWidth2: 276
    readonly property real snapWidth3: 450

    property real widgetWidth: {
        switch (root.sizeMode) {
            case "1x1": return root.snapWidth1
            case "2x2": return root.snapWidth2
            default:    return root.snapWidth3
        }
    }

    Behavior on widgetWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    function modeForWidth(value) {
        var mid1 = (root.snapWidth1 + root.snapWidth2) / 2
        var mid2 = (root.snapWidth2 + root.snapWidth3) / 2
        if (value < mid1) return "1x1"
        if (value < mid2) return "2x2"
        return "1x3"
    }

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    StyledRectangularShadow {
        target: card
        z: -2
    }

    Rectangle {
        id: card
        implicitWidth: root.widgetWidth
        implicitHeight: {
            if (root.sizeMode === "1x1") return root.singleWidth
            if (root.sizeMode === "2x2") return 252
            return root.artSize + 28 + 36 + (root.showLyrics ? 264 : 0)
        }
        radius: Appearance.rounding?.verylarge ?? 30
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: card.width
                height: card.height
                radius: card.radius
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (root.sizeMode === "1x1") return oneByOneContent
                if (root.sizeMode === "2x2") return twoByTwoContent
                return oneByThreeContent
            }
        }

        Component {
            id: oneByOneContent
            Item {
                anchors.fill: parent

                // Crisp, pure cover art (no blur)
                StyledImage {
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    sourceSize.width: 264
                    sourceSize.height: 264
                    visible: root.displayedArtFilePath !== ""
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: 40
                    color: Appearance.colors.colOnSecondaryContainer
                    visible: root.displayedArtFilePath === ""
                }

                // Compact, refined floating play/pause button at bottom middle
                Item {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                    implicitWidth: 26
                    implicitHeight: 26

                    MaterialShape {
                        id: miniSpinShape
                        anchors.fill: parent
                        color: Appearance.colors.colPrimary
                        shape: MaterialShape.Shape.Cookie12Sided

                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 22000
                            loops: Animation.Infinite
                            running: root.currentPlayer?.isPlaying ?? false
                            easing.type: Easing.Linear
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                        iconSize: 14
                        fill: 1
                        color: Appearance.colors.colOnPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.togglePlaying()
                    }
                }
            }
        }

        Component {
            id: twoByTwoContent
            Item {
                anchors.fill: parent

                Image {
                    id: blurredArt
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    sourceSize.width: card.width
                    sourceSize.height: card.height
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true
                    visible: root.displayedArtFilePath !== ""

                    layer.enabled: true
                    layer.effect: StyledBlurEffect {
                        source: blurredArt
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.45)
                        radius: card.radius
                    }
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 0

                    Item { Layout.fillHeight: true }

                    // Centered Album Art Card
                    Rectangle {
                        id: artCard
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 96
                        Layout.alignment: Qt.AlignHCenter
                        color: Appearance.colors.colSurfaceContainerLow
                        radius: 20
                        clip: true

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artCard.width
                                height: artCard.height
                                radius: artCard.radius
                            }
                        }

                        StyledImage {
                            anchors.fill: parent
                            source: root.displayedArtFilePath
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                            sourceSize.width: 192
                            sourceSize.height: 192
                            visible: root.displayedArtFilePath !== ""
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "music_note"
                            iconSize: 40
                            color: Appearance.colors.colOnSurfaceVariant
                            visible: root.displayedArtFilePath === ""
                        }
                    }

                    Item { Layout.preferredHeight: 12 }

                    // Centered Title & Artist Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.currentPlayer?.trackTitle ?? Translation.tr("No media playing")
                            font {
                                pixelSize: Appearance.font.pixelSize.normal ?? 14
                                weight: Font.DemiBold
                            }
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.currentPlayer?.trackArtist ?? Translation.tr("Unknown artist")
                            font {
                                pixelSize: Appearance.font.pixelSize.small ?? 12
                            }
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.65
                        }
                    }
                    
                    Item { Layout.preferredHeight: 12 }

                    // Centered Controls Row
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding?.full ?? 999
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                            colRipple: Appearance.colors.colPrimaryContainerActive
                            downAction: () => MprisController.previous()

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                iconSize: 20
                                fill: 1
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        Item {
                            implicitWidth: 46
                            implicitHeight: 46

                            MaterialShape {
                                id: spinShape
                                anchors.fill: parent
                                color: Appearance.colors.colPrimary
                                shape: MaterialShape.Shape.Cookie12Sided

                                RotationAnimation on rotation {
                                    from: 0; to: 360
                                    duration: 22000
                                    loops: Animation.Infinite
                                    running: root.currentPlayer?.isPlaying ?? false
                                    easing.type: Easing.Linear
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                                iconSize: 22
                                fill: 1
                                color: Appearance.colors.colOnPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MprisController.togglePlaying()
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding?.full ?? 999
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                            colRipple: Appearance.colors.colPrimaryContainerActive
                            downAction: () => MprisController.next()

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"
                                iconSize: 20
                                fill: 1
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
        Component {
            id: oneByThreeContent
            Item {
                anchors.fill: parent
Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: card.width
            sourceSize.height: card.height
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true
            visible: root.displayedArtFilePath !== ""

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.45)
                radius: card.radius
            }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Main Row
            Item {
                width: parent.width
                height: root.artSize + 28

                Rectangle {
                    id: artRect
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    width: root.artSize
                    height: root.artSize
                    color: Appearance.colors.colSurfaceContainerLow
                    radius: 20
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artRect.width
                            height: artRect.height
                            radius: artRect.radius
                        }
                    }

                    StyledImage {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: artRect.width * 2
                        sourceSize.height: artRect.height * 2
                        visible: root.displayedArtFilePath !== ""
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "music_note"
                        iconSize: artRect.width / 2.5
                        color: Appearance.colors.colOnSecondaryContainer
                        visible: root.displayedArtFilePath === ""
                    }
                }

                ColumnLayout {
                    anchors {
                        left: artRect.right
                        right: parent.right
                        top: artRect.top
                        bottom: artRect.bottom
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 4

                    // Artist + Title
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackArtist ?? "Play"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentPlayer?.trackTitle ?? Translation.tr("Something")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.65
                            elide: Text.ElideRight
                        }
                    }

                    // Controls pill
                    Rectangle {
                        id: controlsPill
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: controlsRow.implicitWidth + 10
                        implicitHeight: root.buttonSize + 8
                        radius: Appearance.rounding?.full ?? 999
                        color: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.9)

                        RowLayout {
                            id: controlsRow
                            anchors.centerIn: parent
                            spacing: 2

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: root.showLyrics && !LyricsService.ccMode
                                    ? Appearance.colors.colPrimary
                                    : "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => {
                                    if (LyricsService.ccMode) {
                                        LyricsService.ccMode = false
                                        LyricsService.restartLyrics()
                                    }
                                    root.showLyrics = !root.showLyrics
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "lyrics"
                                    iconSize: root.buttonIconSize
                                    fill: root.showLyrics && !LyricsService.ccMode ? 1 : 0
                                    color: root.showLyrics && !LyricsService.ccMode
                                        ? Appearance.colors.colOnPrimary
                                        : Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: LyricsService.ccMode
                                    ? Appearance.colors.colPrimary
                                    : "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => {
                                    if (LyricsService.ccMode && !root.showLyrics) {
                                        root.showLyrics = true
                                    } else {
                                        LyricsService.toggleCC()
                                        root.showLyrics = LyricsService.ccMode
                                    }
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "closed_caption"
                                    iconSize: root.buttonIconSize
                                    fill: LyricsService.ccMode ? 1 : 0
                                    color: LyricsService.ccMode
                                        ? Appearance.colors.colOnPrimary
                                        : Appearance.colors.colOnPrimaryContainer
                                }
                            }

                            // Play/pause: outer Item at original button size;
                            // the shape rotates, the icon inside stays still
                            Item {
                                implicitWidth: root.buttonSize + 16
                                implicitHeight: root.buttonSize + 16

                                MaterialShape {
                                    id: spinShape
                                    anchors.fill: parent
                                    color: Appearance.colors.colPrimary
                                    shape: MaterialShape.Shape.Cookie12Sided

                                    RotationAnimation on rotation {
                                        from: 0; to: 360
                                        duration: 22000
                                        loops: Animation.Infinite
                                        running: root.currentPlayer?.isPlaying ?? false
                                        easing.type: Easing.Linear
                                    }
                                }

                                // Icon is a direct sibling of the shape — NOT a child — so it never rotates
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
                                    iconSize: root.buttonIconSize + 4
                                    fill: 1
                                    color: Appearance.colors.colOnPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MprisController.togglePlaying()
                                }
                            }

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => MprisController.next()
                                altAction: () => MprisController.previous()

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "skip_next"
                                    iconSize: root.buttonIconSize
                                    fill: 1
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                        }
                    }
                }
            }

            // ── Wavy progress bar row ─────────────────────────────────────────
            Item {
                width: parent.width
                height: 36

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16
                        rightMargin: 16
                    }
                    spacing: 8

                    StyledText {
                        text: {
                            const pos = root.currentPlayer?.position ?? 0
                            const m = Math.floor(pos / 60)
                            const s = Math.floor(pos % 60)
                            return m + ":" + (s < 10 ? "0" : "") + s
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller ?? 12 ?? 10
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.5
                        font.features: { "tnum": 1 }
                    }

                    StyledSlider {
                        id: trackSlider
                        Layout.fillWidth: true
                        configuration: StyledSlider.Configuration.Wavy
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.8)
                        handleColor: Appearance.colors.colPrimary
                        value: {
                            if (trackSlider.pressed) return trackSlider.value
                            const len = root.currentPlayer?.length ?? 1
                            const pos = root.currentPlayer?.position ?? 0
                            return len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
                        }
                        onMoved: {
                            if (root.currentPlayer && root.currentPlayer.length > 0) {
                                root.currentPlayer.position = value * root.currentPlayer.length
                            }
                        }
                    }

                    StyledText {
                        text: {
                            const len = root.currentPlayer?.length ?? 0
                            const m = Math.floor(len / 60)
                            const s = Math.floor(len % 60)
                            return m + ":" + (s < 10 ? "0" : "") + s
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller ?? 12 ?? 10
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.5
                        font.features: { "tnum": 1 }
                    }
                }
            }

            // Divisor
            Item {
                width: parent.width
                height: root.showLyrics ? 2 : 0
                visible: root.showLyrics

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Appearance.colors.colOnPrimaryContainer }
                        GradientStop { position: 0.8; color: Appearance.colors.colOnPrimaryContainer }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.15
                }
            }

            Item {
                width: parent.width
                height: root.showLyrics ? 250 : 0
                visible: root.showLyrics

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 8
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.55)
                    radius: Appearance.rounding.normal
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)

                    Lyrics {
                        anchors.fill: parent
                        anchors.margins: 10
                        textAlignment: Text.AlignHCenter
                        textColor: Appearance.colors.colOnLayer0
                        activeColor: Appearance.colors.colPrimary
                        dimColor: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                        indicatorColor: Appearance.colors.colPrimary
                        indicatorShapeColor: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    
            }
        }
    }

    ResizeHandler {
        anchorItem: card
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        currentWidth: root.widgetWidth
        onResized: (newWidth) => {
            root.sizeMode = root.modeForWidth(newWidth)
        }
        onResizeFinished: {
            if (root.configEntry) {
                root.configEntry.sizeMode = root.sizeMode
            }
        }
    }
}
