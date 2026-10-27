import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    RowLayout {
        id: contentRow
        spacing: 10
        anchors.centerIn: parent

        function formatKB(kb) {
            if (kb === undefined || isNaN(kb)) return "-- GB";
            return (kb / (1024 * 1024)).toFixed(1) + " GB";
        }

        // Card 1: RAM
        Rectangle {
            id: ramCard
            implicitWidth: 155
            implicitHeight: 105
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "memory"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "RAM"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: ramPercentText.implicitWidth + 10
                        implicitHeight: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer
                        StyledText {
                            id: ramPercentText
                            anchors.centerIn: parent
                            text: `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer3
                    clip: true
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1.0, ResourceUsage.memoryUsedPercentage))
                        radius: Appearance.rounding.full
                        color: ResourceUsage.memoryUsedPercentage > 0.85 ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Used")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.memoryUsed)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Free")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.memoryFree)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3outline
                    }
                }
            }
        }

        // Card 2: SWAP
        Rectangle {
            id: swapCard
            visible: ResourceUsage.swapTotal > 0
            implicitWidth: 155
            implicitHeight: 105
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            readonly property real swapRatio: ResourceUsage.swapTotal > 0 ? (ResourceUsage.swapUsed / ResourceUsage.swapTotal) : 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "swap_horiz"
                        iconSize: 18
                        color: Appearance.colors.colTertiary
                    }
                    StyledText {
                        text: "Swap"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: swapPercentText.implicitWidth + 10
                        implicitHeight: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colTertiaryContainer
                        StyledText {
                            id: swapPercentText
                            anchors.centerIn: parent
                            text: `${Math.round(swapCard.swapRatio * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnTertiaryContainer
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer3
                    clip: true
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1.0, swapCard.swapRatio))
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colTertiary
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Used")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.swapUsed)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Free")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.swapFree)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3outline
                    }
                }
            }
        }

        // Card 3: CPU
        Rectangle {
            id: cpuCard
            implicitWidth: 155
            implicitHeight: 105
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "planner_review"
                        iconSize: 18
                        color: Appearance.colors.colSecondary
                    }
                    StyledText {
                        text: "CPU"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: cpuPercentText.implicitWidth + 10
                        implicitHeight: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colSecondaryContainer
                        StyledText {
                            id: cpuPercentText
                            anchors.centerIn: parent
                            text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer3
                    clip: true
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1.0, ResourceUsage.cpuUsage))
                        radius: Appearance.rounding.full
                        color: ResourceUsage.cpuUsage > 0.85 ? Appearance.m3colors.m3error : Appearance.colors.colSecondary
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Load")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: ResourceUsage.cpuTemp > 0
                    StyledText {
                        text: Translation.tr("Temp")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 3
                        MaterialSymbol {
                            text: "device_thermostat"
                            iconSize: 13
                            color: ResourceUsage.cpuTemp > 80 ? Appearance.m3colors.m3error : (ResourceUsage.cpuTemp > 65 ? "#f59e0b" : "#10b981")
                        }
                        StyledText {
                            text: `${Math.round(ResourceUsage.cpuTemp)}°C`
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: ResourceUsage.cpuTemp > 80 ? Appearance.m3colors.m3error : (ResourceUsage.cpuTemp > 65 ? "#f59e0b" : "#10b981")
                        }
                    }
                }
            }
        }

        // Card 4: Disk (/home)
        Rectangle {
            id: diskCard
            implicitWidth: 165
            implicitHeight: 105
            radius: Appearance.rounding.normal
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            readonly property real diskRatio: ResourceUsage.diskTotal > 0 ? (ResourceUsage.diskUsed / ResourceUsage.diskTotal) : 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    MaterialSymbol {
                        text: "hard_drive"
                        iconSize: 18
                        color: Appearance.m3colors.m3primary
                    }
                    StyledText {
                        text: "Disk (/home)"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSurface
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: diskPercentText.implicitWidth + 10
                        implicitHeight: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer
                        StyledText {
                            id: diskPercentText
                            anchors.centerIn: parent
                            text: `${Math.round(diskCard.diskRatio * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer3
                    clip: true
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1.0, diskCard.diskRatio))
                        radius: Appearance.rounding.full
                        color: diskCard.diskRatio > 0.9 ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Used")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.diskUsed)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Free")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: contentRow.formatKB(ResourceUsage.diskFree)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3outline
                    }
                }
            }
        }
    }
}
