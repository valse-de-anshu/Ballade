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

    property int layoutVersion: 0

    function hasNextVisible(idx, _version) {
        for (let i = idx + 1; i < root.items.length; ++i) {
            if (root.items[i] && root.items[i].visible) return true;
        }
        return false;
    }

    Component.onCompleted: {
        for (let i = 0; i < root.items.length; ++i) {
            const child = root.items[i]
            if (child) {
                child.visibleChanged.connect(() => {
                    root.layoutVersion++
                })
            }
        }
    }

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
                id: delegateItem
                required property int index
                readonly property Item sourceItem: (root.items && index < root.items.length) ? root.items[index] : null
                readonly property bool itemVisible: Boolean(sourceItem && sourceItem.visible)

                visible: delegateItem.itemVisible
                Layout.fillWidth: true
                spacing: 0

                Item {
                    visible: delegateItem.itemVisible
                    Layout.fillWidth: true
                    implicitHeight: delegateItem.itemVisible ? ((delegateItem.sourceItem ? delegateItem.sourceItem.implicitHeight : 0) + root.itemVerticalPadding) : 0

                    ColumnLayout {
                        id: contentArea
                        anchors { fill: parent; margins: 6 }
                        spacing: 0

                        Component.onCompleted: {
                            const child = delegateItem.sourceItem
                            if (child) {
                                child.parent = contentArea
                                child.Layout.fillWidth = true
                            }
                        }
                    }
                }

                Rectangle {
                    visible: delegateItem.itemVisible && root.hasNextVisible(index, root.layoutVersion)
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