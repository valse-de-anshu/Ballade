import QtQuick
import qs.modules.common

MouseArea {
    id: root
    property int gridSize: 24
    property bool showGrid: false
    readonly property bool isWidgetCanvas: true
    readonly property bool gridVisible: showGrid && Config.options.background.showGrid

    property bool centerXActive: false
    property bool centerYActive: false

    function setDragging(active) {
        console.log("[WidgetCanvas] setDragging:", active)
        root.showGrid = active
        if (!active) {
            root.centerXActive = false
            root.centerYActive = false
        }
    }

    function setCenterActive(xActive, yActive) {
        // console.log("[WidgetCanvas] setCenterActive:", xActive, yActive)
        root.centerXActive = xActive
        root.centerYActive = yActive
    }

    Item {
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.gridVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Repeater {
            model: Math.ceil(root.width / root.gridSize)
            delegate: Rectangle {
                required property int index
                z: 997
                x: index * root.gridSize
                width: 1
                height: root.height
                color: Appearance.colors.colLayer0Border
            }
        }

        Repeater {
            model: Math.ceil(root.height / root.gridSize)
            delegate: Rectangle {
                required property int index
                z: 997
                y: index * root.gridSize
                width: root.width
                height: 1
                color: Appearance.colors.colLayer0Border
            }
        }
    }

    Rectangle {
        id: centerLineV
        z: 998
        visible: root.gridVisible
        x: root.width / 2 - width / 2
        width: root.centerXActive ? 3 : 1
        height: root.height
        color: root.centerXActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
        opacity: root.centerXActive ? 1 : 0.6

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Rectangle {
        id: centerLineH
        z: 998
        visible: root.gridVisible
        y: root.height / 2 - height / 2
        width: root.width
        height: root.centerYActive ? 3 : 1
        color: root.centerYActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
        opacity: root.centerYActive ? 1 : 0.6

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Component {
        id: flashLineComponent
        Rectangle {
            id: flashLine
            z: 999
            property bool vertical: true
            property real linePos: 0
            color: Appearance.colors.colPrimary
            x: vertical ? linePos : 0
            y: vertical ? 0 : linePos
            width: vertical ? 2 : root.width
            height: vertical ? root.height : 2

            NumberAnimation on opacity {
                from: 1.0
                to: 0
                duration: 2000
                easing.type: Easing.OutCubic
                running: true
                onFinished: flashLine.destroy()
            }
        }
    }

    function flashLines(verticalPositions, horizontalPositions) {
        console.log("[WidgetCanvas] flashLines:", verticalPositions, horizontalPositions)
        for (let i = 0; i < verticalPositions.length; i++)
            flashLineComponent.createObject(root, { vertical: true, linePos: verticalPositions[i] })
        for (let i = 0; i < horizontalPositions.length; i++)
            flashLineComponent.createObject(root, { vertical: false, linePos: horizontalPositions[i] })
    }
}