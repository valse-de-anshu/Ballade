import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: bellIcon.implicitWidth
    implicitHeight: bellIcon.implicitHeight

    MaterialSymbol {
        id: bellIcon
        anchors.centerIn: parent
        text: Notifications.silent ? "notifications_paused" : "notifications"
        iconSize: Appearance.font.pixelSize.larger
        color: rightSidebarButton.colText
    }

    Rectangle {
        id: notifDot
        visible: !Notifications.silent && Notifications.unread > 0
        z: 2

        anchors {
            top: bellIcon.top
            topMargin: 2
            right: bellIcon.right
            rightMargin: 1
        }

        width: 6
        height: 6
        radius: 3

        color: Appearance.colors.colPrimary
        border.width: 1
        border.color: Appearance.colors.colLayer0Base || "#141313"
    }
}
