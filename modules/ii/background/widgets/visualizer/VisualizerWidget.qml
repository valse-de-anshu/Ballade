import QtQuick
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
    readonly property string style: (configEntry && configEntry.style) ? configEntry.style : "bars"
    readonly property bool shaderStyle: ["aurora", "ring", "dots", "mirror"].includes(style)
    readonly property bool isRing: style === "ring"
    readonly property bool useCoverColors: shaderStyle && Boolean(configEntry && configEntry.colorSource === "cover")

    property real ringSize: (Config.options.background.widgets.visualizer && Config.options.background.widgets.visualizer.ringSize) ? Config.options.background.widgets.visualizer.ringSize : 380
    property bool isResizing: false
    Connections {
        target: Config.options.background.widgets.visualizer
        function onRingSizeChanged() {
            if (root.isResizing) return;
            const cfgVal = Config.options.background.widgets.visualizer && Config.options.background.widgets.visualizer.ringSize
                ? Config.options.background.widgets.visualizer.ringSize
                : 380;
            if (Math.abs(root.ringSize - cfgVal) > 1) {
                root.ringSize = cfgVal;
            }
        }
    }
    // height stored as 0-100 percentage. 0% → 20px sliver, 100% → full screen height.
    // Widget is anchored to bottom (y = screenHeight - implicitHeight), so small height
    // = only the very top edge of aurora is visible peeking up from the bottom.
    readonly property real heightPct: (configEntry && configEntry.height !== undefined) ? Math.max(0, Math.min(configEntry.height, 100)) : 100
    readonly property real bandHeight: 20 + (heightPct / 100) * (screenHeight - 20)
    readonly property real barsHeight: 240

    implicitWidth: isRing ? ringSize : screenWidth
    implicitHeight: isRing ? ringSize : shaderStyle ? bandHeight : barsHeight
    width: implicitWidth
    height: implicitHeight
    x: isRing ? targetX : 0
    y: isRing ? targetY : screenHeight - implicitHeight
    draggable: isRing && placementStrategy === "free" && !Config.options.background.widgetsLocked
    hoverEnabled: isRing

    function restoreXYBinding() {
        root.x = Qt.binding(() => root.isRing ? root.targetX : 0);
        root.y = Qt.binding(() => root.isRing ? root.targetY : root.screenHeight - root.implicitHeight);
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

        // Categorize into chromatic colors and monochrome/grayscale tones
        const chromatic = [];
        const monochrome = [];

        for (let i = 0; i < raw.length; i++) {
            const c = raw[i];
            const sat = (c && c.hslSaturation !== undefined) ? c.hslSaturation : 0;
            const lit = (c && c.hslLightness !== undefined) ? c.hslLightness : 0.5;
            const hue = (c && c.hslHue !== undefined) ? c.hslHue : -1;

            if (hue >= 0 && sat > 0.12 && lit > 0.05 && lit < 0.95) {
                // Saturated color with genuine hue
                const vibrance = sat * 1.5 + (1.0 - Math.abs(lit - 0.5));
                chromatic.push({ color: c, sat: sat, lit: lit, hue: hue, score: vibrance });
            } else {
                // Achromatic / neutral (black, white, gray)
                monochrome.push({ color: c, lit: lit });
            }
        }

        chromatic.sort((a, b) => b.score - a.score);
        monochrome.sort((a, b) => b.lit - a.lit);

        // Find distinct chromatic colors (different hues)
        const distinctChromatic = [];
        for (let i = 0; i < chromatic.length; i++) {
            const candidate = chromatic[i];
            const isDistinct = distinctChromatic.every(p => {
                let hDiff = Math.abs(candidate.hue - p.hue);
                if (hDiff > 0.5) hDiff = 1.0 - hDiff;
                return hDiff > 0.07;
            });
            if (isDistinct || distinctChromatic.length === 0) {
                distinctChromatic.push(candidate);
            }
        }

        function formatColor(h, s, l) {
            return Qt.hsla(Math.max(0, Math.min(h, 1.0)),
                           Math.max(0, Math.min(s, 1.0)),
                           Math.max(0.25, Math.min(l, 0.92)),
                           1.0);
        }

        // Case 1: 3 or more distinct colorful tones in artwork
        if (distinctChromatic.length >= 3) {
            const c1 = formatColor(distinctChromatic[0].hue, Math.max(distinctChromatic[0].sat, 0.5), Math.max(0.45, Math.min(distinctChromatic[0].lit, 0.7)));
            const c2 = formatColor(distinctChromatic[1].hue, Math.max(distinctChromatic[1].sat, 0.5), Math.max(0.5, Math.min(distinctChromatic[1].lit, 0.75)));
            const c3 = formatColor(distinctChromatic[2].hue, Math.max(distinctChromatic[2].sat, 0.5), Math.max(0.55, Math.min(distinctChromatic[2].lit, 0.8)));
            return [c1, c2, c3];
        }

        // Case 2: 2 distinct colorful tones in artwork
        if (distinctChromatic.length === 2) {
            const c1 = formatColor(distinctChromatic[0].hue, Math.max(distinctChromatic[0].sat, 0.55), 0.52);
            const c2 = formatColor(distinctChromatic[1].hue, Math.max(distinctChromatic[1].sat, 0.55), 0.68);
            const avgHue = (distinctChromatic[0].hue + distinctChromatic[1].hue) / 2.0;
            const c3 = formatColor(avgHue, Math.max(distinctChromatic[0].sat, 0.6), 0.80);
            return [c1, c2, c3];
        }

        // Case 3: 1 dominant colorful tone (e.g. Blue logo with black & white background)
        if (distinctChromatic.length === 1) {
            const base = distinctChromatic[0];
            const h = base.hue;
            const s = Math.max(base.sat, 0.6);
            // Main color, lighter vibrant tip highlight, deep rich base
            const c1 = formatColor(h, s, 0.52);
            const c2 = formatColor(h, Math.max(s * 0.85, 0.4), 0.78);
            const c3 = formatColor((h + 0.04) % 1.0, s, 0.38);
            return [c1, c2, c3];
        }

        // Case 4: Completely monochrome / black & white cover art
        const c1 = Qt.rgba(0.95, 0.96, 0.98, 1.0);  // Pure bright white
        const c2 = Qt.rgba(0.65, 0.70, 0.78, 1.0);  // Cool silver slate
        const c3 = Qt.rgba(0.25, 0.28, 0.34, 1.0);  // Deep charcoal
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
        active: root.shaderStyle
        sensitivity: (root.configEntry && root.configEntry.sensitivity !== undefined) ? root.configEntry.sensitivity : 1
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
            }
        }
    }

    ResizeHandler {
        anchorItem: root
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked || !root.isRing
        currentWidth: root.ringSize
        resizeMode: "diagonal"
        onResized: newValue => {
            root.isResizing = true;
            root.ringSize = Math.round(Math.min(Math.max(newValue, 200), 900));
        }
        onResizeFinished: {
            const finalSize = root.ringSize;
            Config.options.background.widgets.visualizer.ringSize = finalSize;
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
            anchors.bottom: parent.bottom
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
                    topLeftRadius: bars.barWidth / 2
                    topRightRadius: bars.barWidth / 2
                    anchors.bottom: parent.bottom

                    property real intensity: pointValue / bars.maxBarHeight
                    color: Qt.rgba(
                        Appearance.colors.colPrimary.r * intensity + Appearance.colors.colPrimaryContainer.r * (1 - intensity),
                        Appearance.colors.colPrimary.g * intensity + Appearance.colors.colPrimaryContainer.g * (1 - intensity),
                        Appearance.colors.colPrimary.b * intensity + Appearance.colors.colPrimaryContainer.b * (1 - intensity),
                        1
                    )

                    Behavior on height {
                        NumberAnimation { duration: bars.smoothingDuration; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
