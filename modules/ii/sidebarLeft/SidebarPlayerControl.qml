pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    property var player: MprisController.activePlayer
    property string effectiveArtUrl: {
        const url = root.player?.trackUrl || ""
        let ytMatch = url.match(/(?:v=|\/vi\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/)
        if (ytMatch && ytMatch[1]) {
            return "https://img.youtube.com/vi/" + ytMatch[1] + "/hqdefault.jpg"
        }
        return root.player?.trackArtUrl ?? ""
    }
    
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(effectiveArtUrl) + ".jpg"
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: Config.options.sidebar.media.artColors
        ? ColorUtils.mix(
            (colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary),
            Appearance.colors.colPrimaryContainer,
            0.8
          )
        : Appearance.colors.colPrimaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000
    property int visualizerSmoothing: 2
    property real radius

    property string displayedArtFilePath: {
        if (!effectiveArtUrl || effectiveArtUrl.length === 0) return ""
        if (downloaded) return Qt.resolvedUrl(artFilePath)
        return ""
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player?.positionChanged()  
    }

    onArtFilePathChanged: {
        if (!effectiveArtUrl || effectiveArtUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
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

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: -1
        anchors.bottomMargin: 4
        color: ColorUtils.transparentize(artDominantColor, 0.9)
        radius: Appearance.rounding.normal

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: background.width
            sourceSize.height: background.height
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
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.45)
                radius: Appearance.rounding.normal
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.height * 0.04
            spacing: 0

            // ── Player selector & CC Toggle ──
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 8

                StyledComboBox {
                    id: playerSelector
                    visible: MprisController.players.length > 1
                    Layout.fillWidth: true
                    model: MprisController.players.map(p => {
                        let name = p.identity ?? p.desktopEntry ?? "Unknown"
                        if (name === "Mozilla Firefox") return "Zen Browser"
                        return name
                    })
                    currentIndex: Math.max(0, MprisController.players.indexOf(MprisController.activePlayer))
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < MprisController.players.length) {
                            MprisController.setActivePlayer(MprisController.players[currentIndex])
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 34
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.full
                    colBackground: LyricsService.ccMode
                        ? blendedColors.colPrimary
                        : ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colPrimaryHover
                    colRipple: blendedColors.colPrimaryActive
                    downAction: () => LyricsService.toggleCC()
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: LyricsService.ccMode ? 1 : 0
                        horizontalAlignment: Text.AlignHCenter
                        color: LyricsService.ccMode
                            ? blendedColors.colOnPrimary
                            : blendedColors.colOnSecondaryContainer
                        text: "closed_caption"
                    }
                }
            }

            // ── Album art ──
            Item {
                id: artContainer
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.min(parent.width * 0.35, parent.height * 0.35)
                implicitHeight: implicitWidth
                Layout.bottomMargin: 10

                Image {
                    id: coverArt
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artContainer.implicitWidth
                            height: artContainer.implicitHeight
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            // ── Track info ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    id: titleText
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.huge 
                    font.bold: true
                    color: blendedColors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || "No media playing"

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: titleText; property: "x"; to: -titleText.width; duration: 150; easing.type: Easing.InQuad }
                            PropertyAction { target: titleText; property: "text" }
                            NumberAnimation { target: titleText; property: "x"; from: titleText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                }

                Item {
                    id: artistTextContainer
                    Layout.fillWidth: true
                    implicitHeight: artistText.implicitHeight
                    clip: true

                    StyledText {
                        id: artistText
                        anchors.fill: parent
                        font.pixelSize: Appearance.font.pixelSize.large 
                        color: blendedColors.colSubtext
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.player?.trackArtist || "Something"

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: artistText; property: "x"; to: -artistText.width; duration: 150; easing.type: Easing.InQuad }
                                PropertyAction { target: artistText; property: "text" }
                                NumberAnimation { target: artistText; property: "x"; from: artistText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // ── Lyrics ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.55)
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.85)

                Lyrics {
                    id: lyricsComp
                    anchors.fill: parent
                    anchors.margins: 10
                    opacity: MprisController.activePlayer !== null ? 1 : 0 
                    textAlignment: Text.AlignHCenter
                    textColor: Appearance.colors.colOnPrimaryContainer
                    activeColor: Appearance.colors.colPrimary
                    dimColor: Appearance.colors.colSubtext
                    indicatorColor: {
                        let c = root.blendedColors.colPrimaryContainer
                        return (c && c != "#000000" && c != "transparent") ? c : root.artDominantColor
                    }
                    indicatorShapeColor: {
                        let c = root.blendedColors.colOnPrimaryContainer
                        if (c && c != "#000000" && c != "#ffffff" && c != "transparent") return c
                        return root.blendedColors.colPrimary || Appearance.colors.colPrimary
                    }
                }
            }

            // ── Progress ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 5
                spacing: 12

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: blendedColors.colSubtext
                    font.letterSpacing: -0.4
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                    Loader {
                        id: sliderLoader
                        anchors.fill: parent
                        active: root.player?.canSeek ?? false  
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            handleColor: blendedColors.colPrimary
                            value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                            onMoved: {root.player.position = value * root.player.length
                                lyricsComp.restartLyrics()
                            }
                        }
                    }

                    Loader {
                        id: progressBarLoader
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                        }
                        active: !(root.player?.canSeek ?? false)  
                        sourceComponent: StyledProgressBar {
                            wavy: root.player?.isPlaying ?? false  
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                        }
                    }
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal 
                    color: blendedColors.colSubtext
                    font.letterSpacing: -0.4
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                }
            }

            // ── Controls ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                RippleButton {
                    property real baseSize: Math.max(42, parent.parent.height * 0.06)
                    implicitWidth: baseSize * 1.5
                    implicitHeight: baseSize * 1.5
                    buttonRadius: Appearance.rounding.verylarge
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => root.player?.previous()
                    contentItem: MaterialSymbol {
                        iconSize: 25
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "skip_previous"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(70, parent.parent.height * 0.1)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: (root.player?.isPlaying ?? false) ? Appearance.rounding.verylarge : baseSize / 2  
                    colBackground: (root.player?.isPlaying ?? false) ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                    colBackgroundHover: (root.player?.isPlaying ?? false) ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                    colRipple: (root.player?.isPlaying ?? false) ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                    downAction: () => root.player?.togglePlaying()  
                    contentItem: MaterialSymbol {
                        iconSize: 50
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: (root.player?.isPlaying ?? false) ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                        text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(42, parent.parent.height * 0.06)
                    implicitWidth: baseSize * 1.5
                    implicitHeight: baseSize * 1.5
                    buttonRadius: Appearance.rounding.verylarge
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => root.player?.next()
                    contentItem: MaterialSymbol {
                        iconSize: 25
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "skip_next"
                    }
                }
            }

            // ── Volume ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 8

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    implicitWidth: baseSize
                    implicitHeight: baseSize
                    buttonRadius: Appearance.rounding.large
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => {
                        if (root.player && root.player.volumeSupported) {
                            root.player.volume = (root.player.volume > 0) ? 0 : 1.0  
                        } else {
                            Audio.toggleMute()
                        }
                    }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: (Audio.muted || (root.player?.volume ?? 1) <= 0) ? "volume_off"
                            : (Audio.volume < 0.5) ? "volume_down"
                            : "volume_up"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: Appearance.rounding.large
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => {
                        if (root.player && root.player.volumeSupported) {
                            root.player.volume = Math.max(0, (root.player.volume ?? 1) - 0.05)  
                        } else {
                            Audio.decrementVolume(0.05)
                        }
                    }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "volume_down"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: Appearance.rounding.large
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => {
                        if (root.player && root.player.volumeSupported) {
                            root.player.volume = Math.min(1.0, (root.player.volume ?? 1) + 0.05)  
                        } else {
                            Audio.incrementVolume(0.05)
                        }
                    }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "volume_up"
                    }
                }
            }
        }
    }
}