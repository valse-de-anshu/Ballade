import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
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

    implicitWidth: ListView.view ? ListView.view.width : 380
    implicitHeight: isImage ? 115 : 62

    Rectangle {
        id: bgCard
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: Appearance.rounding.normal

        color: {
            if (root.isSelected) {
                return root.isListFocused 
                    ? Appearance.colors.colPrimaryContainer 
                    : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.5);
            }
            if (mouseArea.containsMouse) {
                return Appearance.colors.colLayer1Hover;
            }
            return Appearance.colors.colLayer1;
        }

        border.width: root.isSelected ? 1.5 : (root.isPinned ? 1 : 0)
        border.color: {
            if (root.isSelected) {
                return root.isListFocused ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border;
            }
            if (root.isPinned) {
                return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.4);
            }
            return "transparent";
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 8

            // Left Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3

                // ID label (e.g. #26510)
                RowLayout {
                    spacing: 4
                    MaterialSymbol {
                        visible: root.isPinned
                        font.pixelSize: 12
                        text: "push_pin"
                        color: Appearance.colors.colPrimary
                    }
                    Text {
                        text: root.entryId ? `#${root.entryId}` : ""
                        font.family: Appearance.font.family.main
                        font.pixelSize: 11
                        color: root.isSelected 
                            ? ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.3) 
                            : Appearance.colors.colSubtext
                    }
                }

                // If image: show snippet + thumbnail
                Item {
                    visible: root.isImage
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70

                    Loader {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        active: root.isImage
                        sourceComponent: CliphistImage {
                            entry: root.entryString
                            maxWidth: 100
                            maxHeight: 70
                            radius: Appearance.rounding.small
                        }
                    }
                }

                // If color: circle swatch + hex
                RowLayout {
                    visible: !root.isImage && root.hasDetectedColor
                    spacing: 8
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: root.hasDetectedColor ? root.detectedColor : "transparent"
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border
                    }
                    Text {
                        text: root.detectedColor
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: 12
                        color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                // If normal text: text snippet
                Text {
                    visible: !root.isImage && !root.hasDetectedColor
                    Layout.fillWidth: true
                    text: root.cleanedText.replace(/\n/g, " ").trim()
                    font.family: Appearance.font.family.main
                    font.pixelSize: 13
                    color: root.isSelected 
                        ? Appearance.colors.colOnPrimaryContainer 
                        : Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Right Actions (Pin, Copy, Delete)
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 2

                // Pin
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    onClicked: root.pinToggled()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 15
                        text: "push_pin"
                        color: root.isPinned 
                            ? Appearance.colors.colPrimary 
                            : (root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext)
                    }

                    StyledToolTip {
                        text: root.isPinned ? "Unpin" : "Pin"
                    }
                }

                // Copy
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    onClicked: root.copyRequested()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 15
                        text: "content_copy"
                        color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }

                    StyledToolTip {
                        text: "Copy"
                    }
                }

                // Delete
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    onClicked: root.deleteRequested()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 15
                        text: "delete"
                        color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }

                    StyledToolTip {
                        text: "Delete (Del)"
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: root.itemClicked()
        }
    }
}
