pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
    id: root

    property string entry: ""
    property int itemIndex: 0
    property bool isSelected: false
    property bool isListFocused: true

    signal itemClicked()
    signal pinToggled()
    signal deleteRequested()
    signal copyRequested()

    readonly property string entryString: root.entry
    readonly property string entryId: Cliphist.getEntryId(entryString)
    readonly property string cleanedText: StringUtils.cleanCliphistEntry(entryString)
    readonly property bool isCliphistImage: Cliphist.entryIsImage(entryString)
    readonly property string localImagePath: {
        let clean = root.cleanedText.trim();
        if (clean.startsWith("file://")) clean = clean.substring(7);
        if (/^\/.*\.(png|jpe?g|webp|gif|svg|bmp|ico|avif)$/i.test(clean)) {
            return clean;
        }
        return "";
    }
    readonly property bool isImage: isCliphistImage || localImagePath !== ""
    readonly property string detectedColor: !isImage ? ColorUtils.detectColor(cleanedText) : ""
    readonly property bool hasDetectedColor: detectedColor !== ""
    readonly property bool isPinned: {
        const _ = Cliphist.pinRevision;
        return Cliphist.isPinned(entryString);
    }

    implicitWidth: ListView.view ? ListView.view.width : 400
    implicitHeight: isImage ? 58 : 46
    focusPolicy: Qt.NoFocus

    buttonRadius: Appearance.rounding.normal
    colBackground: root.isSelected
        ? (root.isListFocused ? Appearance.colors.colPrimaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.45))
        : (root.hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple: Appearance.colors.colPrimaryContainerActive

    property color colForeground: root.isSelected
        ? Appearance.colors.colOnPrimaryContainer
        : Appearance.m3colors.m3onSurface

    onClicked: root.itemClicked()

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 10

        // Leading indicator: Thumbnail / Color Swatch / Material Symbol
        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.isImage ? 52 : 24
            Layout.preferredHeight: root.isImage ? 40 : 24

            // 1. Image Thumbnail
            Loader {
                anchors.centerIn: parent
                active: root.isImage
                visible: root.isImage
                sourceComponent: root.isCliphistImage ? cliphistImgComp : fileImgComp
            }

            Component {
                id: cliphistImgComp
                CliphistImage {
                    entry: root.entryString
                    maxWidth: 52
                    maxHeight: 40
                    radius: Appearance.rounding.small
                }
            }

            Component {
                id: fileImgComp
                Image {
                    source: root.localImagePath !== "" ? ("file://" + root.localImagePath) : ""
                    width: 52
                    height: 40
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            // 2. Color Swatch
            Rectangle {
                anchors.centerIn: parent
                visible: !root.isImage && root.hasDetectedColor
                width: 22
                height: 22
                radius: Appearance.rounding.small
                color: root.hasDetectedColor ? root.detectedColor : "transparent"
                border.width: 1.5
                border.color: ColorUtils.applyAlpha(Appearance.m3colors.m3outline, 0.5)

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: ColorUtils.isDark(parent.color)
                        ? ColorUtils.applyAlpha("#ffffff", 0.3)
                        : ColorUtils.applyAlpha("#000000", 0.3)
                }
            }

            // 3. Material Symbol for regular text
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.isImage && !root.hasDetectedColor
                text: root.isPinned ? "push_pin" : "content_paste"
                iconSize: 20
                color: root.isPinned ? Appearance.colors.colPrimary : (root.isSelected ? root.colForeground : Appearance.colors.colSubtext)
            }
        }

        // Center Content: Single clean text line
        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.hasDetectedColor
                ? root.detectedColor
                : (root.isImage ? (root.localImagePath !== "" ? root.localImagePath.split("/").pop() : Translation.tr("Image")) : root.cleanedText.replace(/[\r\n\t]+/g, " ").trim())
            font.pixelSize: Appearance.font.pixelSize.normal
            font.family: root.hasDetectedColor ? Appearance.font.family.monospace : Appearance.font.family.main
            font.weight: root.isSelected ? Font.Medium : Font.Normal
            color: root.colForeground
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Trailing Actions: Pin, Copy, Delete
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Pin button
            RippleButton {
                id: pinButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: root.isPinned ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85) : "transparent"
                colBackgroundHover: Appearance.colors.colLayer2
                colRipple: Appearance.colors.colLayer2Active
                onClicked: root.pinToggled()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 17
                    text: root.isPinned ? "keep_off" : "push_pin"
                    color: root.isPinned
                        ? Appearance.colors.colPrimary
                        : (root.isSelected ? root.colForeground : Appearance.colors.colSubtext)
                }

                StyledToolTip {
                    text: root.isPinned ? Translation.tr("Unpin") : Translation.tr("Pin")
                }
            }

            // Copy button
            RippleButton {
                id: copyButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2
                colRipple: Appearance.colors.colLayer2Active
                onClicked: root.copyRequested()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 17
                    text: "content_copy"
                    color: root.isSelected ? root.colForeground : Appearance.colors.colSubtext
                }

                StyledToolTip {
                    text: Translation.tr("Copy")
                }
            }

            // Delete button (Turns red on hover)
            RippleButton {
                id: deleteButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colError
                colRipple: Appearance.colors.colOnError
                onClicked: root.deleteRequested()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 17
                    text: "delete"
                    color: deleteButton.containsMouse ? Appearance.colors.colOnError : (root.isSelected ? root.colForeground : Appearance.colors.colSubtext)
                }

                StyledToolTip {
                    text: Translation.tr("Delete (Del)")
                }
            }
        }
    }
}
