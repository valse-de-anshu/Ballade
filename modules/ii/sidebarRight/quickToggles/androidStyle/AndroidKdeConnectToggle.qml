import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root
    
    toggleModel: KdeConnectToggle {}

    onClicked: {
        KdeConnect.refresh()
        KdeConnect.openSettings()
    }

    onSecondaryClicked: {
        KdeConnect.restartDaemon()
    }
}
