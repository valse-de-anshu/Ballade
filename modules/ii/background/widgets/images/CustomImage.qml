pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

Item {
    id: root

    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale

    property var cfg: Config.options.background.widgets.customImage
    property string imagePath: cfg?.path ?? ""
    property real widgetSize: cfg?.size ?? 200
    property string shapeName: cfg?.shape ?? "Cookie4Sided"
    property bool isTransparent: cfg?.transparent ?? false
    property bool dropHover: false
    property bool locked: Config.options.background.widgetsLocked

    property bool infiniteLoop: cfg?.infiniteLoop ?? false
    property bool hoverPlaying: true

    Timer {
        id: playTimer
        interval: 40000
        running: false
        repeat: false
        onTriggered: {
            console.log("[CustomImage] 40-second timer triggered! Pausing GIF animation to static image.")
            root.hoverPlaying = false
        }
    }

    Component.onCompleted: {
        if (!root.infiniteLoop) {
            root.hoverPlaying = true
            playTimer.restart()
        }
    }

    onInfiniteLoopChanged: {
        if (infiniteLoop) {
            playTimer.stop()
            root.hoverPlaying = true
        } else {
            root.hoverPlaying = true
            playTimer.restart()
        }
    }

    readonly property bool isFreeShape: shapeName === "Free"
    readonly property bool isVerticalRect: shapeName === "VerticalRectangle" || shapeName === "Vertical Rectangle"
    readonly property bool isRectangle: shapeName === "Rectangle"
    readonly property real imgAspect: {
        let w = animImg.sourceSize.width
        let h = animImg.sourceSize.height
        if (w > 0 && h > 0 && isFinite(w / h)) return w / h
        return 1.0
    }

    width: {
        let size = root.widgetSize || 200
        if (isFreeShape) {
            let asp = root.imgAspect || 1.0
            return asp <= 1.0 ? Math.max(50, size * asp) : size
        } else if (isVerticalRect) {
            return Math.max(50, size * 0.75)
        } else if (isRectangle) {
            return Math.max(50, size * 1.33)
        }
        return size
    }

    height: {
        let size = root.widgetSize || 200
        if (isFreeShape) {
            let asp = root.imgAspect || 1.0
            return asp > 1.0 ? Math.max(50, size / asp) : size
        }
        return size
    }

    x: Math.max(-width + 30, Math.min(cfg?.x ?? 400, scaledScreenWidth - 30))
    y: Math.max(-height + 30, Math.min(cfg?.y ?? 100, scaledScreenHeight - 30))

    Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    function getShape(name) {
        switch (name) {
            case "Free":          return MaterialShape.Shape.Square
            case "VerticalRectangle": return MaterialShape.Shape.Square
            case "Rectangle":     return MaterialShape.Shape.Square
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
            default:              return MaterialShape.Shape.Cookie4Sided
        }
    }

    function savePosition() {
        Config.options.background.widgets.customImage.x = root.x
        Config.options.background.widgets.customImage.y = root.y
    }

    property var cachedCanvas: null
    function findCanvas() {
        if (!cachedCanvas) {
            var p = root.parent
            while (p) {
                if (p.isWidgetCanvas === true) { cachedCanvas = p; break }
                p = p.parent
            }
        }
        return cachedCanvas
    }

    function snap(value) {
        return Math.round(value / 24) * 24
    }

    Item {
        id: dragProxy
        parent: root.parent
        x: root.x
        y: root.y

        onXChanged: {
            if (dragArea.drag.active) {
                var c = root.findCanvas()
                if (c) {
                    var widgetCenterX = root.x + root.width / 2
                    var widgetCenterY = root.y + root.height / 2
                    c.setCenterActive(Math.abs(widgetCenterX - c.width / 2) < 24, Math.abs(widgetCenterY - c.height / 2) < 24)
                }
            }
        }
        onYChanged: {
            if (dragArea.drag.active) {
                var c = root.findCanvas()
                if (c) {
                    var widgetCenterX = root.x + root.width / 2
                    var widgetCenterY = root.y + root.height / 2
                    c.setCenterActive(Math.abs(widgetCenterX - c.width / 2) < 24, Math.abs(widgetCenterY - c.height / 2) < 24)
                }
            }
        }
    }

    Binding {
        target: root
        property: "x"
        value: snap(dragProxy.x)
        when: dragArea.drag.active
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root
        property: "y"
        value: snap(dragProxy.y)
        when: dragArea.drag.active
        restoreMode: Binding.RestoreNone
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        drag.target: root.locked ? undefined : dragProxy
        drag.axis: Drag.XAndYAxis
        drag.minimumX: -root.width + 30
        drag.maximumX: root.scaledScreenWidth - 30
        drag.minimumY: -root.height + 30
        drag.maximumY: root.scaledScreenHeight - 30
        cursorShape: root.locked ? Qt.ArrowCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

        onEntered: {
            if (!root.infiniteLoop) {
                root.hoverPlaying = true
                playTimer.restart()
            }
        }

        onPressed: {
            dragProxy.x = root.x
            dragProxy.y = root.y
            if (!root.locked) {
                var c = root.findCanvas()
                console.log("[CustomImage] onPressed findCanvas result:", c)
                if (c) c.setDragging(true)
            }
            if (!root.infiniteLoop) {
                root.hoverPlaying = true
                playTimer.restart()
            }
        }

        onReleased: {
            var c = root.findCanvas()
            if (c) {
                c.setDragging(false)
                var left = root.x
                var right = root.x + root.width
                var top = root.y
                var bottom = root.y + root.height
                var verticalLines = [left, right]
                var horizontalLines = [top, bottom]

                var widgetCenterX = root.x + root.width / 2
                var widgetCenterY = root.y + root.height / 2
                if (Math.abs(widgetCenterX - c.width / 2) < 12)
                    verticalLines.push(c.width / 2)
                if (Math.abs(widgetCenterY - c.height / 2) < 12)
                    horizontalLines.push(c.height / 2)

                if (Config.options.background.showSnapLines ?? true)
                    c.flashLines(verticalLines, horizontalLines)
            }
            dragProxy.x = root.x
            dragProxy.y = root.y
            root.savePosition()
        }
    }

    MaterialShape {
        id: shadowShape
        anchors.fill: parent
        color: root.isTransparent ? "transparent" : Appearance.colors.colPrimaryContainer
        shape: root.getShape(root.shapeName)
        visible: false
    }

    StyledDropShadow {
        target: shadowShape
        z: -1
        visible: !root.isTransparent
    }

    MaterialShape {
        id: imageShape
        anchors.fill: parent
        z: 0
        color: root.isTransparent
            ? (root.imagePath === "" ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.7) : "transparent")
            : Appearance.colors.colPrimaryContainer
        shape: root.getShape(root.shapeName)

        layer.enabled: !(root.isFreeShape || root.isVerticalRect || root.isRectangle)
        layer.effect: OpacityMask {
            maskSource: MaterialShape {
                width: imageShape.width
                height: imageShape.height
                shape: root.getShape(root.shapeName)
            }
        }

        AnimatedImage {
            id: animImg
            anchors.fill: parent
            source: root.imagePath !== "" ? ("file://" + root.imagePath) : ""
            fillMode: (root.isFreeShape || root.isVerticalRect || root.isRectangle) ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            visible: root.imagePath !== "" && status !== Image.Error
            playing: visible && root.visible && !GlobalStates.screenLocked && (root.infiniteLoop || root.hoverPlaying)
            paused: !playing
        }

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.widgetSize / 3
            text: root.dropHover ? "download" : "image"
            fill: root.dropHover ? 1 : 0
            color: root.dropHover ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimaryContainer
            visible: root.imagePath === ""
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        }

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: (drag) => { drag.accept(Qt.CopyAction); root.dropHover = true }
            onExited: { root.dropHover = false }
            onDropped: (drop) => {
                if (drop.hasUrls && drop.urls.length > 0) {
                    var cleanPath = drop.urls[0].toString().replace(/^file:\/\//, "")
                    var ext = cleanPath.split(".").pop().toLowerCase()
                    var accepted = ["png","jpg","jpeg","webp","avif","bmp","gif","tiff","tif"]
                    if (accepted.indexOf(ext) !== -1) {
                        Config.options.background.widgets.customImage.path = cleanPath
                    }
                }
                root.dropHover = false
            }
        }
    }

    ResizeHandler {
        anchorItem: imageShape
        hoverActive: dragArea.containsMouse
        locked: Config.options.background.widgetsLocked
        currentWidth: (root.widgetSize && !isNaN(root.widgetSize)) ? root.widgetSize : 200
        resizeMode: "diagonal"
        z: 10
        onResized: (newValue) => {
            root.widgetSize = Math.max(80, newValue)
        }
        onResizeFinished: {
            Config.options.background.widgets.customImage.size = root.widgetSize
        }
    }
}
