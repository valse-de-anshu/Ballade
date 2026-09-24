pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    implicitHeight: col.implicitHeight + 16

    readonly property color colLayer0Base: Appearance.colors.colLayer0Base ?? Appearance.colors.colLayer0

    readonly property var widgetList: [
        { key: "clock",       icon: "schedule",           name: Translation.tr("Clock") },
        { key: "calendar",    icon: "calendar_month",     name: Translation.tr("Calendar") },
        { key: "weather",     icon: "partly_cloudy_day",  name: Translation.tr("Weather") },
        { key: "goals",       icon: "flag",               name: Translation.tr("Goals & Notes") },
        { key: "media",       icon: "music_note",         name: Translation.tr("Media") },
        { key: "visualizer",  icon: "graphic_eq",         name: Translation.tr("Visualizer") },
        { key: "resources",   icon: "monitor_heart",      name: Translation.tr("Resources") },
        { key: "worldClock",  icon: "public",             name: Translation.tr("World Clock") },
        { key: "userCard",    icon: "person",             name: Translation.tr("User Card") },
        { key: "customImage", icon: "image",              name: Translation.tr("Custom Image") },
        { key: "images",      icon: "photo_library",      name: Translation.tr("Image Converter") },
    ]

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(root.colLayer0Base.r, root.colLayer0Base.g, root.colLayer0Base.b, 0.22)
        border.width: 0
        border.color: "transparent"

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 8 }
        spacing: 2

        ConfigSwitch {
            Layout.fillWidth: true
            buttonIcon: "lock"
            text: Translation.tr("Lock widget positions")
            checked: Config.options.background.widgetsLocked
            onCheckedChanged: Config.options.background.widgetsLocked = checked
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.4
        }

        Repeater {
            model: root.widgetList
            delegate: ConfigSwitch {
                required property var modelData
                Layout.fillWidth: true
                buttonIcon: modelData.icon
                text: modelData.name
                checked: Config.options.background.widgets[modelData.key].enable
                onCheckedChanged: Config.options.background.widgets[modelData.key].enable = checked
            }
        }
    }
}