import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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

    function openCentered(shouldOpen) {
        if (!shouldOpen) {
            GlobalStates.desktopMenuOpen = false
            return
        }
        const focusedName = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""
        const foundScreen = Quickshell.screens.find(s => s.name === focusedName)
        const screen = foundScreen ? foundScreen : Quickshell.screens[0]
        GlobalStates.desktopMenuScreen = screen
        GlobalStates.desktopMenuX = screen.width / 2
        GlobalStates.desktopMenuY = screen.height / 2
        GlobalStates.desktopMenuOpen = true
    }

    IpcHandler {
        target: "desktopMenu"
        function toggle() {
            root.openCentered(!GlobalStates.desktopMenuOpen)
        }
        function open() {
            root.openCentered(true)
        }
        function close() {
            GlobalStates.desktopMenuOpen = false
        }
    }

    // Auto dismiss immediately when moving to a window or switching monitor/workspace
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (GlobalStates.desktopMenuOpen) {
                GlobalStates.desktopMenuOpen = false
            }
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (GlobalStates.desktopMenuOpen) {
                GlobalStates.desktopMenuOpen = false
            }
        }
        function onFocusedMonitorChanged() {
            if (GlobalStates.desktopMenuOpen) {
                GlobalStates.desktopMenuOpen = false
            }
        }
    }

    Loader {
        active: GlobalStates.desktopMenuOpen
        sourceComponent: PanelWindow {
            id: menuWindow

            screen: GlobalStates.desktopMenuScreen ? GlobalStates.desktopMenuScreen : Quickshell.screens[0]

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:desktopMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.desktopMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            property Component openSubmenuComponent: null
            property real submenuAnchorY: 0
            property real submenuWidth: 260

            Timer {
                id: submenuCloseTimer
                interval: 220
                onTriggered: menuWindow.openSubmenuComponent = null
            }

            // Click outside to dismiss immediately
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onClicked: GlobalStates.desktopMenuOpen = false
                onWheel: GlobalStates.desktopMenuOpen = false
            }

            readonly property color colLayer0Base: (Appearance.colors && Appearance.colors.colLayer0Base) ? Appearance.colors.colLayer0Base : Appearance.colors.colLayer0

            // Context Menu card
            Rectangle {
                id: menuCard
                width: 264
                implicitHeight: menuCol.implicitHeight + 16
                x: Math.min(Math.max(GlobalStates.desktopMenuX, 12), menuWindow.width - width - 12)
                y: Math.min(Math.max(GlobalStates.desktopMenuY, 12), menuWindow.height - implicitHeight - 12)
                radius: 20
                color: Qt.rgba(menuWindow.colLayer0Base.r, menuWindow.colLayer0Base.g, menuWindow.colLayer0Base.b, 0.22)
                border.width: 0
                border.color: "transparent"
                focus: true
                Keys.onEscapePressed: GlobalStates.desktopMenuOpen = false

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.6
                    shadowVerticalOffset: 4
                }

                scale: 0.92
                opacity: 0
                transformOrigin: Item.TopLeft

                Component.onCompleted: {
                    scale = 1.0
                    opacity = 1.0
                }

                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                // Prevent click inside menu card from closing the menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                ColumnLayout {
                    id: menuCol
                    anchors { fill: parent; margins: 8 }
                    spacing: 3

                    // Open Terminal
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "terminal"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("Terminal"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            Quickshell.execDetached(["bash", "-c", Config.options.apps.terminal || "kitty"])
                        }
                    }

                    // Open File Manager
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "folder"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("File Manager"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            Quickshell.execDetached(["bash", "-c", "dolphin ~ || xdg-open ~"])
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 3
                        Layout.bottomMargin: 3
                        implicitHeight: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    // Next Wallpaper
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "shuffle"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("Next Wallpaper"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            Wallpapers.randomFromCurrentFolder(Appearance.m3colors.darkmode)
                        }
                    }

                    // Wallpaper Gallery
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "wallpaper"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("Wallpaper Gallery"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            GlobalStates.wallpaperSelectorTarget = "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    // Centered Wallpaper Submenu
                    RippleButton {
                        id: centeredWallpaperBtn
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "crop_square"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Centered Wallpaper")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                            }
                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.5
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            }
                        }

                        Component {
                            id: centeredWallpaperSubmenuComp
                            CenteredWallpaperSubmenu {}
                        }

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) {
                                    submenuCloseTimer.stop()
                                    menuWindow.submenuWidth = 330
                                    menuWindow.submenuAnchorY = menuCard.y + centeredWallpaperBtn.y
                                    menuWindow.openSubmenuComponent = centeredWallpaperSubmenuComp
                                } else {
                                    submenuCloseTimer.restart()
                                }
                            }
                        }
                        onClicked: {
                            if (menuWindow.openSubmenuComponent === centeredWallpaperSubmenuComp) {
                                menuWindow.openSubmenuComponent = null
                            } else {
                                submenuCloseTimer.stop()
                                menuWindow.submenuWidth = 330
                                menuWindow.submenuAnchorY = menuCard.y + centeredWallpaperBtn.y
                                menuWindow.openSubmenuComponent = centeredWallpaperSubmenuComp
                            }
                        }
                    }

                    // Desktop Widgets Submenu
                    RippleButton {
                        id: widgetsBtn
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "widgets"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Desktop Widgets")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                            }
                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: 18
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.5
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            }
                        }

                        Component {
                            id: widgetsSubmenuComp
                            WidgetsSubmenu {}
                        }

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) {
                                    submenuCloseTimer.stop()
                                    menuWindow.submenuWidth = 260
                                    menuWindow.submenuAnchorY = menuCard.y + widgetsBtn.y
                                    menuWindow.openSubmenuComponent = widgetsSubmenuComp
                                } else {
                                    submenuCloseTimer.restart()
                                }
                            }
                        }
                        onClicked: {
                            if (menuWindow.openSubmenuComponent === widgetsSubmenuComp) {
                                menuWindow.openSubmenuComponent = null
                            } else {
                                submenuCloseTimer.stop()
                                menuWindow.submenuWidth = 260
                                menuWindow.submenuAnchorY = menuCard.y + widgetsBtn.y
                                menuWindow.openSubmenuComponent = widgetsSubmenuComp
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 3
                        Layout.bottomMargin: 3
                        implicitHeight: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    // Ballade Settings
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "settings"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("Settings"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            GlobalStates.settingsOpen = true
                        }
                    }

                    // Restart Shell
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.09)
                        contentItem: RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            MaterialSymbol { text: "refresh"; iconSize: 20; color: Appearance.colors.colOnLayer0 }
                            StyledText { Layout.fillWidth: true; text: Translation.tr("Restart Shell"); font.pixelSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnLayer0 }
                        }
                        onClicked: {
                            GlobalStates.desktopMenuOpen = false
                            Quickshell.reload(true)
                        }
                    }
                }
            }

            // SubMenu (Widgets toggle)
            Loader {
                id: submenuLoader
                active: menuWindow.openSubmenuComponent !== null
                width: menuWindow.submenuWidth
                sourceComponent: menuWindow.openSubmenuComponent

                x: (menuCard.x + menuCard.width + 8 + menuWindow.submenuWidth > menuWindow.width)
                    ? menuCard.x - menuWindow.submenuWidth - 8
                    : menuCard.x + menuCard.width + 8

                y: Math.min(
                    Math.max(menuWindow.submenuAnchorY, 12),
                    menuWindow.height - (item && item.implicitHeight !== undefined ? item.implicitHeight : 0) - 12
                )

                scale: active ? 1.0 : 0.92
                opacity: active ? 1.0 : 0.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) submenuCloseTimer.stop()
                        else submenuCloseTimer.restart()
                    }
                }
            }
        }
    }
}