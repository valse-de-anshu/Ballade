import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property bool isInput: true // true for input, false for output
    property string placeholderText
    property string text: ""
    property color containerColor: Appearance.colors.colPrimaryContainer
    property var inputTextArea: isInput ? inputLoader.item : undefined
    readonly property string displayedText: isInput ? (inputLoader.item?.text ?? "") : root.text
    default property alias actionButtons: actions.data
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: containerColor
    radius: Appearance.rounding.normal

    signal inputTextChanged(); // Signal emitted when text changes

    // Input text area
    Loader {
        id: inputLoader
        active: root.isInput
        visible: root.isInput
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusRow.top
        anchors.margins: 4
        sourceComponent: StyledTextArea {
            id: inputTextArea
            anchors.fill: parent
            placeholderText: root.placeholderText
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            padding: 12
            background: null
            onTextChanged: root.inputTextChanged()
        }
    }

    // Output text area
    Loader {
        id: outputLoader
        active: !root.isInput
        visible: !root.isInput
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusRow.top
        anchors.margins: 4
        sourceComponent: Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: outputTextArea.implicitHeight + 24
            clip: true

            StyledText {
                id: outputTextArea
                width: parent.width - 24
                x: 12
                y: 12
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.text.length > 0 ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                text: root.text.length > 0 ? root.text : root.placeholderText
            }
        }
    }

    // Status bar pinned directly at the bottom of the card
    RowLayout {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 10
        spacing: 8

        StyledText {
            visible: root.isInput
            text: Translation.tr("%1 characters").arg(inputLoader.item?.text?.length ?? 0)
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: actions
            spacing: 6
        }
    }
}