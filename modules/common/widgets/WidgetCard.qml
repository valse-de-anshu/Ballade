import QtQuick
import qs
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property var widget: null
    property bool glass: true
    property color fill: Qt.rgba(
        Appearance.colors.colLayer0Base.r,
        Appearance.colors.colLayer0Base.g,
        Appearance.colors.colLayer0Base.b,
        0.12
    )
    property bool shadowed: Config.options.background.widgets.shadow ?? true

    radius: Appearance.rounding?.verylarge ?? 30
    color: glass && (Config.options?.background?.widgets?.glass?.enable ?? false) ? "transparent" : fill

    StyledRectangularShadow {
        target: root
        z: -2
        visible: root.shadowed
    }

    WindowGlass {
        anchors.fill: parent
        cardRadius: root.radius
        tint: root.fill
        glassEnabled: root.glass && (Config.options?.background?.widgets?.glass?.enable ?? false)
    }
}
