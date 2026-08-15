import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    property bool warning: percentage * 100 >= warningThreshold
    property string rawTextOverride: ""

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors {
            verticalCenter: parent.verticalCenter
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 20
            implicitHeight: 20

            ClippedFilledCircularProgress {
                anchors.fill: parent
                visible: Config.options.bar.resources.style !== "outline"
                lineWidth: Appearance.rounding.unsharpen
                value: percentage
                implicitSize: 20
                colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                accountForLightBleeding: !root.warning
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        font.weight: Font.DemiBold
                        fill: 1
                        text: iconName
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            ClippedOutlineCircularProgress {
                anchors.fill: parent
                visible: Config.options.bar.resources.style === "outline"
                lineWidth: Appearance.rounding.unsharpen
                value: percentage
                implicitSize: 20
                colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        font.weight: Font.DemiBold
                        fill: 1
                        text: iconName
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            visible: Config.options.bar.resources.showValue
            implicitWidth: visible ? fullPercentageTextMetrics.width : 0
            implicitHeight: percentageText.implicitHeight
            clip: true

            TextMetrics {
                id: fullPercentageTextMetrics
                text: percentageText.text.replace(/[0-9]/g, '0')
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.rawTextOverride !== "" ? root.rawTextOverride : `${Math.round(percentage * 100).toString()}`
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
