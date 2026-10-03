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

    PanelWindow {
        id: panelWindow

        visible: GlobalStates.clipboardOpen
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:clipboard"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.clipboardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Mask to only modal item - ensures NO black light, NO compositor dimming, NO dark scrim
        mask: Region {
            item: GlobalStates.clipboardOpen ? modal : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        implicitWidth: Screen.width
        implicitHeight: Screen.height

        Connections {
            target: GlobalStates
            function onClipboardOpenChanged() {
                if (!GlobalStates.clipboardOpen) {
                    GlobalFocusGrab.dismiss();
                } else {
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
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
            scale: GlobalStates.clipboardOpen ? 1.0 : 0.98

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            onRequestClose: {
                GlobalStates.clipboardOpen = false;
            }
        }
    }
}
