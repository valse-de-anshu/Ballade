pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root

    property int activeSection: 0 // 0 = List (Left), 1 = Editor (Right)
    property string searchQuery: ""
    property int selectedIndex: 0
    property string toastMessage: ""

    signal requestClose()

    implicitWidth: 890
    implicitHeight: 540

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.windowRounding
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    StyledRectangularShadow {
        target: root
    }

    readonly property var rawFiltered: Cliphist.fuzzyQuery(root.searchQuery)

    readonly property string selectedEntry: {
        if (root.rawFiltered.length === 0 || root.selectedIndex < 0 || root.selectedIndex >= root.rawFiltered.length) {
            return "";
        }
        return root.rawFiltered[root.selectedIndex];
    }

    function showToast(msg) {
        root.toastMessage = msg;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 1800
        onTriggered: root.toastMessage = ""
    }

    // Split Layout
    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 0

        // Left Pane: Material Impulse Clipboard List
        ClipboardListPane {
            id: listPane
            Layout.preferredWidth: 430
            Layout.fillHeight: true
            searchQuery: root.searchQuery
            filteredList: root.rawFiltered
            selectedIndex: root.selectedIndex
            isListFocused: root.activeSection === 0

            onSearchQueryChanged: root.searchQuery = searchQuery
            onSelectedIndexChanged: root.selectedIndex = selectedIndex

            onRequestFocusEditor: {
                root.activeSection = 1;
                editorPane.focusEditor();
            }

            onRequestCopyAndClose: entry => {
                Cliphist.copy(entry);
                root.showToast(Translation.tr("Copied"));
                closeDelayTimer.restart();
            }

            onRequestPasteAndClose: entry => {
                Cliphist.paste(entry);
                root.requestClose();
            }

            onRequestClose: root.requestClose()
            onShowNotification: msg => root.showToast(msg)
        }

        // Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            color: Appearance.colors.colOutlineVariant
        }

        // Right Pane: Preview & Live Editor
        ClipboardEditorPane {
            id: editorPane
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentEntry: root.selectedEntry
            isEditorFocused: root.activeSection === 1

            onRequestFocusList: {
                root.activeSection = 0;
                listPane.focusList();
            }

            onRequestClose: root.requestClose()
            onShowNotification: msg => root.showToast(msg)
        }
    }

    Timer {
        id: closeDelayTimer
        interval: 100
        onTriggered: root.requestClose()
    }

    // Toast Banner
    Rectangle {
        id: toastBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        implicitHeight: 28
        implicitWidth: toastText.implicitWidth + 24
        visible: root.toastMessage.length > 0
        opacity: root.toastMessage.length > 0 ? 1 : 0
        z: 99

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        StyledText {
            id: toastText
            anchors.centerIn: parent
            text: root.toastMessage
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnPrimary
        }
    }

    Component.onCompleted: {
        listPane.focusList();
    }
}
