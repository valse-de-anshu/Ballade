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

    readonly property bool barVertical: Config.options.bar.vertical
    readonly property string barEdge: {
        if (!barVertical) return Config.options.bar.bottom ? "bottom" : "top"
        return Config.options.bar.bottom ? "right" : "left"
    }
    readonly property real barThickness: barVertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight

    component: PanelWindow {
        id: popupWindow

        // Bring contentItem reference into this scope
        property Item innerContent: root.contentItem
        property bool isShown: false
        property real lastValidX: 0
        property real lastValidY: 0

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
                popupWindow.isShown = root.shouldBeOpen;
            }
        }

        color: "transparent"
        anchors.left: root.barEdge !== "right"
        anchors.right: root.barEdge === "right"
        anchors.top: root.barEdge !== "bottom"
        anchors.bottom: root.barEdge === "bottom"

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        readonly property real centerOffsetX: {
            if (!popupWindow.isShown && popupWindow.lastValidX > 0) {
                return popupWindow.lastValidX;
            }
            if (!root.hoverTarget || !root.hoverTarget.visible || root.hoverTarget.width <= 0) {
                return popupWindow.lastValidX > 0 ? popupWindow.lastValidX : Appearance.sizes.elevationMargin;
            }
            const mapped = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
            );
            if (mapped && !isNaN(mapped.x) && mapped.x > 0) {
                const margin = Appearance.sizes.elevationMargin;
                const maxLeft = (popupWindow.screen?.width ?? 1920) - popupBackground.implicitWidth - margin - 10;
                const val = Math.max(margin, Math.min(mapped.x, maxLeft));
                popupWindow.lastValidX = val;
                return val;
            }
            return popupWindow.lastValidX > 0 ? popupWindow.lastValidX : Appearance.sizes.elevationMargin;
        }

        readonly property real centerOffsetY: {
            if (!popupWindow.isShown && popupWindow.lastValidY > 0) {
                return popupWindow.lastValidY;
            }
            if (!root.hoverTarget || !root.hoverTarget.visible || root.hoverTarget.height <= 0) {
                return popupWindow.lastValidY > 0 ? popupWindow.lastValidY : Appearance.sizes.elevationMargin;
            }
            const mapped = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
            );
            if (mapped && !isNaN(mapped.y) && mapped.y > 0) {
                const margin = Appearance.sizes.elevationMargin;
                const maxTop = (popupWindow.screen?.height ?? 1080) - popupBackground.implicitHeight - margin - 15;
                const val = Math.max(margin, Math.min(mapped.y, maxTop));
                popupWindow.lastValidY = val;
                return val;
            }
            return popupWindow.lastValidY > 0 ? popupWindow.lastValidY : Appearance.sizes.elevationMargin;
        }

        mask: Region {
            item: popupBackground
        }
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        margins {
            left: {
                if (root.barEdge === "right") return 0
                if (root.barEdge === "left") return root.barThickness
                return centerOffsetX 
            }
            top: {
                if (root.barEdge === "bottom") return 0
                if (root.barEdge === "top") return root.barThickness
                return centerOffsetY
            }
            right: root.barEdge === "right" ? root.barThickness : 0
            bottom: root.barEdge === "bottom" ? root.barThickness : 0
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
            opacity: popupBackground.opacity
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 8

            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }

            // Use local reference instead of crossing LazyLoader scope boundary
            implicitWidth: (popupWindow.innerContent?.implicitWidth ?? 0) + margin * 2
            implicitHeight: (popupWindow.innerContent?.implicitHeight ?? 0) + margin * 2

            color: Appearance.colors.colLayer1Base
            radius: Appearance.rounding.normal + 4
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            transformOrigin: root.barEdge === "bottom" ? Item.Bottom : Item.Top

            opacity: popupWindow.isShown ? 1 : 0
            scale: popupWindow.isShown ? 1.0 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: popupWindow.isShown ? 140 : 120
                    easing.type: popupWindow.isShown ? Easing.OutCubic : Easing.InCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: popupWindow.isShown ? 150 : 120
                    easing.type: popupWindow.isShown ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.05
                }
            }

            // Reparent content here once the window is ready
            Component.onCompleted: {
                if (popupWindow.innerContent) {
                    popupWindow.innerContent.parent = popupBackground
                    popupWindow.innerContent.anchors.centerIn = popupBackground
                }
            }
        }
    }
}