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
    readonly property bool isCliphistImage: Cliphist.entryIsImage(currentEntry)
    readonly property string localImagePath: {
        if (!currentEntry) return "";
        let clean = StringUtils.cleanCliphistEntry(currentEntry).trim();
        if (clean.startsWith("file://")) clean = clean.substring(7);
        if (/^\/.*\.(png|jpe?g|webp|gif|svg|bmp|ico|avif)$/i.test(clean)) {
            return clean;
        }
        return "";
    }
    readonly property bool isImage: isCliphistImage || localImagePath !== ""
    readonly property string detectedColor: !isImage ? ColorUtils.detectColor(editorText || StringUtils.cleanCliphistEntry(currentEntry)) : ""
    readonly property bool hasDetectedColor: detectedColor !== ""
    readonly property string imageFilePath: `${Directories.cliphistDecode}/${entryId}.png`

    function checkIsBinary(text) {
        if (!text || text.length === 0) return false;
        const checkLen = Math.min(text.length, 512);
        for (let i = 0; i < checkLen; i++) {
            const code = text.charCodeAt(i);
            if (code === 0) return true;
            if (code < 32 && code !== 9 && code !== 10 && code !== 13) return true;
        }
        return false;
    }

    readonly property bool isBinary: !isImage && checkIsBinary(rawDecodedText)

    readonly property int charCount: editorText.length
    readonly property int lineCount: editorText === "" ? 0 : editorText.split(/\r\n|\r|\n/).length

    function focusEditor() {
        if (!isImage && !hasDetectedColor && !isBinary) {
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

        // 1. Direct local image file
        if (root.localImagePath !== "") {
            root.isLoading = false;
            if (imageViewer) {
                imageViewer.source = "file://" + root.localImagePath;
            }
            return;
        }

        // 2. Cliphist binary image
        if (root.isCliphistImage) {
            root.isLoading = true;
            imageDecodeProc.running = false;
            imageDecodeProc.command = [
                "bash", "-c",
                `mkdir -p '${Directories.cliphistDecode}' && rm -f '${root.imageFilePath}' && printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode > '${root.imageFilePath}'`
            ];
            imageDecodeProc.running = true;
            return;
        }

        // 3. Text decode
        root.isLoading = true;
        textDecodeProc.running = false;
        textDecodeProc.command = [
            "bash", "-c",
            `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode`
        ];
        textDecodeProc.running = true;
    }

    Component.onCompleted: {
        decodeCurrentEntry();
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
                const fullText = textCollector.text;
                root._settingText = true;
                root.rawDecodedText = fullText;

                if (root.checkIsBinary(fullText)) {
                    root.editorText = "";
                    textArea.text = "";
                } else if (fullText.length > 35000) {
                    root.editorText = fullText.substring(0, 35000);
                    textArea.text = root.editorText;
                } else {
                    root.editorText = fullText;
                    if (textArea.text !== fullText) {
                        textArea.text = fullText;
                    }
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
            `mkdir -p '${Directories.cliphistDecode}' && rm -f '${root.imageFilePath}' && printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode > '${root.imageFilePath}'`
        ]
        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;
            if (exitCode === 0) {
                if (imageViewer) {
                    imageViewer.source = "";
                    imageViewer.source = "file://" + root.imageFilePath;
                }
            }
        }
    }

    // Main Layout aligned with left pane
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Header Bar (aligned vertically with Search Bar on the left)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            visible: !!root.currentEntry

            // Title / Type indicator
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    iconSize: 20
                    text: root.isImage ? "image" : (root.hasDetectedColor ? "palette" : (root.isBinary ? "data_object" : "edit_note"))
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: {
                        if (!root.currentEntry) return Translation.tr("Editor");
                        if (root.isImage) return Translation.tr("Image");
                        if (root.hasDetectedColor) return root.detectedColor;
                        if (root.isBinary) return Translation.tr("Binary Data");
                        return `${root.charCount} chars • ${root.lineCount} lines`;
                    }
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
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
            }

            Item { Layout.fillWidth: true }

            // Actions for Text
            RowLayout {
                visible: !root.isImage && !root.isBinary && !root.hasDetectedColor
                spacing: 6

                // Revert
                RippleButton {
                    visible: root.isModified
                    implicitHeight: 32
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
                    implicitHeight: 32
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
                    implicitHeight: 32
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
                    visible: root.localImagePath !== ""
                    implicitHeight: 32
                    implicitWidth: openImgRow.implicitWidth + 16
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", root.localImagePath]);
                        root.requestClose();
                    }

                    contentItem: RowLayout {
                        id: openImgRow
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol { font.pixelSize: 15; text: "open_in_new"; color: Appearance.colors.colOnLayer1 }
                        StyledText { text: Translation.tr("Open"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                    }
                }

                RippleButton {
                    implicitHeight: 32
                    implicitWidth: copyImgRow.implicitWidth + 18
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    onClicked: {
                        if (root.localImagePath !== "") {
                            Quickshell.execDetached(["bash", "-c", `wl-copy < '${root.localImagePath}'`]);
                        } else {
                            Cliphist.copy(root.currentEntry);
                        }
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

            // Actions for Color
            RowLayout {
                visible: !root.isImage && root.hasDetectedColor
                spacing: 6

                RippleButton {
                    implicitHeight: 32
                    implicitWidth: copyColorRow.implicitWidth + 18
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    onClicked: {
                        Cliphist.copyText(root.detectedColor);
                        root.showNotification(Translation.tr("Copied color"));
                    }

                    contentItem: RowLayout {
                        id: copyColorRow
                        anchors.centerIn: parent
                        spacing: 5
                        MaterialSymbol { font.pixelSize: 15; text: "content_copy"; color: Appearance.colors.colOnPrimary }
                        StyledText { text: Translation.tr("Copy Color"); font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                    }
                }
            }

            // Actions for Binary Data
            RowLayout {
                visible: root.isBinary
                spacing: 6

                RippleButton {
                    implicitHeight: 32
                    implicitWidth: copyBinRow.implicitWidth + 18
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    onClicked: {
                        Cliphist.copy(root.currentEntry);
                        root.showNotification(Translation.tr("Copied binary data"));
                    }

                    contentItem: RowLayout {
                        id: copyBinRow
                        anchors.centerIn: parent
                        spacing: 5
                        MaterialSymbol { font.pixelSize: 15; text: "content_copy"; color: Appearance.colors.colOnPrimary }
                        StyledText { text: Translation.tr("Copy Data"); font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: Appearance.colors.colOnPrimary }
                    }
                }
            }
        }

        // Horizontal Separator (matches left pane separator)
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOutlineVariant
        }

        // Content Area Container
        Rectangle {
            id: editorBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal
            border.width: root.isEditorFocused ? 1.5 : 1
            border.color: root.isEditorFocused ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
            focus: root.isEditorFocused

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape || event.key === Qt.Key_Backtab) {
                    root.requestFocusList();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.isImage) {
                        if (root.localImagePath !== "") {
                            Quickshell.execDetached(["bash", "-c", `wl-copy < '${root.localImagePath}'`]);
                        } else {
                            Cliphist.copy(root.currentEntry);
                        }
                        root.requestClose();
                        event.accepted = true;
                    } else if (root.hasDetectedColor) {
                        Cliphist.copyText(root.detectedColor);
                        root.requestClose();
                        event.accepted = true;
                    } else if (root.isBinary) {
                        Cliphist.copy(root.currentEntry);
                        root.requestClose();
                        event.accepted = true;
                    }
                }
            }

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

            // VIEW 1: TEXT EDITING
            Item {
                anchors.fill: parent
                anchors.margins: 10
                visible: !!root.currentEntry && !root.isImage && !root.hasDetectedColor && !root.isBinary

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(height, textArea.contentHeight + 20)
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
                            } else if ((event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) && event.key === Qt.Key_Left) {
                                root.requestFocusList();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left && (textArea.cursorPosition === 0 || (textArea.selectionStart === textArea.selectionEnd && textArea.cursorPosition === 0))) {
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

            // VIEW 2: IMAGE PREVIEW WITH PATH BAR
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                visible: !!root.currentEntry && root.isImage

                // Image Location Path Bar
                Rectangle {
                    visible: root.localImagePath !== ""
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 6

                        MaterialSymbol {
                            text: "folder_open"
                            font.pixelSize: 15
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.localImagePath
                            font.pixelSize: 11
                            font.family: Appearance.font.family.monospace
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideMiddle
                        }

                        RippleButton {
                            implicitHeight: 24
                            implicitWidth: copyPathSmallRow.implicitWidth + 12
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: {
                                Cliphist.copyText(root.localImagePath);
                                root.showNotification(Translation.tr("Copied path"));
                            }

                            contentItem: RowLayout {
                                id: copyPathSmallRow
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol { font.pixelSize: 12; text: "content_copy"; color: Appearance.colors.colSubtext }
                                StyledText { text: Translation.tr("Copy Path"); font.pixelSize: 10; color: Appearance.colors.colSubtext }
                            }
                        }
                    }
                }

                // Strictly bounded Image Viewer
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Image {
                        id: imageViewer
                        anchors.fill: parent
                        anchors.margins: 4
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        cache: false
                        clip: true
                        source: ""
                    }
                }
            }

            // VIEW 3: COLOR PREVIEW
            Item {
                anchors.fill: parent
                visible: !!root.currentEntry && !root.isImage && root.hasDetectedColor

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
                }
            }

            // VIEW 4: BINARY CONTENT PREVIEW
            Item {
                anchors.fill: parent
                visible: !!root.currentEntry && !root.isImage && !root.hasDetectedColor && root.isBinary

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    implicitWidth: 260

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 42
                        text: "data_object"
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Binary Data")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("%1 bytes • Raw binary content").arg(root.rawDecodedText.length)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: Translation.tr("Direct text preview is disabled to prevent system slowdown.")
                        font.pixelSize: 11
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
