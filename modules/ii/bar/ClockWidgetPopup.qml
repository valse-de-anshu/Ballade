import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    readonly property string formattedDate: DateTime.collapsedCalendarFormat || Qt.locale().toString(DateTime.clock.date, "dddd, MMMM dd")
    readonly property string formattedYear: Qt.locale().toString(DateTime.clock.date, "yyyy")
    readonly property string formattedTime: DateTime.time
    readonly property string formattedUptime: DateTime.uptime

    Item {
        id: popupContainer
        implicitWidth: 320
        implicitHeight: mainLayout.implicitHeight

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: 12

        // Card 1: Time & Date Hero Header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Left: Clock Icon + Time & Date
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 6
                        MaterialSymbol {
                            text: "schedule"
                            iconSize: 22
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: root.formattedTime
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    StyledText {
                        Layout.leftMargin: 2
                        text: `${root.formattedDate}, ${root.formattedYear}`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                // Right: System Uptime Pill
                Rectangle {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    implicitHeight: 26
                    implicitWidth: uptimeRow.implicitWidth + 14
                    radius: Appearance.rounding.full
                    color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.3)

                    RowLayout {
                        id: uptimeRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: "timelapse"
                            iconSize: 14
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: root.formattedUptime
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }

        // Card 2: To Do Tasks
        Rectangle {
            Layout.fillWidth: true
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
            implicitHeight: taskColumn.implicitHeight + 20

            readonly property var unfinishedTodos: {
                const list = Todo.list ?? [];
                return list.filter(item => !item.done);
            }

            ColumnLayout {
                id: taskColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 8

                // Task Section Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialSymbol {
                        text: "checklist"
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Pending Tasks")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: parent.parent.parent.unfinishedTodos.length > 0
                        implicitWidth: countText.implicitWidth + 10
                        implicitHeight: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer

                        StyledText {
                            id: countText
                            anchors.centerIn: parent
                            text: `${parent.parent.parent.parent.unfinishedTodos.length}`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }

                // If tasks exist, show up to 4 items cleanly
                Repeater {
                    model: parent.parent.unfinishedTodos.slice(0, 4)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: taskRow.implicitHeight + 10
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.03)

                        RowLayout {
                            id: taskRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 8
                            }
                            spacing: 8

                            MaterialSymbol {
                                text: "radio_button_unchecked"
                                iconSize: 14
                                color: Appearance.colors.colOutline
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.content || ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }
                }

                // If more than 4 tasks
                StyledText {
                    visible: parent.parent.unfinishedTodos.length > 4
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("+ %1 more tasks").arg(parent.parent.unfinishedTodos.length - 4)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colPrimary
                }

                // If no tasks: Friendly clean empty state
                RowLayout {
                    visible: parent.parent.unfinishedTodos.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    spacing: 8

                    MaterialSymbol {
                        text: "task_alt"
                        iconSize: 16
                        color: Appearance.colors.colSecondary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("All tasks completed!")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
    }
}
}
