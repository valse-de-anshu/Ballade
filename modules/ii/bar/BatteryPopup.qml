import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    readonly property real percentage: Battery.percentage
    readonly property int percentInt: Math.round(percentage * 100)
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isFull: Battery.chargeState === 4 || percentInt >= 99
    readonly property bool isLow: Battery.isLow
    readonly property real powerRate: Battery.energyRate

    function formatTime(seconds) {
        if (!seconds || seconds <= 0 || isNaN(seconds)) return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        if (h > 0) return `${h}h ${m}m`;
        return `${m}m`;
    }

    readonly property string timeText: {
        if (isFull) return Translation.tr("Fully charged");
        if (isCharging) {
            const tf = formatTime(Battery.timeToFull);
            return tf ? Translation.tr("%1 until full").arg(tf) : Translation.tr("Charging");
        }
        const te = formatTime(Battery.timeToEmpty);
        return te ? Translation.tr("%1 remaining").arg(te) : Translation.tr("On battery");
    }

    readonly property string statusTitle: {
        if (isFull) return Translation.tr("Fully Charged");
        if (isCharging) return Translation.tr("Charging");
        if (isLow) return Translation.tr("Battery Low");
        return Translation.tr("Discharging");
    }

    readonly property color statusColor: {
        if (isLow && !isCharging) return Appearance.m3colors.m3error;
        if (isCharging) return Appearance.colors.colPrimary;
        if (isFull) return Appearance.colors.colSecondary;
        return Appearance.colors.colOnLayer0;
    }

    readonly property string batteryIconName: {
        if (isFull) return "battery_full";
        if (isCharging) return "battery_charging_full";
        if (percentInt <= 20) return "battery_alert";
        if (percentInt <= 40) return "battery_2_bar";
        if (percentInt <= 60) return "battery_4_bar";
        if (percentInt <= 80) return "battery_5_bar";
        return "battery_full";
    }

    Item {
        id: popupContainer
        implicitWidth: 280
        implicitHeight: mainLayout.implicitHeight

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: 10

        // Hero Battery Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 0
            border.color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MaterialSymbol {
                        text: root.batteryIconName
                        iconSize: 28
                        color: root.statusColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            spacing: 6
                            StyledText {
                                text: `${root.percentInt}%`
                                font.pixelSize: Appearance.font.pixelSize.huge
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                implicitHeight: 22
                                implicitWidth: statusPillText.implicitWidth + 12
                                radius: Appearance.rounding.full
                                color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.3)

                                StyledText {
                                    id: statusPillText
                                    anchors.centerIn: parent
                                    text: root.statusTitle
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Bold
                                    color: root.statusColor
                                }
                            }
                        }

                        StyledText {
                            text: root.timeText
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }
                }

                // Battery Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Appearance.colors.colLayer3

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(6, Math.min(parent.width * root.percentage, parent.width))
                        radius: 3
                        color: root.statusColor

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }

        // Metrics Grid (2 Cards)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Card 1: Rate
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 62
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                border.width: 0
                border.color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    RowLayout {
                        spacing: 4
                        MaterialSymbol {
                            text: "bolt"
                            iconSize: 14
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Rate")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    StyledText {
                        text: root.powerRate > 0.01 ? `${root.powerRate.toFixed(1)} W` : (root.isFull ? "Idle" : "AC Power")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            // Card 2: Health
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 62
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                border.width: 0
                border.color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    RowLayout {
                        spacing: 4
                        MaterialSymbol {
                            text: "favorite"
                            iconSize: 14
                            color: Appearance.colors.colSecondary
                        }
                        StyledText {
                            text: Translation.tr("Health")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    StyledText {
                        text: Battery.health > 0 ? `${Battery.health.toFixed(0)}%` : "Good"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }
    }
}
}
