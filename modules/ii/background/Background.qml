pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.goals

Variants {
    id: root
    model: Quickshell.screens

    function getShapeFromName(name) {
        switch (name) {
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie7Sided
        }
    }

    function getColorFromName(name) {
        switch (name) {
            case "primary":            return Appearance.colors.colPrimary
            case "secondary":          return Appearance.colors.colSecondary
            case "tertiary":           return Appearance.colors.colTertiary
            case "primaryContainer":   return Appearance.colors.colPrimaryContainer
            case "secondaryContainer": return Appearance.colors.colSecondaryContainer
            case "tertiaryContainer":  return Appearance.colors.colTertiaryContainer
            case "layer0":             return Appearance.colors.colLayer0
            case "layer1":             return Appearance.colors.colLayer1
            default:                  return Appearance.colors.colPrimaryContainer
        }
    }

    PanelWindow {
        id: bgRoot

        required property var modelData
        property string currentWallpaperSource: Images.getStaticWallpaperImage(Config.options.background.wallpaperPath, Config.options.background.thumbnailPath)
        property string previousWallpaperSource: currentWallpaperSource
        property bool videoRevealed: false

        //centered Wallpaper
        property bool centeredWallpaperEnabled: Config.options.background.centeredWallpaper && (!Config.options.background.centeredWallpaperOnlyWhenLocked || GlobalStates.screenLocked)
        property int centeredWallpaperShape: getShapeFromName(Config.options.background.centeredWallpaperShape)
        property int centeredWallpaperSize: Config.options.background.centeredWallpaperSize
        property color centeredWallpaperColor: root.getColorFromName(Config.options.background.centeredWallpaperColor)
        property real splitFraction: {
            switch (Config.options.background.splitRatio) {
                case "0":  return 0.0
                case "25": return 0.28
                case "50": return 0.54
                default:   return 1.0
            }
        }
        readonly property bool overviewBlurActive: Config.options.overview.style === "niri" && GlobalStates.overviewOpen && Config.options.overview.enable
        readonly property bool userBlurActive: Config.options.background.showBlur
        readonly property bool blurFullScreen: bgRoot.overviewBlurActive || bgRoot.splitFraction >= 1.0

        property var shaderList: ["circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "crt", "dissolve", "glitch", "ripple", "shatter"]
        property string currentShader: "magic"
        property string wallpaperAnimation: Config.options.background.wallpaperAnimation ?? "random"

        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

        // ── Parallax ──────────────────────────────────────────────────────
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property list<HyprlandWorkspace> relevantWindows_p: Hyprland.workspaces.values.filter(ws => ws.monitor && ws.monitor.name == monitor.name)
        property int firstWorkspaceId_p: relevantWindows_p[0]?.id || 1
        property int lastWorkspaceId_p: relevantWindows_p[relevantWindows_p.length - 1]?.id || 10
        property int totalWorkspaces_p: Math.ceil(lastWorkspaceId_p / workspaceChunkSize) * workspaceChunkSize
        property int workspaceIndex_p: (monitor.activeWorkspace?.id ?? 1) - 1
        readonly property real parallaxZoom: Config.options.background.parallax?.workspaceZoom ?? 1.05
        property real minSuitableScale_p: 1
        property real scaledW: modelData.width  * minSuitableScale_p * parallaxZoom
        property real scaledH: modelData.height * minSuitableScale_p * parallaxZoom
        property real parallaxPixelsX: Math.max(0, scaledW - screen.width)

        property real wallpaperFraction: {
            if (totalWorkspaces_p <= 1) return 0.5;
            return Math.max(0, Math.min(1, workspaceIndex_p / (totalWorkspaces_p - 1)));
        }
        property real usedFractionX: {
            let f = wallpaperFraction;
            let sidebarFraction = parallaxZoom / workspaceChunkSize / 2;
            f += (sidebarFraction * GlobalStates.sidebarRightOpen - sidebarFraction * GlobalStates.sidebarLeftOpen);
            return Math.max(0, Math.min(1, f));
        }
        property real parallaxX: -parallaxPixelsX * usedFractionX
        property real parallaxY: (modelData.height - scaledH) / 2



        property string effectiveWallpaperPath: {
            if (GlobalStates.screenLocked && Config.options.background.lockWall !== "")
                return Config.options.background.lockWall;
            return Wallpapers.previewPath || Wallpapers.confirmedPath || Config.options.background.wallpaperPath;
        }

        property bool wallpaperIsVideo: Boolean(bgRoot.effectiveWallpaperPath) && /\.(mp4|webm|mkv|avi|mov)$/i.test(bgRoot.effectiveWallpaperPath)
        property string wallpaperPath: wallpaperIsVideo ? Images.getStaticWallpaperImage(bgRoot.effectiveWallpaperPath, Config.options.background.thumbnailPath) : bgRoot.effectiveWallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }

        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        property real transitionProgress: 1.0

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Component.onCompleted: {
            // parallax scale
            bgRoot.minSuitableScale_p = Math.max(screen.width / modelData.width, screen.height / modelData.height);
            // wallpaper setup
            previousWallpaper.source = ""
            wallpaper.source = bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
            bgRoot.currentWallpaperSource = bgRoot.wallpaperPath
            bgRoot.previousWallpaperSource = ""
            bgRoot.transitionProgress = 1.0
            if (bgRoot.wallpaperAnimation !== "") {
                bgRoot.currentShader = bgRoot.wallpaperAnimation === "random"
                    ? bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
                    : bgRoot.wallpaperAnimation
            }
            bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
        }

        onWallpaperIsVideoChanged: {
            if (bgRoot.wallpaperIsVideo) {
                if (!GlobalStates.screenLocked) {
                    videoRevealSafetyTimer.restart()
                }
            } else {
                bgRoot.videoRevealed = false
            }
        }

        Timer {
            id: videoRevealSafetyTimer
            interval: 1400
            running: bgRoot.wallpaperIsVideo && !bgRoot.videoRevealed
            repeat: false
            onTriggered: {
                if (bgRoot.wallpaperIsVideo && !bgRoot.videoRevealed) {
                    bgRoot.videoRevealed = true
                    bgRoot.transitionProgress = 1.0
                }
            }
        }

        onWallpaperPathChanged: {
            bgRoot.videoRevealed = false
            if (wallpaperSafetyTriggered) {
                previousWallpaper.source = ""
                wallpaper.source = ""
                bgRoot.transitionProgress = 1.0
                return
            }
            if (bgRoot.wallpaperAnimation === "") {
                wallpaper.source = wallpaperPath
                bgRoot.currentWallpaperSource = wallpaperPath
                if (!bgRoot.wallpaperIsVideo) return
                bgRoot.videoRevealed = true
                return
            }

            previousWallpaper.source = bgRoot.currentWallpaperSource
            wallpaper.source = wallpaperPath
            bgRoot.currentWallpaperSource = wallpaperPath
            if (bgRoot.wallpaperAnimation === "random") {
                bgRoot.currentShader = bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
            } else {
                bgRoot.currentShader = bgRoot.wallpaperAnimation
            }
            bgRoot.transitionProgress = 0.0
            if (wallpaper.status === Image.Ready) {
                transitionAnim.restart()
            } else {
                Qt.callLater(() => {
                    if (bgRoot.transitionProgress === 0.0 && !transitionAnim.running) {
                        transitionAnim.restart()
                    }
                })
            }
            if (bgRoot.wallpaperIsVideo) {
                videoRevealSafetyTimer.restart()
            }
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: 1200
            easing.type: Easing.InOutCubic
            onFinished: {
                previousWallpaper.source = ""
                bgRoot.previousWallpaperSource = ""
                bgRoot.transitionProgress = 1.0
                bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
            }
        }

        Timer {
            id: wallpaperChangeTimer
            interval: Config.options.wallpaperSelector.changeInterval
            running: Config.options.wallpaperSelector.changeInterval > 0
            repeat: true
            onTriggered: {
                if (Wallpapers.folderModel.count > 0) {
                    Wallpapers.randomFromCurrentFolder()
                }
            }
        }

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (!GlobalStates.screenLocked) {
                    bgRoot.videoRevealed = bgRoot.wallpaperIsVideo
                } else {
                    bgRoot.videoRevealed = false
                }
            }
        }

        Item {
            anchors.fill: parent

            Image {
                id: previousWallpaper
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: true
                visible: false
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }

            StyledImage {
                id: wallpaper
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: blurLoader.active || fastBlurLoader.active
                visible: !bgRoot.wallpaperIsVideo && (!blurLoader.active && (!fastBlurLoader.active || !bgRoot.blurFullScreen))
                    && (bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0)
                onStatusChanged: {
                    if (status === Image.Ready && bgRoot.transitionProgress === 0.0) {
                        transitionAnim.restart()
                    }
                }
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }

            MediaPlayer {
                id: liveWallpaperPlayer
                source: bgRoot.wallpaperIsVideo ? (bgRoot.effectiveWallpaperPath.startsWith("file://") ? bgRoot.effectiveWallpaperPath : "file://" + bgRoot.effectiveWallpaperPath) : ""
                videoOutput: liveVideoOutput
                loops: MediaPlayer.Infinite
                audioOutput: null

                readonly property bool shouldPlay: bgRoot.wallpaperIsVideo && !GlobalStates.screenLocked && !(ToplevelManager?.activeToplevel?.fullscreen ?? false)

                function updatePlayback() {
                    if (shouldPlay) {
                        play();
                    } else {
                        pause();
                    }
                }

                Component.onCompleted: updatePlayback()
                onMediaStatusChanged: {
                    if ((mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) && shouldPlay) {
                        play();
                    }
                }
                onSourceChanged: {
                    if (source.toString() !== "" && shouldPlay) {
                        play();
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onScreenLockedChanged() {
                    liveWallpaperPlayer.updatePlayback();
                }
            }

            Connections {
                target: ToplevelManager
                function onActiveToplevelChanged() {
                    liveWallpaperPlayer.updatePlayback();
                }
            }

            Connections {
                target: bgRoot
                function onWallpaperIsVideoChanged() {
                    liveWallpaperPlayer.updatePlayback();
                }
                function onEffectiveWallpaperPathChanged() {
                    liveWallpaperPlayer.updatePlayback();
                }
            }

            VideoOutput {
                id: liveVideoOutput
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                fillMode: VideoOutput.PreserveAspectCrop
                layer.enabled: (blurLoader.active || fastBlurLoader.active) && bgRoot.blurFullScreen
                visible: bgRoot.wallpaperIsVideo
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }

            ShaderEffect {
                id: transitionEffect
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                layer.enabled: blurLoader.active || fastBlurLoader.active
                visible: (!blurLoader.active && (!fastBlurLoader.active || !bgRoot.blurFullScreen)) && bgRoot.wallpaperAnimation !== "" && !bgRoot.videoRevealed
                    && bgRoot.transitionProgress < 1.0
                property var fromImage: previousWallpaper
                property var toImage: wallpaper
                property var source1: previousWallpaper
                property var source2: wallpaper
                property real time: 0.0
                property real progress: bgRoot.transitionProgress
                property real aspectX: width / height
                property real aspectY: 1.0
                property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                property vector2d origin: Qt.vector2d(0.5, 0.5)
                fragmentShader: bgRoot.wallpaperAnimation !== ""
                    ? Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)
                    : ""
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                Timer {
                    interval: 16
                    repeat: true
                    running: transitionEffect.visible
                    onTriggered: transitionEffect.time += interval / 1000.0
                }
                onVisibleChanged: if (!visible) transitionEffect.time = 0.0
            }

            Loader {
                id: blurLoader
                z: 8
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0 ? wallpaper : transitionEffect
                    radius: GlobalStates.screenLocked ? (Config.options.lock.blur.radius ?? 64) : 0
                    samples: Config.options.lock.blur.size 
                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            Loader {
                id: fastBlurLoader
                z: 7
                active: !GlobalStates.screenLocked && (bgRoot.userBlurActive || bgRoot.overviewBlurActive)
                    && (!bgRoot.centeredWallpaperEnabled || bgRoot.blurFullScreen)
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                sourceComponent: Item {
                    id: blurRoot
                    anchors.fill: parent

                    readonly property real fadeWidth: 140
                    readonly property real blurRadius: Config.options.background.blurRadius ?? 32
                    readonly property bool alignRight: Config.options.background.splitSide === "right"
                    property real coreWidth: bgRoot.blurFullScreen ? blurRoot.width : blurRoot.width * bgRoot.splitFraction

                    Behavior on coreWidth {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    FastBlur {
                        id: blurLayer
                        anchors.fill: parent
                        // Source from composite (wallpaper + viz bars) so bars get baked
                        // into the blur — they appear as glowing smears through frosted glass
                        source: blurCompositeSource
                        radius: blurRoot.blurRadius

                        Behavior on radius {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        layer.enabled: !bgRoot.blurFullScreen
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: blurLayer.width
                                height: blurLayer.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: blurRoot.alignRight ? 1 - (blurRoot.coreWidth / blurRoot.width) : Math.max(0, (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width); color: blurRoot.alignRight ? "transparent" : "white" }
                                    GradientStop { position: blurRoot.alignRight ? Math.min(1, 1 - (blurRoot.coreWidth - blurRoot.fadeWidth) / blurRoot.width) : Math.min(1, blurRoot.coreWidth / blurRoot.width); color: blurRoot.alignRight ? "white" : "transparent" }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: centeredWallpaperDimOverlay
                z: 10
                anchors.fill: parent
                color: "#000000"
                opacity: bgRoot.centeredWallpaperEnabled ? 0.65 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
            }

            // Centered wallpaper shadow behind shape
            MaterialShape {
                id: centeredWallpaperShadow
                z: 11
                anchors.centerIn: parent
                width: 1000
                height: 1000
                shape: bgRoot.centeredWallpaperShape
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: opacity > 0
                opacity: bgRoot.centeredWallpaperEnabled ? 1 : 0
                scale: (bgRoot.centeredWallpaperSize / 1000) * (bgRoot.centeredWallpaperEnabled ? 1 : 0.85)

                Behavior on opacity {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.9)
                    shadowBlur: 0.95
                    shadowVerticalOffset: 8
                }
            }

            // Centered wallpaper shape displaying middle wallpaper
            MaterialShape {
                id: centeredWallpaperShapeItem
                z: 12
                anchors.centerIn: parent
                width: 1000
                height: 1000
                color: "transparent"
                shape: bgRoot.centeredWallpaperShape
                transformOrigin: Item.Center
                visible: opacity > 0
                opacity: bgRoot.centeredWallpaperEnabled ? 1 : 0
                scale: (bgRoot.centeredWallpaperSize / 1000) * (bgRoot.centeredWallpaperEnabled ? 1 : 0.85)

                Behavior on opacity {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: MaterialShape {
                        width: 1000
                        height: 1000
                        shape: bgRoot.centeredWallpaperShape
                    }
                }

                Image {
                    anchors.fill: parent
                    source: bgRoot.wallpaperPath ? ("file://" + CF.FileUtils.trimFileProtocol(Images.getStaticWallpaperImage(bgRoot.wallpaperPath, Config.options.background.thumbnailPath))) : ""
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    asynchronous: true
                    antialiasing: true
                    smooth: true
                }
            }

            DropArea {
                id: wallpaperDropArea
                anchors.fill: parent
                keys: ["text/uri-list"]

                property var currentUrls: []

                onEntered: (drag) => {
                    drag.accepted = drag.hasUrls
                    wallpaperDropArea.currentUrls = drag.hasUrls ? drag.urls : []
                }

                onExited: {
                    wallpaperDropArea.currentUrls = []
                }

                onDropped: (drop) => {
                    if (!drop.hasUrls) {
                        drop.accepted = false
                        wallpaperDropArea.currentUrls = []
                        return
                    }

                    if (drop.urls.length === 1) {
                        const path = CF.FileUtils.trimFileProtocol(decodeURIComponent(drop.urls[0].toString()))
                        const validExt = /\.(png|jpe?g|webp|bmp|gif)$/i.test(path)
                        if (validExt) {
                            Wallpapers.select(path, Appearance.m3colors.darkmode)
                        } else {
                            const globalPos = wallpaperDropArea.mapToGlobal(drop.x, drop.y)
                            DropShelf.show(drop.urls, globalPos.x, globalPos.y)
                        }
                    } else {
                        const globalPos = wallpaperDropArea.mapToGlobal(drop.x, drop.y)
                        DropShelf.show(drop.urls, globalPos.x, globalPos.y)
                    }
                    drop.accept()
                    wallpaperDropArea.currentUrls = []
                }

                Rectangle {
                    id: dropOverlay
                    anchors.fill: parent
                    visible: wallpaperDropArea.containsDrag
                    color: CF.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)

                    property bool isSingleImage: wallpaperDropArea.currentUrls.length === 1
                        && /\.(png|jpe?g|webp|bmp|gif)$/i.test(
                            CF.FileUtils.trimFileProtocol(wallpaperDropArea.currentUrls[0].toString())
                        )

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: dropOverlay.isSingleImage ? "wallpaper" : "stacks"
                            iconSize: 64
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: dropOverlay.isSingleImage
                                ? Translation.tr("Drop to set as wallpaper")
                                : Translation.tr("Drop to add to shelf")
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            // Composite source for FastBlur: wallpaper image + visualizer bars
            // rendered together as one layer-enabled texture.
            // FastBlur will source from this instead of raw wallpaper,
            // so the bars get baked into the blur — glowing smears through frosted glass.
            Item {
                id: blurCompositeSource
                x: bgRoot.parallaxX
                y: bgRoot.parallaxY
                width: bgRoot.scaledW
                height: bgRoot.scaledH
                // Only needs to exist (and be usable as a source) when blur is active
                visible: bgRoot.userBlurActive || bgRoot.overviewBlurActive
                // layer.enabled makes Qt render this subtree to an offscreen texture
                // that FastBlur can sample from — this is the key to compositing
                layer.enabled: bgRoot.userBlurActive || bgRoot.overviewBlurActive

                // Wallpaper / video captured via ShaderEffectSource into the composite
                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: bgRoot.wallpaperIsVideo
                        ? liveVideoOutput
                        : (bgRoot.wallpaperAnimation === "" || bgRoot.transitionProgress >= 1.0 ? wallpaper : transitionEffect)
                    hideSource: false   // keep original wallpaper visible for non-blur code paths
                    live: true
                }


            }


            MouseArea {
                id: desktopRightClickArea
                anchors.fill: parent
                z: -2
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    GlobalStates.desktopMenuScreen = bgRoot.screen
                    GlobalStates.desktopMenuX = mouse.x
                    GlobalStates.desktopMenuY = mouse.y
                    GlobalStates.desktopMenuOpen = true
                }
            }
        }
    }
}
