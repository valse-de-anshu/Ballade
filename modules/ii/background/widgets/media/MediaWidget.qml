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

    signal requestReset()

    configEntryName: "media"

    readonly property var playerList: MprisController.players
    property MprisPlayer currentPlayer: MprisController.activePlayer
    property string effectiveArtUrl: {
        const url = root.currentPlayer?.trackUrl || ""
        let ytMatch = url.match(/(?:v=|\/vi\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/)
        if (ytMatch && ytMatch[1]) {
            return "https://img.youtube.com/vi/" + ytMatch[1] + "/hqdefault.jpg"
        }
        return root.currentPlayer?.trackArtUrl ?? ""
    }

    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(effectiveArtUrl) + ".jpg"
    property string artFilePath: `${artDownloadLocation}/${artFileName}`

    property real widgetWidth: 450
    property real widgetHeight: 126
    property real artSize: 98
    property real buttonSize: 34
    property real buttonIconSize: 18

    property bool downloaded: false
    property bool showLyrics: false

    property string displayedArtFilePath: {
        if (!effectiveArtUrl || effectiveArtUrl.length === 0) return ""
        if (downloaded) return Qt.resolvedUrl(artFilePath)
        return ""
    }

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    onArtFilePathChanged: updateArt()

    function updateArt() {
        if (!effectiveArtUrl || effectiveArtUrl.length === 0) {
            root.downloaded = false
            return
        }
        coverArtDownloader.targetFile = effectiveArtUrl
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.effectiveArtUrl
        property string artFilePath: root.artFilePath
        command: ["bash", "-c", `
            if [ -f '${artFilePath}' ]; then exit 0; fi
            if [[ '${targetFile}' == file://* ]]; then
                src_file="${targetFile.replace("file://", "")}"
                for i in {1..20}; do
                    if [ -s "$src_file" ]; then break; fi
                    sleep 0.1
                done
            fi
            curl -sSL '${targetFile}' -o '${artFilePath}'
        `]
        onExited: (exitCode, exitStatus) => { root.downloaded = true }
    }

    StyledRectangularShadow {
        target: card
        z: -2
    }

    Rectangle {
        id: card
        implicitWidth: root.widgetWidth
        implicitHeight: root.artSize + 28 + 36 + (root.showLyrics ? 264 : 0)
        radius: Appearance.rounding?.verylarge ?? 30
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)
        clip: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: card.width
                height: card.height
                radius: card.radius
            }
        }

        Behavior on implicitHeight {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

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
                                    onClicked: root.currentPlayer?.togglePlaying()
                                }
                            }

                            RippleButton {
                                implicitWidth: root.buttonSize
                                implicitHeight: root.buttonSize
                                buttonRadius: Appearance.rounding?.full ?? 999
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                colRipple: Appearance.colors.colPrimaryContainerActive
                                downAction: () => root.currentPlayer?.next()
                                altAction: () => root.currentPlayer?.previous()

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
                        font.pixelSize: Appearance.font.pixelSize.smaller ?? 10
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.5
                        font.features: { "tnum": 1 }
                    }

                    StyledSlider {
                        id: trackSlider
                        Layout.fillWidth: true
                        configuration: StyledSlider.Configuration.Wavy
                        trackWidth: 10
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.8)
                        handleColor: Appearance.colors.colPrimary
                        value: {
                            const len = root.currentPlayer?.length ?? 0
                            const pos = root.currentPlayer?.position ?? 0
                            return len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
                        }
                        onMoved: {
                            const len = root.currentPlayer?.length ?? 0
                            if (len > 0) root.currentPlayer?.seek(value * len)
                        }
                    }

                    StyledText {
                        text: {
                            const len = root.currentPlayer?.length ?? 0
                            const m = Math.floor(len / 60)
                            const s = Math.floor(len % 60)
                            return m + ":" + (s < 10 ? "0" : "") + s
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller ?? 10
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
