pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Service to manage system idle and sleep inhibition.
 */
Singleton {
    id: root

    property bool inhibit: true

    function load() {}

    function syncFromPersistent() {
        if (!Persistent.ready) return;
        if (!Persistent.isNewHyprlandInstance) {
            root.inhibit = Persistent.states.idle.inhibit ?? true;
        } else {
            root.inhibit = true;
            Persistent.states.idle.inhibit = true;
        }
    }

    Component.onCompleted: {
        syncFromPersistent();
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            root.syncFromPersistent();
        }
    }

    onInhibitChanged: {
        if (Persistent.ready) {
            Persistent.states.idle.inhibit = root.inhibit;
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        if (Persistent.ready) {
            Persistent.states.idle.inhibit = root.inhibit;
        }
    }

    // System-level inhibitor via systemd-inhibit.
    // Blocks idle timeouts in hypridle and prevents automatic sleep/suspend on battery or AC.
    Process {
        id: systemdInhibitProcess
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=ballade", "--why=Keep system awake", "sleep", "infinity"]
        running: root.inhibit
        onExited: (exitCode, exitStatus) => {
            if (root.inhibit) {
                systemdInhibitProcess.running = true;
            }
        }
    }

    // Wayland protocol inhibitor fallback
    IdleInhibitor {
        id: idleInhibitor
        enabled: root.inhibit
        window: PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region {
                item: null
            }
        }
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            root.toggleInhibit();
        }

        function setInhibit(active: bool): void {
            root.toggleInhibit(active);
        }
    }
}
