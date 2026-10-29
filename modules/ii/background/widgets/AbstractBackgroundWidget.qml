import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale
    property bool isLockWidget: false
    property bool visibleWhenLocked: Config.options.lock.showWidgets
    readonly property var desktopConfigEntry: Config.options.background && Config.options.background.widgets ? Config.options.background.widgets[configEntryName] : null
    property var configEntry: isLockWidget
        ? (Config.options.lock && Config.options.lock.widgets ? Config.options.lock.widgets[configEntryName] : null)
        : desktopConfigEntry
    property string placementStrategy: configEntry?.placementStrategy ?? "free"

    function getDefaultLockX() {
        const mode = (configEntry && configEntry.position) ? configEntry.position : (configEntryName === "clock" ? "center" : (configEntryName === "media" ? "bottomLeft" : "default"));
        const sw = (scaledScreenWidth > 0) ? scaledScreenWidth : screenWidth;
        const w = (width > 0) ? width : (implicitWidth > 0 ? implicitWidth : 300);
        switch (mode) {
            case "center":
            case "top":
            case "bottom":
                return Math.round((sw - w) / 2);
            case "topLeft":
            case "bottomLeft":
                return 48;
            case "topRight":
            case "bottomRight":
                return Math.round(sw - w - 48);
            case "custom":
                return (configEntry && configEntry.x !== undefined && configEntry.x > 0) ? configEntry.x : Math.round((sw - w) / 2);
            case "default":
            default: {
                const desk = desktopConfigEntry;
                return (desk && desk.x !== undefined && desk.x > 0) ? desk.x : 48;
            }
        }
    }

    function getDefaultLockY() {
        const mode = (configEntry && configEntry.position) ? configEntry.position : (configEntryName === "clock" ? "center" : (configEntryName === "media" ? "bottomLeft" : "default"));
        const sh = (scaledScreenHeight > 0) ? scaledScreenHeight : screenHeight;
        const h = (height > 0) ? height : (implicitHeight > 0 ? implicitHeight : 200);
        switch (mode) {
            case "center":
                return Math.round((sh - h) / 2 - 40);
            case "top":
            case "topLeft":
            case "topRight":
                return 48;
            case "bottom":
            case "bottomLeft":
            case "bottomRight":
                return Math.round(sh - h - 120);
            case "custom":
                return (configEntry && configEntry.y !== undefined && configEntry.y > 0) ? configEntry.y : Math.round((sh - h) / 2 - 40);
            case "default":
            default: {
                const desk = desktopConfigEntry;
                return (desk && desk.y !== undefined && desk.y > 0) ? desk.y : 48;
            }
        }
    }

    property real targetX: isLockWidget
        ? Math.max(-width + 30, Math.min(getDefaultLockX(), scaledScreenWidth - 30))
        : Math.max(-width + 30, Math.min(configEntry?.x ?? 0, scaledScreenWidth - 30))
    property real targetY: isLockWidget
        ? Math.max(-height + 30, Math.min(getDefaultLockY(), scaledScreenHeight - 30))
        : Math.max(-height + 30, Math.min(configEntry?.y ?? 0, scaledScreenHeight - 30))
    x: targetX
    y: targetY
    draggable: !Config.options.background.widgetsLocked
    property bool initialPositionSet: false
    animateXPos: !dragging && initialPositionSet
    animateYPos: !dragging && initialPositionSet
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    function restoreXYBinding() {
        if (isLockWidget) {
            root.targetX = Qt.binding(() => Math.max(-root.width + 30, Math.min(root.getDefaultLockX(), root.scaledScreenWidth - 30)));
            root.targetY = Qt.binding(() => Math.max(-root.height + 30, Math.min(root.getDefaultLockY(), root.scaledScreenHeight - 30)));
            root.x = Qt.binding(() => root.targetX);
            root.y = Qt.binding(() => root.targetY);
            return;
        }
        root.targetX = Qt.binding(() => Math.max(-root.width + 30, Math.min(root.configEntry?.x ?? 0, root.scaledScreenWidth - 30)));
        root.targetY = Qt.binding(() => Math.max(-root.height + 30, Math.min(root.configEntry?.y ?? 0, root.scaledScreenHeight - 30)));
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
    }

    function saveDraggedPosition() {
        if (!configEntry) return;
        const newX = Math.round(root.lastDragX !== undefined ? root.lastDragX : root.x);
        const newY = Math.round(root.lastDragY !== undefined ? root.lastDragY : root.y);
        if (newX <= 0 && newY <= 0) return;
        if (isLockWidget) {
            configEntry.position = "custom";
            configEntry.x = newX;
            configEntry.y = newY;
        } else {
            configEntry.placementStrategy = "free";
            configEntry.x = newX;
            configEntry.y = newY;
        }
        Config.save();
        root.targetX = newX;
        root.targetY = newY;
        root.x = newX;
        root.y = newY;
        root.restoreXYBinding();
    }

    Connections {
        target: root.configEntry
        ignoreUnknownSignals: true
        function onXChanged() {
            if (!root.dragging) root.restoreXYBinding();
        }
        function onYChanged() {
            if (!root.dragging) root.restoreXYBinding();
        }
        function onPlacementStrategyChanged() {
            if (!root.dragging) root.restoreXYBinding();
        }
        function onPositionChanged() {
            if (!root.dragging) root.restoreXYBinding();
        }
    }

    property bool hadActualDrag: false

    onDraggingChanged: {
        if (dragging) {
            hadActualDrag = true;
        } else if (hadActualDrag) {
            hadActualDrag = false;
            if (configEntry) {
                saveDraggedPosition();
            }
        }
    }

    Component.onCompleted: {
        if (!isLockWidget && configEntry) {
            // If x and y are uninitialized, center in a natural desktop area
            if ((configEntry.x === undefined || configEntry.x <= 0) && (configEntry.y === undefined || configEntry.y <= 0)) {
                let naturalX = Math.round(Math.max(48, (scaledScreenWidth - (width > 0 ? width : 450)) / 2));
                let naturalY = Math.round(Math.max(80, (scaledScreenHeight - (height > 0 ? height : 200)) / 2));
                configEntry.x = naturalX;
                configEntry.y = naturalY;
                Config.save();
            }
        }
        restoreXYBinding();
        Qt.callLater(() => {
            initialPositionSet = true;
        });
    }

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Boolean(Config.options.background.wallpaperPath) && /\.(mp4|webm|mkv|avi|mov)$/i.test(Config.options.background.wallpaperPath)
    property string wallpaperPath: wallpaperIsVideo ? (Config.options.background.thumbnailPath || Config.options.background.wallpaperPath) : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    Connections {
        target: Wallpapers
        function onChanged() { refreshPlacementIfNeeded() }
    }
    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }
    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        // TODO: make these less arbitrary
        property int contentWidth: 300
        property int contentHeight: 300
        property int horizontalPadding: 200
        property int verticalPadding: 200
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh") // Comments to force the formatter to break lines
            , "--screen-width", Math.round(root.scaledScreenWidth) //
            , "--screen-height", Math.round(root.scaledScreenHeight) //
            , "--width", contentWidth //
            , "--height", contentHeight //
            , "--horizontal-padding", horizontalPadding //
            , "--vertical-padding", verticalPadding //
            , wallpaperPath //
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
            // "--visual-output",
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                // console.log("[Background] Least busy region output:", output)
                if (output.length === 0) return;
                try {
                    const parsedContent = JSON.parse(output);
                    root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                    if (root.placementStrategy === "free") return;
                    root.targetX = parsedContent.center_x * root.wallpaperScale - root.width / 2;
                    root.targetY  = parsedContent.center_y * root.wallpaperScale - root.height / 2;
                } catch (e) {
                    // Ignore non-JSON script output gracefully
                }
            }
        }
    }
}