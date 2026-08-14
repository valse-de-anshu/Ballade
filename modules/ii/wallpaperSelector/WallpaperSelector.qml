import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool reallyOpen: false

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                closeAnimTimer.stop()
                root.reallyOpen = true
            } else {
                closeAnimTimer.restart()
            }
        }
    }

    Timer {
        id: closeAnimTimer
        interval: 300
        onTriggered: root.reallyOpen = false
    }

    Loader {
        id: wallpaperSelectorLoader
        active: root.reallyOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            // Full-screen transparent overlay — same approach as hyprquickpaper
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            implicitWidth: Screen.width
            implicitHeight: Screen.height

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow)
                picker.forceActiveFocus()
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow)
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false
                }
            }

            Item {
                id: fadeItem
                anchors.fill: parent
                opacity: GlobalStates.wallpaperSelectorOpen ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                HyprPickerContent {
                    id: picker
                    anchors.fill: parent
                    focus: true
                    onDismissed: GlobalStates.wallpaperSelectorOpen = false
                }
            }
        }
    }

    function toggleWallpaperSelector() {
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode)
            return
        }
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { root.toggleWallpaperSelector() }
        function random(): void { Wallpapers.randomFromCurrentFolder() }
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: root.toggleWallpaperSelector()
    }

    CompositorGlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: Wallpapers.randomFromCurrentFolder()
    }
}
