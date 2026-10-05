pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 * Optimized with event-specific debouncing to prevent IPC bursts and frame drops during window open/close.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    // Debounced Internals

    Timer {
        id: debounceWindowTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (!getClients.running) getClients.running = true;
        }
    }

    Timer {
        id: debounceWorkspaceTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (!getWorkspaces.running) getWorkspaces.running = true;
            if (!getActiveWorkspace.running) getActiveWorkspace.running = true;
        }
    }

    function updateWindowList() {
        debounceWindowTimer.restart();
    }

    function updateLayers() {
        if (!getLayers.running) getLayers.running = true;
    }

    function updateMonitors() {
        if (!getMonitors.running) getMonitors.running = true;
    }

    function updateWorkspaces() {
        debounceWorkspaceTimer.restart();
    }

    function updateAll() {
        debounceWindowTimer.restart();
        debounceWorkspaceTimer.restart();
        updateMonitors();
        updateLayers();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const ev = event.name;
            // Ignore events that don't need any updates
            if (["openlayer", "closelayer", "screencast", "submap", "keybind", "mouse"].includes(ev)) return;

            // Window-specific events
            if (["openwindow", "closewindow", "movewindow", "windowtitle", "windowtitlev2", "activewindow", "activewindowv2", "fullscreen", "changefloatingmode", "pin"].includes(ev)) {
                debounceWindowTimer.restart();
                return;
            }

            // Workspace-specific events
            if (["workspace", "workspacev2", "focusedmon", "createworkspace", "destroyworkspace", "moveworkspace"].includes(ev)) {
                debounceWorkspaceTimer.restart();
                return;
            }

            // Monitor configuration events
            if (["monitoradded", "monitorremoved"].includes(ev)) {
                root.updateMonitors();
                return;
            }

            // General fallback
            debounceWindowTimer.restart();
            debounceWorkspaceTimer.restart();
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(clientsCollector.text);
                    let tempWinByAddress = {};
                    for (var i = 0; i < root.windowList.length; ++i) {
                        var win = root.windowList[i];
                        tempWinByAddress[win.address] = win;
                    }
                    root.windowByAddress = tempWinByAddress;
                    root.addresses = root.windowList.map(win => win.address);
                } catch (e) {
                    // Safe handling of transient JSON parse errors
                }
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(monitorsCollector.text);
                } catch (e) {
                    // Safe handling
                }
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                try {
                    root.layers = JSON.parse(layersCollector.text);
                } catch (e) {
                    // Safe handling
                }
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                try {
                    var rawWorkspaces = JSON.parse(workspacesCollector.text);
                    root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                    let tempWorkspaceById = {};
                    for (var i = 0; i < root.workspaces.length; ++i) {
                        var ws = root.workspaces[i];
                        tempWorkspaceById[ws.id] = ws;
                    }
                    root.workspaceById = tempWorkspaceById;
                    root.workspaceIds = root.workspaces.map(ws => ws.id);
                } catch (e) {
                    // Safe handling
                }
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                try {
                    root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
                } catch (e) {
                    // Safe handling
                }
            }
        }
    }
}
