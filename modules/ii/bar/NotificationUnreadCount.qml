import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

MaterialSymbol {
    id: root
    readonly property bool showUnreadCount: Config.options.bar.indicators.notifications.showUnreadCount
    text: Notifications.silent ? "notifications_paused" : "notifications"
    iconSize: Appearance.font.pixelSize.larger
    color: rightSidebarButton.colText

    Rectangle {
        id: notifPing
        visible: !Notifications.silent && Notifications.unread > 0
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: root.showUnreadCount ? -4 : 1
            topMargin: root.showUnreadCount ? -4 : 3
        }
        color: Appearance.colors.colOnLayer0
        z: 1

        width: root.showUnreadCount ? Math.max(16, notificationCounterText.implicitWidth + 8) : 8
        height: root.showUnreadCount ? 16 : 8
        radius: height / 2

        StyledText {
            id: notificationCounterText
            visible: root.showUnreadCount
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colLayer0
            text: Notifications.unread > 99 ? "99+" : Notifications.unread
        }
    }
}
