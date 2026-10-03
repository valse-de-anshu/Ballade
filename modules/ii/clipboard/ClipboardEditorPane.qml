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

    readonly property int charCount: editorText.length
    readonly property int lineCount: editorText === "" ? 0 : editorText.split(/\r\n|\r|\n/).length

    function focusEditor() {
        if (!isImage && !hasDetectedColor) {
            textArea.forceActiveFocus();
        } else {
            editorBox.forceActiveFocus();
        }
    }

    Timer {
        id: textDecodeTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (!root.currentEntry || root.isImage) return;
            textDecodeProc.running = false;
            textDecodeProc.command = [
                "bash", "-c",
                `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode`
            ];
            textDecodeProc.running = true;
        }
    }

    function decodeCurrentEntry() {
        const entry = root.currentEntry;
        if (!entry) {
            root._settingText = true;
            root.rawDecodedText = "";
            root.editorText = "";
            textArea.text = "";
            root._settingText = false;
            root.isLoading = false;
            if (imageViewer) imageViewer.source = "";
            return;
        }

        const id = Cliphist.getEntryId(entry);
        const isCliphistImg = Cliphist.entryIsImage(entry);
        let clean = StringUtils.cleanCliphistEntry(entry).trim();
        if (clean.startsWith("file://")) clean = clean.substring(7);
        const isLocalImg = /^\/.*\.(png|jpe?g|webp|gif|svg|bmp|ico|avif)$/i.test(clean);

        // 1. Direct local image file
        if (isLocalImg) {
            root.isLoading = false;
            textDecodeTimer.stop();
            textDecodeProc.running = false;
            imageDecodeProc.running = false;
            if (imageViewer) {
                imageViewer.source = "file://" + clean;
            }
            return;
        }

        // 2. Cliphist binary image
        if (isCliphistImg) {
            root.isLoading = true;
            textDecodeTimer.stop();
            textDecodeProc.running = false;
            const targetPath = `${Directories.cliphistDecode}/${id}.png`;
            imageDecodeProc.running = false;
            imageDecodeProc.command = [
                "bash", "-c",
                `[ -s '${targetPath}' ] || (mkdir -p '${Directories.cliphistDecode}' && printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${targetPath}')`
            ];
            imageDecodeProc.running = true;
            return;
        }

        // 3. Text or Color
        if (imageViewer) imageViewer.source = "";
        imageDecodeProc.running = false;

        // Immediate snippet preview so navigation feels instant
        root._settingText = true;
        root.editorText = clean;
        textArea.text = clean;
        root._settingText = false;

        root.isLoading = true;
        textDecodeTimer.restart();
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
                let fullText = textCollector.text;
                // Strip ANSI escape codes and null bytes
                fullText = fullText.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").replace(/\0/g, "");

                root._settingText = true;
                root.rawDecodedText = fullText;

                if (fullText.length > 50000) {
                    root.editorText = fullText.substring(0, 50000);
                } else {
                    root.editorText = fullText;
                }
                if (textArea.text !== root.editorText) {
                    textArea.text = root.editorText;
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
            `[ -s '${root.imageFilePath}' ] || (mkdir -p '${Directories.cliphistDecode}' && printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(root.currentEntry)}' | ${Cliphist.cliphistBinary} decode > '${root.imageFilePath}')`
        ]
        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;
            if (exitCode === 0) {
                const id = Cliphist.getEntryId(root.currentEntry);
                if (id && imageViewer) {
                    imageViewer.source = "file://" + Directories.cliphistDecode + "/" + id + ".png";
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
                    text: root.isImage ? "image" : (root.hasDetectedColor ? "palette" : "edit_note")
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: {
                        if (!root.currentEntry) return Translation.tr("Editor");
                        if (root.isImage) return Translation.tr("Image");
                        if (root.hasDetectedColor) return root.detectedColor;
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
                visible: !root.isImage && !root.hasDetectedColor
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
                visible: !!root.currentEntry && !root.isImage && !root.hasDetectedColor

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
        }
    }
}
