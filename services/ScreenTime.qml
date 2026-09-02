pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

/**
 * Screen Time Tracking & Well-Being Manager Singleton.
 * Ultra-low resource active window tracker (3s sampling).
 * Persists and aggregates daily, weekly, monthly, and yearly screen time per application.
 */
Singleton {
    id: root

    // ── The daemon (screentime-daemon.py) owns all data writing.
    // QML is read-only: it reloads the JSON every 5 seconds.
    property string filePath: Directories.screentimePath
    property var screenTimeData: ({})
    property string todayDateStr: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property bool isLoaded: false

    function load() {
        console.log("[ScreenTime] Read-only mode — daemon handles tracking")
    }

    // Reactive midnight / date watcher
    Timer {
        id: midnightDateTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            let actualToday = Qt.formatDate(new Date(), "yyyy-MM-dd")
            if (root.todayDateStr !== actualToday) {
                root.todayDateStr = actualToday
            }
        }
    }

    // Reload data from daemon-written JSON every 5 seconds
    Timer {
        id: reloadTimer
        interval: 5000
        repeat: true
        running: root.isLoaded
        onTriggered: screenTimeFileView.reload()
    }

    // ── Prettified Name Mapping ──
    function formatAppName(appId) {
        if (!appId || !appId.trim()) return "Desktop"
        let lower = appId.toLowerCase().trim()
        if (lower.includes("zen")) return "Zen Browser"
        if (lower.includes("chrome")) return "Google Chrome"
        if (lower.includes("firefox")) return "Firefox"
        if (lower.includes("brave")) return "Brave Browser"
        if (lower.includes("code") || lower.includes("vscodium")) return "VS Code"
        if (lower.includes("kitty")) return "Kitty Terminal"
        if (lower.includes("foot")) return "Foot Terminal"
        if (lower.includes("alacritty")) return "Alacritty"
        if (lower.includes("obsidian")) return "Obsidian"
        if (lower.includes("joplin")) return "Joplin Notes"
        if (lower.includes("spotify")) return "Spotify"
        if (lower.includes("discord") || lower.includes("vesktop")) return "Discord"
        if (lower.includes("telegram")) return "Telegram"
        if (lower.includes("nautilus") || lower.includes("thunar") || lower.includes("dolphin")) return "Files"
        if (lower.includes("mpv") || lower.includes("vlc")) return "Media Player"
        if (lower.includes("gwenview")) return "Image Viewer"
        if (lower.includes("okular")) return "Document Viewer"
        if (lower.includes("libreoffice") || lower.includes("soffice")) return "LibreOffice"
        if (lower.includes("onlyoffice")) return "ONLYOFFICE"
        if (lower.includes("gimp") || lower.includes("inkscape") || lower.includes("krita")) return "Creative Suite"
        if (lower.includes("steam")) return "Steam"
        if (lower.includes("quickshell") || lower.includes("ballade")) return "System Shell"

        // Strip reverse DNS if any (e.g. org.gnome.Calculator -> Calculator)
        let parts = appId.split(".")
        let last = parts[parts.length - 1]
        return last.charAt(0).toUpperCase() + last.slice(1)
    }

    function formatAppIcon(appId) {
        if (!appId || !appId.trim()) return "desktop_windows"
        let lower = appId.toLowerCase().trim()
        if (lower.includes("zen") || lower.includes("chrome") || lower.includes("firefox") || lower.includes("brave") || lower.includes("browser")) return "language"
        if (lower.includes("code") || lower.includes("dev")) return "code"
        if (lower.includes("terminal") || lower.includes("kitty") || lower.includes("foot") || lower.includes("alacritty")) return "terminal"
        if (lower.includes("obsidian") || lower.includes("joplin") || lower.includes("notes")) return "description"
        if (lower.includes("spotify") || lower.includes("music")) return "music_note"
        if (lower.includes("discord") || lower.includes("telegram") || lower.includes("chat")) return "chat"
        if (lower.includes("files") || lower.includes("nautilus") || lower.includes("thunar") || lower.includes("dolphin")) return "folder"
        if (lower.includes("mpv") || lower.includes("vlc") || lower.includes("video")) return "movie"
        if (lower.includes("gwenview") || lower.includes("image")) return "image"
        if (lower.includes("okular") || lower.includes("pdf") || lower.includes("document") || lower.includes("office") || lower.includes("soffice")) return "menu_book"
        if (lower.includes("settings") || lower.includes("control")) return "settings"
        return "apps"
    }

    function formatHoursMinutes(sec) {
        if (!sec || sec <= 0) return "0s"
        let h = Math.floor(sec / 3600)
        let m = Math.floor((sec % 3600) / 60)
        let s = sec % 60
        if (h > 0 && m > 0) return `${h}h ${m}m`
        if (h > 0) return `${h}h`
        if (m > 0) return `${m}m`
        return `${s}s`
    }

    function formatShortDuration(sec) {
        if (!sec || sec <= 0) return "0s"
        let h = Math.floor(sec / 3600)
        let m = Math.floor((sec % 3600) / 60)
        let s = sec % 60
        if (h > 0 && m > 0) return `${h}h ${m}m`
        if (h > 0) return `${h}h`
        if (m > 0 && s > 0) return `${m}m ${s}s`
        if (m > 0) return `${m}m`
        return `${s}s`
    }

    // ── Helper functions for multi-day aggregation ──
    function parseDateString(str) {
        if (!str || typeof str !== "string") return new Date()
        let parts = str.split("-")
        if (parts.length === 3) {
            return new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10))
        }
        return new Date()
    }

    function mergeDayAppsIntoAggregate(aggMap, dayApps) {
        if (!Array.isArray(dayApps)) return
        for (let a of dayApps) {
            if (!aggMap[a.appId]) {
                let titlesMap = {}
                if (Array.isArray(a.titles)) {
                    for (let t of a.titles) {
                        titlesMap[t.title] = (titlesMap[t.title] || 0) + (t.seconds || 0)
                    }
                }
                aggMap[a.appId] = {
                    appId: a.appId,
                    name: a.name || root.formatAppName(a.appId),
                    icon: a.icon || root.formatAppIcon(a.appId),
                    seconds: a.seconds || 0,
                    titlesMap: titlesMap
                }
            } else {
                aggMap[a.appId].seconds += (a.seconds || 0)
                if (Array.isArray(a.titles)) {
                    for (let t of a.titles) {
                        aggMap[a.appId].titlesMap[t.title] = (aggMap[a.appId].titlesMap[t.title] || 0) + (t.seconds || 0)
                    }
                }
            }
        }
    }

    function buildAggregatedAppsList(aggMap, totalSec) {
        let appsList = []
        for (let id in aggMap) {
            let item = aggMap[id]
            let pct = totalSec > 0 ? Math.round((item.seconds / totalSec) * 100) : 0
            let titlesArr = []
            if (item.titlesMap) {
                for (let t in item.titlesMap) {
                    titlesArr.push({ title: t, seconds: item.titlesMap[t] || 0 })
                }
                titlesArr.sort((a, b) => b.seconds - a.seconds)
            }
            appsList.push({
                appId: item.appId,
                name: item.name,
                icon: item.icon,
                seconds: item.seconds,
                percent: pct,
                titles: titlesArr
            })
        }
        appsList.sort((a, b) => b.seconds - a.seconds)
        return appsList
    }

    // ── Data Query & Aggregation API ──

    // 1. Daily Stats for given YYYY-MM-DD
    function getDailyStats(dateStr) {
        let emptyHourly = []
        for (let h = 0; h < 24; ++h) {
            emptyHourly.push({ hour: h, label: (h < 10 ? "0" + h : "" + h), seconds: 0, percentOfMax: 0 })
        }

        if (!dateStr || !root.screenTimeData[dateStr]) {
            return {
                dateStr: dateStr || root.todayDateStr,
                totalSeconds: 0,
                hourly: emptyHourly,
                hourlyRaw: new Array(24).fill(0),
                apps: [],
                maxHourSeconds: 0
            }
        }

        let dayRecord = root.screenTimeData[dateStr]
        let total = dayRecord.totalSeconds || 0
        let hourlyRaw = (Array.isArray(dayRecord.hourly) && dayRecord.hourly.length === 24) ? dayRecord.hourly : new Array(24).fill(0)
        let maxHour = Math.max(...hourlyRaw, 1)

        let hourlyStructured = []
        for (let h = 0; h < 24; ++h) {
            let sec = hourlyRaw[h] || 0
            hourlyStructured.push({
                hour: h,
                label: (h < 10 ? "0" + h : "" + h),
                seconds: sec,
                percentOfMax: total > 0 ? Math.round((sec / maxHour) * 100) : 0
            })
        }

        let appsList = []
        let appsObj = dayRecord.apps || {}
        for (let appId in appsObj) {
            let item = appsObj[appId]
            let sec = item.seconds || 0
            let pct = total > 0 ? Math.round((sec / total) * 100) : 0
            let titlesArr = []
            if (item.titles && typeof item.titles === "object") {
                for (let t in item.titles) {
                    titlesArr.push({ title: t, seconds: item.titles[t] || 0 })
                }
                titlesArr.sort((a, b) => b.seconds - a.seconds)
            }
            appsList.push({
                appId: appId,
                name: item.name || root.formatAppName(appId),
                icon: item.icon || root.formatAppIcon(appId),
                seconds: sec,
                percent: pct,
                titles: titlesArr
            })
        }
        appsList.sort((a, b) => b.seconds - a.seconds)

        return {
            dateStr: dateStr,
            totalSeconds: total,
            hourly: hourlyStructured,
            hourlyRaw: hourlyRaw,
            apps: appsList,
            maxHourSeconds: maxHour
        }
    }

    // 2. Weekly Stats for the week containing `targetDate`
    function getWeeklyStats(targetDate) {
        let d = (targetDate instanceof Date) ? new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()) : root.parseDateString(targetDate)
        let dayOfWeek = d.getDay() // 0=Sun, 1=Mon, ..., 6=Sat
        let diffToMonday = (dayOfWeek === 0 ? -6 : 1 - dayOfWeek) // Mon start
        let monday = new Date(d.getFullYear(), d.getMonth(), d.getDate() + diffToMonday)

        let days = []
        let totalWeekSeconds = 0
        let aggregatedApps = {}
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let rawDaySecs = []

        for (let i = 0; i < 7; ++i) {
            let cur = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i)
            let m = cur.getMonth() + 1
            let day = cur.getDate()
            let mm = m < 10 ? "0" + m : "" + m
            let dd = day < 10 ? "0" + day : "" + day
            let curStr = cur.getFullYear() + "-" + mm + "-" + dd

            let dayStat = root.getDailyStats(curStr)
            totalWeekSeconds += dayStat.totalSeconds
            rawDaySecs.push(dayStat.totalSeconds)

            days.push({
                label: dayLabels[i],
                dateStr: curStr,
                dayNum: day,
                seconds: dayStat.totalSeconds,
                isToday: (curStr === root.todayDateStr)
            })

            root.mergeDayAppsIntoAggregate(aggregatedApps, dayStat.apps)
        }

        let maxDaySec = Math.max(...rawDaySecs, 1)
        for (let item of days) {
            item.percentOfMax = totalWeekSeconds > 0 ? Math.round((item.seconds / maxDaySec) * 100) : 0
        }

        let appsList = root.buildAggregatedAppsList(aggregatedApps, totalWeekSeconds)
        let activeDays = days.filter(d => d.seconds > 0).length || 1

        return {
            totalSeconds: totalWeekSeconds,
            days: days,
            apps: appsList,
            averageDaily: Math.round(totalWeekSeconds / activeDays),
            maxDaySeconds: maxDaySec,
            startDateStr: days[0].dateStr,
            endDateStr: days[6].dateStr
        }
    }

    // 3. Monthly Stats for Year & Month (month is 0..11)
    function getMonthlyStats(year, month) {
        let mNum = month + 1
        let prefix = year + "-" + (mNum < 10 ? "0" + mNum : "" + mNum) + "-"
        let totalMonthSeconds = 0
        let aggregatedApps = {}
        let daysInMonth = new Date(year, month + 1, 0).getDate()
        let days = []
        let rawDaySecs = []

        for (let day = 1; day <= daysInMonth; ++day) {
            let dd = day < 10 ? "0" + day : "" + day
            let dateStr = prefix + dd
            let dayData = root.screenTimeData[dateStr]
            let daySec = dayData ? (dayData.totalSeconds || 0) : 0
            totalMonthSeconds += daySec
            rawDaySecs.push(daySec)

            days.push({
                dayNum: day,
                label: "" + day,
                dateStr: dateStr,
                seconds: daySec,
                isToday: (dateStr === root.todayDateStr)
            })

            if (dayData && dayData.apps) {
                for (let appId in dayData.apps) {
                    let appInfo = dayData.apps[appId]
                    if (!aggregatedApps[appId]) {
                        let titlesMap = Object.assign({}, appInfo.titles || {})
                        aggregatedApps[appId] = {
                            appId: appId,
                            name: appInfo.name || root.formatAppName(appId),
                            icon: appInfo.icon || root.formatAppIcon(appId),
                            seconds: appInfo.seconds || 0,
                            titlesMap: titlesMap
                        }
                    } else {
                        aggregatedApps[appId].seconds += (appInfo.seconds || 0)
                        if (appInfo.titles) {
                            for (let t in appInfo.titles) {
                                aggregatedApps[appId].titlesMap[t] = (aggregatedApps[appId].titlesMap[t] || 0) + (appInfo.titles[t] || 0)
                            }
                        }
                    }
                }
            }
        }

        let maxDaySec = Math.max(...rawDaySecs, 1)
        for (let item of days) {
            item.percentOfMax = totalMonthSeconds > 0 ? Math.round((item.seconds / maxDaySec) * 100) : 0
        }

        let appsList = root.buildAggregatedAppsList(aggregatedApps, totalMonthSeconds)
        let activeDays = days.filter(d => d.seconds > 0).length || 1

        return {
            totalSeconds: totalMonthSeconds,
            days: days,
            apps: appsList,
            averageDaily: Math.round(totalMonthSeconds / activeDays),
            maxDaySeconds: maxDaySec
        }
    }

    // 4. Yearly Stats for Year
    function getYearlyStats(year) {
        let yearPrefix = year + "-"
        let totalYearSeconds = 0
        let aggregatedApps = {}
        let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let months = []
        let rawMonthSecs = new Array(12).fill(0)

        let now = new Date()
        let currentYear = now.getFullYear()
        let currentMonth = now.getMonth()

        for (let dateKey in root.screenTimeData) {
            if (dateKey.indexOf(yearPrefix) === 0) {
                let parts = dateKey.split("-")
                let mIdx = parseInt(parts[1], 10) - 1 // 0..11
                let dayData = root.screenTimeData[dateKey]
                let daySec = dayData ? (dayData.totalSeconds || 0) : 0
                totalYearSeconds += daySec
                if (mIdx >= 0 && mIdx < 12) {
                    rawMonthSecs[mIdx] += daySec
                }

                if (dayData && dayData.apps) {
                    for (let appId in dayData.apps) {
                        let appInfo = dayData.apps[appId]
                        if (!aggregatedApps[appId]) {
                            let titlesMap = Object.assign({}, appInfo.titles || {})
                            aggregatedApps[appId] = {
                                appId: appId,
                                name: appInfo.name || root.formatAppName(appId),
                                icon: appInfo.icon || root.formatAppIcon(appId),
                                seconds: appInfo.seconds || 0,
                                titlesMap: titlesMap
                            }
                        } else {
                            aggregatedApps[appId].seconds += (appInfo.seconds || 0)
                            if (appInfo.titles) {
                                for (let t in appInfo.titles) {
                                    aggregatedApps[appId].titlesMap[t] = (aggregatedApps[appId].titlesMap[t] || 0) + (appInfo.titles[t] || 0)
                                }
                            }
                        }
                    }
                }
            }
        }

        let maxMonthSec = Math.max(...rawMonthSecs, 1)
        for (let m = 0; m < 12; ++m) {
            let mSec = rawMonthSecs[m] || 0
            months.push({
                label: monthLabels[m],
                monthIndex: m,
                seconds: mSec,
                percentOfMax: totalYearSeconds > 0 ? Math.round((mSec / maxMonthSec) * 100) : 0,
                isCurrentMonth: (year === currentYear && m === currentMonth)
            })
        }

        let appsList = root.buildAggregatedAppsList(aggregatedApps, totalYearSeconds)
        let activeMonths = months.filter(m => m.seconds > 0).length || 1
        let activeDaysCount = 0
        for (let dateKey in root.screenTimeData) {
            if (dateKey.indexOf(yearPrefix) === 0 && (root.screenTimeData[dateKey]?.totalSeconds > 0)) {
                activeDaysCount++
            }
        }
        activeDaysCount = Math.max(1, activeDaysCount)

        return {
            totalSeconds: totalYearSeconds,
            months: months,
            apps: appsList,
            averageDaily: Math.round(totalYearSeconds / activeDaysCount),
            averageMonthly: Math.round(totalYearSeconds / activeMonths),
            maxMonthSeconds: maxMonthSec
        }
    }

    // ── Persistence FileView ──
    FileView {
        id: screenTimeFileView
        path: root.filePath
        onLoaded: {
            try {
                const parsed = JSON.parse(screenTimeFileView.text())
                if (parsed && typeof parsed === "object") {
                    root.screenTimeData = parsed
                }
            } catch (e) {
                root.screenTimeData = {}
            }
            root.isLoaded = true
        }
        onLoadFailed: error => {
            // Daemon will create the file; just mark as loaded and let reloadTimer retry
            root.isLoaded = true
        }
    }
}
