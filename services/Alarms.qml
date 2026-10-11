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
    property string currentMinute: ""
    property bool isRinging: false

    function formatAlarmTime(t24) {
        if (!t24) return ""
        let parts = t24.split(":")
        if (parts.length < 2) return t24
        let h = parseInt(parts[0], 10)
        let m = parts[1]
        let ampm = (h >= 12) ? "PM" : "AM"
        let h12 = (h % 12 === 0) ? 12 : (h % 12)
        return `${h12}:${m} ${ampm}`
    }

    function getAlarmNextDate(timeStr, repeatDays, dateStr) {
        if (!timeStr) return null
        let parts = timeStr.trim().split(":")
        let targetH = parseInt(parts[0], 10)
        let targetM = parseInt(parts[1], 10)
        if (isNaN(targetH) || isNaN(targetM)) return null

        let now = new Date()

        // Specific future date
        if (dateStr && dateStr.trim()) {
            let dParts = dateStr.trim().split("-")
            if (dParts.length === 3) {
                let y = parseInt(dParts[0], 10)
                let m = parseInt(dParts[1], 10) - 1
                let d = parseInt(dParts[2], 10)
                return new Date(y, m, d, targetH, targetM, 0, 0)
            }
        }

        // Recurring days (0=Sunday, 1..6=Monday..Saturday)
        if (Array.isArray(repeatDays) && repeatDays.length > 0) {
            for (let offset = 0; offset <= 7; ++offset) {
                let candDay = (now.getDay() + offset) % 7
                if (repeatDays.includes(candDay)) {
                    let cand = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset, targetH, targetM, 0, 0)
                    if (cand.getTime() > now.getTime()) {
                        return cand
                    }
                }
            }
        }

        // One-time alarm without specific date: today if later, else tomorrow
        let todayCand = new Date(now.getFullYear(), now.getMonth(), now.getDate(), targetH, targetM, 0, 0)
        if (todayCand.getTime() > now.getTime()) {
            return todayCand
        }
        return new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, targetH, targetM, 0, 0)
    }

    function formatRemainingTime(targetDate) {
        if (!targetDate) return ""
        let now = new Date()
        let diffMs = targetDate.getTime() - now.getTime()
        if (diffMs <= 0) return "less than a minute"

        let totalMinutes = Math.round(diffMs / 60000)
        if (totalMinutes < 1) return "less than a minute"

        let days = Math.floor(totalMinutes / (24 * 60))
        let hours = Math.floor((totalMinutes % (24 * 60)) / 60)
        let minutes = totalMinutes % 60

        let parts = []
        if (days > 0) parts.push(days + (days === 1 ? " day" : " days"))
        if (hours > 0) parts.push(hours + (hours === 1 ? " hour" : " hours"))
        if (minutes > 0 || (days === 0 && hours === 0)) parts.push(minutes + (minutes === 1 ? " minute" : " minutes"))

        if (parts.length === 1) return parts[0]
        if (parts.length === 2) return parts[0] + " and " + parts[1]
        return parts[0] + ", " + parts[1] + " and " + parts[2]
    }

    function notifyAlarmScheduled(alm) {
        if (!alm || !alm.time) return
        let nextDate = getAlarmNextDate(alm.time, alm.repeatDays, alm.date)
        let remainingStr = formatRemainingTime(nextDate)
        let formattedTime = formatAlarmTime(alm.time)
        let label = (alm.label && alm.label.trim()) ? alm.label.trim() : "Alarm"

        let title = "⏰ Alarm Set (" + formattedTime + ")"
        let body = "'" + label + "' will ring in " + remainingStr + "."

        Quickshell.execDetached([
            "notify-send",
            title,
            body,
            "-a", "Shell",
            "--hint=int:transient:1"
        ])
    }

    function save() {
        alarmsFileView.setText(JSON.stringify({ alarms: root.alarmsList }, null, 2))
    }

    function addAlarm(timeStr, label, repeatDays, dateStr) {
        if (!timeStr || !timeStr.trim()) return
        let defaultAllWeek = [0, 1, 2, 3, 4, 5, 6]
        let days = Array.isArray(repeatDays) ? repeatDays : defaultAllWeek
        let item = {
            id: "alm-" + Date.now() + "-" + Math.floor(Math.random() * 1000),
            time: timeStr.trim(),
            label: (label && label.trim()) ? label.trim() : "Alarm",
            enabled: true,
            repeatDays: days,
            date: dateStr ? dateStr.trim() : "",
            isFuture: Boolean(dateStr && dateStr.trim())
        }
        let list = root.alarmsList.slice()
        list.push(item)
        root.alarmsList = list
        save()
        notifyAlarmScheduled(item)
    }

    function updateAlarm(alarmId, timeStr, label, repeatDays, dateStr) {
        if (!timeStr || !timeStr.trim()) return
        let list = root.alarmsList.slice()
        let updatedItem = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alarmId) {
                list[i] = Object.assign({}, list[i], {
                    time: timeStr.trim(),
                    label: (label && label.trim()) ? label.trim() : (list[i].label || "Alarm"),
                    repeatDays: Array.isArray(repeatDays) ? repeatDays : (list[i].repeatDays || [0, 1, 2, 3, 4, 5, 6]),
                    date: (dateStr !== undefined) ? dateStr.trim() : (list[i].date || ""),
                    isFuture: Boolean(dateStr && dateStr.trim()),
                    enabled: true
                })
                updatedItem = list[i]
                break
            }
        }
        root.alarmsList = list
        save()
        if (updatedItem) {
            notifyAlarmScheduled(updatedItem)
        }
    }

    function toggleAlarm(alarmId) {
        let list = root.alarmsList.slice()
        let toggledItem = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === alarmId) {
                list[i] = Object.assign({}, list[i], { enabled: !list[i].enabled })
                toggledItem = list[i]
                break
            }
        }
        root.alarmsList = list
        save()
        if (toggledItem) {
            if (toggledItem.enabled) {
                notifyAlarmScheduled(toggledItem)
            } else {
                Quickshell.execDetached([
                    "notify-send",
                    "⏰ Alarm Disabled",
                    "'" + toggledItem.label + "' (" + formatAlarmTime(toggledItem.time) + ") turned off",
                    "-a", "Shell",
                    "--hint=int:transient:1"
                ])
            }
        }
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
        if (root.currentMinute !== currentHHMM) {
            root.currentMinute = currentHHMM
        }
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
