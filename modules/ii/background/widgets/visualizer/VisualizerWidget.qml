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

    implicitWidth: isRing ? ringSize : screenWidth
    implicitHeight: isRing ? ringSize : shaderStyle ? bandHeight : barsHeight
    width: implicitWidth
    height: implicitHeight
    x: isRing ? targetX : 0
    y: isRing ? targetY : (isTop ? 0 : (screenHeight - implicitHeight))
    enabled: isRing
    acceptedButtons: isRing ? Qt.LeftButton : Qt.NoButton
    draggable: isRing && !Config.options.background.widgetsLocked
    hoverEnabled: isRing

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
            case "dots": return [c.m3primary, c.m3secondary, c.m3tertiary];
            default: return [c.m3primary, c.m3primaryContainer, c.m3tertiary];
        }
    }
    readonly property var coverPalette: {
        const raw = Array.from((coverQuantizer && coverQuantizer.colors) ? coverQuantizer.colors : []);
        if (!raw || raw.length === 0) return null;

        // 1. Parse all extracted colors into RGB, HSL, and calculate Chroma
        const parsed = [];
        let totalLit = 0;
        let maxSaturation = 0;

        for (let i = 0; i < raw.length; i++) {
            const c = raw[i];
            if (!c) continue;
            const r = (c.r !== undefined && !isNaN(c.r)) ? c.r : 0.5;
            const g = (c.g !== undefined && !isNaN(c.g)) ? c.g : 0.5;
            const b = (c.b !== undefined && !isNaN(c.b)) ? c.b : 0.5;
            const h = (c.hslHue !== undefined && c.hslHue >= 0) ? c.hslHue : 0;
            const s = (c.hslSaturation !== undefined && !isNaN(c.hslSaturation)) ? c.hslSaturation : 0;
            const l = (c.hslLightness !== undefined && !isNaN(c.hslLightness)) ? c.hslLightness : 0.5;

            totalLit += l;
            if (s > maxSaturation) maxSaturation = s;

            // Chroma emphasizes colors with distinct saturation while rewarding pleasing mid-lightness
            const chroma = s * (1.0 - Math.abs(l - 0.5) * 0.4);
            parsed.push({ r: r, g: g, b: b, h: h, s: s, l: l, chroma: chroma, color: c });
        }

        if (parsed.length === 0) return null;

        const avgCoverLit = totalLit / parsed.length;
        const isMonochrome = maxSaturation < 0.08;

        // Sort by chroma descending (most vibrant / characterful colors first)
        parsed.sort((a, b) => b.chroma - a.chroma);

        // 2. Select up to 4 Dominant distinct anchor colors across the cover
        const dominants = [];
        for (let i = 0; i < parsed.length; i++) {
            if (dominants.length >= 4) break;
            const candidate = parsed[i];

            // Filter out near-identical hues so we get true color variety
            const isDistinct = dominants.every(d => {
                let diff = Math.abs(candidate.h - d.h);
                if (diff > 0.5) diff = 1.0 - diff;
                if (diff < 0.055) {
                    return Math.abs(candidate.l - d.l) > 0.30 || Math.abs(candidate.s - d.s) > 0.35;
                }
                return true;
            });

            if (isDistinct || dominants.length === 0) {
                dominants.push(candidate);
            }
        }

        // 3. Collect non-dominant colors and compute the atmospheric ambient light
        const nonDominants = parsed.filter(c => !dominants.includes(c));
        let ambR = 0, ambG = 0, ambB = 0;
        const ndCount = nonDominants.length > 0 ? nonDominants.length : parsed.length;
        const ndSource = nonDominants.length > 0 ? nonDominants : parsed;

        for (let i = 0; i < ndSource.length; i++) {
            ambR += ndSource[i].r;
            ambG += ndSource[i].g;
            ambB += ndSource[i].b;
        }
        ambR /= ndCount;
        ambG /= ndCount;
        ambB /= ndCount;

        // Determine if artwork has a Dark Aesthetic (avg lightness is low or dominants are dark)
        const d1Lit = dominants[0] ? dominants[0].l : 0.5;
        const isDarkCover = (avgCoverLit < 0.34) || (d1Lit < 0.28 && avgCoverLit < 0.45);

        // Helper: blend two RGB colors
        function mixRgb(c1, c2, weight2) {
            const w1 = 1.0 - weight2;
            return {
                r: c1.r * w1 + c2.r * weight2,
                g: c1.g * w1 + c2.g * weight2,
                b: c1.b * w1 + c2.b * weight2
            };
        }

        // Helper: Format tuned color with adaptive dynamic range
        function tuneAdaptiveColor(rgbObj, minSat, targetLit, isDark) {
            const qc = Qt.rgba(
                Math.max(0, Math.min(rgbObj.r, 1.0)),
                Math.max(0, Math.min(rgbObj.g, 1.0)),
                Math.max(0, Math.min(rgbObj.b, 1.0)),
                1.0
            );
            let h = qc.hslHue >= 0 ? qc.hslHue : 0.55;
            let s = qc.hslSaturation;

            if (isDark) {
                // In dark theme: let colors stay deep, moody, and velvety!
                s = Math.max(s, minSat * 0.7);
                s = Math.min(s, 0.90);
                // Keep targetLit low (0.12 - 0.35) so dark covers shine in their true darkness!
                let l = Math.max(0.10, Math.min(targetLit, 0.72));
                return Qt.hsla(h, s, l, 1.0);
            } else {
                // In bright/vibrant theme: boost into cozy radiant glow
                s = Math.max(s, minSat);
                s = Math.min(s, 0.88);
                let l = Math.max(0.38, Math.min(targetLit, 0.86));
                return Qt.hsla(h, s, l, 1.0);
            }
        }

        // Case A: Pure Monochrome / Black & White cover art
        if (isMonochrome) {
            if (isDarkCover) {
                // Dark Moody Obsidian aesthetic (pure black/charcoal luxury with cool starlight rim)
                const c1 = Qt.hsla(0.62, 0.25, 0.12, 1.0); // Deep velvety midnight obsidian
                const c2 = Qt.hsla(0.58, 0.30, 0.24, 1.0); // Moody slate shadow
                const c3 = Qt.hsla(0.55, 0.25, 0.65, 1.0); // Glowing cool starlight rim
                return [c1, c2, c3];
            } else {
                // Ethereal Celestial Aurora glow
                const c1 = Qt.hsla(0.62, 0.65, 0.46, 1.0); // Deep velvety twilight sapphire
                const c2 = Qt.hsla(0.48, 0.72, 0.62, 1.0); // Soft ethereal aurora cyan / mint
                const c3 = Qt.hsla(0.12, 0.60, 0.80, 1.0); // Luminous warm pearl starlight
                return [c1, c2, c3];
            }
        }

        // Case B: Artwork with colors — Aurora Fusion of 4 Dominants + Ambient Non-Dominants
        const d1 = dominants[0];
        const d2 = dominants.length > 1 ? dominants[1] : { r: d1.r, g: d1.g, b: d1.b, h: (d1.h + 0.12) % 1.0, s: d1.s, l: d1.l };
        const d3 = dominants.length > 2 ? dominants[2] : { r: d2.r, g: d2.g, b: d2.b, h: (d1.h + 0.25) % 1.0, s: d2.s, l: d2.l };
        const d4 = dominants.length > 3 ? dominants[3] : { r: d3.r, g: d3.g, b: d3.b, h: (d1.h + 0.38) % 1.0, s: d3.s, l: d3.l };

        const ambObj = { r: ambR, g: ambG, b: ambB };

        // 1. Base Glow (c1): Rich foundation blending D1 with ambient warmth
        const rawBase = mixRgb(d1, ambObj, 0.22);
        // If dark cover: L ≈ 0.12 - 0.20 (deep dark!); If bright cover: L ≈ 0.46
        const baseLit = isDarkCover ? Math.max(0.12, Math.min(d1.l * 0.9, 0.20)) : 0.46;
        const c1 = tuneAdaptiveColor(rawBase, 0.65, baseLit, isDarkCover);

        // 2. Midwave (c2): Flowing atmosphere blending D2 + D3 + ambient midtones
        const midDominants = mixRgb(d2, d3, 0.45);
        const rawMid = mixRgb(midDominants, ambObj, 0.18);
        // If dark cover: L ≈ 0.22 - 0.34 (moody dark midtone!); If bright cover: L ≈ 0.62
        const midLit = isDarkCover ? Math.max(0.22, Math.min(avgCoverLit * 1.1, 0.34)) : 0.62;
        const c2 = tuneAdaptiveColor(rawMid, 0.68, midLit, isDarkCover);

        // 3. Crest Shimmer (c3): Luminous accent highlight on peaks blending D4 + D2 + bright ambient
        const crestDominants = mixRgb(d4, d2, 0.50);
        const rawCrest = mixRgb(crestDominants, ambObj, 0.15);
        // If dark cover: L ≈ 0.58 (subtle glowing rim so it is visible against dark wallpaper); If bright: L ≈ 0.78
        const crestLit = isDarkCover ? Math.max(0.52, Math.min(avgCoverLit + 0.35, 0.68)) : 0.78;
        const c3 = tuneAdaptiveColor(rawCrest, 0.58, crestLit, isDarkCover);

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
        depth: 4
        rescaleSize: 128
    }

    VisualizerEngine {
        id: levelEngine
        active: root.shaderStyle
        persistVisible: root.isRing
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
                visible: Boolean(root.coverUrl && root.coverUrl !== "")
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: (root.coverUrl && root.coverUrl !== "") ? root.coverUrl : ""
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

                    property real intensity: pointValue / bars.maxBarHeight
                    property color barCol1: (root.visualizerColors && root.visualizerColors[0]) ? root.visualizerColors[0] : Appearance.colors.colPrimary
                    property color barCol2: (root.visualizerColors && root.visualizerColors[1]) ? root.visualizerColors[1] : Appearance.colors.colPrimaryContainer
                    color: Qt.rgba(
                        barCol1.r * intensity + barCol2.r * (1 - intensity),
                        barCol1.g * intensity + barCol2.g * (1 - intensity),
                        barCol1.b * intensity + barCol2.b * (1 - intensity),
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
