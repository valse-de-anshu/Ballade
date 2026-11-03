pragma ComponentBehavior: Bound
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
        active: GlobalStates.clipboardOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            visible: true
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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

            // Transparent full-screen click-to-dismiss backdrop
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GlobalStates.clipboardOpen = false;
                }
            }

            // Split Clipboard Modal (Positioned below top bar)
            ClipboardModal {
                id: modal
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Appearance.sizes.barHeight + 14

                opacity: GlobalStates.clipboardOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                }

                onRequestClose: {
                    GlobalStates.clipboardOpen = false;
                }
            }
        }
    }
}
