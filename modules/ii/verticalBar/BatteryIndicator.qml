import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool vertical: true
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: Appearance.sizes.baseVerticalBarWidth
    implicitHeight: batteryProgress.valueBarWidth + 8

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        value: percentage
        rotation: -90
        highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            ColumnLayout {
                rotation: 90
                anchors.centerIn: parent
                spacing: -7

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    fill: 1
                    text: "bolt"
                    Layout.topMargin: 4
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: root.isCharging && root.percentage < 1
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: root.isCharging ? 2 : 4
                    font: batteryProgress.font
                    text: Math.round(root.percentage * 100)
                    visible: root.percentage < 1 || !root.isCharging
                }
            }
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
