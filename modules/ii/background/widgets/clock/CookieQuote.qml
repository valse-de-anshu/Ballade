import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects


Item {
    id: root

    readonly property string quoteText: Config.options.background.widgets.clock.quote.text

    implicitWidth: quoteBox.implicitWidth
    implicitHeight: quoteBox.implicitHeight

    Rectangle {
        id: quoteBox
        y: Config.options.background.widgets.clock.style === "pixel" && Config.options.background.widgets.clock.pixel.orientation === "horizontal" ? -26 : 0
        x: Config.options.background.widgets.clock.style === "pixel" && Config.options.background.widgets.clock.pixel.orientation === "horizontal" ? -20 : 0
        implicitWidth: quoteRow.implicitWidth + 12 * 2
        implicitHeight: quoteRow.implicitHeight + 6 * 2
        radius: Appearance.rounding.full
        color: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            0.18
        )
        border.width: 0
        border.color: "transparent"

        Row {
            id: quoteRow
            anchors.centerIn: parent
            spacing: 6
            
            MaterialSymbol {
                id: quoteIcon
                anchors.verticalCenter: parent.verticalCenter
                iconSize: Appearance.font.pixelSize.normal
                text: "format_quote"
                color: Appearance.colors.colPrimary
            }
            StyledText {
                id: quoteStyledText
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                text: Config.options.background.widgets.clock.quote.text
                color: Appearance.colors.colOnLayer0
                font {
                    family: Config.options.background.widgets.clock.quote.followClock ? Config.options.background.widgets.clock.digital.font.family : Appearance.font.family.reading 
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.DemiBold
                }
            }
        }
    }
}
