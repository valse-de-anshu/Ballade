pragma ComponentBehavior: Bound
import qs
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

    function getDisplayTitle(rawTitle, rawArtist) {
        if (!rawTitle) return Translation.tr("No media playing");
        let t = rawTitle.trim();
        t = t.replace(/^\(\d+\)\s*/, "");
        t = t.replace(/\s*-\s*YouTube(?:\s*Music)?$/i, "");
        t = t.replace(/\s*\|\s*(?:Spotify|SoundCloud)$/i, "");
        t = t.replace(/\s*\|{1,2}\s*(?:slowed|reverb|remix|speed\s*up|sped\s*up|official|audio|video|lyrics?|edit|version).*$/i, "");
        if (t.includes(" - ")) {
            let parts = t.split(" - ");
            if (parts.length >= 2) {
                let candidate = parts.slice(1).join(" - ").trim();
                candidate = candidate.replace(/\s*[\(\[][^\)\]]*(?:slowed|reverb|remix|edit|official|audio|video|lyrics?|feat|ft\.)[^\)\]]*[\)\]]/gi, "").trim();
                if (candidate.length > 0) return candidate;
            }
        }
        t = t.replace(/\s*[\(\[][^\)\]]*(?:slowed|reverb|remix|edit|official|audio|video|lyrics?)[^\)\]]*[\)\]]/gi, "").trim();
        return t || rawTitle;
    }

    function getDisplayArtist(rawTitle, rawArtist) {
        if (!rawTitle && !rawArtist) return "";
        let t = (rawTitle || "").trim();
        let a = (rawArtist || "").trim();
        const generic = ["mozilla firefox", "firefox", "zen browser", "zen", "google chrome", "chrome", "chromium", "brave", "edge", "unknown artist", "various artists", "browser"];
        if (generic.includes(a.toLowerCase())) a = "";

        if (!a && t.includes(" - ")) {
            let parts = t.split(" - ");
            let cand = parts[0].replace(/^\(\d+\)\s*/, "").trim();
            if (cand.length > 0) return cand;
        }
        return a || (root.player ? (rawArtist || Translation.tr("Unknown Artist")) : "");
    }

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

    // ── Deep Velvet Obsidian Canvas with Subtle Ambient Aura (No Over-Bleed) ──
    Rectangle {
        id: background
        anchors.fill: parent
        color: Qt.rgba(0.06, 0.05, 0.08, 0.92)
        radius: Appearance.rounding.large
        clip: true

        // Subdued, highly blurred ambient color tint (opacity 0.22 prevents over-bleed)
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
            opacity: 0.22
            visible: Boolean(root.displayedArtFilePath)

            layer.enabled: Boolean(root.displayedArtFilePath)
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }
        }

        // Ambient dark vignette
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.50) }
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
            spacing: 24

            // ── LEFT COLUMN: Playback Showcase (Art + Info + Transport + Volume) ──
            ColumnLayout {
                Layout.preferredWidth: Math.min(280, Math.max(240, root.width * 0.35))
                Layout.fillHeight: true
                spacing: 10

                // 1. Source Indicator
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

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
                        spacing: 5
                        MaterialSymbol {
                            text: "graphic_eq"
                            iconSize: 13
                            color: root.blendedColors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.player ? (root.player.identity ?? root.player.desktopEntry ?? "Media Player") : "No Active Player"
                            font.pixelSize: 11
                            font.weight: Font.Normal
                            color: Qt.rgba(1, 1, 1, 0.45)
                            elide: Text.ElideRight
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // 2. Cover Art Card with Soft Elevation Shadow
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Math.min(170, Math.max(130, root.height * 0.35))
                    implicitHeight: implicitWidth

                    // Subtle soft ambient glow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        radius: 20
                        color: ColorUtils.transparentize(root.artDominantColor, 0.70)
                        opacity: root.displayedArtFilePath ? 0.6 : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.30)
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
                                color: ColorUtils.transparentize(root.blendedColors.colPrimaryContainer, 0.20)

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.74; height: width; radius: width / 2
                                    color: "transparent"
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.75)
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.46; height: width; radius: width / 2
                                    color: "transparent"
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.75)
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

                // 3. Track Title & Artist (Clean, parsed, minimal)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.getDisplayTitle(root.player?.trackTitle, root.player?.trackArtist)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        color: Qt.rgba(1, 1, 1, 0.50)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.getDisplayArtist(root.player?.trackTitle, root.player?.trackArtist)
                    }
                }

                // 4. Progress Slider & Timestamps
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.features: { "tnum": 1 }
                        text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 18

                        Loader {
                            anchors.fill: parent
                            active: root.player?.canSeek ?? false
                            sourceComponent: StyledSlider {
                                configuration: StyledSlider.Configuration.Wavy
                                wavy: true
                                animateWave: root.player?.isPlaying ?? false
                                circleHandle: true
                                circleHandleSize: 12
                                circleHandlePressedSize: 14
                                highlightColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                                trackColor: Qt.rgba(255, 255, 255, 0.12)
                                handleColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
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
                                wavy: true
                                animateWave: root.player?.isPlaying ?? false
                                highlightColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                                trackColor: Qt.rgba(255, 255, 255, 0.12)
                                value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                            }
                        }
                    }

                    StyledText {
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.features: { "tnum": 1 }
                        text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                    }
                }

                // 5. Material 3 Transport Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    RippleButton {
                        implicitWidth: 42; implicitHeight: 42
                        buttonRadius: 21
                        colBackground: Qt.rgba(255, 255, 255, 0.08)
                        colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                        colRipple: Qt.rgba(255, 255, 255, 0.24)
                        downAction: () => MprisController.previous()
                        contentItem: MaterialSymbol {
                            iconSize: 22
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.blendedColors?.colOnSurface ?? "#ffffff"
                            text: "skip_previous"
                        }
                    }

                    RippleButton {
                        implicitWidth: 54; implicitHeight: 54
                        buttonRadius: 27
                        colBackground: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                        colBackgroundHover: root.blendedColors?.colPrimaryHover ?? Appearance.colors.colPrimaryHover
                        colRipple: root.blendedColors?.colPrimaryActive ?? Qt.rgba(255, 255, 255, 0.25)
                        downAction: () => MprisController.togglePlaying()
                        contentItem: MaterialSymbol {
                            iconSize: 28
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.blendedColors?.colOnPrimary ?? Appearance.colors.colOnPrimary
                            text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                        }
                    }

                    RippleButton {
                        implicitWidth: 42; implicitHeight: 42
                        buttonRadius: 21
                        colBackground: Qt.rgba(255, 255, 255, 0.08)
                        colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                        colRipple: Qt.rgba(255, 255, 255, 0.24)
                        downAction: () => MprisController.next()
                        contentItem: MaterialSymbol {
                            iconSize: 22
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: root.blendedColors?.colOnSurface ?? "#ffffff"
                            text: "skip_next"
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── RIGHT COLUMN: Dedicated Full-Height Lyrics Stage ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Top Minimal Tools: Compact CC Pill + Refresh
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item { Layout.fillWidth: true }

                    // Minimal CC Pill
                    Rectangle {
                        implicitWidth: 42; implicitHeight: 22; radius: 11
                        color: LyricsService.ccMode
                            ? root.blendedColors.colPrimary
                            : (wideCcMa.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05))
                        border.width: 1
                        border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : Qt.rgba(255, 255, 255, 0.10)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 3
                            MaterialSymbol {
                                text: "closed_caption"
                                iconSize: 12
                                fill: LyricsService.ccMode ? 1 : 0
                                color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : Qt.rgba(1, 1, 1, 0.70)
                            }
                            StyledText {
                                text: "CC"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : Qt.rgba(1, 1, 1, 0.70)
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
                        implicitWidth: 22; implicitHeight: 22; radius: 11
                        color: wideRefMa.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : "transparent"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 14
                            color: Qt.rgba(1, 1, 1, 0.50)
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

                // Full-Height Lyrics with natural edge dissolve
                Lyrics {
                    id: wideLyricsComp
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: Qt.rgba(1, 1, 1, 0.55)
                    activeColor: "#ffffff"
                    dimColor: Qt.rgba(1, 1, 1, 0.30)
                    indicatorColor: root.blendedColors?.colPrimaryContainer ?? Appearance.colors.colPrimaryContainer
                    indicatorShapeColor: root.blendedColors?.colOnPrimaryContainer ?? Appearance.colors.colOnPrimaryContainer
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
            anchors.topMargin: 12
            spacing: 8

            // 1. Top Minimal Header: Source + CC + Refresh
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
                    spacing: 5
                    MaterialSymbol {
                        text: "graphic_eq"
                        iconSize: 13
                        color: root.blendedColors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.identity ?? root.player.desktopEntry ?? "Media Player") : "No Active Player"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Qt.rgba(1, 1, 1, 0.45)
                        elide: Text.ElideRight
                    }
                }

                // Minimal CC Button
                Rectangle {
                    implicitWidth: 38; implicitHeight: 20; radius: 10
                    color: LyricsService.ccMode
                        ? root.blendedColors.colPrimary
                        : (compCcMa.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05))
                    border.width: 1
                    border.color: LyricsService.ccMode ? root.blendedColors.colPrimary : Qt.rgba(255, 255, 255, 0.10)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            text: "closed_caption"
                            iconSize: 11
                            fill: LyricsService.ccMode ? 1 : 0
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : Qt.rgba(1, 1, 1, 0.70)
                        }
                        StyledText {
                            text: "CC"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: LyricsService.ccMode ? root.blendedColors.colOnPrimary : Qt.rgba(1, 1, 1, 0.70)
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
                    implicitWidth: 20; implicitHeight: 20; radius: 10
                    color: compRefMa.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 13
                        color: Qt.rgba(1, 1, 1, 0.45)
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

            // 2. Compact Cover Art Card with Subtle Glow (Comfortable headroom, not kissing top area)
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                Layout.bottomMargin: 4
                implicitWidth: Math.min(120, Math.min(root.width * 0.42, root.height * 0.20))
                implicitHeight: implicitWidth

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 16
                    color: ColorUtils.transparentize(root.artDominantColor, 0.70)
                    opacity: root.displayedArtFilePath ? 0.6 : 0
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: ColorUtils.transparentize(root.blendedColors.colLayer2, 0.30)
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
                            color: ColorUtils.transparentize(root.blendedColors.colPrimaryContainer, 0.20)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.72; height: width; radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.75)
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.44; height: width; radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.transparentize(root.blendedColors.colOnPrimaryContainer, 0.75)
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 28; height: 28; radius: 14
                                color: root.blendedColors.colPrimary
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: (root.player?.isPlaying ?? false) ? "equalizer" : "music_note"
                                    iconSize: 16
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
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.getDisplayTitle(root.player?.trackTitle, root.player?.trackArtist)
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Qt.rgba(1, 1, 1, 0.50)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.getDisplayArtist(root.player?.trackTitle, root.player?.trackArtist)
                }
            }

            // 4. Middle Stage: Full-Height Immersive Lyrics
            Lyrics {
                id: compLyricsComp
                Layout.fillWidth: true
                Layout.fillHeight: true
                textAlignment: Text.AlignHCenter
                textColor: Qt.rgba(1, 1, 1, 0.55)
                activeColor: "#ffffff"
                dimColor: Qt.rgba(1, 1, 1, 0.30)
                indicatorColor: root.blendedColors?.colPrimaryContainer ?? Appearance.colors.colPrimaryContainer
                indicatorShapeColor: root.blendedColors?.colOnPrimaryContainer ?? Appearance.colors.colOnPrimaryContainer
            }

            // 5. Progress Slider & Timestamps
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.40)
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 18

                    Loader {
                        anchors.fill: parent
                        active: root.player?.canSeek ?? false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            wavy: true
                            animateWave: root.player?.isPlaying ?? false
                            circleHandle: true
                            circleHandleSize: 11
                            circleHandlePressedSize: 13
                            highlightColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                            trackColor: Qt.rgba(255, 255, 255, 0.12)
                            handleColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
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
                            wavy: true
                            animateWave: root.player?.isPlaying ?? false
                            highlightColor: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                            trackColor: Qt.rgba(255, 255, 255, 0.12)
                            value: (root.player?.position ?? 0) / (root.player?.length ?? 1)
                        }
                    }
                }

                StyledText {
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.40)
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                }
            }

            // 6. Material 3 Transport Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: Qt.rgba(255, 255, 255, 0.08)
                    colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                    colRipple: Qt.rgba(255, 255, 255, 0.24)
                    downAction: () => MprisController.previous()
                    contentItem: MaterialSymbol {
                        iconSize: 20
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors?.colOnSurface ?? "#ffffff"
                        text: "skip_previous"
                    }
                }

                RippleButton {
                    implicitWidth: 48; implicitHeight: 48
                    buttonRadius: 24
                    colBackground: root.blendedColors?.colPrimary ?? Appearance.colors.colPrimary
                    colBackgroundHover: root.blendedColors?.colPrimaryHover ?? Appearance.colors.colPrimaryHover
                    colRipple: root.blendedColors?.colPrimaryActive ?? Qt.rgba(255, 255, 255, 0.25)
                    downAction: () => MprisController.togglePlaying()
                    contentItem: MaterialSymbol {
                        iconSize: 26
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors?.colOnPrimary ?? Appearance.colors.colOnPrimary
                        text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                    }
                }

                RippleButton {
                    implicitWidth: 38; implicitHeight: 38
                    buttonRadius: 19
                    colBackground: Qt.rgba(255, 255, 255, 0.08)
                    colBackgroundHover: Qt.rgba(255, 255, 255, 0.16)
                    colRipple: Qt.rgba(255, 255, 255, 0.24)
                    downAction: () => MprisController.next()
                    contentItem: MaterialSymbol {
                        iconSize: 20
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.blendedColors?.colOnSurface ?? "#ffffff"
                        text: "skip_next"
                    }
                }
            }
        }
    }
}