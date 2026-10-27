import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0

    property bool shouldBeOpen: hoverTarget && hoverTarget.containsMouse

    Timer {
        id: exitTimer
        interval: 160
        repeat: false
    }

    onShouldBeOpenChanged: {
        if (!shouldBeOpen && active) {
            exitTimer.restart();
        } else if (shouldBeOpen) {
            exitTimer.stop();
        }
    }

    active: shouldBeOpen || exitTimer.running

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        property bool isShown: false
        property real lastValidX: 0
        property real lastValidY: 0

        visible: root.shouldBeOpen || exitTimer.running

        Component.onCompleted: {
            enterTimer.restart();
        }

        Timer {
            id: enterTimer
            interval: 10
            repeat: false
            onTriggered: {
                popupWindow.isShown = root.shouldBeOpen;
            }
        }

        Connections {
            target: root
            function onShouldBeOpenChanged() {
                if (root.shouldBeOpen) {
                    enterTimer.restart();
                } else {
                    popupWindow.isShown = false;
                }
            }
        }

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin



        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (Config.options.bar.vertical) return Appearance.sizes.verticalBarWidth;
                if (!popupWindow.isShown && popupWindow.lastValidX !== 0) {
                    return popupWindow.lastValidX;
                }
                if (!root.hoverTarget || !root.hoverTarget.visible || root.hoverTarget.width <= 0) {
                    return popupWindow.lastValidX;
                }
                const mapped = root.QsWindow?.mapFromItem(
                    root.hoverTarget, 
                    (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                );
                if (mapped && !isNaN(mapped.x)) {
                    popupWindow.lastValidX = mapped.x;
                    return mapped.x;
                }
                return popupWindow.lastValidX;
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                if (!popupWindow.isShown && popupWindow.lastValidY !== 0) {
                    return popupWindow.lastValidY;
                }
                if (!root.hoverTarget || !root.hoverTarget.visible || root.hoverTarget.height <= 0) {
                    return popupWindow.lastValidY;
                }
                const mapped = root.QsWindow?.mapFromItem(
                    root.hoverTarget, 
                    (root.hoverTarget.height - popupBackground.implicitHeight) / 2, 0
                );
                if (mapped && !isNaN(mapped.y)) {
                    popupWindow.lastValidY = mapped.y;
                    return mapped.y;
                }
                return popupWindow.lastValidY;
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Top

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Qt.rgba(
                Appearance.colors.colLayer0Base.r,
                Appearance.colors.colLayer0Base.g,
                Appearance.colors.colLayer0Base.b,
                0.18
            )
            radius: Appearance.rounding.windowRounding
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            transformOrigin: popupWindow.anchors.bottom ? Item.Bottom : Item.Top

            opacity: popupWindow.isShown ? 1.0 : 0.0
            scale: popupWindow.isShown ? 1.0 : 0.85
            y: popupWindow.isShown ? 0 : (popupWindow.anchors.bottom ? 16 : -16)

            Behavior on opacity {
                NumberAnimation {
                    duration: popupWindow.isShown ? 180 : 130
                    easing.type: popupWindow.isShown ? Easing.OutQuad : Easing.InQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: popupWindow.isShown ? 220 : 140
                    easing.type: popupWindow.isShown ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.18
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: popupWindow.isShown ? 220 : 140
                    easing.type: popupWindow.isShown ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.15
                }
            }
        }
    }
}
