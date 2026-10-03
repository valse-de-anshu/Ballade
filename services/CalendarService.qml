pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property string targetFilePath: Directories.calendarTargetPath
    readonly property string eventsFilePath: Directories.calendarEventsPath

    property var pinnedTargets: []
    property var userEvents: []
    property var metaPayload: ({})

    signal targetsChanged()
    signal eventsChanged()

    // ── Target Persistence (Pinned Items) ──
    FileView {
        id: targetFileView
        path: root.targetFilePath
        onLoaded: root.loadTargets()
        onLoadFailed: root.loadTargets()
    }

    // ── Events Persistence (User Notes / Events) ──
    FileView {
        id: eventsFileView
        path: root.eventsFilePath
        onLoaded: root.loadEvents()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                root.userEvents = []
                eventsFileView.setText(JSON.stringify([]))
            }
        }
    }

    function loadTargets() {
        try {
            if (targetFileView.loaded && targetFileView.text().trim().length > 0) {
                const parsed = JSON.parse(targetFileView.text())
                if (parsed && typeof parsed === "object") {
                    root.metaPayload = parsed
                    if (Array.isArray(parsed.targets)) {
                        root.pinnedTargets = parsed.targets
                        root.targetsChanged()
                        return
                    } else if (parsed.date) {
                        root.pinnedTargets = [{
                            date: parsed.date,
                            title: parsed.title || "",
                            type: parsed.type || "festival"
                        }]
                        root.targetsChanged()
                        return
                    }
                }
            }
        } catch (e) {}
        root.metaPayload = {}
        root.pinnedTargets = []
        root.targetsChanged()
    }

    function saveTargets() {
        let payload = Object.assign({}, root.metaPayload || {})
        payload.targets = (root.pinnedTargets || []).slice(0)
        delete payload.date
        delete payload.title
        delete payload.type
        root.metaPayload = payload
        targetFileView.setText(JSON.stringify(payload, null, 2))
    }

    function isEventPinned(dateKey, title) {
        if (!root.pinnedTargets || root.pinnedTargets.length === 0) return false
        let d = (dateKey || "").trim()
        let t = (title || "").trim()
        return root.pinnedTargets.some(item => {
            let itemD = (item.date || "").trim()
            let itemT = (item.title || "").trim()
            if (t.length > 0) {
                return itemD === d && itemT === t
            } else {
                return itemD === d
            }
        })
    }

    function pinTarget(dateKey, title, type) {
        let d = (dateKey || "").trim()
        let t = (title || "").trim()
        if (isEventPinned(d, t)) return
        let list = (root.pinnedTargets || []).slice(0)
        list.push({
            date: d,
            title: t,
            type: type || "festival"
        })
        root.pinnedTargets = list
        root.targetsChanged()
        saveTargets()
    }

    function unpinTarget(dateKey, title) {
        if (!root.pinnedTargets || root.pinnedTargets.length === 0) return
        let d = (dateKey || "").trim()
        let t = (title || "").trim()
        let list = root.pinnedTargets.filter(item => {
            let itemD = (item.date || "").trim()
            let itemT = (item.title || "").trim()
            if (t.length > 0) {
                return !(itemD === d && itemT === t)
            } else {
                return itemD !== d
            }
        })
        root.pinnedTargets = list
        root.targetsChanged()
        saveTargets()
    }

    function clearTargets() {
        root.pinnedTargets = []
        root.targetsChanged()
        saveTargets()
    }

    function loadEvents() {
        try {
            if (eventsFileView.loaded && eventsFileView.text().trim().length > 0) {
                const parsed = JSON.parse(eventsFileView.text())
                if (Array.isArray(parsed)) {
                    root.userEvents = parsed
                    root.eventsChanged()
                    return
                }
            }
        } catch (e) {}
        root.userEvents = []
        root.eventsChanged()
    }

    function saveEvents() {
        eventsFileView.setText(JSON.stringify(root.userEvents, null, 2))
    }

    function addEvent(dateKey, text) {
        if (!text || text.trim().length === 0) return
        const item = {
            id: Date.now().toString() + "-" + Math.floor(Math.random() * 10000),
            date: dateKey,
            text: text.trim(),
            createdAt: Date.now()
        }
        let updated = (root.userEvents || []).slice(0)
        updated.push(item)
        root.userEvents = updated
        root.eventsChanged()
        saveEvents()
    }

    function deleteEvent(id) {
        let updated = (root.userEvents || []).filter(e => e.id !== id)
        root.userEvents = updated
        root.eventsChanged()
        saveEvents()
    }

    function getEventsForDate(dateKey) {
        return (root.userEvents || []).filter(e => e.date === dateKey)
    }

    function hasUserEventOnDate(dateKey) {
        return (root.userEvents || []).some(e => e.date === dateKey)
    }
}
