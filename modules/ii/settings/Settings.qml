//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Scope {
    id: root

    Component.onCompleted: {
        GlobalStates.settingsOpen = false;
    }

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen

        function hide() {
            GlobalStates.settingsOpen = false;
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                settingsWindow.userMoved = false;
                settingsWindow.forceActiveFocus();
            }
        }

        Rectangle {
            id: settingsWindow
            width: Math.min(parent.width - 80, 1080)
            height: Math.min(parent.height - 80, 780)
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5
            z: 1
            focus: true

            property bool userMoved: false
            anchors.centerIn: userMoved ? undefined : parent

            opacity: GlobalStates.settingsOpen ? 1 : 0
            scale: GlobalStates.settingsOpen ? 1 : 0.95

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.scrollUp === "function") {
                        GlobalStates.currentPageInstance.scrollUp();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Down) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.scrollDown === "function") {
                        GlobalStates.currentPageInstance.scrollDown();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_PageUp) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.pageUp === "function") {
                        GlobalStates.currentPageInstance.pageUp();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_PageDown) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.pageDown === "function") {
                        GlobalStates.currentPageInstance.pageDown();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Home) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.scrollToTop === "function") {
                        GlobalStates.currentPageInstance.scrollToTop();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_End) {
                    if (GlobalStates.currentPageInstance && typeof GlobalStates.currentPageInstance.scrollToBottom === "function") {
                        GlobalStates.currentPageInstance.scrollToBottom();
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                id: dragHandle
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: closeBtn.left
                height: 36
                color: "transparent"
                z: 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    drag.target: settingsWindow
                    drag.axis: Drag.XAndYAxis
                    onPressed: settingsWindow.userMoved = true
                    onDoubleClicked: settingsWindow.userMoved = false
                }
            }

            // Top-right Close Button
            Rectangle {
                id: closeBtn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                width: 28
                height: 28
                radius: Appearance.rounding.full
                color: closeMouseArea.containsMouse ? CF.ColorUtils.transparentize(Appearance.colors.colError, 0.8) : "transparent"
                z: 10

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 18
                    color: closeMouseArea.containsMouse ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panelWindow.hide()
                }
            }

            SettingsContent {
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open(): void   { GlobalStates.settingsOpen = true; }
        function close(): void  { GlobalStates.settingsOpen = false; }
    }

    CompositorGlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
    }
}