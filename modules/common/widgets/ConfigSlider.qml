import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    signal moved()

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias pressed: slider.pressed
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property alias from: slider.from
    property alias to: slider.to
    property real textWidth: 120
    property bool showLabel: true

    RowLayout {
        id: row
        visible: root.showLabel
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.preferredWidth: root.textWidth
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    StyledSlider {
        id: slider
        configuration: StyledSlider.Configuration.XS
        usePercentTooltip: root.usePercentTooltip
        onMoved: root.moved()
    }
}