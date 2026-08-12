pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

// Standalone draggable image widget for extra custom images.
// Does NOT extend AbstractBackgroundWidget to avoid the shared configEntry problem.
Item {
    id: root

    required property int imageIndex
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale

    property var cfg: Config.options.background.widgets.customImages[root.imageIndex] ?? {}
    property string imagePath: cfg.path ?? ""
    property real widgetSize: cfg.size ?? 200
    property string shapeName: cfg.shape ?? "Cookie4Sided"
    property bool dropHover: false
    property bool locked: Config.options.background.widgetsLocked

    width: widgetSize
    height: widgetSize

    x: Math.max(0, Math.min(cfg.x ?? (100 + root.imageIndex * 220), scaledScreenWidth - width))
    y: Math.max(0, Math.min(cfg.y ?? 100, scaledScreenHeight - height))

    Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    function getShape(name) {
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
            default:              return MaterialShape.Shape.Cookie4Sided
        }
    }

    function savePosition() {
        var arr = Config.options.background.widgets.customImages.slice()
        if (!arr[root.imageIndex]) return
        arr[root.imageIndex] = Object.assign({}, arr[root.imageIndex], {
            x: root.x,
            y: root.y
        })
        Config.options.background.widgets.customImages = arr
    }

    // -- Drag ---
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root.locked ? undefined : root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: root.scaledScreenWidth - root.width
        drag.minimumY: 0
        drag.maximumY: root.scaledScreenHeight - root.height
        cursorShape: root.locked ? Qt.ArrowCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
        onReleased: root.savePosition()
    }

    // -- Visual ---
    MaterialShape {
        id: shadowShape
        anchors.fill: parent
        color: Appearance.colors.colPrimaryContainer
        shape: root.getShape(root.shapeName)
        visible: false
    }

    StyledDropShadow {
        target: shadowShape
        z: -1
    }

    MaterialShape {
        id: imageShape
        anchors.fill: parent
        z: 0
        color: Appearance.colors.colPrimaryContainer
        shape: root.getShape(root.shapeName)

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: MaterialShape {
                width: imageShape.width
                height: imageShape.height
                shape: root.getShape(root.shapeName)
            }
        }

        // GIF / image
        AnimatedImage {
            anchors.fill: parent
            source: root.imagePath !== "" ? ("file://" + root.imagePath) : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: root.imagePath !== "" && status !== Image.Error
            playing: true
            paused: false
        }

        // Placeholder icon when no path set
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.widgetSize / 3
            text: root.dropHover ? "download" : "image"
            fill: root.dropHover ? 1 : 0
            color: root.dropHover ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimaryContainer
            visible: root.imagePath === ""
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        }

        // Drag-and-drop file onto widget
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
                        var arr = Config.options.background.widgets.customImages.slice()
                        arr[root.imageIndex] = Object.assign({}, arr[root.imageIndex], { path: cleanPath })
                        Config.options.background.widgets.customImages = arr
                    }
                }
                root.dropHover = false
            }
        }
    }

    // Resize handle (bottom-right corner)
    Rectangle {
        visible: !root.locked
        width: 18; height: 18
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: "transparent"
        z: 10

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 14
            text: "open_in_full"
            color: Appearance.colors.colOnPrimaryContainer
            opacity: 0.7
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            property real startX: 0
            property real startSize: 0
            onPressed: (mouse) => {
                startX = mouse.x
                startSize = root.widgetSize
            }
            onMouseXChanged: (mouse) => {
                if (pressed) {
                    var delta = mouse.x - startX
                    root.widgetSize = Math.max(80, startSize + delta)
                }
            }
            onReleased: {
                var arr = Config.options.background.widgets.customImages.slice()
                arr[root.imageIndex] = Object.assign({}, arr[root.imageIndex], { size: root.widgetSize })
                Config.options.background.widgets.customImages = arr
            }
        }
    }
}
