import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property list<Item> items
    property real bigRadius: Appearance.rounding.normal
    property real smallRadius: Appearance.rounding.normal
    property color bgcolor: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.70)
    property color borderColor: Appearance.colors.colLayer0Border
    property real itemVerticalPadding: 8

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 12

    radius: root.bigRadius
    color: root.bgcolor
    border.width: 1
    border.color: root.borderColor

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 4
        }
        spacing: 0

        Repeater {
            model: root.items.length
            delegate: ColumnLayout {
                required property int index
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    implicitHeight: (root.items[index]?.implicitHeight ?? 0) + root.itemVerticalPadding

                    ColumnLayout {
                        id: contentArea
                        anchors { fill: parent; margins: 6 }
                        spacing: 0

                        Component.onCompleted: {
                            const child = root.items[index]
                            if (child) {
                                child.parent = contentArea
                                child.Layout.fillWidth = true
                            }
                        }
                    }
                }

                Rectangle {
                    visible: index < root.items.length - 1
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    height: 1
                    color: ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.16)
                }
            }
        }
    }
}