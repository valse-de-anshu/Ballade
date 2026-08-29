pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Global Goals Manager Singleton.
 * Manages daily, weekly, monthly, yearly, and long-term goals with calendar scheduling.
 */
Singleton {
    id: root

    property var filePath: Directories.config + "/goals.json"
    property var goalsList: []

    function normalizeHorizon(hId) {
        if (!hId) return "daily"
        let lower = hId.toLowerCase().trim().replace(/[^a-z]/g, "")
        if (lower === "daily" || lower === "day") return "daily"
        if (lower === "weekly" || lower === "week") return "weekly"
        if (lower === "monthly" || lower === "month") return "monthly"
        if (lower === "yearly" || lower === "year") return "yearly"
        if (lower === "longterm" || lower === "long" || lower === "vision") return "longterm"
        if (lower === "todo" || lower === "task" || lower === "general") return "todo"
        return lower
    }

    function normalizeDateStr(str) {
        if (!str || !str.trim()) return ""
        str = str.trim()
        let dmy = str.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$/)
        if (dmy) {
            let d = parseInt(dmy[1]) < 10 ? "0" + parseInt(dmy[1]) : "" + parseInt(dmy[1])
            let m = parseInt(dmy[2]) < 10 ? "0" + parseInt(dmy[2]) : "" + parseInt(dmy[2])
            return dmy[3] + "-" + m + "-" + d
        }
        let ymd = str.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$/)
        if (ymd) {
            let m = parseInt(ymd[2]) < 10 ? "0" + parseInt(ymd[2]) : "" + parseInt(ymd[2])
            let d = parseInt(ymd[3]) < 10 ? "0" + parseInt(ymd[3]) : "" + parseInt(ymd[3])
            return ymd[1] + "-" + m + "-" + d
        }
        return str
    }

    function save() {
        goalsFileView.setText(JSON.stringify({ goals: root.goalsList }, null, 2))
    }

    function addGoal(title, horizon, calendarDate) {
        if (!title || !title.trim()) return
        let normalizedH = normalizeHorizon(horizon)
        let item = {
            id: "g-" + Date.now() + "-" + Math.floor(Math.random() * 1000),
            title: title.trim(),
            horizon: normalizedH,
            completed: false,
            calendarDate: calendarDate ? normalizeDateStr(calendarDate) : "",
            dueDate: calendarDate ? normalizeDateStr(calendarDate) : "",
            createdAt: Date.now(),
            completedAt: null
        }
        root.goalsList = [item, ...root.goalsList]
        save()
        return item.id
    }

    function toggleGoal(id) {
        root.goalsList = root.goalsList.map(g => {
            if (g.id === id) {
                let next = !g.completed
                return Object.assign({}, g, { completed: next, completedAt: next ? Date.now() : null })
            }
            return g
        })
        save()
    }

    function setGoalCalendarDate(id, rawDateStr) {
        let formatted = normalizeDateStr(rawDateStr)
        root.goalsList = root.goalsList.map(g => {
            if (g.id === id) {
                return Object.assign({}, g, { calendarDate: formatted, dueDate: formatted })
            }
            return g
        })
        save()
    }

    function removeGoalCalendarDate(id) {
        root.goalsList = root.goalsList.map(g => {
            if (g.id === id) {
                return Object.assign({}, g, { calendarDate: "", dueDate: "" })
            }
            return g
        })
        save()
    }

    function deleteGoal(id) {
        root.goalsList = root.goalsList.filter(g => g.id !== id)
        save()
    }

    function getStats(hId) {
        let norm = normalizeHorizon(hId)
        let list = (hId === "all") ? root.goalsList : root.goalsList.filter(g => normalizeHorizon(g.horizon) === norm)
        let done = list.filter(g => g.completed).length
        return { total: list.length, done: done, percent: list.length > 0 ? Math.round(done / list.length * 100) : 0 }
    }

    function refresh() {
        goalsFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: goalsFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                const parsed = JSON.parse(goalsFileView.text())
                if (parsed && Array.isArray(parsed.goals)) {
                    root.goalsList = parsed.goals
                }
            } catch (e) {
                console.log("[Goals] Error parsing file: " + e)
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.goalsList = []
                save()
            }
        }
    }
}
