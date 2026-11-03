import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "visualizer"

    // "bars" is the original Rectangle visualizer, the others are shaders/<style>.frag.qsb
    readonly property string style: (configEntry && configEntry.style)
        ? configEntry.style
        : ((desktopConfigEntry && desktopConfigEntry.style) ? desktopConfigEntry.style : "bars")
    readonly property bool shaderStyle: ["aurora", "ring", "dots", "mirror"].includes(style)
    readonly property bool isRing: style === "ring"
    readonly property string position: {
        if (configEntry && configEntry.position !== undefined && configEntry.position !== "") {
            return configEntry.position;
        }
        return ["aurora", "mirror"].includes(style) ? "top" : "bottom";
    }
    readonly property bool isTop: !isRing && position === "top"
    readonly property bool useCoverColors: shaderStyle && Boolean(
        (configEntry && configEntry.colorSource)
            ? (configEntry.colorSource === "cover")
            : (desktopConfigEntry && desktopConfigEntry.colorSource === "cover")
    )

    property real ringSize: (root.configEntry && root.configEntry.ringSize)
        ? root.configEntry.ringSize
        : ((root.desktopConfigEntry && root.desktopConfigEntry.ringSize) ? root.desktopConfigEntry.ringSize : 380)
    property bool isResizing: false
    Connections {
        target: root.configEntry
        function onRingSizeChanged() {
            if (root.isResizing) return;
            const cfgVal = (root.configEntry && root.configEntry.ringSize)
                ? root.configEntry.ringSize
                : ((root.desktopConfigEntry && root.desktopConfigEntry.ringSize) ? root.desktopConfigEntry.ringSize : 380);
            if (Math.abs(root.ringSize - cfgVal) > 1) {
                root.ringSize = cfgVal;
            }
        }
    }
    // height stored as 0-100 percentage. 0% → 20px sliver, 100% → full screen height.
    // Widget is anchored to bottom (y = screenHeight - implicitHeight), so small height
    // = only the very top edge of aurora is visible peeking up from the bottom.
    readonly property real heightPct: {
        if (configEntry && configEntry.height !== undefined) {
            return Math.max(0, Math.min(configEntry.height, 100));
        }
        if (desktopConfigEntry && desktopConfigEntry.height !== undefined) {
            return Math.max(0, Math.min(desktopConfigEntry.height, 100));
        }
        return 100;
    }
    readonly property real bandHeight: 20 + (heightPct / 100) * (screenHeight - 20)
    readonly property real barsHeight: 240

    function getSavedRingX() {
        const sw = (root.scaledScreenWidth > 0) ? root.scaledScreenWidth : (root.screenWidth > 0 ? root.screenWidth : 1920);
        const w = (root.ringSize > 0) ? root.ringSize : 380;
        const centerX = Math.round((sw - w) / 2);

        if (root.isLockWidget) {
            const mode = (root.configEntry && root.configEntry.position) ? root.configEntry.position : "default";
            if (mode === "custom" && root.configEntry && root.configEntry.x !== undefined && root.configEntry.x > 0) {
                return root.configEntry.x;
            }
            if (mode === "center") return centerX;
            if (mode === "topLeft" || mode === "bottomLeft") return 48;
            if (mode === "topRight" || mode === "bottomRight") return Math.round(sw - w - 48);
            if (mode === "top" || mode === "bottom") return centerX;
            if (root.desktopConfigEntry && root.desktopConfigEntry.x !== undefined && root.desktopConfigEntry.x > 0) {
                return root.desktopConfigEntry.x;
            }
            return centerX;
        }

        if (root.configEntry && root.configEntry.placementStrategy === "free" && root.configEntry.x !== undefined && root.configEntry.x > 0) {
            return root.configEntry.x;
        }
        if (root.configEntry && root.configEntry.x !== undefined && root.configEntry.x > 0) {
            return root.configEntry.x;
        }
        return centerX;
    }
    function getSavedRingY() {
        const sh = (root.scaledScreenHeight > 0) ? root.scaledScreenHeight : (root.screenHeight > 0 ? root.screenHeight : 1080);
        const h = (root.ringSize > 0) ? root.ringSize : 380;
        const centerY = Math.round((sh - h) / 2);

        if (root.isLockWidget) {
            const mode = (root.configEntry && root.configEntry.position) ? root.configEntry.position : "default";
            if (mode === "custom" && root.configEntry && root.configEntry.y !== undefined && root.configEntry.y > 0) {
                return root.configEntry.y;
            }
            if (mode === "center") return centerY;
            if (mode === "top" || mode === "topLeft" || mode === "topRight") return 48;
            if (mode === "bottom" || mode === "bottomLeft" || mode === "bottomRight") return Math.round(sh - h - 120);
            if (root.desktopConfigEntry && root.desktopConfigEntry.y !== undefined && root.desktopConfigEntry.y > 0) {
                return root.desktopConfigEntry.y;
            }
            return centerY;
        }

        if (root.configEntry && root.configEntry.placementStrategy === "free" && root.configEntry.y !== undefined && root.configEntry.y > 0) {
            return root.configEntry.y;
        }
        if (root.configEntry && root.configEntry.y !== undefined && root.configEntry.y > 0) {
            return root.configEntry.y;
        }
        return centerY;
    }

    readonly property bool hasAudioPoints: {
        const pts = GlobalStates.visualizerPoints;
        if (!pts || pts.length === 0) return false;
        for (let i = 0; i < pts.length; i++) {
            if (pts[i] > 0) return true;
        }
        return false;
    }
    readonly property bool isMusicPlaying: Boolean(
        (MprisController.activePlayer && MprisController.activePlayer.isPlaying) ||
        (MprisController.players && MprisController.players.some(p => p && p.isPlaying)) ||
        hasAudioPoints
    )

    implicitWidth: isRing ? ringSize : screenWidth
    implicitHeight: isRing ? ringSize : shaderStyle ? bandHeight : barsHeight
    width: implicitWidth
    height: implicitHeight
    x: isRing ? targetX : 0
    y: isRing ? targetY : (isTop ? 0 : (screenHeight - implicitHeight))
    opacity: isMusicPlaying ? 1.0 : 0.0
    visible: opacity > 0.001
    enabled: isMusicPlaying && isRing
    acceptedButtons: (isMusicPlaying && isRing) ? Qt.LeftButton : Qt.NoButton
    draggable: isMusicPlaying && isRing && !Config.options.background.widgetsLocked
    hoverEnabled: isMusicPlaying && isRing

    Behavior on opacity {
        NumberAnimation {
            duration: 350
            easing.type: Easing.InOutQuad
        }
    }

    function restoreXYBinding() {
        if (!root.isRing) {
            root.targetX = 0;
            root.targetY = 0;
            root.x = 0;
            root.y = Qt.binding(() => root.isTop ? 0 : (root.screenHeight - root.implicitHeight));
            return;
        }
        root.targetX = Qt.binding(() => Math.max(-root.ringSize + 30, Math.min(root.getSavedRingX(), root.scaledScreenWidth - 30)));
        root.targetY = Qt.binding(() => Math.max(-root.ringSize + 30, Math.min(root.getSavedRingY(), root.scaledScreenHeight - 30)));
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
    }

    function saveVisualizerPosition() {
        if (!root.isRing || !root.configEntry) return;
        const newX = Math.round(root.lastDragX !== undefined ? root.lastDragX : root.x);
        const newY = Math.round(root.lastDragY !== undefined ? root.lastDragY : root.y);
        if (root.isLockWidget) {
            root.configEntry.position = "custom";
            root.configEntry.x = newX;
            root.configEntry.y = newY;
            if (root.desktopConfigEntry) {
                root.desktopConfigEntry.x = newX;
                root.desktopConfigEntry.y = newY;
            }
        } else {
            root.configEntry.placementStrategy = "free";
            root.configEntry.x = newX;
            root.configEntry.y = newY;
            if (Config.options.lock && Config.options.lock.widgets && Config.options.lock.widgets[root.configEntryName]) {
                const lockEntry = Config.options.lock.widgets[root.configEntryName];
                lockEntry.position = "custom";
                lockEntry.x = newX;
                lockEntry.y = newY;
            }
        }
        Config.save();
        root.targetX = newX;
        root.targetY = newY;
        root.x = newX;
        root.y = newY;
        root.restoreXYBinding();
    }

    property bool hadActualDrag: false

    onDraggingChanged: {
        if (dragging) {
            hadActualDrag = true;
        } else if (hadActualDrag) {
            hadActualDrag = false;
            if (isRing && configEntry) {
                saveVisualizerPosition();
            }
        }
    }

    Component.onCompleted: {
        if (root.isRing) {
            root.x = root.getSavedRingX();
            root.y = root.getSavedRingY();
        }
        root.restoreXYBinding();
    }

    onIsRingChanged: {
        if (root.isRing) {
            root.x = root.getSavedRingX();
            root.y = root.getSavedRingY();
        }
        root.restoreXYBinding();
    }

    onStyleChanged: {
        root.restoreXYBinding();
    }

    Connections {
        target: root.configEntry
        function onXChanged() {
            if (root.isRing && !root.dragging) root.restoreXYBinding();
        }
        function onYChanged() {
            if (root.isRing && !root.dragging) root.restoreXYBinding();
        }
        function onPositionChanged() {
            root.restoreXYBinding();
        }
    }

    // Palettes: color1 and color2 carry the shape, color3 the accent (peaks, fallback cover)
    readonly property var themePalette: {
        const c = Appearance.m3colors;
        switch (root.style) {
            case "aurora": return [c.m3primary, c.m3tertiary, c.m3secondary];
            case "ring": return [c.m3primary, c.m3tertiary, c.m3primaryContainer];
            case "dots": return [c.m3onBackground, c.m3primary, c.m3error];
            default: return [c.m3primary, c.m3primaryContainer, c.m3tertiary];
        }
    }
    readonly property var coverPalette: {
        const raw = Array.from((coverQuantizer && coverQuantizer.colors) ? coverQuantizer.colors : []);
        if (!raw || raw.length === 0) return null;

        // Categorize into genuinely chromatic colors vs monochrome/grayscale neutral tones
        const chromatic = [];
        const monochrome = [];

        for (let i = 0; i < raw.length; i++) {
            const c = raw[i];
            if (!c) continue;
            const r = c.r !== undefined ? c.r : 0;
            const g = c.g !== undefined ? c.g : 0;
            const b = c.b !== undefined ? c.b : 0;
            const maxC = Math.max(r, g, b);
            const minC = Math.min(r, g, b);
            const chroma = maxC - minC;
            const lit = (c.hslLightness !== undefined) ? c.hslLightness : (maxC + minC) / 2.0;
            const sat = (c.hslSaturation !== undefined) ? c.hslSaturation : (lit <= 0 || lit >= 1 ? 0 : chroma / (1.0 - Math.abs(2.0 * lit - 1.0)));
            const hue = (c.hslHue !== undefined) ? c.hslHue : -1;

            // Strict threshold: Chroma must be >= 0.12 and lightness between 0.12 and 0.88
            // to avoid dark shadow artifacts or near-white highlights masquerading as vivid color!
            if (chroma >= 0.12 && sat >= 0.16 && lit >= 0.12 && lit <= 0.88 && hue >= 0) {
                const vibrance = chroma * 1.5 + (1.0 - Math.abs(lit - 0.5));
                chromatic.push({ color: c, sat: sat, lit: lit, hue: hue, chroma: chroma, score: vibrance });
            } else {
                monochrome.push({ color: c, lit: lit });
            }
        }

        chromatic.sort((a, b) => b.score - a.score);
        monochrome.sort((a, b) => a.lit - b.lit); // Sort darkest to lightest

        function formatColor(h, s, l) {
            return Qt.hsla(Math.max(0, Math.min(h, 1.0)),
                           Math.max(0, Math.min(s, 1.0)),
                           Math.max(0.12, Math.min(l, 0.95)),
                           1.0);
        }

        // Luminous white tip for loud parts
        const whiteTip = Qt.rgba(0.98, 0.98, 1.0, 1.0);

        // Case 1: Truly monochrome / black & white / grayscale artwork (e.g. Dante Devil May Cry)
        if (chromatic.length === 0) {
            // Base = deep artwork shadow / dark charcoal tone from the cover
            const c1 = Qt.rgba(0.12, 0.13, 0.16, 1.0);
            // Mid = sleek silver / steel gray from the artwork
            const c2 = Qt.rgba(0.68, 0.71, 0.76, 1.0);
            // Tip = pure radiant luminous white
            const c3 = whiteTip;
            return [c1, c2, c3];
        }

        // Find distinct chromatic colors (different hues)
        const distinctChromatic = [];
        for (let i = 0; i < chromatic.length; i++) {
            const candidate = chromatic[i];
            const isDistinct = distinctChromatic.every(p => {
                let hDiff = Math.abs(candidate.hue - p.hue);
                if (hDiff > 0.5) hDiff = 1.0 - hDiff;
                return hDiff > 0.08;
            });
            if (isDistinct || distinctChromatic.length === 0) {
                distinctChromatic.push(candidate);
            }
        }

        // Case 2: Multi-color artwork (2 or more distinct vibrant hues)
        if (distinctChromatic.length >= 2) {
            const hero = distinctChromatic[0];
            const sec = distinctChromatic[1];
            // c1: Deep cover base tone (grounded dark atmospheric tone)
            const c1 = formatColor(sec.hue, Math.min(sec.sat, 0.70), 0.28);
            // c2: Vibrant dominant hero color from the artwork
            const c2 = formatColor(hero.hue, hero.sat, 0.55);
            // c3: Luminous white tip for loud parts
            const c3 = whiteTip;
            return [c1, c2, c3];
        }

        // Case 3: 1 dominant colorful tone (e.g. Crimson artwork or Blue logo)
        const base = distinctChromatic[0];
        const h = base.hue;
        const s = base.sat;
        // c1: Deep grounded base tone of the cover
        const c1 = formatColor(h, Math.min(s, 0.65), 0.25);
        // c2: Radiant dominant hero color
        const c2 = formatColor(h, s, 0.54);
        // c3: Luminous white tip for loud parts
        const c3 = whiteTip;
        return [c1, c2, c3];
    }
    readonly property var visualizerColors: (root.useCoverColors && root.coverPalette) ? root.coverPalette : root.themePalette

    // Cover art path powered reliably by MprisController
    readonly property string coverUrl: {
        const path = MprisController.readyArtFilePath;
        if (!path || path.length === 0) return "";
        return path.startsWith("file://") ? path : Qt.resolvedUrl(path);
    }

    ColorQuantizer {
        id: coverQuantizer
        source: root.coverUrl
        depth: 3
        rescaleSize: 96
    }

    VisualizerEngine {
        id: levelEngine
        active: root.shaderStyle && root.isMusicPlaying
        persistVisible: false
        sensitivity: {
            if (root.configEntry && root.configEntry.sensitivity !== undefined) return root.configEntry.sensitivity;
            if (root.desktopConfigEntry && root.desktopConfigEntry.sensitivity !== undefined) return root.desktopConfigEntry.sensitivity;
            return 1;
        }
    }

    Loader {
        anchors.fill: parent
        active: root.style === "bars"
        sourceComponent: BarsVisualizer {}
    }

    Loader {
        anchors.fill: parent
        active: root.shaderStyle
        sourceComponent: Item {
            // Ring: the cover is rendered into a texture so the shader gets it already cropped
            Item {
                id: coverItem
                width: 512
                height: 512
                visible: root.isRing
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.isRing ? root.coverUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(512, 512)
                    asynchronous: true
                    smooth: true
                }
            }
            ShaderEffectSource {
                id: coverTexture
                sourceItem: coverItem
                hideSource: true
                visible: false
            }

            VisualizerShader {
                anchors.fill: parent
                style: root.style
                engine: levelEngine
                color1: (root.visualizerColors && root.visualizerColors[0]) ? root.visualizerColors[0] : Appearance.colors.colPrimary
                color2: (root.visualizerColors && root.visualizerColors[1]) ? root.visualizerColors[1] : Appearance.colors.colTertiary
                color3: (root.visualizerColors && root.visualizerColors[2]) ? root.visualizerColors[2] : Appearance.colors.colSecondary
                cover: coverTexture
                hasCover: coverImage.status === Image.Ready ? 1 : 0
                transform: Scale {
                    origin.y: root.height / 2
                    yScale: (["aurora", "dots"].includes(root.style) && root.isTop) ? -1 : 1
                }
            }
        }
    }

    ResizeHandler {
        anchorItem: root
        hoverActive: root.containsMouse && root.isMusicPlaying
        locked: Config.options.background.widgetsLocked || !root.isRing || !root.isMusicPlaying
        visible: root.isMusicPlaying && root.isRing
        enabled: root.isMusicPlaying && root.isRing
        currentWidth: root.ringSize
        resizeMode: "diagonal"
        onResized: newValue => {
            root.isResizing = true;
            root.ringSize = Math.round(Math.min(Math.max(newValue, 200), 900));
        }
        onResizeFinished: {
            const finalSize = root.ringSize;
            if (root.configEntry) root.configEntry.ringSize = finalSize;
            if (root.desktopConfigEntry) root.desktopConfigEntry.ringSize = finalSize;
            Config.save();
            // Reset flag after a short delay so the Connections handler doesn't fight us
            resizeCooldownTimer.restart();
        }
    }

    Timer {
        id: resizeCooldownTimer
        interval: 300
        repeat: false
        onTriggered: root.isResizing = false
    }

    // Original visualizer: one rounded Rectangle per 12 px of screen width
    component BarsVisualizer: Item {
        id: bars

        readonly property var points: GlobalStates.visualizerPoints

        property real barWidth: 4
        property real barSpacing: 8
        property real maxBarHeight: 220
        property real maxVisualizerValue: 1000
        property real smoothingDuration: 150

        readonly property int barCount: Math.max(1, Math.floor(root.screenWidth / (barWidth + barSpacing)))

        readonly property var smoothedPoints: {
            let raw = points
            if (!raw || raw.length === 0) return Array(barCount).fill(0)
            let count = barCount
            let mapped = new Array(count)
            let rawLenM1 = raw.length - 1

            for (let i = 0; i < count; i++) {
                let progress = i / (count - 1 || 1)
                let relPos = progress * rawLenM1
                let low = Math.floor(relPos)
                let high = Math.ceil(relPos)
                let mix = relPos - low
                mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < raw.length ? mix : 0))
            }

            let smoothed = new Array(count)
            let sW = 0.2
            for (let j = 0; j < count; j++) {
                let p = mapped[Math.max(0, j - 1)]
                let n = mapped[Math.min(count - 1, j + 1)]
                smoothed[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW)
            }
            return smoothed
        }

        property real activityOpacity: 0
        Behavior on activityOpacity {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }

        Timer {
            id: silenceTimer
            interval: 1000
            onTriggered: bars.activityOpacity = 0
        }

        onPointsChanged: {
            if (points.some(p => p > 0)) {
                bars.activityOpacity = 1.0
                silenceTimer.restart()
            }
        }

        Row {
            anchors.top: root.isTop ? parent.top : undefined
            anchors.bottom: root.isTop ? undefined : parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: bars.barSpacing
            opacity: bars.activityOpacity

            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: bars.barCount
                Rectangle {
                    required property int index
                    width: bars.barWidth
                    property real pointValue: {
                        const v = (bars.smoothedPoints && bars.smoothedPoints[index] !== undefined) ? bars.smoothedPoints[index] : 0
                        return Math.max(bars.barWidth, (v / bars.maxVisualizerValue) * bars.maxBarHeight)
                    }
                    height: pointValue
                    topLeftRadius: root.isTop ? 0 : (bars.barWidth / 2)
                    topRightRadius: root.isTop ? 0 : (bars.barWidth / 2)
                    bottomLeftRadius: root.isTop ? (bars.barWidth / 2) : 0
                    bottomRightRadius: root.isTop ? (bars.barWidth / 2) : 0
                    anchors.top: root.isTop ? parent.top : undefined
                    anchors.bottom: root.isTop ? undefined : parent.bottom

                    property real intensity: Math.max(0.0, Math.min(pointValue / bars.maxBarHeight, 1.0))
                    property color barCol1: (root.visualizerColors && root.visualizerColors[0]) ? root.visualizerColors[0] : Appearance.colors.colPrimary
                    property color barCol2: (root.visualizerColors && root.visualizerColors[1]) ? root.visualizerColors[1] : Appearance.colors.colTertiary
                    property color barCol3: (root.visualizerColors && root.visualizerColors[2]) ? root.visualizerColors[2] : Qt.rgba(0.98, 0.98, 1.0, 1.0)
                    color: {
                        if (intensity < 0.5) {
                            const f = intensity * 2.0;
                            return Qt.rgba(
                                barCol1.r * (1.0 - f) + barCol2.r * f,
                                barCol1.g * (1.0 - f) + barCol2.g * f,
                                barCol1.b * (1.0 - f) + barCol2.b * f,
                                1.0
                            );
                        } else {
                            const f = (intensity - 0.5) * 2.0;
                            return Qt.rgba(
                                barCol2.r * (1.0 - f) + barCol3.r * f,
                                barCol2.g * (1.0 - f) + barCol3.g * f,
                                barCol2.b * (1.0 - f) + barCol3.b * f,
                                1.0
                            );
                        }
                    }

                    Behavior on height {
                        NumberAnimation { duration: bars.smoothingDuration; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
