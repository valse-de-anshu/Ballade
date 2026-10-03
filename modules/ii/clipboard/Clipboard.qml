import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: root

    property bool reallyOpen: false

    Connections {
        target: GlobalStates
        function onClipboardOpenChanged() {
            if (GlobalStates.clipboardOpen) {
                closeAnimTimer.stop();
                root.reallyOpen = true;
            } else {
                closeAnimTimer.restart();
            }
        }
    }

    Timer {
        id: closeAnimTimer
        interval: 220
        onTriggered: root.reallyOpen = false
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen;
        }

        function open(): void {
            GlobalStates.clipboardOpen = true;
        }

        function close(): void {
            GlobalStates.clipboardOpen = false;
        }
    }

    Loader {
        id: clipboardLoader
        active: root.reallyOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            implicitWidth: Screen.width
            implicitHeight: Screen.height

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }

            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.clipboardOpen = false;
                }
            }

            // Outer wrapper with fade animation
            Item {
                id: fadeWrapper
                anchors.fill: parent
                opacity: GlobalStates.clipboardOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                // Dimmed backdrop
                Rectangle {
                    anchors.fill: parent
                    color: ColorUtils.transparentize("#000000", 0.25)

                    // Click backdrop to dismiss
                    MouseArea {
                        anchors.fill: parent
                        onClicked: GlobalStates.clipboardOpen = false
                    }
                }

                // Split Clipboard Modal positioned right under top bar
                ClipboardModal {
                    id: modal
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 56

                    onRequestClose: {
                        GlobalStates.clipboardOpen = false;
                    }
                }
            }
        }
    }
}
