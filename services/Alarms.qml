pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Global Alarms Manager Singleton Service.
 * Manages daily recurring alarms, future date alarms, snoozing, and audio/notification ringing.
 */
Singleton {
    id: root

    property var filePath: Directories.config + "/alarms.json"
    property var alarmsList: []
    property var activeRingingAlarm: null
    property string lastTriggeredMinute: ""
    property string lastWarnedMinute: ""
    property bool isRinging: false

    function save() {
        alarmsFileView.setText(JSON.stringify({ alarms: root.alarmsList }, null, 2))
    }

    function addAlarm(timeStr, label, repeatDays, dateStr) {
        if (!timeStr || !timeStr.trim()) return
        let item = {
            id: "alm-" + Date.now() + "-" + Math.floor(Math.random() * 1000),
            time: timeStr.trim(),
            label: (label && label.trim()) ? label.trim() : "Alarm",
            enabled: true,
            repeatDays: Array.isArray(repeatDays) ? repeatDays : [],
            date: dateStr ? dateStr.trim() : "",
            isFuture: Boolean(dateStr && dateStr.trim())
        }
        let list = root.alarmsList.slice()
        list.push(item)
        root.alarmsList = list
        save()
    }

    function updateAlarm(alarmId, timeStr, label, repeatDays, dateStr) {
        if (!timeStr || !timeStr.trim()) return
        let list = root.alarmsList.slice()
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alarmId) {
                list[i] = Object.assign({}, list[i], {
                    time: timeStr.trim(),
                    label: (label && label.trim()) ? label.trim() : (list[i].label || "Alarm"),
                    repeatDays: Array.isArray(repeatDays) ? repeatDays : (list[i].repeatDays || []),
                    date: (dateStr !== undefined) ? dateStr.trim() : (list[i].date || ""),
                    isFuture: Boolean(dateStr && dateStr.trim()),
                    enabled: true
                })
                break
            }
        }
        root.alarmsList = list
        save()
    }

    function toggleAlarm(alarmId) {
        let list = root.alarmsList.slice()
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alarmId) {
                list[i] = Object.assign({}, list[i], { enabled: !list[i].enabled })
                break
            }
        }
        root.alarmsList = list
        save()
    }

    function deleteAlarm(alarmId) {
        root.alarmsList = root.alarmsList.filter(a => a.id !== alarmId)
        save()
    }

    function snoozeActiveAlarm() {
        let alm = root.activeRingingAlarm
        if (!alm) return
        let minutes = 5
        let d = new Date(Date.now() + minutes * 60 * 1000)
        let hh = String(d.getHours()).padStart(2, "0")
        let mm = String(d.getMinutes()).padStart(2, "0")
        let snoozeTime = hh + ":" + mm

        let list = root.alarmsList.slice()
        let found = false
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alm.id) {
                list[i] = Object.assign({}, list[i], { time: snoozeTime, enabled: true })
                found = true
                break
            }
        }
        // If one-time alarm already disabled, re-add as snoozed
        if (!found) {
            list.push(Object.assign({}, alm, { time: snoozeTime, enabled: true }))
        }
        root.alarmsList = list
        save()

        Quickshell.execDetached(["notify-send",
            "💤 Snoozed",
            "'" + alm.label + "' will ring again at " + snoozeTime,
            "-a", "Shell"])

        stopRinging()
    }

    function snoozeAlarm(alarmId, minutes) {
        minutes = minutes || 5
        let d = new Date(Date.now() + minutes * 60 * 1000)
        let hh = String(d.getHours()).padStart(2, "0")
        let mm = String(d.getMinutes()).padStart(2, "0")
        let snoozeTime = hh + ":" + mm

        let list = root.alarmsList.slice()
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alarmId) {
                list[i] = Object.assign({}, list[i], { time: snoozeTime, enabled: true })
                break
            }
        }
        root.alarmsList = list
        save()
        stopRinging()
    }

    function stopRinging() {
        root.isRinging = false
        root.activeRingingAlarm = null
        ringRepeatTimer.stop()
        Quickshell.execDetached(["bash", "-c", "killall -9 -q paplay pw-play mpv ffplay canberra-gtk-play 2>/dev/null"])
    }

    function dismissRinging() {
        stopRinging()
    }

    function checkAlarms() {
        let now = new Date()
        let currentHHMM = String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0")
        let currentDateStr = Qt.formatDate(now, "yyyy-MM-dd")
        let currentDayOfWeek = now.getDay()

        // ── 10-Minute Warning ──────────────────────────────────────
        let warn10 = new Date(now.getTime() + 10 * 60 * 1000)
        let warn10HHMM = String(warn10.getHours()).padStart(2, "0") + ":" + String(warn10.getMinutes()).padStart(2, "0")

        if (root.lastWarnedMinute !== warn10HHMM) {
            for (let j = 0; j < root.alarmsList.length; ++j) {
                let wa = root.alarmsList[j]
                if (!wa.enabled) continue
                if (wa.time !== warn10HHMM) continue
                if (wa.date && wa.date !== "" && wa.date !== currentDateStr) continue
                if (wa.repeatDays && wa.repeatDays.length > 0 && !wa.repeatDays.includes(currentDayOfWeek)) continue

                root.lastWarnedMinute = warn10HHMM
                Quickshell.execDetached(["notify-send",
                    "⏰ Alarm in 10 minutes",
                    "'" + wa.label + "' rings at " + wa.time,
                    "-a", "Shell"])
                break
            }
        }

        // ── Main Alarm Trigger ─────────────────────────────────────
        if (root.lastTriggeredMinute === currentHHMM) return

        for (let i = 0; i < root.alarmsList.length; ++i) {
            let alm = root.alarmsList[i]
            if (!alm.enabled) continue
            if (alm.time !== currentHHMM) continue
            if (alm.date && alm.date !== "" && alm.date !== currentDateStr) continue
            if (alm.repeatDays && alm.repeatDays.length > 0 && !alm.repeatDays.includes(currentDayOfWeek)) continue

            root.lastTriggeredMinute = currentHHMM
            root.activeRingingAlarm = alm
            root.isRinging = true

            // Standard notification
            Quickshell.execDetached(["notify-send",
                "⏰ " + alm.label,
                "Alarm is ringing! (" + alm.time + ")",
                "-a", "Shell"])

            root.playAlarmAudio()
            ringRepeatTimer.restart()

            // Disable one-time alarms after firing
            if (!alm.repeatDays || alm.repeatDays.length === 0) {
                toggleAlarm(alm.id)
            }
            break
        }
    }

    function playAlarmAudio() {
        if (Config.options.sounds.alarm === false) return
        let customPath = Config.options.sounds.alarmSoundPath
        let vol = Math.max(0, Math.min(100, Config.options.sounds.alarmVolume ?? 80))
        let soundPath = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

        Quickshell.execDetached([
            "bash",
            Directories.scriptPath + "/play-audio.sh",
            "--file", customPath,
            "--volume", vol.toString(),
            "--fallback", soundPath,
            "--category", "alarm"
        ])
    }

    // Repeat audio every 3.5 seconds while ringing (continuous scream)
    Timer {
        id: ringRepeatTimer
        interval: 3500
        running: false
        repeat: true
        onTriggered: {
            if (root.isRinging) {
                root.playAlarmAudio()
            } else {
                stop()
            }
        }
    }

    Timer {
        id: alarmCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.checkAlarms()
    }

    FileView {
        id: alarmsFileView
        path: root.filePath

        onLoaded: {
            try {
                let parsed = JSON.parse(text())
                if (parsed && Array.isArray(parsed.alarms)) {
                    root.alarmsList = parsed.alarms
                } else if (Array.isArray(parsed)) {
                    root.alarmsList = parsed
                } else {
                    root.alarmsList = []
                }
            } catch (e) {
                root.alarmsList = []
            }
        }

        onLoadFailed: {
            root.alarmsList = []
            save()
        }
    }
}
