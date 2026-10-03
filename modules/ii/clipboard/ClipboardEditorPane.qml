import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string currentEntry: ""
    property bool isEditorFocused: false
    property string rawDecodedText: ""
    property string editorText: ""
    property bool isModified: (editorText !== rawDecodedText && !isImage)
    property bool isLoading: false

    signal requestFocusList()
    signal requestClose()
    signal showNotification(string text)

    readonly property string entryId: Cliphist.getEntryId(currentEntry)
    readonly property bool isImage: Cliphist.entryIsImage(currentEntry)
    readonly property string detectedColor: !isImage ? ColorUtils.detectColor(editorText || StringUtils.cleanCliphistEntry(currentEntry)) : ""
    readonly property bool hasDetectedColor: detectedColor !== ""
    readonly property string imageFilePath: `${Directories.cliphistDecode}/${entryId}.png`

    readonly property int charCount: editorText.length
    readonly property int lineCount: editorText === "" ? 0 : editorText.split(/\r\n|\r|\n/).length

    function focusEditor() {
        if (!isImage && !hasDetectedColor) {
            textArea.forceActiveFocus();
        } else {
            editorBox.forceActiveFocus();
        }
    }

    function decodeCurrentEntry() {
        if (!root.currentEntry) {
            root.rawDecodedText = "";
            root.editorText = "";
            root.isLoading = false;
            return;
        }

        if (root.isImage) {
            root.isLoading = true;
            imageDecodeProc.running = true;
            return;
        }

        root.isLoading = true;
        textDecodeProc.running = true;
    }

    onCurrentEntryChanged: {
        decodeCurrentEntry();
    }

    // Process for text decoding
    Process {
        id: textDecodeProc
        command: [
            "bash", "-c",
            `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode`
        ]
        stdout: StdioCollector {
            id: textCollector
            onStreamFinished: {
                root.rawDecodedText = textCollector.text;
                root.editorText = textCollector.text;
                root.isLoading = false;
            }
        }
    }

    // Process for image decoding
    Process {
        id: imageDecodeProc
        command: [
            "bash", "-c",
            `mkdir -p '${Directories.cliphistDecode}' && [ -f '${root.imageFilePath}' ] || printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode > '${root.imageFilePath}'`
        ]
        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;
            if (exitCode === 0) {
                imageViewer.source = "";
                imageViewer.source = "file://" + root.imageFilePath;
            }
        }
    }

    Rectangle {
        id: editorBox
        anchors.fill: parent
        anchors.margins: 8
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal
        border.width: root.isEditorFocused ? 1.5 : 0
        border.color: Appearance.colors.colPrimary

        // Empty state
        Item {
            anchors.fill: parent
            visible: !root.currentEntry

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 28
                    text: "preview"
                    color: Appearance.colors.colSubtext
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Select an item to view or edit"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 12
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Active Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            visible: !!root.currentEntry

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.entryId ? `#${root.entryId}` : "Item"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                Text {
                    visible: !root.isImage
                    text: `•  ${root.charCount} chars`
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    color: Appearance.colors.colSubtext
                }

                Text {
                    visible: root.isModified
                    text: "•  Edited"
                    font.family: Appearance.font.family.main
                    font.pixelSize: 11
                    color: Appearance.colors.colPrimary
                }

                Item { Layout.fillWidth: true }

                // Actions for Text
                RowLayout {
                    visible: !root.isImage
                    spacing: 4

                    // Revert (if modified)
                    RippleButton {
                        visible: root.isModified
                        implicitHeight: 26
                        implicitWidth: revertRow.implicitWidth + 12
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2
                        onClicked: {
                            root.editorText = root.rawDecodedText;
                            textArea.text = root.rawDecodedText;
                        }

                        contentItem: RowLayout {
                            id: revertRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { font.pixelSize: 13; text: "undo"; color: Appearance.colors.colSubtext }
                            Text { text: "Revert"; font.family: Appearance.font.family.main; font.pixelSize: 11; color: Appearance.colors.colSubtext }
                        }
                    }

                    // Copy
                    RippleButton {
                        implicitHeight: 26
                        implicitWidth: copyRow.implicitWidth + 14
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: {
                            Cliphist.copyText(root.editorText);
                            root.showNotification("Copied to clipboard");
                        }

                        contentItem: RowLayout {
                            id: copyRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { font.pixelSize: 13; text: "content_copy"; color: Appearance.colors.colOnLayer1 }
                            Text { text: "Copy"; font.family: Appearance.font.family.main; font.pixelSize: 11; color: Appearance.colors.colOnLayer1 }
                        }
                    }

                    // Paste
                    RippleButton {
                        implicitHeight: 26
                        implicitWidth: pasteRow.implicitWidth + 14
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimary
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: {
                            Cliphist.pasteText(root.editorText);
                            root.requestClose();
                        }

                        contentItem: RowLayout {
                            id: pasteRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { font.pixelSize: 13; text: "output"; color: Appearance.colors.colOnPrimary }
                            Text { text: "Paste"; font.family: Appearance.font.family.main; font.pixelSize: 11; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                        }
                    }
                }

                // Actions for Image
                RowLayout {
                    visible: root.isImage
                    spacing: 4

                    RippleButton {
                        implicitHeight: 26
                        implicitWidth: copyImgRow.implicitWidth + 14
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimary
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: {
                            Cliphist.copy(root.currentEntry);
                            root.showNotification("Copied image");
                        }

                        contentItem: RowLayout {
                            id: copyImgRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { font.pixelSize: 13; text: "content_copy"; color: Appearance.colors.colOnPrimary }
                            Text { text: "Copy Image"; font.family: Appearance.font.family.main; font.pixelSize: 11; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                        }
                    }
                }
            }

            // Body Area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // VIEW 1: TEXT EDITING
                Item {
                    anchors.fill: parent
                    visible: !root.isImage && !root.hasDetectedColor

                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        clip: true
                        contentWidth: textArea.width
                        contentHeight: textArea.height
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {}

                        StyledTextArea {
                            id: textArea
                            width: flickable.width
                            text: root.editorText
                            wrapMode: TextEdit.Wrap
                            font.family: Appearance.font.family.main
                            font.pixelSize: 13
                            selectByMouse: true
                            renderType: Text.NativeRendering
                            color: Appearance.colors.colOnLayer1

                            onTextChanged: {
                                if (root.editorText !== text) {
                                    root.editorText = text;
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.modifiers === Qt.ControlModifier && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                    Cliphist.copyText(root.editorText);
                                    root.requestClose();
                                    event.accepted = true;
                                } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_S) {
                                    Cliphist.copyText(root.editorText);
                                    root.showNotification("Saved to clipboard");
                                    event.accepted = true;
                                } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_Left) {
                                    root.requestFocusList();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Left && textArea.cursorPosition === 0) {
                                    root.requestFocusList();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    root.requestFocusList();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                // VIEW 2: IMAGE PREVIEW
                Item {
                    anchors.fill: parent
                    visible: root.isImage

                    Image {
                        id: imageViewer
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        source: (root.isImage && root.imageFilePath) ? ("file://" + root.imageFilePath) : ""
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                            root.requestFocusList();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Cliphist.copy(root.currentEntry);
                            root.requestClose();
                            event.accepted = true;
                        }
                    }
                }

                // VIEW 3: COLOR PREVIEW
                Item {
                    anchors.fill: parent
                    visible: !root.isImage && root.hasDetectedColor

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 140
                            height: 80
                            radius: Appearance.rounding.normal
                            color: root.hasDetectedColor ? root.detectedColor : "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.detectedColor
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitHeight: 28
                            implicitWidth: 90
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: {
                                Cliphist.copyText(root.detectedColor);
                                root.showNotification("Copied color");
                            }

                            contentItem: Text {
                                anchors.centerIn: parent
                                text: "Copy Color"
                                font.family: Appearance.font.family.main
                                font.pixelSize: 11
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                            root.requestFocusList();
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }
}
