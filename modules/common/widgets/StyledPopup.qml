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

    property Timer exitTimer: Timer {
        interval: 160
        repeat: false
    }

    onShouldBeOpenChanged: {
        if (!shouldBeOpen && active) {
            root.exitTimer.restart();
        } else if (shouldBeOpen) {
            root.exitTimer.stop();
        }
    }

    active: shouldBeOpen || root.exitTimer.running

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
        property real lastValidX: Appearance.sizes.elevationMargin
        property real lastValidY: Appearance.sizes.elevationMargin

        visible: root.shouldBeOpen || root.exitTimer.running

        Component.onCompleted: {
            updateOffsets();
            enterTimer.restart();
        }

        Timer {
            id: enterTimer
            interval: 10
            repeat: false
            onTriggered: {
                popupWindow.updateOffsets();
                popupWindow.isShown = root.shouldBeOpen;
            }
        }

        Connections {
            target: root
            function onShouldBeOpenChanged() {
                if (root.shouldBeOpen) {
                    popupWindow.updateOffsets();
                    enterTimer.restart();
                } else {
                    popupWindow.isShown = false;
                }
            }
        }

        function updateOffsets() {
            if (!root.hoverTarget || !root.hoverTarget.visible || root.hoverTarget.width <= 0) return;
            const mappedX = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
            );
            if (mappedX && !isNaN(mappedX.x) && mappedX.x > 0) {
                const margin = Appearance.sizes.elevationMargin;
                const maxLeft = (popupWindow.screen?.width ?? 1920) - popupBackground.implicitWidth - margin - 10;
                popupWindow.lastValidX = Math.max(margin, Math.min(mappedX.x, maxLeft));
            }
            const mappedY = root.QsWindow?.mapFromItem(
                root.hoverTarget,
                0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
            );
            if (mappedY && !isNaN(mappedY.y) && mappedY.y > 0) {
                const margin = Appearance.sizes.elevationMargin;
                const maxTop = (popupWindow.screen?.height ?? 1080) - popupBackground.implicitHeight - margin - 15;
                popupWindow.lastValidY = Math.max(margin, Math.min(mappedY.y, maxTop));
            }
        }

        color: "transparent"
        anchors.left: root.barEdge !== "right"
        anchors.right: root.barEdge === "right"
        anchors.top: root.barEdge !== "bottom"
        anchors.bottom: root.barEdge === "bottom"

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        readonly property real centerOffsetX: popupWindow.lastValidX
        readonly property real centerOffsetY: popupWindow.lastValidY

        mask: Region {
            item: (popupWindow.isShown && popupBackground.opacity > 0) ? popupBackground : null
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