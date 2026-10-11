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
        color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.40)
        radius: Appearance.rounding.large
        clip: true

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
                color: ColorUtils.transparentize(root.blendedColors.colLayer0, 0.45)
            }
        }

        // Ambient dark scrim for readable contrast
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.20) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
            }
        }

        // ══════════════════════════════════════════════════════════════
        // ── RESPONSIVE CONTENT AREA ───────────────────────────────────
        // ══════════════════════════════════════════════════════════════
        Item {
            anchors.fill: parent
            anchors.margins: root.isWide ? 18 : 12

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
            spacing: 20

            // ── LEFT COLUMN: Playback Showcase (Art + Info + Transport + Volume) ──
            ColumnLayout {
                Layout.preferredWidth: Math.min(320, Math.max(260, parent.width * 0.36))
                Layout.fillHeight: true
                spacing: 12

                // 1. Source Indicator
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledComboBox {
                        id: widePlayerSelector
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
                            color: Qt.rgba(1, 1, 1, 0.75)
                            elide: Text.ElideRight
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // 2. Cover Art Card with Soft Ambient Glow
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Math.min(210, Math.min(parent.width - 24, parent.height * 0.40))
                    implicitHeight: implicitWidth

                    // Ambient glow behind cover art
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        radius: Appearance.rounding.large + 2
                        color: ColorUtils.transparentize(root.artDominantColor, 0.65)
                        opacity: root.displayedArtFilePath ? 0.8 : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.large
                        color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.35)
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

                        // Luxury Vinyl Placeholder when no cover art
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

                // 3. Track Title & Artist (Clean, bold, luxury typography)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.player?.trackTitle || Translation.tr("No media playing")
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Qt.rgba(1, 1, 1, 0.65)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.player?.trackArtist || (root.player ? Translation.tr("Unknown Artist") : "")
                    }
                }

                // 4. Progress Slider & Timestamps
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.features: { "tnum": 1 }
                        text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 20

                        Loader {
                            id: wideProgressSlider
                            anchors.fill: parent
                            active: root.player?.canSeek ?? false
                            sourceComponent: StyledSlider {
                                configuration: StyledSlider.Configuration.Wavy
                                circleHandle: true
                                circleHandleSize: 12
                                circleHandlePressedSize: 14
                                highlightColor: root.blendedColors.colPrimary
                                trackColor: Qt.rgba(255, 255, 255, 0.16)
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
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                            active: !(root.player?.canSeek ?? false)
                            sourceComponent: StyledProgressBar {
                                highlightColor: root.blendedColors.colPrimary
                                trackColor: Qt.rgba(255, 255, 255, 0.16)
                                value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                            }
                        }
                    }

                    StyledText {
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.55)
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
                        colBackground: Qt.rgba(255, 255, 255, 0.08)
                        colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                        colRipple: Qt.rgba(255, 255, 255, 0.25)
                        downAction: () => MprisController.previous()
                        contentItem: MaterialSymbol {
                            iconSize: 22
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: "#ffffff"
                            text: "skip_previous"
                        }
                    }

                    RippleButton {
                        implicitWidth: 52; implicitHeight: 52
                        buttonRadius: 26
                        colBackground: root.blendedColors.colPrimary
                        colBackgroundHover: root.blendedColors.colPrimaryHover
                        colRipple: root.blendedColors.colPrimaryActive
                        downAction: () => MprisController.togglePlaying()
                        contentItem: MaterialSymbol {
                            iconSize: 28
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.blendedColors.colOnPrimary
                            text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                        }
                    }

                    RippleButton {
                        implicitWidth: 38; implicitHeight: 38
                        buttonRadius: 19
                        colBackground: Qt.rgba(255, 255, 255, 0.08)
                        colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                        colRipple: Qt.rgba(255, 255, 255, 0.25)
                        downAction: () => MprisController.next()
                        contentItem: MaterialSymbol {
                            iconSize: 22
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: "#ffffff"
                            text: "skip_next"
                        }
                    }
                }

                // 6. Volume Control (MATCHES progress slider styling perfectly)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        iconSize: 18
                        color: Qt.rgba(1, 1, 1, 0.65)
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
                        configuration: StyledSlider.Configuration.Wavy
                        circleHandle: true
                        circleHandleSize: 12
                        circleHandlePressedSize: 14
                        from: 0
                        to: 1
                        value: root.player?.volume ?? Audio.volume
                        highlightColor: root.blendedColors.colPrimary
                        trackColor: Qt.rgba(255, 255, 255, 0.16)
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
                        font.pixelSize: 11
                        font.features: { "tnum": 1 }
                        color: Qt.rgba(1, 1, 1, 0.60)
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Subtle vertical glass divider
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Qt.rgba(255, 255, 255, 0.08)
            }

            // ── RIGHT COLUMN: Dedicated Full-Height Lyrics Stage ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                // Minimalist Tools: CC Toggle Pill + Refresh
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    // CC Toggle Chip
                    Rectangle {
                        implicitWidth: 58; implicitHeight: 28; radius: 14
                        color: LyricsService.ccMode
                            ? root.blendedColors.colPrimary
                            : (wideCcMa.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                        border.width: 1
                        border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : Qt.rgba(255, 255, 255, 0.15)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "closed_caption"
                                iconSize: 14
                                fill: LyricsService.ccMode ? 1 : 0
                                color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : "#ffffff"
                            }
                            StyledText {
                                text: "CC"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : "#ffffff"
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
                        color: wideRefMa.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 16
                            color: Qt.rgba(1, 1, 1, 0.70)
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

                // Full-Height Lyrics Experience
                Lyrics {
                    id: wideLyricsComp
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fadeColor: root.blendedColors.colLayer0
                    textColor: Qt.rgba(1, 1, 1, 0.75)
                    activeColor: "#ffffff"
                    dimColor: Qt.rgba(1, 1, 1, 0.40)
                    indicatorColor: root.blendedColors.colPrimaryContainer
                    indicatorShapeColor: root.blendedColors.colOnPrimaryContainer
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
            spacing: 10

            // 1. Top Minimal Header: Source Icon / Selector + CC + Refresh
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
                        color: Qt.rgba(1, 1, 1, 0.75)
                        elide: Text.ElideRight
                    }
                }

                // Minimal CC Button
                Rectangle {
                    implicitWidth: 46; implicitHeight: 26; radius: 13
                    color: LyricsService.ccMode
                        ? root.blendedColors.colPrimary
                        : (compCcMa.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                    border.width: 1
                    border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : Qt.rgba(255, 255, 255, 0.15)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        MaterialSymbol {
                            text: "closed_caption"
                            iconSize: 13
                            fill: LyricsService.ccMode ? 1 : 0
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : "#ffffff"
                        }
                        StyledText {
                            text: "CC"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : "#ffffff"
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
                    color: compRefMa.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 15
                        color: Qt.rgba(1, 1, 1, 0.70)
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

            // 2. Compact Cover Art Card
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.min(130, Math.min(parent.width * 0.44, parent.height * 0.22))
                implicitHeight: implicitWidth

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: Appearance.rounding.large
                    color: ColorUtils.transparentize(root.artDominantColor, 0.70)
                    opacity: root.displayedArtFilePath ? 0.8 : 0
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.35)
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
                                width: 30; height: 30; radius: 15
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
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || Translation.tr("No media playing")
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.65)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.player?.trackArtist || (root.player ? Translation.tr("Unknown Artist") : "")
                }
            }

            // 4. Middle Stage: Full-Height Immersive Lyrics
            Lyrics {
                id: compLyricsComp
                Layout.fillWidth: true
                Layout.fillHeight: true
                textAlignment: Text.AlignHCenter
                fadeColor: root.blendedColors.colLayer0
                textColor: Qt.rgba(1, 1, 1, 0.75)
                activeColor: "#ffffff"
                dimColor: Qt.rgba(1, 1, 1, 0.40)
                indicatorColor: root.blendedColors.colPrimaryContainer
                indicatorShapeColor: root.blendedColors.colOnPrimaryContainer
            }

            // 5. Progress Slider & Timestamps
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 20

                    Loader {
                        anchors.fill: parent
                        active: root.player?.canSeek ?? false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            circleHandle: true
                            circleHandleSize: 12
                            circleHandlePressedSize: 14
                            highlightColor: root.blendedColors.colPrimary
                            trackColor: Qt.rgba(255, 255, 255, 0.16)
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
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                        active: !(root.player?.canSeek ?? false)
                        sourceComponent: StyledProgressBar {
                            highlightColor: root.blendedColors.colPrimary
                            trackColor: Qt.rgba(255, 255, 255, 0.16)
                            value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                        }
                    }
                }

                StyledText {
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                }
            }

            // 6. Centered Transport Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: Qt.rgba(255, 255, 255, 0.08)
                    colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                    colRipple: Qt.rgba(255, 255, 255, 0.25)
                    downAction: () => MprisController.previous()
                    contentItem: MaterialSymbol {
                        iconSize: 22
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: "#ffffff"
                        text: "skip_previous"
                    }
                }

                RippleButton {
                    implicitWidth: 50; implicitHeight: 50
                    buttonRadius: 25
                    colBackground: root.blendedColors.colPrimary
                    colBackgroundHover: root.blendedColors.colPrimaryHover
                    colRipple: root.blendedColors.colPrimaryActive
                    downAction: () => MprisController.togglePlaying()
                    contentItem: MaterialSymbol {
                        iconSize: 28
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors.colOnPrimary
                        text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                    }
                }

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: Qt.rgba(255, 255, 255, 0.08)
                    colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                    colRipple: Qt.rgba(255, 255, 255, 0.25)
                    downAction: () => MprisController.next()
                    contentItem: MaterialSymbol {
                        iconSize: 22
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: "#ffffff"
                        text: "skip_next"
                    }
                }
            }

            // 7. Volume Row (MATCHES progress slider styling perfectly)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    iconSize: 18
                    color: Qt.rgba(1, 1, 1, 0.65)
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
                    configuration: StyledSlider.Configuration.Wavy
                    circleHandle: true
                    circleHandleSize: 12
                    circleHandlePressedSize: 14
                    from: 0
                    to: 1
                    value: root.player?.volume ?? Audio.volume
                    highlightColor: root.blendedColors.colPrimary
                    trackColor: Qt.rgba(255, 255, 255, 0.16)
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
                    font.pixelSize: 11
                    font.features: { "tnum": 1 }
                    color: Qt.rgba(1, 1, 1, 0.60)
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}