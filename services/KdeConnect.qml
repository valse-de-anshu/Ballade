pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property bool available: true
    property bool connected: false
    property string deviceName: ""
    property string deviceId: ""
    property string deviceIp: ""
    property string statusText: Translation.tr("Disconnected")

    property list<var> devices: []

    function refresh() {
        if (!statusProcess.running) {
            statusProcess.running = true;
        }
    }

    function restartDaemon() {
        Quickshell.execDetached(["bash", "-c", `
            killall -9 kdeconnectd kdeconnect-indicator 2>/dev/null
            sleep 0.5
            if [ -x /usr/lib/kdeconnectd ]; then
                /usr/lib/kdeconnectd &
            elif [ -x /usr/libexec/kdeconnectd ]; then
                /usr/libexec/kdeconnectd &
            else
                kdeconnectd &
            fi
            sleep 1
            kdeconnect-cli --refresh
            notify-send "KDE Connect" "KDE Connect daemon restarted" -a "KDE Connect" -i kdeconnect
        `]);
        refreshTimer.restart();
    }

    function ringPhone() {
        if (root.deviceId) {
            Quickshell.execDetached(["kdeconnect-cli", "-d", root.deviceId, "--ring"]);
        } else {
            Quickshell.execDetached(["kdeconnect-cli", "--ring"]);
        }
    }

    function pingPhone() {
        if (root.deviceId) {
            Quickshell.execDetached(["kdeconnect-cli", "-d", root.deviceId, "--ping"]);
        } else {
            Quickshell.execDetached(["kdeconnect-cli", "--ping"]);
        }
    }

    function openSettings() {
        Quickshell.execDetached(["bash", "-c", "kdeconnect-app || kdeconnect-settings || kcmshell6 kcm_kdeconnect || kcmshell5 kcm_kdeconnect &"]);
    }

    Process {
        id: statusProcess
        command: ["bash", "-c", "kdeconnect-cli -l 2>/dev/null"]
        stdout: StdioCollector {
            onDataChanged: {
                let out = text.trim();
                if (!out || out.length === 0) {
                    root.connected = false;
                    root.deviceName = "";
                    root.deviceId = "";
                    root.statusText = Translation.tr("No devices found");
                    return;
                }

                // Format: - Galaxy A21s: 91e7cae684c5496d967d601409c78baa on 192.168.29.146 via LAN (paired and reachable)
                let lines = out.split("\n");
                let foundConnected = false;
                let devs = [];

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (!line.startsWith("-")) continue;
                    let match = line.match(/^-\s*([^:]+):\s*([a-f0-9]+)\s*(?:on\s*([^\s]+))?.*?\((.*?)\)/i);
                    if (match) {
                        let name = match[1].trim();
                        let id = match[2].trim();
                        let ip = match[3] ? match[3].trim() : "";
                        let state = match[4] ? match[4].trim() : "";
                        let isReachable = state.toLowerCase().includes("reachable");
                        let isPaired = state.toLowerCase().includes("paired");

                        devs.push({
                            name: name,
                            id: id,
                            ip: ip,
                            state: state,
                            reachable: isReachable,
                            paired: isPaired
                        });

                        if (isReachable && isPaired && !foundConnected) {
                            foundConnected = true;
                            root.connected = true;
                            root.deviceName = name;
                            root.deviceId = id;
                            root.deviceIp = ip;
                            root.statusText = name + " (Connected)";
                        }
                    }
                }

                root.devices = devs;
                if (!foundConnected) {
                    root.connected = false;
                    if (devs.length > 0) {
                        root.deviceName = devs[0].name;
                        root.deviceId = devs[0].id;
                        root.statusText = devs[0].name + " (" + devs[0].state + ")";
                    } else {
                        root.deviceName = "";
                        root.deviceId = "";
                        root.statusText = Translation.tr("Disconnected");
                    }
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 8000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
