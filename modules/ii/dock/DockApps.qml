pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool contextMenuMode: false
    property var contextMenuApp: null
    property bool requestDockShow: previewPopup.show

    function openContextMenu(appEntry, button) {
        if (!appEntry || !button) return;
        contextMenuApp = appEntry;
        contextMenuMode = true;
        if (root.QsWindow) {
            previewPopup.cachedCenterX = root.popupCenterXForButton(button);
        }
        previewPopup.show = true;
    }

    function closeContextMenu() {
        contextMenuMode = false;
        contextMenuApp = null;
        if (!root.buttonHovered) {
            previewPopup.show = false;
        }
    }

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow)
            return 0;
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x;
    }

    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup
        property var activeAppTopLevel: (root.contextMenuMode && root.contextMenuApp) ? root.contextMenuApp : root.lastHoveredButton?.appToplevel

        property bool shouldShow: root.contextMenuMode ? true : ((popupMouseArea.containsMouse || root.buttonHovered) && activeAppTopLevel && activeAppTopLevel.toplevels && activeAppTopLevel.toplevels.length > 0)

        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (!root.contextMenuMode && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (!root.buttonHovered && !popupMouseArea.containsMouse && !root.contextMenuMode) {
                    previewPopup.show = false;
                } else if (root.buttonHovered && !root.contextMenuMode && root.lastHoveredButton && root.QsWindow) {
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                }
                updateTimer.restart();
            }
        }

        onShouldShowChanged: {
            updateTimer.restart();
        }

        Timer {
            id: updateTimer
            interval: 80
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: popupBackground.opacity > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: Math.max(0, Math.min(previewPopup.implicitWidth - width, previewPopup.cachedCenterX - width / 2))

            onExited: {
                if (root.contextMenuMode && !root.buttonHovered) {
                    root.closeContextMenu();
                }
            }

            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                id: popupBackground
                property real padding: 6
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: (root.contextMenuMode ? contextMenuColumn.implicitHeight : previewRowLayout.implicitHeight) + padding * 2
                implicitWidth: (root.contextMenuMode ? Math.max(160, contextMenuColumn.implicitWidth) : previewRowLayout.implicitWidth) + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                // 1. Context Menu Layout (Pin / Unpin and Close)
                ColumnLayout {
                    id: contextMenuColumn
                    visible: root.contextMenuMode
                    anchors.centerIn: parent
                    spacing: 3

                    // Header: App Title
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 4
                        spacing: 8

                        IconImage {
                            source: Quickshell.iconPath(AppSearch.guessIcon(previewPopup.activeAppTopLevel?.appId ?? ""), "image-missing")
                            implicitSize: 20
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const entry = DesktopEntries.heuristicLookup(previewPopup.activeAppTopLevel?.appId ?? "");
                                return entry?.name || previewPopup.activeAppTopLevel?.appId || Translation.tr("Application");
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.colors.colOutlineVariant
                        opacity: 0.25
                    }

                    // Pin / Unpin Button
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        onClicked: {
                            if (previewPopup.activeAppTopLevel?.appId) {
                                TaskbarApps.togglePin(previewPopup.activeAppTopLevel.appId);
                            }
                            root.closeContextMenu();
                        }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            MaterialSymbol {
                                iconSize: 16
                                text: TaskbarApps.isPinned(previewPopup.activeAppTopLevel?.appId ?? "") ? "bookmark_remove" : "keep"
                                color: TaskbarApps.isPinned(previewPopup.activeAppTopLevel?.appId ?? "") ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: TaskbarApps.isPinned(previewPopup.activeAppTopLevel?.appId ?? "") ? Translation.tr("Unpin from Dock") : Translation.tr("Pin to Dock")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                    }

                    // Close Window Button (if active)
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        visible: (previewPopup.activeAppTopLevel?.toplevels?.length ?? 0) > 0
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.8)
                        onClicked: {
                            if (previewPopup.activeAppTopLevel?.toplevels) {
                                for (const toplevel of previewPopup.activeAppTopLevel.toplevels) {
                                    toplevel?.close();
                                }
                            }
                            root.closeContextMenu();
                        }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            MaterialSymbol {
                                iconSize: 16
                                text: "close"
                                color: Appearance.colors.colError
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Close")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                            }
                        }
                    }
                }

                // 2. Window Previews Layout (When hovering)
                RowLayout {
                    id: previewRowLayout
                    visible: !root.contextMenuMode
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.activeAppTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            Layout.fillHeight: true
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                windowButton.modelData?.activate();
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    StyledText {
                                        Layout.margins: 5
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: windowButton.modelData?.title
                                        elide: Text.ElideRight
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                    GroupButton {
                                        id: pinButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: root.windowControlsHeight
                                        baseHeight: root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: TaskbarApps.isPinned(previewPopup.activeAppTopLevel?.appId ?? "") ? "bookmark_remove" : "keep"
                                            iconSize: Appearance.font.pixelSize.small
                                            color: TaskbarApps.isPinned(previewPopup.activeAppTopLevel?.appId ?? "") ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            if (previewPopup.activeAppTopLevel?.appId) {
                                                TaskbarApps.togglePin(previewPopup.activeAppTopLevel.appId);
                                            }
                                        }
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: root.windowControlsHeight
                                        baseHeight: root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            windowButton.modelData?.close();
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: screencopyView.height
                                    implicitWidth: screencopyView.width
                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowButton.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: screencopyView.width
                                                height: screencopyView.height
                                                radius: Appearance.rounding.small
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
