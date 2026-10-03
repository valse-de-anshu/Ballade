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
    readonly property bool isImage: Cliphist.entryIsImage(entryString)
    readonly property string cleanedText: StringUtils.cleanCliphistEntry(entryString)
    readonly property string detectedColor: !isImage ? ColorUtils.detectColor(cleanedText) : ""
    readonly property bool hasDetectedColor: detectedColor !== ""
    readonly property bool isPinned: Cliphist.isPinned(entryString)
    readonly property bool isCurrentClipboard: Quickshell.clipboardText !== "" && (root.cleanedText === Quickshell.clipboardText)

    implicitWidth: ListView.view ? ListView.view.width : 400
    implicitHeight: isImage ? 86 : 56

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
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 10

        // Leading indicator: Thumbnail / Color Swatch / Material Symbol
        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.isImage ? 56 : 28
            Layout.preferredHeight: root.isImage ? 44 : 28

            // 1. Image Thumbnail
            Loader {
                anchors.centerIn: parent
                active: root.isImage
                visible: root.isImage
                sourceComponent: CliphistImage {
                    entry: root.entryString
                    maxWidth: 56
                    maxHeight: 44
                    radius: Appearance.rounding.small
                }
            }

            // 2. Color Swatch
            Rectangle {
                anchors.centerIn: parent
                visible: !root.isImage && root.hasDetectedColor
                width: 24
                height: 24
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
                iconSize: 22
                color: root.isPinned ? Appearance.colors.colPrimary : (root.isSelected ? root.colForeground : Appearance.colors.colSubtext)
            }
        }

        // Center Content: Metadata and Text
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Top Row: #ID and badges
            RowLayout {
                spacing: 6

                StyledText {
                    text: root.entryId ? `#${root.entryId}` : ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: root.isSelected
                        ? ColorUtils.transparentize(root.colForeground, 0.25)
                        : Appearance.colors.colSubtext
                }

                // Pinned indicator badge
                Rectangle {
                    visible: root.isPinned
                    Layout.preferredHeight: 14
                    Layout.preferredWidth: pinRow.implicitWidth + 8
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)

                    RowLayout {
                        id: pinRow
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            text: "push_pin"
                            font.pixelSize: 10
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: "Pinned"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                // Current active clipboard badge
                Rectangle {
                    visible: root.isCurrentClipboard
                    Layout.preferredHeight: 14
                    Layout.preferredWidth: activeRow.implicitWidth + 8
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary

                    RowLayout {
                        id: activeRow
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            text: "check"
                            font.pixelSize: 10
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: "Active"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            // Main Text snippet or color hex
            StyledText {
                Layout.fillWidth: true
                text: root.hasDetectedColor
                    ? root.detectedColor
                    : (root.isImage ? "Image" : root.cleanedText.replace(/[\r\n\t]+/g, " ").trim())
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: root.hasDetectedColor ? Appearance.font.family.monospace : Appearance.font.family.main
                font.weight: root.isSelected ? Font.Medium : Font.Normal
                color: root.colForeground
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Trailing Actions: Pin, Copy, Delete
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Pin button
            RippleButton {
                id: pinButton
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
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
