import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 2

    property alias text: sliderName.text
    property alias from: sliderWidget.from
    property alias to: sliderWidget.to
    property alias value: sliderWidget.value
    property alias tooltipContent: sliderWidget.tooltipContent
    property alias stopIndicatorValues: sliderWidget.stopIndicatorValues

    signal moved()
    
    ContentSubsectionLabel {
        id: sliderName
        visible: Boolean(text && text.length > 0)
        Layout.fillWidth: true
        text: ""
    }

    StyledSlider {
        id: sliderWidget
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        configuration: StyledSlider.Configuration.S
        onMoved: root.moved()
    }
}

