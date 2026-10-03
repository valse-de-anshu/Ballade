pragma ComponentBehavior: Bound
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
    property bool _settingText: false
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
        if (imageViewer) imageViewer.source = "";
        if (!root.currentEntry) {
            root._settingText = true;
            root.rawDecodedText = "";
            root.editorText = "";
            root._settingText = false;
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
                root._settingText = true;
                root.rawDecodedText = textCollector.text;
                root.editorText = textCollector.text;
                if (textArea.text !== textCollector.text) {
                    textArea.text = textCollector.text;
                }
                root._settingText = false;
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
        anchors.margins: 10
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal
        border.width: root.isEditorFocused ? 1.5 : 1
        border.color: root.isEditorFocused ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

        // Empty state
        Item {
            anchors.fill: parent
            visible: !root.currentEntry

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 36
                    text: "preview"
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Select an item to preview or edit")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Active Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            visible: !!root.currentEntry

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: root.entryId ? `#${root.entryId}` : Translation.tr("Entry")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    visible: !root.isImage
                    text: `•  ${root.charCount} chars  •  ${root.lineCount} lines`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }

                // Edited pill badge
                Rectangle {
                    visible: root.isModified
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: editedText.implicitWidth + 12
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)

                    StyledText {
                        id: editedText
                        anchors.centerIn: parent
                        text: Translation.tr("Edited")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                // Actions for Text
                RowLayout {
                    visible: !root.isImage
                    spacing: 6

                    // Revert (if modified)
                    RippleButton {
                        visible: root.isModified
                        implicitHeight: 30
                        implicitWidth: revertRow.implicitWidth + 16
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: {
                            root._settingText = true;
                            root.editorText = root.rawDecodedText;
                            textArea.text = root.rawDecodedText;
                            root._settingText = false;
                        }

                        contentItem: RowLayout {
                            id: revertRow
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol { font.pixelSize: 15; text: "undo"; color: Appearance.colors.colSubtext }
                            StyledText { text: Translation.tr("Revert"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                        }
                    }

                    // Copy
                    RippleButton {
                        implicitHeight: 30
                        implicitWidth: copyRow.implicitWidth + 18
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: {
                            Cliphist.copyText(root.editorText);
                            root.showNotification(Translation.tr("Copied to clipboard"));
                        }

                        contentItem: RowLayout {
                            id: copyRow
                            anchors.centerIn: parent
                            spacing: 5
                            MaterialSymbol { font.pixelSize: 15; text: "content_copy"; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: Translation.tr("Copy"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                        }
                    }

                    // Paste
                    RippleButton {
                        implicitHeight: 30
                        implicitWidth: pasteRow.implicitWidth + 18
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: {
                            Cliphist.pasteText(root.editorText);
                            root.requestClose();
                        }

                        contentItem: RowLayout {
                            id: pasteRow
                            anchors.centerIn: parent
                            spacing: 5
                            MaterialSymbol { font.pixelSize: 15; text: "output"; color: Appearance.colors.colOnPrimary }
                            StyledText { text: Translation.tr("Paste"); font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                        }
                    }
                }

                // Actions for Image
                RowLayout {
                    visible: root.isImage
                    spacing: 6

                    RippleButton {
                        implicitHeight: 30
                        implicitWidth: copyImgRow.implicitWidth + 18
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: {
                            Cliphist.copy(root.currentEntry);
                            root.showNotification(Translation.tr("Copied image"));
                        }

                        contentItem: RowLayout {
                            id: copyImgRow
                            anchors.centerIn: parent
                            spacing: 5
                            MaterialSymbol { font.pixelSize: 15; text: "content_copy"; color: Appearance.colors.colOnPrimary }
                            StyledText { text: Translation.tr("Copy Image"); font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
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
                        contentWidth: width
                        contentHeight: Math.max(height, textArea.contentHeight + 24)
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {}

                        StyledTextArea {
                            id: textArea
                            width: flickable.width
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: Appearance.font.pixelSize.small
                            selectByMouse: true
                            renderType: Text.NativeRendering
                            color: Appearance.colors.colOnLayer1

                            Connections {
                                target: root
                                function onEditorTextChanged() {
                                    if (!root._settingText && textArea.text !== root.editorText) {
                                        root._settingText = true;
                                        textArea.text = root.editorText;
                                        root._settingText = false;
                                    }
                                }
                            }

                            onTextChanged: {
                                if (!root._settingText && root.editorText !== text) {
                                    root._settingText = true;
                                    root.editorText = text;
                                    root._settingText = false;
                                }
                            }

                            // Keep viewport smoothly scrolled to cursor when moving up and down
                            onCursorPositionChanged: {
                                const cr = textArea.cursorRectangle;
                                if (cr.y < flickable.contentY) {
                                    flickable.contentY = Math.max(0, cr.y - 14);
                                } else if (cr.y + cr.height > flickable.contentY + flickable.height) {
                                    flickable.contentY = Math.min(
                                        Math.max(0, flickable.contentHeight - flickable.height),
                                        cr.y + cr.height - flickable.height + 14
                                    );
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.modifiers === Qt.ControlModifier && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                    Cliphist.copyText(root.editorText);
                                    root.requestClose();
                                    event.accepted = true;
                                } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_S) {
                                    Cliphist.copyText(root.editorText);
                                    root.showNotification(Translation.tr("Saved to clipboard"));
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
                                // Keys.Key_Up and Keys.Key_Down naturally navigate lines and trigger onCursorPositionChanged for scrolling!
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
                        anchors.margins: 10
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        source: ""
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
                        spacing: 14

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 140
                            height: 80
                            radius: Appearance.rounding.normal
                            color: root.hasDetectedColor ? root.detectedColor : "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.detectedColor
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitHeight: 32
                            implicitWidth: 110
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            colRipple: Appearance.colors.colLayer2Active
                            onClicked: {
                                Cliphist.copyText(root.detectedColor);
                                root.showNotification(Translation.tr("Copied color"));
                            }

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol { font.pixelSize: 15; text: "content_copy"; color: Appearance.colors.colOnLayer1 }
                                StyledText {
                                    text: Translation.tr("Copy Color")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1
                                }
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
