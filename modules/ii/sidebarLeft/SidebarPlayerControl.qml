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
    property string displayedArtFilePath: MprisController.readyArtFilePath

    property color artDominantColor: Config.options.sidebar.media.artColors
        ? ColorUtils.mix(
            (colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary),
            Appearance.colors.colPrimaryContainer,
            0.8
          )
        : Appearance.colors.colPrimaryContainer

    readonly property bool isWide: width >= 560
    readonly property bool hasMedia: root.player !== null && Boolean(root.player.trackTitle || root.player.isPlaying)

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player?.positionChanged()
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

    // ── Background Ambient Art Blur & Tint ──
    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: 4
        color: ColorUtils.transparentize(artDominantColor, 0.90)
        radius: Appearance.rounding.large

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
            visible: Boolean(root.displayedArtFilePath)

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.48)
                radius: background.radius
            }
        }

        // Fallback ambient gradient if no cover art is present
        Rectangle {
            anchors.fill: parent
            visible: !root.displayedArtFilePath
            color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.25)
            radius: background.radius
        }

        // ══════════════════════════════════════════════════════════════
        // ── RESPONSIVE CONTENT AREA ───────────────────────────────────
        // ══════════════════════════════════════════════════════════════
        Item {
            anchors.fill: parent
            anchors.margins: root.isWide ? 14 : 10

            Loader {
                anchors.fill: parent
                sourceComponent: root.isWide ? wideLayoutComponent : compactLayoutComponent
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    // ── 1. WIDE / HORIZONTAL SPLIT LAYOUT (Detached or Extended) ──────
    // ══════════════════════════════════════════════════════════════════
    Component {
        id: wideLayoutComponent

        RowLayout {
            anchors.fill: parent
            spacing: 16

            // ── LEFT COLUMN: Playback Card (Art + Info + Transport + Volume) ──
            Rectangle {
                Layout.preferredWidth: Math.min(350, Math.max(280, parent.width * 0.38))
                Layout.fillHeight: true
                radius: Appearance.rounding.large
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.50)
                border.width: 1
                border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.82)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // 1. Player Selector or Identity Header
                    RowLayout {
                        Layout.fillWidth: true
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
                            onActivated: (index) => {
                                if (index >= 0 && index < MprisController.players.length) {
                                    MprisController.setActivePlayer(MprisController.players[index])
                                }
                            }
                        }

                        RowLayout {
                            visible: MprisController.players.length <= 1
                            Layout.fillWidth: true
                            spacing: 6
                            MaterialSymbol {
                                text: "graphic_eq"
                                iconSize: 16
                                color: root.blendedColors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: root.player ? (root.player.identity ?? root.player.desktopEntry ?? "Media Player") : "No Active Player"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: root.blendedColors.colOnLayer0
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // 2. Cover Art with Vinyl Placeholder
                    Item {
                        id: wideArtContainer
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Math.min(190, Math.min(parent.width - 20, parent.height * 0.36))
                        implicitHeight: implicitWidth

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.large
                            color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.40)
                            border.width: 1
                            border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.75)
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.displayedArtFilePath
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                antialiasing: true
                                asynchronous: true
                                visible: Boolean(root.displayedArtFilePath)
                            }

                            // Vinyl Record Placeholder when no art is loaded
                            Item {
                                anchors.fill: parent
                                visible: !root.displayedArtFilePath

                                Rectangle {
                                    anchors.fill: parent
                                    color: ColorUtils.transparentize(root.blendedColors.colPrimaryContainer, 0.25)

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.74; height: width; radius: width / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.70)
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.46; height: width; radius: width / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.70)
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 36; height: 36; radius: 18
                                        color: root.blendedColors.colPrimary
                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: (root.player?.isPlaying ?? false) ? "equalizer" : "music_note"
                                            iconSize: 20
                                            color: root.blendedColors.colOnPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Track Title & Artist
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: root.blendedColors.colOnLayer0
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.player?.trackTitle || "No media playing"
                        }

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: root.blendedColors.colSubtext
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.player?.trackArtist || (root.player ? "Unknown Artist" : "Play something to get started")
                        }
                    }

                    // 4. Progress Bar & Times
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.blendedColors.colSubtext
                            font.features: { "tnum": 1 }
                            text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(wideSlider.implicitHeight, wideBar.implicitHeight)

                            Loader {
                                id: wideSlider
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: root.blendedColors.colPrimary
                                    trackColor: root.blendedColors.colSecondaryContainer
                                    handleColor: root.blendedColors.colPrimary
                                    value: {
                                        if (pressed) return value
                                        const len = root.player?.length ?? 1
                                        const pos = root.player?.position ?? 0
                                        return len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
                                    }
                                    onMoved: {
                                        if (root.player && root.player.length > 0) {
                                            root.player.position = value * root.player.length
                                        }
                                        LyricsService.syncPosition()
                                    }
                                }
                            }

                            Loader {
                                id: wideBar
                                anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    highlightColor: root.blendedColors.colPrimary
                                    trackColor: root.blendedColors.colSecondaryContainer
                                    value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                                }
                            }
                        }

                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.blendedColors.colSubtext
                            font.features: { "tnum": 1 }
                            text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                        }
                    }

                    // 5. Centered Transport Controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        RippleButton {
                            implicitWidth: 38; implicitHeight: 38
                            buttonRadius: 19
                            colBackground: ColorUtils.transparentize(root.blendedColors.colSecondaryContainer, 0.6)
                            colBackgroundHover: root.blendedColors.colSecondaryContainerHover
                            colRipple: root.blendedColors.colSecondaryContainerActive
                            downAction: () => MprisController.previous()
                            contentItem: MaterialSymbol {
                                iconSize: 22
                                fill: 1
                                horizontalAlignment: Text.AlignHCenter
                                color: root.blendedColors.colOnSecondaryContainer
                                text: "skip_previous"
                            }
                        }

                        // Play / Pause Button (Fixed 52x52 Round Button)
                        RippleButton {
                            implicitWidth: 52; implicitHeight: 52
                            buttonRadius: 26
                            colBackground: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimary : root.blendedColors.colSecondaryContainer
                            colBackgroundHover: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryHover : root.blendedColors.colSecondaryContainerHover
                            colRipple: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryActive : root.blendedColors.colSecondaryContainerActive
                            downAction: () => MprisController.togglePlaying()
                            contentItem: MaterialSymbol {
                                iconSize: 30
                                fill: 1
                                horizontalAlignment: Text.AlignHCenter
                                color: (root.player?.isPlaying ?? false) ? root.blendedColors.colOnPrimary : root.blendedColors.colOnSecondaryContainer
                                text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                            }
                        }

                        RippleButton {
                            implicitWidth: 38; implicitHeight: 38
                            buttonRadius: 19
                            colBackground: ColorUtils.transparentize(root.blendedColors.colSecondaryContainer, 0.6)
                            colBackgroundHover: root.blendedColors.colSecondaryContainerHover
                            colRipple: root.blendedColors.colSecondaryContainerActive
                            downAction: () => MprisController.next()
                            contentItem: MaterialSymbol {
                                iconSize: 22
                                fill: 1
                                horizontalAlignment: Text.AlignHCenter
                                color: root.blendedColors.colOnSecondaryContainer
                                text: "skip_next"
                            }
                        }
                    }

                    // 6. Volume Slider Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            iconSize: 18
                            color: root.blendedColors.colSubtext
                            text: (Audio.sink?.audio?.muted || Audio.volume <= 0) ? "volume_off"
                                : (Audio.volume < 0.5) ? "volume_down"
                                : "volume_up"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Audio.toggleMute()
                                    GlobalStates.osdVolumeOpen = true
                                }
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            configuration: StyledSlider.Configuration.XS
                            from: 0
                            to: 1
                            value: root.player?.volume ?? Audio.volume
                            highlightColor: root.blendedColors.colPrimary
                            trackColor: root.blendedColors.colSecondaryContainer
                            handleColor: root.blendedColors.colPrimary
                            onMoved: {
                                Audio.volume = value
                                if (root.player && root.player.volumeSupported) {
                                    root.player.volume = value
                                }
                                GlobalStates.osdVolumeOpen = true
                            }
                        }

                        StyledText {
                            text: `${Math.round((root.player?.volume ?? Audio.volume) * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.blendedColors.colSubtext
                            Layout.preferredWidth: 34
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── RIGHT COLUMN: Dedicated Lyrics & Subtitles Stage ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.large
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.55)
                border.width: 1
                border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.85)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Lyrics Header: Title + CC Toggle Chip + Reload Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            spacing: 6
                            MaterialSymbol {
                                text: LyricsService.ccMode ? "closed_caption" : "lyrics"
                                iconSize: 18
                                color: root.blendedColors.colPrimary
                            }
                            StyledText {
                                text: LyricsService.ccMode ? Translation.tr("Subtitles / Captions") : Translation.tr("Synchronized Lyrics")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: root.blendedColors.colOnLayer0
                            }
                            StyledText {
                                visible: LyricsService.status === "ok"
                                text: LyricsService.ccMode ? "• YouTube CC" : "• Synced LRC"
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: root.blendedColors.colSubtext
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // CC Toggle Chip
                        Rectangle {
                            implicitWidth: 62; implicitHeight: 28; radius: 14
                            color: LyricsService.ccMode
                                ? root.blendedColors.colPrimary
                                : (wideCcMa.containsMouse ? ColorUtils.transparentize(root.blendedColors.colLayer3, 0.3) : ColorUtils.transparentize(root.blendedColors.colLayer3, 0.6))
                            border.width: 1
                            border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : ColorUtils.transparentize(root.blendedColors.colOutlineVariant, 0.5)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    text: "closed_caption"
                                    iconSize: 15
                                    fill: LyricsService.ccMode ? 1 : 0
                                    color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer0
                                }
                                StyledText {
                                    text: "CC"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer0
                                }
                            }

                            MouseArea {
                                id: wideCcMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LyricsService.toggleCC()
                            }
                        }

                        // Reload Button
                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 14
                            color: wideRefMa.containsMouse ? ColorUtils.transparentize(root.blendedColors.colLayer3, 0.4) : "transparent"
                            border.width: wideRefMa.containsMouse ? 1 : 0
                            border.color: ColorUtils.transparentize(root.blendedColors.colOutlineVariant, 0.6)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "refresh"
                                iconSize: 16
                                color: root.blendedColors.colSubtext
                            }

                            MouseArea {
                                id: wideRefMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: LyricsService.reloadLyrics()
                            }
                        }
                    }

                    // Lyrics Component
                    Lyrics {
                        id: wideLyricsComp
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        textAlignment: Text.AlignHCenter
                        textColor: Appearance.colors.colOnPrimaryContainer
                        activeColor: root.blendedColors.colPrimary
                        dimColor: root.blendedColors.colSubtext
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
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    // ── 2. COMPACT / VERTICAL SINGLE-COLUMN LAYOUT (Docked Sidebar) ───
    // ══════════════════════════════════════════════════════════════════
    Component {
        id: compactLayoutComponent

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // 1. Top Bar: Player Selector + CC Toggle + Refresh
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledComboBox {
                    id: compactPlayerSelector
                    visible: MprisController.players.length > 1
                    Layout.fillWidth: true
                    model: MprisController.players.map(p => {
                        let name = p.identity ?? p.desktopEntry ?? "Unknown"
                        if (name === "Mozilla Firefox") return "Zen Browser"
                        return name
                    })
                    currentIndex: Math.max(0, MprisController.players.indexOf(MprisController.activePlayer))
                    onActivated: (index) => {
                        if (index >= 0 && index < MprisController.players.length) {
                            MprisController.setActivePlayer(MprisController.players[index])
                        }
                    }
                }

                RowLayout {
                    visible: MprisController.players.length <= 1
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "graphic_eq"
                        iconSize: 15
                        color: root.blendedColors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.identity ?? root.player.desktopEntry ?? "Media Player") : "No Active Player"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: root.blendedColors.colOnLayer0
                        elide: Text.ElideRight
                    }
                }

                // CC Toggle Button
                Rectangle {
                    implicitWidth: 50; implicitHeight: 26; radius: 13
                    color: LyricsService.ccMode
                        ? root.blendedColors.colPrimary
                        : (compCcMa.containsMouse ? ColorUtils.transparentize(root.blendedColors.colLayer3, 0.4) : ColorUtils.transparentize(root.blendedColors.colLayer3, 0.6))
                    border.width: 1
                    border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : ColorUtils.transparentize(root.blendedColors.colOutlineVariant, 0.5)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        MaterialSymbol {
                            text: "closed_caption"
                            iconSize: 13
                            fill: LyricsService.ccMode ? 1 : 0
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer0
                        }
                        StyledText {
                            text: "CC"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer0
                        }
                    }

                    MouseArea {
                        id: compCcMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LyricsService.toggleCC()
                    }
                }

                // Refresh Button
                Rectangle {
                    implicitWidth: 26; implicitHeight: 26; radius: 13
                    color: compRefMa.containsMouse ? ColorUtils.transparentize(root.blendedColors.colLayer3, 0.4) : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 15
                        color: root.blendedColors.colSubtext
                    }

                    MouseArea {
                        id: compRefMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: LyricsService.reloadLyrics()
                    }
                }
            }

            // 2. Centered Album Art
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.min(150, Math.min(parent.width * 0.45, parent.height * 0.25))
                implicitHeight: implicitWidth

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.40)
                    border.width: 1
                    border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.75)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        asynchronous: true
                        visible: Boolean(root.displayedArtFilePath)
                    }

                    Item {
                        anchors.fill: parent
                        visible: !root.displayedArtFilePath

                        Rectangle {
                            anchors.fill: parent
                            color: ColorUtils.transparentize(root.blendedColors.colPrimaryContainer, 0.25)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.72; height: width; radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.70)
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.44; height: width; radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.70)
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 32; height: 32; radius: 16
                                color: root.blendedColors.colPrimary
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: (root.player?.isPlaying ?? false) ? "equalizer" : "music_note"
                                    iconSize: 18
                                    color: root.blendedColors.colOnPrimary
                                }
                            }
                        }
                    }
                }
            }

            // 3. Track Title & Artist
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: root.blendedColors.colOnLayer0
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || "No media playing"
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.blendedColors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.player?.trackArtist || (root.player ? "Unknown Artist" : "Play something to get started")
                }
            }

            // 4. Compact Lyrics Box
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.55)
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: ColorUtils.transparentize(root.blendedColors.colOnLayer0, 0.85)

                Lyrics {
                    id: compLyricsComp
                    anchors.fill: parent
                    anchors.margins: 10
                    textAlignment: Text.AlignHCenter
                    textColor: Appearance.colors.colOnPrimaryContainer
                    activeColor: root.blendedColors.colPrimary
                    dimColor: root.blendedColors.colSubtext
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

            // 5. Progress Bar & Times
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.blendedColors.colSubtext
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(compSlider.implicitHeight, compBar.implicitHeight)

                    Loader {
                        id: compSlider
                        anchors.fill: parent
                        active: root.player?.canSeek ?? false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            highlightColor: root.blendedColors.colPrimary
                            trackColor: root.blendedColors.colSecondaryContainer
                            handleColor: root.blendedColors.colPrimary
                            value: {
                                if (pressed) return value
                                const len = root.player?.length ?? 1
                                const pos = root.player?.position ?? 0
                                return len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
                            }
                            onMoved: {
                                if (root.player && root.player.length > 0) {
                                    root.player.position = value * root.player.length
                                }
                                LyricsService.syncPosition()
                            }
                        }
                    }

                    Loader {
                        id: compBar
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                        active: !(root.player?.canSeek ?? false)
                        sourceComponent: StyledProgressBar {
                            highlightColor: root.blendedColors.colPrimary
                            trackColor: root.blendedColors.colSecondaryContainer
                            value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                        }
                    }
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.blendedColors.colSubtext
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                }
            }

            // 6. Centered Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: ColorUtils.transparentize(root.blendedColors.colSecondaryContainer, 0.6)
                    colBackgroundHover: root.blendedColors.colSecondaryContainerHover
                    colRipple: root.blendedColors.colSecondaryContainerActive
                    downAction: () => MprisController.previous()
                    contentItem: MaterialSymbol {
                        iconSize: 22
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors.colOnSecondaryContainer
                        text: "skip_previous"
                    }
                }

                RippleButton {
                    implicitWidth: 50; implicitHeight: 50
                    buttonRadius: 25
                    colBackground: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimary : root.blendedColors.colSecondaryContainer
                    colBackgroundHover: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryHover : root.blendedColors.colSecondaryContainerHover
                    colRipple: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryActive : root.blendedColors.colSecondaryContainerActive
                    downAction: () => MprisController.togglePlaying()
                    contentItem: MaterialSymbol {
                        iconSize: 28
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: (root.player?.isPlaying ?? false) ? root.blendedColors.colOnPrimary : root.blendedColors.colOnSecondaryContainer
                        text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                    }
                }

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: ColorUtils.transparentize(root.blendedColors.colSecondaryContainer, 0.6)
                    colBackgroundHover: root.blendedColors.colSecondaryContainerHover
                    colRipple: root.blendedColors.colSecondaryContainerActive
                    downAction: () => MprisController.next()
                    contentItem: MaterialSymbol {
                        iconSize: 22
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors.colOnSecondaryContainer
                        text: "skip_next"
                    }
                }
            }

            // 7. Volume Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    iconSize: 18
                    color: root.blendedColors.colSubtext
                    text: (Audio.sink?.audio?.muted || Audio.volume <= 0) ? "volume_off"
                        : (Audio.volume < 0.5) ? "volume_down"
                        : "volume_up"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Audio.toggleMute()
                            GlobalStates.osdVolumeOpen = true
                        }
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.XS
                    from: 0
                    to: 1
                    value: root.player?.volume ?? Audio.volume
                    highlightColor: root.blendedColors.colPrimary
                    trackColor: root.blendedColors.colSecondaryContainer
                    handleColor: root.blendedColors.colPrimary
                    onMoved: {
                        Audio.volume = value
                        if (root.player && root.player.volumeSupported) {
                            root.player.volume = value
                        }
                        GlobalStates.osdVolumeOpen = true
                    }
                }

                StyledText {
                    text: `${Math.round((root.player?.volume ?? Audio.volume) * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.blendedColors.colSubtext
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}