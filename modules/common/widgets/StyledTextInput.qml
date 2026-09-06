import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    id: rootInput
    color: Appearance.colors.colOnLayer1
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }

    MouseArea {
        id: rightClickArea
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            mouse.accepted = true
            if (rootInput.selectedText.length === 0) {
                rootInput.cursorPosition = rootInput.positionAt(mouse.x, mouse.y)
            }
            rootInput.forceActiveFocus()
            contextMenu.openAt(mouse.x, mouse.y)
        }
    }

    TextContextMenu {
        id: contextMenu
        target: rootInput
    }
}
