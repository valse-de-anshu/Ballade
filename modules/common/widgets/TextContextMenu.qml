pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Popup {
    id: root

    property var target: null

    padding: 6
    implicitWidth: 196
    implicitHeight: menuColumn.implicitHeight + padding * 2
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    focus: true
    dim: false

    function openAt(mouseX, mouseY) {
        if (!target) return

        target.forceActiveFocus()

        let win = target.Window.window
        let winW = win ? win.width : 1920
        let winH = win ? win.height : 1080

        let pt = target.mapToItem(null, mouseX, mouseY)
        let menuW = root.implicitWidth
        let menuH = root.implicitHeight

        let posX = Math.max(8, Math.min(pt.x, winW - menuW - 8))
        let posY = pt.y
        if (posY + menuH > winH - 8) {
            posY = Math.max(8, pt.y - menuH)
        }

        let localPt = target.mapFromItem(null, posX, posY)
        root.x = localPt.x
        root.y = localPt.y
        root.open()
    }

    background: Item {
        StyledRectangularShadow {
            target: menuBg
        }

        Rectangle {
            id: menuBg
            anchors.fill: parent
            radius: Appearance.rounding.normal
            clip: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: ColorUtils.applyAlpha(Appearance.m3colors.m3surfaceContainerHighest, 0.96)
                }
                GradientStop {
                    position: 1.0
                    color: ColorUtils.applyAlpha(Appearance.m3colors.m3surfaceContainerHigh, 0.93)
                }
            }
            border.width: 1
            border.color: ColorUtils.applyAlpha(Appearance.m3colors.m3outlineVariant, 0.35)
        }
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
        NumberAnimation {
            property: "scale"
            from: 0.94
            to: 1.0
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    component ContextMenuItem: Rectangle {
        id: item
        property string icon: ""
        property string text: ""
        property string shortcut: ""
        property bool isDestructive: false
        enabled: true
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 34
        radius: Appearance.rounding.small
        color: (!enabled) ? "transparent" : (mouseArea.containsMouse
            ? (item.isDestructive ? ColorUtils.applyAlpha(Appearance.colors.colError, 0.16)
                                  : ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.09))
            : "transparent")

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 10

            MaterialSymbol {
                text: item.icon
                iconSize: Appearance.font.pixelSize.normal
                color: !item.enabled ? Appearance.colors.colSubtext
                     : (item.isDestructive && mouseArea.containsMouse) ? Appearance.colors.colError
                     : Appearance.colors.colOnSurface
                opacity: item.enabled ? 1.0 : 0.38
            }

            StyledText {
                Layout.fillWidth: true
                text: item.text
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.main
                color: !item.enabled ? Appearance.colors.colSubtext
                     : (item.isDestructive && mouseArea.containsMouse) ? Appearance.colors.colError
                     : Appearance.colors.colOnSurface
                opacity: item.enabled ? 1.0 : 0.38
            }

            StyledText {
                visible: item.shortcut !== ""
                text: item.shortcut
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.main
                color: Appearance.colors.colSubtext
                opacity: item.enabled ? 0.7 : 0.25
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: item.enabled
            cursorShape: item.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: item.enabled
            onClicked: {
                root.close()
                item.triggered()
            }
        }
    }

    component ContextMenuSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        implicitHeight: 1
        color: ColorUtils.applyAlpha(Appearance.m3colors.m3outlineVariant, 0.35)
    }

    contentItem: ColumnLayout {
        id: menuColumn
        spacing: 2

        ContextMenuItem {
            icon: "undo"
            text: Translation.tr("Undo")
            shortcut: "Ctrl+Z"
            enabled: root.target ? (!root.target.readOnly && (root.target.canUndo ?? false)) : false
            onTriggered: root.target?.undo()
        }

        ContextMenuItem {
            icon: "redo"
            text: Translation.tr("Redo")
            shortcut: "Ctrl+Y"
            enabled: root.target ? (!root.target.readOnly && (root.target.canRedo ?? false)) : false
            onTriggered: root.target?.redo()
        }

        ContextMenuSeparator {}

        ContextMenuItem {
            icon: "content_cut"
            text: Translation.tr("Cut")
            shortcut: "Ctrl+X"
            enabled: root.target ? (!root.target.readOnly && root.target.selectedText && root.target.selectedText.length > 0) : false
            onTriggered: root.target?.cut()
        }

        ContextMenuItem {
            icon: "content_copy"
            text: Translation.tr("Copy")
            shortcut: "Ctrl+C"
            enabled: root.target ? (root.target.selectedText && root.target.selectedText.length > 0) : false
            onTriggered: root.target?.copy()
        }

        ContextMenuItem {
            icon: "content_paste"
            text: Translation.tr("Paste")
            shortcut: "Ctrl+V"
            enabled: root.target ? (!root.target.readOnly && (root.target.canPaste ?? (Quickshell.clipboardText && Quickshell.clipboardText.length > 0))) : false
            onTriggered: root.target?.paste()
        }

        ContextMenuItem {
            icon: "delete"
            text: Translation.tr("Delete")
            shortcut: "Del"
            isDestructive: true
            enabled: root.target ? (!root.target.readOnly && root.target.selectedText && root.target.selectedText.length > 0) : false
            onTriggered: {
                if (root.target && root.target.remove && root.target.selectionStart !== undefined && root.target.selectionEnd !== undefined) {
                    root.target.remove(root.target.selectionStart, root.target.selectionEnd)
                }
            }
        }

        ContextMenuSeparator {}

        ContextMenuItem {
            icon: "select_all"
            text: Translation.tr("Select All")
            shortcut: "Ctrl+A"
            enabled: root.target ? (root.target.text && root.target.text.length > 0 && (!root.target.selectedText || root.target.selectedText.length !== root.target.text.length)) : false
            onTriggered: root.target?.selectAll()
        }
    }
}
