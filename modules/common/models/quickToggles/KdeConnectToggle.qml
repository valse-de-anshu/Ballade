import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("KDE Connect")
    statusText: KdeConnect.connected ? (KdeConnect.deviceName || Translation.tr("Connected")) : Translation.tr("Disconnected")
    tooltipText: Translation.tr("KDE Connect: %1 | Alt-click to restart daemon").arg(statusText)
    icon: KdeConnect.connected ? "phonelink_ring" : "phonelink_off"

    available: true
    toggled: KdeConnect.connected
    mainAction: () => {
        KdeConnect.refresh()
        KdeConnect.openSettings()
    }
    hasMenu: false
    altAction: () => {
        KdeConnect.restartDaemon()
    }
}
