import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.sidebarLeft.aiChat

AbstractBackgroundWidget {
    id: root
    configEntryName: "goals"
    hoverEnabled: true

    // ── Size Modes ──────────────────────────────────────
    property string sizeMode: configEntry?.sizeMode ?? "full"
    readonly property bool isCompact: sizeMode === "compact"

    implicitWidth: root.sectionMode === "wellbeing" ? 340 : 260
    implicitHeight: isCompact ? 250 : (root.sectionMode === "wellbeing" ? 540 : 500)

    Behavior on implicitWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    // ── Goal Data via Singleton Service ────────────────────
    readonly property var goalsList: Goals.goalsList
    property string expandedHorizon: "daily"
    property string compactHorizon: ""
    property bool isUserTyping: false
    property string schedulingGoalId: "" // Which goal has the calendar date picker open

    function updateDesktopKeyboardFocus() {
        GlobalStates.desktopWidgetKeyboardFocus = root.isUserTyping
            || (root.activeToolScreen === "alarm" && !root.alarmShowSavedList)
            || (root.activeToolScreen === "notes" && root.notesViewMode === "edit" && !root.notesShowPreview)
            || (root.activeToolScreen === "todo")
    }

    onIsUserTypingChanged: updateDesktopKeyboardFocus()
    onActiveToolScreenChanged: {
        updateDesktopKeyboardFocus()
        if (root.activeToolScreen === "alarm") {
            Qt.callLater(() => {
                if (wheelBox) wheelBox.forceActiveFocus()
            })
        } else if (root.activeToolScreen === "todo") {
            Qt.callLater(() => {
                if (todoTaskInput) todoTaskInput.forceActiveFocus()
            })
        }
        // Reset notes view when leaving notes screen
        if (root.activeToolScreen !== "notes") {
            root.notesViewMode = "list"
            root.notesEditingId = ""
            root.notesShowPreview = false
        }
    }
    onAlarmShowSavedListChanged: updateDesktopKeyboardFocus()
    onNotesViewModeChanged: updateDesktopKeyboardFocus()
    onNotesShowPreviewChanged: updateDesktopKeyboardFocus()

    // ── Mode: "goals" (Section 1) vs "general" (Section 2) ───
    property string sectionMode: "goals"
    property string activeToolScreen: "" // "" | "alarm" | "notes"

    // ── Alarm Wheel Picker State ──
    property int alarmPickerHour: 6
    property int alarmPickerMinute: 0
    property string alarmPickerAmPm: "am"
    property string alarmFocusedCol: "hours" // "hours" | "minutes" | "ampm"
    property var alarmSelectedDays: [0] // 0=Sunday
    property string alarmSpecificDate: ""
    property bool alarmShowSavedList: false
    property string editingAlarmId: ""

    // ── Notes Canvas State ──
    property string notesViewMode: "list"    // "list" | "edit"
    property string notesEditingId: ""       // ID of note being edited (empty = new)
    property bool notesShowPreview: false    // toggle edit ↔ rendered preview

    // ── Digital Well-Being & Screen Time State ──
    property string stHorizonFilter: "daily" // "daily" | "weekly" | "monthly" | "yearly"
    property string todayDateStr: (typeof DateTime !== "undefined" && DateTime.clock) ? Qt.formatDate(DateTime.clock.date, "yyyy-MM-dd") : Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string stSelectedDate: root.todayDateStr
    property int stSelectedYear: (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date.getFullYear() : new Date().getFullYear()
    property int stSelectedMonth: (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date.getMonth() : new Date().getMonth()
    property bool stShowDatePicker: false
    property string stHoveredBarInfo: ""
    property string stSelectedAppId: ""  // App tapped to view detail

    // ── To-Do Tool State ──
    property string todoFilter: "all" // "all" | "pending" | "done"

    Timer {
        id: goalsMidnightWatcher
        interval: 15000
        repeat: true
        running: true
        onTriggered: {
            let actualToday = (typeof DateTime !== "undefined" && DateTime.clock) ? Qt.formatDate(DateTime.clock.date, "yyyy-MM-dd") : Qt.formatDate(new Date(), "yyyy-MM-dd")
            if (root.todayDateStr !== actualToday) {
                let wasToday = (root.stSelectedDate === root.todayDateStr)
                root.todayDateStr = actualToday
                if (wasToday) {
                    root.stSelectedDate = actualToday
                    let now = new Date()
                    root.stSelectedYear = now.getFullYear()
                    root.stSelectedMonth = now.getMonth()
                }
            }
        }
    }

    function getScreenTimeStats() {
        let emptyStats = { totalSeconds: 0, apps: [], averageDaily: 0, averageMonthly: 0 }
        try {
            if (typeof ScreenTime === "undefined" || !ScreenTime) return emptyStats
            let _react = ScreenTime.screenTimeData
            if (root.stHorizonFilter === "daily") {
                return ScreenTime.getDailyStats(root.stSelectedDate) || emptyStats
            } else if (root.stHorizonFilter === "weekly") {
                let parts = root.stSelectedDate.split("-")
                let d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
                return ScreenTime.getWeeklyStats(d) || emptyStats
            } else if (root.stHorizonFilter === "monthly") {
                return ScreenTime.getMonthlyStats(root.stSelectedYear, root.stSelectedMonth) || emptyStats
            } else {
                return ScreenTime.getYearlyStats(root.stSelectedYear) || emptyStats
            }
        } catch (e) {
            return emptyStats
        }
    }

    property int stCalendarPickerYear: (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date.getFullYear() : new Date().getFullYear()
    property int stCalendarPickerMonth: (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date.getMonth() : new Date().getMonth()

    function getCalendarPickerMatrix(year, month) {
        const firstOfMonth = new Date(year, month, 1)
        const startOffset = (firstOfMonth.getDay() + 6) % 7
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrevMonth = new Date(year, month, 0).getDate()

        let cells = []
        for (let i = 0; i < startOffset; i++) {
            let pDay = daysInPrevMonth - startOffset + i + 1
            let pMonth = month === 0 ? 11 : month - 1
            let pYear = month === 0 ? year - 1 : year
            let mm = (pMonth + 1) < 10 ? "0" + (pMonth + 1) : "" + (pMonth + 1)
            let dd = pDay < 10 ? "0" + pDay : "" + pDay
            let dateStr = `${pYear}-${mm}-${dd}`
            let dayData = (typeof ScreenTime !== "undefined" && ScreenTime.screenTimeData) ? ScreenTime.screenTimeData[dateStr] : null
            cells.push({
                day: pDay,
                month: pMonth,
                year: pYear,
                dateStr: dateStr,
                currentMonth: false,
                isToday: (dateStr === root.todayDateStr),
                seconds: dayData ? (dayData.totalSeconds || 0) : 0
            })
        }

        for (let d = 1; d <= daysInMonth; d++) {
            let mm = (month + 1) < 10 ? "0" + (month + 1) : "" + (month + 1)
            let dd = d < 10 ? "0" + d : "" + d
            let dateStr = `${year}-${mm}-${dd}`
            let dayData = (typeof ScreenTime !== "undefined" && ScreenTime.screenTimeData) ? ScreenTime.screenTimeData[dateStr] : null
            cells.push({
                day: d,
                month: month,
                year: year,
                dateStr: dateStr,
                currentMonth: true,
                isToday: (dateStr === root.todayDateStr),
                seconds: dayData ? (dayData.totalSeconds || 0) : 0
            })
        }

        let nextDay = 1
        let nMonth = month === 11 ? 0 : month + 1
        let nYear = month === 11 ? year + 1 : year
        let targetTotal = cells.length > 35 ? 42 : 35
        while (cells.length < targetTotal) {
            let mm = (nMonth + 1) < 10 ? "0" + (nMonth + 1) : "" + (nMonth + 1)
            let dd = nextDay < 10 ? "0" + nextDay : "" + nextDay
            let dateStr = `${nYear}-${mm}-${dd}`
            let dayData = (typeof ScreenTime !== "undefined" && ScreenTime.screenTimeData) ? ScreenTime.screenTimeData[dateStr] : null
            cells.push({
                day: nextDay,
                month: nMonth,
                year: nYear,
                dateStr: dateStr,
                currentMonth: false,
                isToday: (dateStr === root.todayDateStr),
                seconds: dayData ? (dayData.totalSeconds || 0) : 0
            })
            nextDay++
        }
        return cells
    }

    function scrollToHorizon(horizonId) {
        if (!horizonId) return
        Qt.callLater(() => {
            if (!goalFlickable || !accordionRepeater) return
            let horizonIdx = root.goalsHorizons.findIndex(h => h.id === horizonId)
            if (horizonIdx < 0) return
            let item = accordionRepeater.itemAt(horizonIdx)
            let targetY = item ? item.y : (horizonIdx * 42)
            let maxY = Math.max(0, goalFlickable.contentHeight - goalFlickable.height)
            let scrollY = Math.min(maxY, targetY)
            if (typeof goalScrollAnim !== "undefined" && goalScrollAnim) {
                goalScrollAnim.stop()
                goalScrollAnim.to = scrollY
                goalScrollAnim.restart()
            } else {
                goalFlickable.contentY = scrollY
            }
        })
    }

    // Section 1: Goals Horizons (5 slots, 72° apart)
    readonly property var goalsHorizons: [
        { id: "daily",    name: "Daily",       icon: "today",              angleDeg: 270 }, // Top
        { id: "weekly",   name: "Weekly",      icon: "calendar_view_week", angleDeg: 342 }, // Upper-Right
        { id: "monthly",  name: "Monthly",     icon: "calendar_month",     angleDeg:  54 }, // Lower-Right
        { id: "yearly",   name: "Yearly",      icon: "workspace_premium",  angleDeg: 126 }, // Lower-Left
        { id: "longterm", name: "Long-Term",   icon: "rocket_launch",      angleDeg: 198 }  // Upper-Left
    ]

    // Section 2: General Tools (Alarm & Markdown Notes)
    readonly property var generalTools: [
        { id: "alarm", name: "Alarm",          icon: "alarm",       angleDeg: 270, tag: "Alarm", desc: "Set wake-up & reminder alarms" },
        { id: "notes", name: "Markdown Notes", icon: "description", angleDeg:  90, tag: "Notes", desc: "Rich .md format reader & editor" }
    ]

    readonly property var currentOrbitModel: (root.sectionMode === "general") ? generalTools : goalsHorizons

    function normalizeHorizon(hId) {
        return Goals.normalizeHorizon(hId)
    }

    function hColor(hId) {
        let norm = normalizeHorizon(hId)
        switch (norm) {
            case "daily":    return Appearance.m3colors.m3primary
            case "weekly":   return Appearance.m3colors.m3secondary
            case "monthly":  return Appearance.m3colors.m3tertiary
            case "yearly":   return Appearance.m3colors.m3success
            case "longterm": return Appearance.m3colors.m3error
            case "todo":     return Appearance.colors.colPrimary
            default:         return Appearance.colors.colOnLayer1
        }
    }

    function hName(hId) {
        let norm = normalizeHorizon(hId)
        let found = goalsHorizons.find(h => h.id === norm)
        return found ? found.name : (norm.charAt(0).toUpperCase() + norm.slice(1))
    }

    function hIcon(hId) {
        let norm = normalizeHorizon(hId)
        let found = goalsHorizons.find(h => h.id === norm)
        return found ? found.icon : "task_alt"
    }

    function getStats(hId) {
        return Goals.getStats(hId)
    }

    function getTomorrowDateStr() {
        let tom = new Date()
        tom.setDate(tom.getDate() + 1)
        let y = tom.getFullYear()
        let m = tom.getMonth() + 1
        let d = tom.getDate()
        let mm = m < 10 ? "0" + m : "" + m
        let dd = d < 10 ? "0" + d : "" + d
        return y + "-" + mm + "-" + dd
    }

    function toggleGoal(id) {
        Goals.toggleGoal(id)
    }

    function setGoalCalendarDate(id, rawDateStr) {
        Goals.setGoalCalendarDate(id, rawDateStr)
        root.schedulingGoalId = ""
    }

    function removeGoalCalendarDate(id) {
        Goals.removeGoalCalendarDate(id)
        root.schedulingGoalId = ""
    }

    function addGoal(title, horizon, calendarDate) {
        Goals.addGoal(title, horizon, calendarDate)
    }

    function deleteGoal(id) {
        Goals.deleteGoal(id)
    }

    function formatAlarmTime(t24) {
        if (!t24) return ""
        let parts = t24.split(":")
        if (parts.length < 2) return t24
        let h = parseInt(parts[0], 10)
        let m = parts[1]
        let ampm = (h >= 12) ? "pm" : "am"
        let h12 = (h % 12 === 0) ? 12 : (h % 12)
        return `${h12}:${m} ${ampm}`
    }

    function formatInlineMd(text) {
        if (!text) return ""
        let s = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        s = s.replace(/\*\*(.*?)\*\*/g, "<b>$1</b>")
        s = s.replace(/__(.*?)__/g, "<b>$1</b>")
        s = s.replace(/\*(.*?)\*/g, "<i>$1</i>")
        s = s.replace(/_(.*?)_/g, "<i>$1</i>")
        s = s.replace(/`([^`]+)`/g, "<span style='background:rgba(255,255,255,0.12); padding:1px 4px; border-radius:3px; font-family:monospace; font-size:11px; color:#a5d6a7;'>$1</span>")
        s = s.replace(/~~(.*?)~~/g, "<s>$1</s>")
        return s
    }

    function renderMarkdownToHtml(raw) {
        if (!raw || !raw.trim()) return "<span style='color:rgba(255,255,255,0.3); font-style:italic;'>Start typing in Edit mode…</span>"
        let lines = raw.split("\n")
        let html = []
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i]
            let trimmed = line.trim()
            if (line.startsWith("# ")) {
                let txt = line.substring(2)
                html.push(`<div style="font-size:16px; font-weight:bold; color:#ffffff; margin:6px 0 2px 0;">${formatInlineMd(txt)}</div>`)
            } else if (line.startsWith("## ")) {
                let txt = line.substring(3)
                html.push(`<div style="font-size:14px; font-weight:bold; color:#ffffff; margin:4px 0 2px 0;">${formatInlineMd(txt)}</div>`)
            } else if (line.startsWith("### ")) {
                let txt = line.substring(4)
                html.push(`<div style="font-size:12px; font-weight:bold; color:#e0e0e0; margin:3px 0 1px 0;">${formatInlineMd(txt)}</div>`)
            } else if (line.startsWith("- ") || line.startsWith("* ")) {
                let txt = line.substring(2)
                html.push(`<div style="margin:2px 0 2px 0; color:#f0f0f0;"><span style="color:#7eb8f7; font-weight:bold; margin-right:6px;">•</span>${formatInlineMd(txt)}</div>`)
            } else if (/^\d+\.\s/.test(line)) {
                let match = line.match(/^(\d+)\.\s(.*)/)
                if (match) {
                    html.push(`<div style="margin:2px 0 2px 0; color:#f0f0f0;"><span style="color:#7eb8f7; font-weight:bold; margin-right:5px;">${match[1]}.</span>${formatInlineMd(match[2])}</div>`)
                } else {
                    html.push(`<div style="margin:2px 0; color:#f0f0f0;">${formatInlineMd(line)}</div>`)
                }
            } else if (line.startsWith("> ")) {
                let txt = line.substring(2)
                html.push(`<div style="border-left:2px solid #7eb8f7; padding-left:6px; margin:3px 0; color:#b0bec5; font-style:italic;">${formatInlineMd(txt)}</div>`)
            } else if (trimmed === "") {
                html.push(`<div style="height:6px;"></div>`)
            } else {
                html.push(`<div style="margin:2px 0; color:#f0f0f0; line-height:130%;">${formatInlineMd(line)}</div>`)
            }
        }
        return html.join("")
    }

    onGoalsListChanged: mainArc.requestPaint()

    // ════════════════════════════════════════════════════════
    // Frosted Glass Card Shell
    // ════════════════════════════════════════════════════════
    // ROOT FROSTED GLASS CONTAINER & SHADOW
    // ════════════════════════════════════════════════════════
    StyledRectangularShadow {
        target: card
        z: -1
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colBackgroundSurfaceContainer
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.96)
        }

        // ════════════════════════════════════════════════════════
        // 1. MAIN RADAR & ACCORDION VIEW (when no tool is full-canvas)
        // ════════════════════════════════════════════════════════
        ColumnLayout {
            id: mainContentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            visible: root.activeToolScreen === ""

            // ── CLEAN THEME-HARMONIZED ALARM ACTIVE BANNER ──
            Rectangle {
                id: satelliteHeaderPill
                visible: opacity > 0
                opacity: Alarms.isRinging ? 1.0 : 0.0
                scale: Alarms.isRinging ? 1.0 : 0.92
                Layout.fillWidth: true
                implicitHeight: Alarms.isRinging ? (root.isCompact ? 36 : 48) : 0
                radius: Appearance.rounding.large
                clip: true
                color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.20)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.60)

                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors { fill: parent; leftMargin: root.isCompact ? 8 : 12; rightMargin: root.isCompact ? 8 : 12 }
                    spacing: root.isCompact ? 6 : 10

                    // Clean Static Alarm Icon
                    MaterialSymbol {
                        text: "alarm"
                        iconSize: root.isCompact ? 17 : 22
                        color: Appearance.colors.colPrimary
                    }

                    // Alarm Details
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2

                        StyledText {
                            Layout.fillWidth: true
                            text: Alarms.activeRingingAlarm ? Alarms.activeRingingAlarm.label : "Alarm"
                            font.pixelSize: root.isCompact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: Alarms.activeRingingAlarm ? root.formatAlarmTime(Alarms.activeRingingAlarm.time) : ""
                            font.pixelSize: 10
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Actions (Snooze & Stop)
                    RowLayout {
                        spacing: root.isCompact ? 4 : 8

                        // Snooze Button
                        Rectangle {
                            implicitWidth: root.isCompact ? 26 : 32
                            implicitHeight: root.isCompact ? 26 : 32
                            radius: Appearance.rounding.full
                            color: snoozeBtnMa.containsMouse ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "snooze"
                                iconSize: root.isCompact ? 13 : 17
                                color: Appearance.colors.colOnSecondaryContainer
                            }

                            MouseArea {
                                id: snoozeBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Alarms.snoozeActiveAlarm()
                            }
                        }

                        // Stop Button
                        Rectangle {
                            implicitWidth: root.isCompact ? 50 : 62
                            implicitHeight: root.isCompact ? 26 : 32
                            radius: Appearance.rounding.full
                            color: stopBtnMa.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 3
                                MaterialSymbol {
                                    text: "close"
                                    iconSize: root.isCompact ? 12 : 15
                                    color: Appearance.colors.colOnPrimary
                                }
                                StyledText {
                                    text: "Stop"
                                    font.pixelSize: root.isCompact ? 10 : Appearance.font.pixelSize.smaller
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnPrimary
                                }
                            }

                            MouseArea {
                                id: stopBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Alarms.stopRinging()
                            }
                        }
                    }
                }
            }

            // ── TOP HEADER ROW (Always Visible: Title & 3-Mode Switcher Tabs) ──
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                spacing: 4

                StyledText {
                    text: (root.sectionMode === "wellbeing") ? "Journal & Focus" : (root.sectionMode === "general") ? "Productivity Tools" : "Goals"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                // 3-Mode Switcher Tabs (Goals | Tools | Journal)
                RowLayout {
                    spacing: 3

                    // Goals Tab
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: root.sectionMode === "goals"
                            ? Appearance.colors.colLayer3
                            : (goalsModeMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.5) : "transparent")
                        border.width: root.sectionMode === "goals" ? 1 : 0
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.5)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "flag"
                            iconSize: 14
                            color: root.sectionMode === "goals" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                        MouseArea {
                            id: goalsModeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sectionMode = "goals"
                        }
                    }

                    // Tools Tab
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: root.sectionMode === "general"
                            ? Appearance.colors.colLayer3
                            : (toolsModeMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.5) : "transparent")
                        border.width: root.sectionMode === "general" ? 1 : 0
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.5)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "widgets"
                            iconSize: 14
                            color: root.sectionMode === "general" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                        MouseArea {
                            id: toolsModeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sectionMode = "general"
                        }
                    }

                    // Journal & Screen Time Tab
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: root.sectionMode === "wellbeing"
                            ? Appearance.colors.colLayer3
                            : (wbModeMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.5) : "transparent")
                        border.width: root.sectionMode === "wellbeing" ? 1 : 0
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.5)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "auto_stories"
                            iconSize: 14
                            color: root.sectionMode === "wellbeing" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                        MouseArea {
                            id: wbModeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sectionMode = "wellbeing"
                            }
                        }
                    }
                }
            }

            // ── TOP: ORBITAL RADAR SECTION (Only for Goals Mode) ──
            Item {
                id: orbitCenter
                visible: root.sectionMode === "goals"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: visible ? 200 : 0
                Layout.preferredHeight: visible ? 200 : 0

                // Ring Canvas
                Canvas {
                    id: mainArc
                    anchors.centerIn: parent
                    width: 140
                    height: 140
                    antialiasing: true

                    onPaint: {
                        let ctx = getContext("2d")
                        ctx.reset()
                        let cx = width / 2, cy = height / 2
                        let r = 45

                        // Track ring
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.lineWidth = 3.5
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                        ctx.stroke()

                        // Progress arc
                        let stats = root.getStats("all")
                        if (stats.percent > 0) {
                            let startAngle = -Math.PI / 2
                            let sweepAngle = (stats.percent / 100) * (Math.PI * 2)
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, startAngle, startAngle + sweepAngle)
                            ctx.lineWidth = 3.5
                            ctx.strokeStyle = Appearance.colors.colPrimary.toString()
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }
                }

                // Center text
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -2
                    readonly property var st: root.getStats("all")

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${parent.st.done}/${parent.st.total}`
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Black
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Goals"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colSubtext
                    }
                }

                // Orbit Buttons — 5 Goals Horizons
                Repeater {
                    id: orbitRepeater
                    model: root.goalsHorizons

                    delegate: Item {
                        required property var modelData
                        readonly property real orbitR: 74
                        readonly property real btnSize: 30
                        readonly property real rad: modelData.angleDeg * Math.PI / 180.0

                        width: btnSize
                        height: btnSize
                        x: Math.round(100 + orbitR * Math.cos(rad) - btnSize / 2)
                        y: Math.round(100 + orbitR * Math.sin(rad) - btnSize / 2)

                        Rectangle {
                            id: orbitBtn
                            readonly property bool isSelected: root.expandedHorizon === modelData.id
                            anchors.centerIn: parent
                            width: isSelected ? 36 : (orbitMa.containsPress ? 28 : parent.btnSize)
                            height: width
                            radius: Appearance.rounding.full

                            color: isSelected
                                ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
                                : (orbitMa.containsMouse
                                    ? Appearance.colors.colLayer3Hover
                                    : Appearance.colors.colLayer2)

                            border.width: 1
                            border.color: isSelected
                                ? Appearance.colors.colPrimary
                                : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)

                            Behavior on width {
                                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                            }
                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 17
                                color: parent.isSelected || orbitMa.containsMouse
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: orbitMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.isCompact) {
                                        root.sizeMode = "full"
                                        if (root.configEntry) root.configEntry.sizeMode = "full"
                                    }
                                    root.expandedHorizon = modelData.id
                                    root.scrollToHorizon(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // ── SEPARATOR LINE (Goals mode) ─────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
                visible: !root.isCompact && root.sectionMode === "goals"
            }

            // ── MAIN CONTENT (ACCORDION FOR GOALS / CARDS FOR TOOLS / WELLBEING) ───
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // ═══════════════════════════════════════════════════
                // SECTION 3: DIGITAL WELL-BEING & SCREEN TIME (Minimal Donut Diagram)
                // ═══════════════════════════════════════════════════
                ColumnLayout {
                    id: wellbeingSection
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    visible: root.sectionMode === "wellbeing"

                    readonly property var currentStats: {
                        let _react = (typeof ScreenTime !== "undefined" && ScreenTime) ? ScreenTime.screenTimeData : null
                        return root.getScreenTimeStats()
                    }

                    // Vibrant, distinct, readable palette — easy to tell slices apart
                    readonly property var slicePalette: [
                        "#7C9FCA", // Calm blue
                        "#7DB88A", // Sage green
                        "#C9956A", // Warm amber
                        "#A07EC4", // Soft violet
                        "#C48A7A", // Terracotta
                        "#5EADB5", // Teal
                        "#B8A055"  // Gold
                    ]

                    // Selected app detail — find it in currentStats
                    readonly property var selectedAppData: {
                        if (!root.stSelectedAppId) return null
                        let apps = wellbeingSection.currentStats.apps || []
                        return apps.find(a => a.appId === root.stSelectedAppId) || null
                    }

                    // ── 1. HORIZON SELECTOR & CALENDAR DATE JUMP ── (hidden in compact mode)
                    RowLayout {
                        visible: !root.isCompact && !wellbeingSection.selectedAppData && !root.stShowDatePicker
                        Layout.fillWidth: true
                        spacing: 4

                        // Pill Group: Daily | Weekly | Monthly | Yearly
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: Appearance.rounding.full
                            color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                Repeater {
                                    model: [
                                        { id: "daily",   label: "Day" },
                                        { id: "weekly",  label: "Week" },
                                        { id: "monthly", label: "Month" },
                                        { id: "yearly",  label: "Year" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Appearance.rounding.full
                                        color: root.stHorizonFilter === modelData.id
                                            ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.20)
                                            : "transparent"
                                        border.width: root.stHorizonFilter === modelData.id ? 1 : 0
                                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: root.stHorizonFilter === modelData.id ? Font.Bold : Font.Normal
                                            color: root.stHorizonFilter === modelData.id ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.stHorizonFilter = modelData.id
                                                root.stShowDatePicker = false
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Calendar Jump Button
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Appearance.rounding.full
                            color: root.stShowDatePicker ? Appearance.colors.colLayer3 : (calStMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.5) : ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40))
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "calendar_month"
                                iconSize: 15
                                color: root.stShowDatePicker ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: calStMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.stCalendarPickerYear = root.stSelectedYear
                                    root.stCalendarPickerMonth = root.stSelectedMonth
                                    root.stShowDatePicker = !root.stShowDatePicker
                                }
                            }
                        }
                    }

                    // ── 0. FULL CALENDAR DATE PICKER SCREEN (shown when calendar icon is clicked) ──
                    Rectangle {
                        visible: root.stShowDatePicker && !root.isCompact && !wellbeingSection.selectedAppData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.rounding.normal
                        color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                        ColumnLayout {
                            anchors { fill: parent; margins: 10 }
                            spacing: 8

                            // Header with Back Button and Month Navigator
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    color: calBackBtnMa.containsMouse ? Appearance.colors.colLayer3 : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50)
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
                                    MaterialSymbol { anchors.centerIn: parent; text: "arrow_back"; iconSize: 14; color: Appearance.colors.colOnLayer1 }
                                    MouseArea {
                                        id: calBackBtnMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.stShowDatePicker = false
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        let d = new Date(root.stCalendarPickerYear, root.stCalendarPickerMonth, 1)
                                        return Qt.formatDate(d, "MMMM yyyy")
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                }

                                // Prev Month Button
                                Rectangle {
                                    implicitWidth: 24; implicitHeight: 24; radius: 12
                                    color: calPrevMonthMa.containsMouse ? Appearance.colors.colLayer3 : "transparent"
                                    MaterialSymbol { anchors.centerIn: parent; text: "chevron_left"; iconSize: 14; color: Appearance.colors.colSubtext }
                                    MouseArea {
                                        id: calPrevMonthMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.stCalendarPickerMonth === 0) {
                                                root.stCalendarPickerMonth = 11
                                                root.stCalendarPickerYear -= 1
                                            } else {
                                                root.stCalendarPickerMonth -= 1
                                            }
                                        }
                                    }
                                }

                                // Next Month Button
                                Rectangle {
                                    implicitWidth: 24; implicitHeight: 24; radius: 12
                                    color: calNextMonthMa.containsMouse ? Appearance.colors.colLayer3 : "transparent"
                                    MaterialSymbol { anchors.centerIn: parent; text: "chevron_right"; iconSize: 14; color: Appearance.colors.colSubtext }
                                    MouseArea {
                                        id: calNextMonthMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.stCalendarPickerMonth === 11) {
                                                root.stCalendarPickerMonth = 0
                                                root.stCalendarPickerYear += 1
                                            } else {
                                                root.stCalendarPickerMonth += 1
                                            }
                                        }
                                    }
                                }

                                // Today Button
                                Rectangle {
                                    implicitWidth: 42; implicitHeight: 22; radius: 11
                                    color: calTodayBtnMa.containsMouse ? Appearance.colors.colLayer3 : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50)
                                    border.width: 1; border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "Today"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    MouseArea {
                                        id: calTodayBtnMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let now = (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date : new Date()
                                            root.stCalendarPickerYear = now.getFullYear()
                                            root.stCalendarPickerMonth = now.getMonth()
                                            root.stSelectedDate = root.todayDateStr
                                            root.stHorizonFilter = "daily"
                                            root.stShowDatePicker = false
                                        }
                                    }
                                }
                            }

                            // Weekday Names Header Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Repeater {
                                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                    delegate: StyledText {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            // Calendar Matrix Grid
                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 7
                                rowSpacing: 3
                                columnSpacing: 3

                                Repeater {
                                    model: root.getCalendarPickerMatrix(root.stCalendarPickerYear, root.stCalendarPickerMonth)

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 4
                                        color: (modelData.dateStr === root.stSelectedDate)
                                            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.25)
                                            : (modelData.seconds > 0
                                                ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.35)
                                                : (modelData.currentMonth ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.65) : "transparent"))
                                        border.width: (modelData.dateStr === root.stSelectedDate || modelData.isToday) ? 1 : 0
                                        border.color: modelData.isToday ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: -2

                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: `${modelData.day}`
                                                font.pixelSize: 9
                                                font.weight: (modelData.seconds > 0 || modelData.isToday) ? Font.Bold : Font.Normal
                                                color: modelData.currentMonth
                                                    ? (modelData.isToday ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1)
                                                    : ColorUtils.transparentize(Appearance.colors.colSubtext, 0.50)
                                            }

                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                visible: modelData.seconds > 0
                                                text: ScreenTime.formatShortDuration(modelData.seconds)
                                                font.pixelSize: 7
                                                font.weight: Font.Bold
                                                color: (modelData.dateStr === root.stSelectedDate) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.stSelectedDate = modelData.dateStr
                                                root.stSelectedYear = modelData.year
                                                root.stSelectedMonth = modelData.month
                                                root.stHorizonFilter = "daily"
                                                root.stShowDatePicker = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── 2. JOURNALING SUMMARY & USAGE DISTRIBUTION ──
                    Rectangle {
                        visible: !wellbeingSection.selectedAppData && !root.stShowDatePicker
                        Layout.fillWidth: true
                        implicitHeight: journalSummaryCol.implicitHeight + 16
                        radius: Appearance.rounding.normal
                        color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                        ColumnLayout {
                            id: journalSummaryCol
                            anchors { fill: parent; margins: 10 }
                            spacing: 8

                            // Simple Row: Big Focus Time on left, Secondary Metric (Uptime/Avg) on right
                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    text: ScreenTime.formatHoursMinutes(wellbeingSection.currentStats.totalSeconds || 0)
                                    font.pixelSize: 22
                                    font.weight: Font.Black
                                    color: Appearance.colors.colOnLayer1
                                }

                                Item { Layout.fillWidth: true }

                                StyledText {
                                    text: {
                                        if (root.stHorizonFilter === "daily") {
                                            return `Uptime: ${(typeof DateTime !== "undefined" && DateTime.uptime) ? DateTime.uptime : "0m"}`
                                        } else if (root.stHorizonFilter === "yearly") {
                                            return `Avg: ${ScreenTime.formatHoursMinutes(wellbeingSection.currentStats.averageMonthly || 0)}/mo`
                                        } else {
                                            return `Avg: ${ScreenTime.formatHoursMinutes(wellbeingSection.currentStats.averageDaily || 0)}/d`
                                        }
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            // Proportional Usage Distribution Segmented Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: 2.5
                                color: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.60)
                                clip: true

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 1

                                    Repeater {
                                        model: wellbeingSection.currentStats.apps || []

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: Math.max(2, (parent.width * ((modelData.seconds || 0) / Math.max(1, wellbeingSection.currentStats.totalSeconds || 1))))
                                            color: wellbeingSection.slicePalette[index % wellbeingSection.slicePalette.length]
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── 3. APP DETAIL JOURNAL VIEW (when app is tapped) ──
                    Rectangle {
                        visible: !!wellbeingSection.selectedAppData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.rounding.normal
                        color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                        border.width: 1
                        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                        ColumnLayout {
                            anchors { fill: parent; margins: 10 }
                            spacing: 8

                            // Header with back button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    color: wbAppBackBtnMa.containsMouse ? Appearance.colors.colLayer3 : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50)
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
                                    MaterialSymbol { anchors.centerIn: parent; text: "arrow_back"; iconSize: 14; color: Appearance.colors.colOnLayer1 }
                                    MouseArea {
                                        id: wbAppBackBtnMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.stSelectedAppId = ""
                                    }
                                }

                                MaterialSymbol {
                                    text: wellbeingSection.selectedAppData?.icon || "apps"
                                    iconSize: 18
                                    color: Appearance.colors.colPrimary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: -2
                                    StyledText {
                                        text: wellbeingSection.selectedAppData?.name || ""
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: {
                                            let sec = wellbeingSection.selectedAppData?.seconds || 0
                                            let dur = ScreenTime.formatShortDuration(sec)
                                            let pct = wellbeingSection.selectedAppData?.percent || 0
                                            let period = (root.stHorizonFilter === "daily")
                                                ? (root.stSelectedDate === root.todayDateStr ? "today" : "on " + root.stSelectedDate)
                                                : (root.stHorizonFilter === "weekly" ? "this week" : (root.stHorizonFilter === "monthly" ? "this month" : "this year"))
                                            return `${dur} (${pct}%) logged ${period}`
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            StyledText {
                                text: `Activity Log (${(wellbeingSection.selectedAppData?.titles || []).length} items)`
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.Bold
                                color: Appearance.colors.colSubtext
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: width
                                contentHeight: titlesListCol.implicitHeight
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }

                                ColumnLayout {
                                    id: titlesListCol
                                    width: parent.width
                                    spacing: 4

                                    StyledText {
                                        visible: !(wellbeingSection.selectedAppData?.titles?.length > 0)
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: 15
                                        text: "No detailed activity recorded for this period."
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                    }

                                    Repeater {
                                        model: wellbeingSection.selectedAppData?.titles || []

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            implicitHeight: titleRow.implicitHeight + 10
                                            radius: Appearance.rounding.small
                                            color: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50)
                                            border.width: 1
                                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.70)

                                            RowLayout {
                                                id: titleRow
                                                anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 5; bottomMargin: 5 }
                                                spacing: 8

                                                Rectangle {
                                                    implicitWidth: 20; implicitHeight: 20; radius: 10
                                                    color: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.30)
                                                    StyledText {
                                                        anchors.centerIn: parent
                                                        text: `${index + 1}`
                                                        font.pixelSize: 8
                                                        font.weight: Font.Bold
                                                        color: Appearance.colors.colSubtext
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        text: {
                                                            let t = modelData.title || ""
                                                            let clean = t.replace(/ [-|–] [^-|–]+$/, "").trim()
                                                            return clean.length > 3 ? clean : t
                                                        }
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        font.weight: Font.DemiBold
                                                        color: Appearance.colors.colOnLayer1
                                                        wrapMode: Text.WordWrap
                                                        maximumLineCount: 2
                                                        elide: Text.ElideRight
                                                    }

                                                    StyledText {
                                                        text: ScreenTime.formatShortDuration(modelData.seconds)
                                                        font.pixelSize: 8
                                                        color: Appearance.colors.colPrimary
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── 3. APPLICATION USAGE BREAKDOWN LIST ──
                    StyledText {
                        text: `Applications (${(wellbeingSection.currentStats.apps || []).length})`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Bold
                        color: Appearance.colors.colSubtext
                        Layout.leftMargin: 2
                        visible: !root.isCompact && !wellbeingSection.selectedAppData && !root.stShowDatePicker
                    }

                    Flickable {
                        visible: !root.isCompact && !wellbeingSection.selectedAppData && !root.stShowDatePicker
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: appsBreakdownCol.implicitHeight
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }

                        ColumnLayout {
                            id: appsBreakdownCol
                            width: parent.width
                            spacing: 5

                            StyledText {
                                visible: !(wellbeingSection.currentStats.apps && wellbeingSection.currentStats.apps.length > 0)
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 15
                                text: "No screen time recorded for this period."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            Repeater {
                                model: wellbeingSection.currentStats.apps || []

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    radius: Appearance.rounding.small
                                    color: appRowMa.containsMouse
                                        ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.40)
                                        : ColorUtils.transparentize(Appearance.colors.colLayer2, 0.60)
                                    border.width: 1
                                    border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.70)

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        spacing: 8

                                        // Donut Slice Color Pip + App Icon
                                        Rectangle {
                                            implicitWidth: 26; implicitHeight: 26; radius: 6
                                            color: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.40)
                                            border.width: 1.5
                                            border.color: wellbeingSection.slicePalette[index % wellbeingSection.slicePalette.length]

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: modelData.icon || "apps"
                                                iconSize: 14
                                                color: Appearance.colors.colSubtext
                                            }
                                        }

                                        // App Name + Progress Bar
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || modelData.appId
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    font.weight: Font.DemiBold
                                                    color: Appearance.colors.colOnLayer1
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    text: `${ScreenTime.formatShortDuration(modelData.seconds)} (${modelData.percent}%)`
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnLayer1
                                                }
                                            }

                                            // Minimalist Track & Progress
                                            Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: 3
                                                radius: 1.5
                                                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.75)

                                                Rectangle {
                                                    width: Math.round(parent.width * (Math.min(100, modelData.percent) / 100))
                                                    height: parent.height
                                                    radius: parent.radius
                                                    color: wellbeingSection.slicePalette[index % wellbeingSection.slicePalette.length]
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: appRowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.stSelectedAppId = modelData.appId
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // If Section 2 (General Tools): Spacious, Premium Tool Cards (90% Space)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    visible: root.sectionMode === "general"

                    // Alarm Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.isCompact ? 48 : 64
                        radius: Appearance.rounding.normal
                        color: almLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha("#ffffff", 0.08)
                            : ColorUtils.applyAlpha("#ffffff", 0.04)
                        border.width: 1
                        border.color: almLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.50)
                            : ColorUtils.applyAlpha("#ffffff", 0.09)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: root.isCompact ? 10 : 14; rightMargin: root.isCompact ? 10 : 14 }
                            spacing: root.isCompact ? 10 : 12

                            Rectangle {
                                implicitWidth: root.isCompact ? 30 : 38
                                implicitHeight: root.isCompact ? 30 : 38
                                radius: root.isCompact ? 8 : 12
                                color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "alarm"
                                    iconSize: root.isCompact ? 16 : 20
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    text: "Alarm Utility"
                                    font.pixelSize: root.isCompact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: {
                                        let active = Alarms.alarmsList.filter(a => a.enabled).length
                                        return active > 0 ? `${active} active alarm${active > 1 ? "s" : ""}` : "Set wake-up & reminder alarms"
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: root.isCompact ? 16 : 18
                                color: Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: almLaunchMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeToolScreen = "alarm"
                        }
                    }

                    // Markdown Notes Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.isCompact ? 48 : 64
                        radius: Appearance.rounding.normal
                        color: notesLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha("#ffffff", 0.08)
                            : ColorUtils.applyAlpha("#ffffff", 0.04)
                        border.width: 1
                        border.color: notesLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.50)
                            : ColorUtils.applyAlpha("#ffffff", 0.09)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: root.isCompact ? 10 : 14; rightMargin: root.isCompact ? 10 : 14 }
                            spacing: root.isCompact ? 10 : 12

                            Rectangle {
                                implicitWidth: root.isCompact ? 30 : 38
                                implicitHeight: root.isCompact ? 30 : 38
                                radius: root.isCompact ? 8 : 12
                                color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "description"
                                    iconSize: root.isCompact ? 16 : 20
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    text: "Markdown Notes"
                                    font.pixelSize: root.isCompact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: `${Notes.list.length} note${Notes.list.length !== 1 ? "s" : ""} saved`
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: root.isCompact ? 16 : 18
                                color: Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: notesLaunchMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeToolScreen = "notes"
                        }
                    }

                    // To-Do List Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.isCompact ? 48 : 64
                        radius: Appearance.rounding.normal
                        color: todoLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha("#ffffff", 0.08)
                            : ColorUtils.applyAlpha("#ffffff", 0.04)
                        border.width: 1
                        border.color: todoLaunchMa.containsMouse
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.50)
                            : ColorUtils.applyAlpha("#ffffff", 0.09)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: root.isCompact ? 10 : 14; rightMargin: root.isCompact ? 10 : 14 }
                            spacing: root.isCompact ? 10 : 12

                            Rectangle {
                                implicitWidth: root.isCompact ? 30 : 38
                                implicitHeight: root.isCompact ? 30 : 38
                                radius: root.isCompact ? 8 : 12
                                color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "checklist"
                                    iconSize: root.isCompact ? 16 : 20
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    text: "To-Do List"
                                    font.pixelSize: root.isCompact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: {
                                        let pending = (Todo.list ?? []).filter(t => !t.done).length
                                        let total = (Todo.list ?? []).length
                                        return total > 0 ? `${pending} pending • ${total} total` : "Manage daily tasks & to-dos"
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: root.isCompact ? 16 : 18
                                color: Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            id: todoLaunchMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeToolScreen = "todo"
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // If Section 1 (Goals): Goals Accordion List
                Flickable {
                    id: goalFlickable
                    visible: root.sectionMode === "goals"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: accordionContentCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                    }

                    NumberAnimation {
                        id: goalScrollAnim
                        target: goalFlickable
                        property: "contentY"
                        duration: 280
                        easing.type: Easing.OutCubic
                    }

                    ColumnLayout {
                        id: accordionContentCol
                        width: goalFlickable.width
                        spacing: 4

                        Repeater {
                            id: accordionRepeater
                            model: root.goalsHorizons

                            delegate: ColumnLayout {
                                id: horizonSection
                                required property var modelData
                                width: accordionContentCol.width
                                spacing: 3

                                readonly property string horizonId: modelData.id
                                readonly property var stats: root.getStats(modelData.id)
                                readonly property bool isExpanded: root.expandedHorizon === modelData.id

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: Appearance.rounding.normal
                                    color: horizonSection.isExpanded
                                        ? ColorUtils.transparentize(Appearance.colors.colLayer2, 0.35)
                                        : (hRowMa.containsMouse
                                            ? Appearance.colors.colLayer3Hover
                                            : ColorUtils.transparentize(Appearance.colors.colLayer2, 0.60))
                                    border.width: 1
                                    border.color: horizonSection.isExpanded
                                        ? ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.40)
                                        : "transparent"

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 10 }
                                        spacing: 8

                                        MaterialSymbol {
                                            text: "chevron_right"
                                            iconSize: 16
                                            color: horizonSection.isExpanded ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                            rotation: horizonSection.isExpanded ? 90 : 0
                                            Behavior on rotation {
                                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                            }
                                        }

                                        MaterialSymbol {
                                            text: modelData.icon
                                            iconSize: 16
                                            color: horizonSection.isExpanded ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }

                                        StyledText {
                                            text: modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.smallie
                                            font.weight: horizonSection.isExpanded ? Font.Bold : Font.Medium
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            implicitWidth: countBadgeText.implicitWidth + 12
                                            implicitHeight: 20
                                            radius: Appearance.rounding.full
                                            color: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50)
                                            border.width: 1
                                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)

                                            StyledText {
                                                id: countBadgeText
                                                anchors.centerIn: parent
                                                text: `${horizonSection.stats.done} / ${horizonSection.stats.total}`
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.weight: Font.Bold
                                                color: Appearance.colors.colSubtext
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: hRowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let isOpening = (root.expandedHorizon !== horizonSection.horizonId)
                                            root.expandedHorizon = isOpening ? horizonSection.horizonId : ""
                                            if (isOpening) {
                                                root.scrollToHorizon(horizonSection.horizonId)
                                            }
                                        }
                                    }
                                }

                                // ── GOALS LIST SECTION ──
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    spacing: 3
                                    visible: horizonSection.isExpanded

                                    Repeater {
                                        model: root.goalsList.filter(g => root.normalizeHorizon(g.horizon) === horizonSection.horizonId)

                                        delegate: ColumnLayout {
                                            id: goalItemWrapper
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Rectangle {
                                                id: goalItemCard
                                                Layout.fillWidth: true
                                                implicitHeight: goalItemContentRow.implicitHeight + 14
                                                radius: Appearance.rounding.small
                                                color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                                                border.width: 1
                                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                                                RowLayout {
                                                    id: goalItemContentRow
                                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                                    spacing: 8

                                                    // Symmetrical Circle Checkbox
                                                    Rectangle {
                                                        implicitWidth: 20
                                                        implicitHeight: 20
                                                        radius: 10
                                                        color: "transparent"
                                                        border.width: 1.5
                                                        border.color: modelData.completed
                                                            ? Appearance.colors.colPrimary
                                                            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.40)
                                                        Behavior on border.color {
                                                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                                        }
                                                        scale: cbMa.containsPress ? 0.85 : 1.0
                                                        Behavior on scale {
                                                            animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
                                                        }

                                                        Rectangle {
                                                            anchors.centerIn: parent
                                                            width: 10
                                                            height: 10
                                                            radius: 5
                                                            visible: modelData.completed
                                                            color: Appearance.colors.colPrimary
                                                        }

                                                        MouseArea {
                                                            id: cbMa
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.toggleGoal(modelData.id)
                                                        }
                                                    }

                                                    StyledText {
                                                        Layout.fillWidth: true
                                                        text: modelData.title
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        font.weight: modelData.completed ? Font.Normal : Font.Medium
                                                        color: modelData.completed ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                                                        font.strikeout: modelData.completed
                                                        wrapMode: Text.WordWrap
                                                    }

                                                    RowLayout {
                                                        spacing: 4

                                                        // Calendar Mention Pill (if already scheduled)
                                                        Rectangle {
                                                            visible: (modelData.calendarDate && modelData.calendarDate.length > 0)
                                                            implicitHeight: 22
                                                            implicitWidth: calPillContent.implicitWidth + 8
                                                            radius: Appearance.rounding.full
                                                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.80)
                                                            border.width: 1
                                                            border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.40)

                                                            RowLayout {
                                                                id: calPillContent
                                                                anchors.centerIn: parent
                                                                spacing: 3

                                                                MaterialSymbol { text: "event"; iconSize: 11; color: Appearance.colors.colPrimary }
                                                                StyledText {
                                                                    text: modelData.calendarDate || ""
                                                                    font.pixelSize: 8
                                                                    font.weight: Font.Bold
                                                                    color: Appearance.colors.colPrimary
                                                                }
                                                                Rectangle {
                                                                    implicitWidth: 14; implicitHeight: 14; radius: 7
                                                                    color: unmentionMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colError, 0.3) : "transparent"
                                                                    MaterialSymbol {
                                                                        anchors.centerIn: parent
                                                                        text: "close"
                                                                        iconSize: 9
                                                                        color: Appearance.colors.colPrimary
                                                                    }
                                                                    MouseArea {
                                                                        id: unmentionMa
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: root.removeGoalCalendarDate(modelData.id)
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // Mention on Calendar Button (opens scheduler)
                                                        Rectangle {
                                                            visible: (!modelData.calendarDate || modelData.calendarDate.length === 0)
                                                            implicitWidth: 22; implicitHeight: 22
                                                            radius: Appearance.rounding.full
                                                            color: root.schedulingGoalId === modelData.id || calAddMouse.containsMouse
                                                                ? Appearance.colors.colLayer3Hover
                                                                : "transparent"

                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: "calendar_add_on"
                                                                iconSize: 14
                                                                color: root.schedulingGoalId === modelData.id || calAddMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                                            }

                                                            MouseArea {
                                                                id: calAddMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    root.schedulingGoalId = (root.schedulingGoalId === modelData.id) ? "" : modelData.id
                                                                }
                                                            }
                                                        }

                                                        // Delete Goal Button
                                                        Rectangle {
                                                            implicitWidth: 22; implicitHeight: 22
                                                            radius: Appearance.rounding.full
                                                            color: delMa.containsMouse ? Appearance.colors.colErrorContainerHover : "transparent"

                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: "close"
                                                                iconSize: 13
                                                                color: delMa.containsMouse ? Appearance.colors.colOnErrorContainer : Appearance.colors.colSubtext
                                                            }

                                                            MouseArea {
                                                                id: delMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.deleteGoal(modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // ── Two-Row Spacious Calendar Scheduler Dropdown ─────
                                            Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: root.schedulingGoalId === modelData.id ? schedulerCol.implicitHeight + 14 : 0
                                                radius: Appearance.rounding.small
                                                color: Appearance.colors.colLayer3
                                                border.width: 1
                                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)
                                                clip: true
                                                visible: implicitHeight > 0

                                                Behavior on implicitHeight {
                                                    animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                                                }

                                                ColumnLayout {
                                                    id: schedulerCol
                                                    anchors { fill: parent; margins: 8 }
                                                    spacing: 6

                                                    // Row 1: Quick Chips + Close
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 6

                                                        // [Today] Quick Button
                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            implicitHeight: 26
                                                            radius: Appearance.rounding.full
                                                            color: todayBtnMa.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimaryContainer
                                                            StyledText {
                                                                anchors.centerIn: parent
                                                                text: "Today"
                                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                                font.weight: Font.Bold
                                                                color: Appearance.colors.colOnPrimaryContainer
                                                            }
                                                            MouseArea {
                                                                id: todayBtnMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    let todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd")
                                                                    root.setGoalCalendarDate(modelData.id, todayStr)
                                                                }
                                                            }
                                                        }

                                                        // [Tomorrow] Quick Button
                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            implicitHeight: 26
                                                            radius: Appearance.rounding.full
                                                            color: tomBtnMa.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                                                            StyledText {
                                                                anchors.centerIn: parent
                                                                text: "Tomorrow"
                                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                                font.weight: Font.Medium
                                                                color: Appearance.colors.colOnLayer2
                                                            }
                                                            MouseArea {
                                                                id: tomBtnMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    root.setGoalCalendarDate(modelData.id, root.getTomorrowDateStr())
                                                                }
                                                            }
                                                        }

                                                        // Close Button
                                                        Rectangle {
                                                            implicitWidth: 26; implicitHeight: 26; radius: 13
                                                            color: closeSchedMa.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"
                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: "close"
                                                                iconSize: 14
                                                                color: Appearance.colors.colSubtext
                                                            }
                                                            MouseArea {
                                                                id: closeSchedMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.schedulingGoalId = ""
                                                            }
                                                        }
                                                    }

                                                    // Row 2: Full-width Custom Date Entry
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 6

                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            implicitHeight: 28
                                                            radius: Appearance.rounding.small
                                                            color: Appearance.colors.colLayer2
                                                            border.width: 1
                                                            border.color: customDateField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                                                            TextField {
                                                                id: customDateField
                                                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                                                placeholderText: "Custom Date (e.g. 2026-08-30)"
                                                                placeholderTextColor: Appearance.colors.colSubtext
                                                                color: Appearance.colors.colOnLayer1
                                                                background: null
                                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                                leftPadding: 0
                                                                onActiveFocusChanged: { if (activeFocus) root.isUserTyping = true }
                                                                onAccepted: {
                                                                    if (text.trim()) root.setGoalCalendarDate(modelData.id, text.trim())
                                                                    customDateField.focus = false
                                                                    root.isUserTyping = false
                                                                }
                                                            }
                                                        }

                                                        Rectangle {
                                                            implicitWidth: 44; implicitHeight: 28
                                                            radius: Appearance.rounding.small
                                                            color: setBtnMa.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                                                            StyledText {
                                                                anchors.centerIn: parent
                                                                text: "Set"
                                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                                font.weight: Font.Bold
                                                                color: Appearance.colors.colOnPrimary
                                                            }
                                                            MouseArea {
                                                                id: setBtnMa
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (customDateField.text.trim()) {
                                                                        root.setGoalCalendarDate(modelData.id, customDateField.text.trim())
                                                                        customDateField.focus = false
                                                                        root.isUserTyping = false
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Inline Goal Input Field
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 34
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colLayer2
                                        border.width: 1
                                        border.color: inlineField.activeFocus
                                            ? Appearance.colors.colPrimary
                                            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                            spacing: 6

                                                TextField {
                                                id: inlineField
                                                Layout.fillWidth: true
                                                placeholderText: `Add ${modelData.name.toLowerCase()} goal…`
                                                placeholderTextColor: Appearance.colors.colSubtext
                                                color: Appearance.colors.colOnLayer1
                                                background: null
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                leftPadding: 0
                                                onActiveFocusChanged: { if (activeFocus) root.isUserTyping = true }
                                                onAccepted: {
                                                    root.addGoal(text, horizonSection.horizonId, "")
                                                    text = ""
                                                    inlineField.focus = false
                                                    root.isUserTyping = false
                                                }
                                            }

                                            Rectangle {
                                                implicitWidth: 22; implicitHeight: 22
                                                radius: 11
                                                color: addBtnMouse.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimaryContainer

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "add"
                                                    iconSize: 15
                                                    color: Appearance.colors.colOnPrimaryContainer
                                                }

                                                MouseArea {
                                                    id: addBtnMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.addGoal(inlineField.text, horizonSection.horizonId, "")
                                                        inlineField.text = ""
                                                        inlineField.focus = false
                                                        root.isUserTyping = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════
        // 2. DEDICATED FULL CANVAS TOOL VIEW (Alarm, Pomodoro, Stopwatch, Notes)
        // ════════════════════════════════════════════════════════
        ColumnLayout {
            id: toolFullCanvasWrapper
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            visible: root.activeToolScreen !== ""

            // Top Navigation Bar with Back Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: backBtnMa.containsMouse ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25) : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.35)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 16
                        color: backBtnMa.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    }

                    MouseArea {
                        id: backBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeToolScreen = ""
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        switch (root.activeToolScreen) {
                            case "alarm": return "Alarm Utility"
                            case "notes": return "Markdown Notes (.md)"
                            case "todo": return "To-Do List"
                            default: return "Tool Workspace"
                        }
                    }
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }

            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
            }

            // ── A. FULL ALARM CANVAS (Material 3 Wheel Picker UI) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                visible: root.activeToolScreen === "alarm"

                // ── RINGING BANNER (persistent, only visible when alarm is ringing) ──
                Rectangle {
                    id: ringingBanner
                    Layout.fillWidth: true
                    visible: Alarms.isRinging
                    implicitHeight: Alarms.isRinging ? ringingBannerContent.implicitHeight + 20 : 0
                    radius: Appearance.rounding.large
                    clip: true
                    color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.20)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.60)

                    ColumnLayout {
                        id: ringingBannerContent
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 12
                        }
                        spacing: 8

                        // Top row: icon + label
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                text: "alarm"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Alarms.activeRingingAlarm ? Alarms.activeRingingAlarm.label : "Alarm"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: Alarms.activeRingingAlarm ? root.formatAlarmTime(Alarms.activeRingingAlarm.time) : ""
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                            }
                        }

                        // Bottom row: Snooze + Stop buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Snooze button
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: Appearance.rounding.full
                                color: ColorUtils.applyAlpha(Appearance.colors.colLayer3, 0.60)
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "snooze"
                                        iconSize: 15
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: "5 min"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Alarms.snoozeActiveAlarm()
                                }
                            }

                            // Stop button
                            Rectangle {
                                implicitWidth: 80
                                implicitHeight: 32
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colPrimary

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 15
                                        color: Appearance.colors.colOnPrimary
                                    }
                                    StyledText {
                                        text: "Stop"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Alarms.stopRinging()
                                }
                            }
                        }
                    }
                }

                // Header Switcher: Create vs Saved Alarms
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Appearance.rounding.full
                        color: !root.alarmShowSavedList ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.40)
                        StyledText {
                            anchors.centerIn: parent
                            text: root.editingAlarmId !== "" ? "Edit Alarm" : "New Alarm"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: !root.alarmShowSavedList ? Font.Bold : Font.Medium
                            color: !root.alarmShowSavedList ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.alarmShowSavedList) {
                                    root.editingAlarmId = ""
                                    alarmLabelField.text = ""
                                }
                                root.alarmShowSavedList = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Appearance.rounding.full
                        color: root.alarmShowSavedList ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.40)
                        StyledText {
                            anchors.centerIn: parent
                            text: `Saved (${Alarms.alarmsList.length})`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: root.alarmShowSavedList ? Font.Bold : Font.Medium
                            color: root.alarmShowSavedList ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.alarmShowSavedList = true
                        }
                    }
                }

                // ── MODE 1: CREATE ALARM (Wheel Picker + Bottom Sheet Card) ──
                Flickable {
                    visible: !root.alarmShowSavedList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: createAlarmCol.implicitHeight

                    ColumnLayout {
                        id: createAlarmCol
                        width: parent.width
                        spacing: 14

                        // ── 1. Top Wheel / Tumbler Time Picker ──────────
                        Rectangle {
                            id: wheelBox
                            Layout.fillWidth: true
                            implicitHeight: 155
                            radius: Appearance.rounding.large
                            color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.50)
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)
                            focus: true

                            Component.onCompleted: {
                                if (root.activeToolScreen === "alarm") forceActiveFocus()
                            }
                            onVisibleChanged: {
                                if (visible && root.activeToolScreen === "alarm") forceActiveFocus()
                            }

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Left) {
                                    if (root.alarmFocusedCol === "ampm") root.alarmFocusedCol = "minutes"
                                    else if (root.alarmFocusedCol === "minutes") root.alarmFocusedCol = "hours"
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Right) {
                                    if (root.alarmFocusedCol === "hours") root.alarmFocusedCol = "minutes"
                                    else if (root.alarmFocusedCol === "minutes") root.alarmFocusedCol = "ampm"
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    if (root.alarmFocusedCol === "hours") {
                                        root.alarmPickerHour = (root.alarmPickerHour - 1 < 1) ? 12 : root.alarmPickerHour - 1
                                    } else if (root.alarmFocusedCol === "minutes") {
                                        root.alarmPickerMinute = (root.alarmPickerMinute - 1 < 0) ? 59 : root.alarmPickerMinute - 1
                                    } else if (root.alarmFocusedCol === "ampm") {
                                        root.alarmPickerAmPm = (root.alarmPickerAmPm === "am") ? "pm" : "am"
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (root.alarmFocusedCol === "hours") {
                                        root.alarmPickerHour = (root.alarmPickerHour + 1 > 12) ? 1 : root.alarmPickerHour + 1
                                    } else if (root.alarmFocusedCol === "minutes") {
                                        root.alarmPickerMinute = (root.alarmPickerMinute + 1 > 59) ? 0 : root.alarmPickerMinute + 1
                                    } else if (root.alarmFocusedCol === "ampm") {
                                        root.alarmPickerAmPm = (root.alarmPickerAmPm === "am") ? "pm" : "am"
                                    }
                                    event.accepted = true
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                // Hours Tumbler
                                Item {
                                    implicitWidth: hoursCol.implicitWidth
                                    implicitHeight: hoursCol.implicitHeight

                                    // Minimal subtle indicator line
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -6
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 18
                                        height: 2
                                        radius: 1
                                        color: (root.alarmFocusedCol === "hours") ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.60) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ColumnLayout {
                                        id: hoursCol
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        // Prev Hour
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: { let prev = root.alarmPickerHour - 1; return prev < 1 ? 12 : prev }
                                            font.pixelSize: 26
                                            font.weight: Font.DemiBold
                                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerHour = (root.alarmPickerHour - 1 < 1) ? 12 : root.alarmPickerHour - 1
                                                    root.alarmFocusedCol = "hours"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }

                                        // Selected Hour (Big & Bold)
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: String(root.alarmPickerHour)
                                            font.pixelSize: 44
                                            font.weight: Font.Black
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        // Next Hour
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: { let next = root.alarmPickerHour + 1; return next > 12 ? 1 : next }
                                            font.pixelSize: 26
                                            font.weight: Font.DemiBold
                                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerHour = (root.alarmPickerHour + 1 > 12) ? 1 : root.alarmPickerHour + 1
                                                    root.alarmFocusedCol = "hours"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        z: 1
                                        onClicked: {
                                            root.alarmFocusedCol = "hours"
                                            wheelBox.forceActiveFocus()
                                        }
                                        onWheel: (wheel) => {
                                            root.alarmFocusedCol = "hours"
                                            wheelBox.forceActiveFocus()
                                            if (wheel.angleDelta.y > 0) root.alarmPickerHour = (root.alarmPickerHour - 1 < 1) ? 12 : root.alarmPickerHour - 1
                                            else if (wheel.angleDelta.y < 0) root.alarmPickerHour = (root.alarmPickerHour + 1 > 12) ? 1 : root.alarmPickerHour + 1
                                        }
                                    }
                                }

                                // Colon Separator
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: ":"
                                    font.pixelSize: 38
                                    font.weight: Font.Black
                                    color: Appearance.colors.colOnLayer1
                                }

                                // Minutes Tumbler
                                Item {
                                    implicitWidth: minCol.implicitWidth
                                    implicitHeight: minCol.implicitHeight

                                    // Minimal subtle indicator line
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -6
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 18
                                        height: 2
                                        radius: 1
                                        color: (root.alarmFocusedCol === "minutes") ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.60) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ColumnLayout {
                                        id: minCol
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        // Prev Minute
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: { let prev = root.alarmPickerMinute - 1; return String(prev < 0 ? 59 : prev).padStart(2, '0') }
                                            font.pixelSize: 26
                                            font.weight: Font.DemiBold
                                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerMinute = (root.alarmPickerMinute - 1 < 0) ? 59 : root.alarmPickerMinute - 1
                                                    root.alarmFocusedCol = "minutes"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }

                                        // Selected Minute (Big & Bold)
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: String(root.alarmPickerMinute).padStart(2, '0')
                                            font.pixelSize: 44
                                            font.weight: Font.Black
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        // Next Minute
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: { let next = root.alarmPickerMinute + 1; return String(next > 59 ? 0 : next).padStart(2, '0') }
                                            font.pixelSize: 26
                                            font.weight: Font.DemiBold
                                            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerMinute = (root.alarmPickerMinute + 1 > 59) ? 0 : root.alarmPickerMinute + 1
                                                    root.alarmFocusedCol = "minutes"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        z: 1
                                        onClicked: {
                                            root.alarmFocusedCol = "minutes"
                                            wheelBox.forceActiveFocus()
                                        }
                                        onWheel: (wheel) => {
                                            root.alarmFocusedCol = "minutes"
                                            wheelBox.forceActiveFocus()
                                            if (wheel.angleDelta.y > 0) root.alarmPickerMinute = (root.alarmPickerMinute - 1 < 0) ? 59 : root.alarmPickerMinute - 1
                                            else if (wheel.angleDelta.y < 0) root.alarmPickerMinute = (root.alarmPickerMinute + 1 > 59) ? 0 : root.alarmPickerMinute + 1
                                        }
                                    }
                                }

                                // AM / PM Selector
                                Item {
                                    implicitWidth: ampmCol.implicitWidth
                                    implicitHeight: ampmCol.implicitHeight

                                    // Minimal subtle indicator line
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -6
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 18
                                        height: 2
                                        radius: 1
                                        color: (root.alarmFocusedCol === "ampm") ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.60) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ColumnLayout {
                                        id: ampmCol
                                        spacing: 12
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.leftMargin: 6

                                        StyledText {
                                            Layout.alignment: Qt.AlignLeft
                                            text: "am"
                                            font.pixelSize: 22
                                            font.weight: (root.alarmPickerAmPm === "am") ? Font.Black : Font.DemiBold
                                            color: (root.alarmPickerAmPm === "am") ? Appearance.colors.colOnLayer1 : ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerAmPm = "am"
                                                    root.alarmFocusedCol = "ampm"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignLeft
                                            text: "pm"
                                            font.pixelSize: 22
                                            font.weight: (root.alarmPickerAmPm === "pm") ? Font.Black : Font.DemiBold
                                            color: (root.alarmPickerAmPm === "pm") ? Appearance.colors.colOnLayer1 : ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.70)
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.alarmPickerAmPm = "pm"
                                                    root.alarmFocusedCol = "ampm"
                                                    wheelBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1
                                        onClicked: {
                                            root.alarmFocusedCol = "ampm"
                                            wheelBox.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }

                        // ── 2. Bottom Sheet Card ────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            radius: Appearance.rounding.large
                            color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
                            implicitHeight: bCardContent.implicitHeight + 24

                            ColumnLayout {
                                id: bCardContent
                                anchors { fill: parent; margins: 12 }
                                spacing: 12

                                // Row 1: Date text + Calendar Button
                                RowLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: root.alarmSpecificDate ? `Date: ${root.alarmSpecificDate}` : `Today-${Qt.formatDate(new Date(), "ddd, d MMM")}`
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    Item { Layout.fillWidth: true }
                                    MaterialSymbol {
                                        text: "edit_calendar"
                                        iconSize: 19
                                        color: calBtnMa.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                                        MouseArea {
                                            id: calBtnMa
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dateInputRow.visible = !dateInputRow.visible
                                        }
                                    }
                                }

                                // Quick Future Date Input (Collapsible)
                                RowLayout {
                                    id: dateInputRow
                                    Layout.fillWidth: true
                                    visible: false
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colLayer1
                                        border.width: 1
                                        border.color: specificDateField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                                        TextField {
                                            id: specificDateField
                                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                            placeholderText: "Specific Date (YYYY-MM-DD)"
                                            placeholderTextColor: Appearance.colors.colSubtext
                                            color: Appearance.colors.colOnLayer1
                                            background: null
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            onActiveFocusChanged: { if (activeFocus) root.isUserTyping = true }
                                            onAccepted: {
                                                root.alarmSpecificDate = text.trim()
                                                focus = false
                                                root.isUserTyping = false
                                            }
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 15
                                        color: Appearance.colors.colSubtext
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.alarmSpecificDate = ""
                                                specificDateField.text = ""
                                                dateInputRow.visible = false
                                            }
                                        }
                                    }
                                }

                                // Row 2: Days of the Week Selector (M T W T F S S)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    readonly property var dayItems: [
                                        { day: 1, label: "M", isSunday: false },
                                        { day: 2, label: "T", isSunday: false },
                                        { day: 3, label: "W", isSunday: false },
                                        { day: 4, label: "T", isSunday: false },
                                        { day: 5, label: "F", isSunday: false },
                                        { day: 6, label: "S", isSunday: false },
                                        { day: 0, label: "S", isSunday: true  }
                                    ]

                                    Repeater {
                                        model: parent.dayItems
                                        delegate: Item {
                                            Layout.fillWidth: true
                                            implicitHeight: 30

                                            readonly property bool isSelected: root.alarmSelectedDays.includes(modelData.day)

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 26; height: 26; radius: 13
                                                color: isSelected
                                                    ? (modelData.isSunday ? Appearance.m3colors.m3error : Appearance.colors.colPrimary)
                                                    : (dayChipMa.containsMouse ? Appearance.colors.colLayer3Hover : "transparent")

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.pixelSize: 12
                                                    font.weight: Font.Bold
                                                    color: isSelected
                                                        ? "#ffffff"
                                                        : (modelData.isSunday ? "#f87171" : Appearance.colors.colOnLayer1)
                                                }

                                                MouseArea {
                                                    id: dayChipMa
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let days = root.alarmSelectedDays.slice()
                                                        let idx = days.indexOf(modelData.day)
                                                        if (idx >= 0) days.splice(idx, 1)
                                                        else days.push(modelData.day)
                                                        root.alarmSelectedDays = days
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Row 3: Alarm Name Underline Input Field
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    color: "transparent"

                                    TextField {
                                        id: alarmLabelField
                                        anchors.fill: parent
                                        placeholderText: "Alarm name"
                                        placeholderTextColor: Appearance.colors.colSubtext
                                        color: Appearance.colors.colOnLayer1
                                        background: null
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        leftPadding: 2
                                        onActiveFocusChanged: { if (activeFocus) root.isUserTyping = true }
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: alarmLabelField.activeFocus ? 1.5 : 1
                                        color: alarmLabelField.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.50)
                                    }
                                }

                                // Row 4: Action Button (Save / Set Alarm)
                                RowLayout {
                                    Layout.fillWidth: true
                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        implicitWidth: 105
                                        implicitHeight: 32
                                        radius: Appearance.rounding.full
                                        color: setAlarmBtnMa.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimary

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            MaterialSymbol {
                                                text: "check"
                                                iconSize: 15
                                                color: Appearance.colors.colOnPrimary
                                            }
                                            StyledText {
                                                text: root.editingAlarmId !== "" ? "Update Alarm" : "Set Alarm"
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.weight: Font.Bold
                                                color: Appearance.colors.colOnPrimary
                                            }
                                        }

                                        MouseArea {
                                            id: setAlarmBtnMa
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let h24 = root.alarmPickerHour
                                                if (root.alarmPickerAmPm === "am") {
                                                    if (h24 === 12) h24 = 0
                                                } else {
                                                    if (h24 !== 12) h24 += 12
                                                }
                                                let timeStr = `${String(h24).padStart(2, '0')}:${String(root.alarmPickerMinute).padStart(2, '0')}`
                                                let labelStr = alarmLabelField.text.trim() || "Alarm"
                                                if (root.editingAlarmId !== "") {
                                                    Alarms.updateAlarm(root.editingAlarmId, timeStr, labelStr, root.alarmSelectedDays, root.alarmSpecificDate)
                                                    root.editingAlarmId = ""
                                                } else {
                                                    Alarms.addAlarm(timeStr, labelStr, root.alarmSelectedDays, root.alarmSpecificDate)
                                                }
                                                alarmLabelField.text = ""
                                                alarmLabelField.focus = false
                                                root.isUserTyping = false
                                                root.alarmShowSavedList = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── MODE 2: SAVED ALARMS LIST ───────────────────
                Flickable {
                    visible: root.alarmShowSavedList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: savedAlarmsCol.implicitHeight
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }

                    ColumnLayout {
                        id: savedAlarmsCol
                        width: parent.width
                        spacing: 6

                        StyledText {
                            visible: Alarms.alarmsList.length === 0
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                            text: "No alarms configured yet."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Repeater {
                            model: Alarms.alarmsList
                            delegate: Rectangle {
                                id: almCard
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: Appearance.rounding.normal
                                color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.45)
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "alarm"
                                        iconSize: 20
                                        color: almCard.modelData.enabled ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: -2
                                        StyledText {
                                            text: root.formatAlarmTime(almCard.modelData.time)
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            font.weight: Font.Bold
                                            color: almCard.modelData.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                                        }
                                        StyledText {
                                            text: almCard.modelData.label || "Alarm"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Edit button
                                    Rectangle {
                                        implicitWidth: 26; implicitHeight: 26; radius: 13
                                        color: editSavedAlmMa.containsMouse ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25) : "transparent"

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "edit"
                                            iconSize: 15
                                            color: editSavedAlmMa.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }

                                        MouseArea {
                                            id: editSavedAlmMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.editingAlarmId = almCard.modelData.id
                                                let t24 = almCard.modelData.time || "06:00"
                                                let parts = t24.split(":")
                                                let h24 = parseInt(parts[0] || "6", 10)
                                                let m = parseInt(parts[1] || "0", 10)
                                                root.alarmPickerAmPm = (h24 >= 12) ? "pm" : "am"
                                                root.alarmPickerHour = (h24 % 12 === 0) ? 12 : (h24 % 12)
                                                root.alarmPickerMinute = m
                                                alarmLabelField.text = almCard.modelData.label || ""
                                                root.alarmSelectedDays = almCard.modelData.repeatDays || []
                                                root.alarmSpecificDate = almCard.modelData.date || ""
                                                root.alarmShowSavedList = false
                                            }
                                        }
                                    }

                                    // Switch
                                    Rectangle {
                                        implicitWidth: 36; implicitHeight: 20; radius: 10
                                        color: almCard.modelData.enabled ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: almCard.modelData.enabled ? 18 : 2
                                            width: 16; height: 16; radius: 8
                                            color: "#ffffff"
                                            Behavior on x { NumberAnimation { duration: 120 } }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Alarms.toggleAlarm(almCard.modelData.id)
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 17
                                        color: delSavedAlmMa.containsMouse ? Appearance.colors.colError : Appearance.colors.colSubtext
                                        MouseArea {
                                            id: delSavedAlmMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Alarms.deleteAlarm(almCard.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── B. FULL MARKDOWN NOTES CANVAS (.md) ─────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                visible: root.activeToolScreen === "notes"

                // ── LIST VIEW ─────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    visible: root.notesViewMode === "list"

                    // Toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            text: `${Notes.list.length} note${Notes.list.length !== 1 ? "s" : ""}`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }

                        // New Note Button
                        Rectangle {
                            implicitWidth: 72; implicitHeight: 26
                            radius: Appearance.rounding.full
                            color: newNoteBtnMa.containsMouse
                                ? ColorUtils.applyAlpha("#e8e8e8", 0.22)
                                : ColorUtils.applyAlpha("#e8e8e8", 0.12)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha("#ffffff", 0.12)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    text: "add"
                                    iconSize: 13
                                    color: ColorUtils.applyAlpha("#ffffff", 0.80)
                                }
                                StyledText {
                                    text: "New"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Medium
                                    color: ColorUtils.applyAlpha("#ffffff", 0.80)
                                }
                            }
                            MouseArea {
                                id: newNoteBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.notesEditingId = ""
                                    root.notesShowPreview = false
                                    noteEditor.text = ""
                                    root.notesViewMode = "edit"
                                    root.isUserTyping = true
                                    Qt.callLater(() => noteEditor.forceActiveFocus())
                                }
                            }
                        }
                    }

                    // Notes list
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: notesListCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }

                        ColumnLayout {
                            id: notesListCol
                            width: parent.width
                            spacing: 5

                            StyledText {
                                visible: Notes.list.length === 0
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 24
                                text: "No notes yet.\nTap + New to create one."
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }

                            Repeater {
                                model: Notes.list
                                delegate: Rectangle {
                                    id: noteListCard
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: noteCardContent.implicitHeight + 18
                                    radius: Appearance.rounding.normal
                                    // Premium neutral card — no theme color cycling
                                    color: (noteCardMa.containsMouse || noteDelMa.containsMouse)
                                        ? ColorUtils.applyAlpha("#ffffff", 0.07)
                                        : ColorUtils.applyAlpha("#ffffff", 0.04)
                                    border.width: 1
                                    border.color: ColorUtils.applyAlpha("#ffffff", 0.09)

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    // Full card click to open note (excluding delete button area)
                                    MouseArea {
                                        id: noteCardMa
                                        anchors.fill: parent
                                        anchors.rightMargin: 32
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.notesEditingId = noteListCard.modelData.id
                                            root.notesShowPreview = false
                                            noteEditor.text = noteListCard.modelData.content || ""
                                            root.notesViewMode = "edit"
                                            root.isUserTyping = true
                                            Qt.callLater(() => noteEditor.forceActiveFocus())
                                        }
                                    }

                                    ColumnLayout {
                                        id: noteCardContent
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                        spacing: 3

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            // Title (first line of markdown)
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: {
                                                    let lines = (noteListCard.modelData.content || "").split("\n")
                                                    let title = lines[0].replace(/^#+\s*/, "").replace(/\*\*/g, "").trim()
                                                    return title || "Untitled"
                                                }
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                                font.weight: Font.DemiBold
                                                color: ColorUtils.applyAlpha("#ffffff", 0.90)
                                                elide: Text.ElideRight
                                            }

                                            // Delete btn (x)
                                            Rectangle {
                                                implicitWidth: 22; implicitHeight: 22; radius: 11
                                                color: noteDelMa.containsMouse ? ColorUtils.applyAlpha("#ff6b6b", 0.25) : "transparent"

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    text: "close"
                                                    iconSize: 14
                                                    color: noteDelMa.containsMouse
                                                        ? ColorUtils.applyAlpha("#ff6b6b", 0.95)
                                                        : ColorUtils.applyAlpha("#ffffff", 0.40)
                                                }

                                                MouseArea {
                                                    id: noteDelMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        Notes.deleteNote(noteListCard.modelData.id)
                                                    }
                                                }
                                            }
                                        }

                                        // Preview snippet (second line, trimmed)
                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: {
                                                let lines = (noteListCard.modelData.content || "").split("\n")
                                                return lines.length > 1 && lines[1].trim().length > 0
                                            }
                                            text: {
                                                let lines = (noteListCard.modelData.content || "").split("\n")
                                                return lines.slice(1).join(" ").replace(/[#*`_~]/g, "").trim().substring(0, 80)
                                            }
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: ColorUtils.applyAlpha("#ffffff", 0.42)
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── EDITOR VIEW ───────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    visible: root.notesViewMode === "edit"

                    // Auto-save timer (debounce 800ms)
                    Timer {
                        id: noteAutoSaveTimer
                        interval: 800
                        repeat: false
                        onTriggered: {
                            let txt = noteEditor.text
                            if (root.notesEditingId) {
                                Notes.updateNote(root.notesEditingId, txt)
                            } else if (txt.trim().length > 0) {
                                root.notesEditingId = Notes.addNote(txt)
                            }
                        }
                    }

                    // Editor toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Back to list
                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 14
                            color: backToListMa.containsMouse
                                ? ColorUtils.applyAlpha("#ffffff", 0.12)
                                : ColorUtils.applyAlpha("#ffffff", 0.06)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha("#ffffff", 0.10)
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "arrow_back"
                                iconSize: 14
                                color: ColorUtils.applyAlpha("#ffffff", 0.75)
                            }
                            MouseArea {
                                id: backToListMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Final save before leaving
                                    noteAutoSaveTimer.stop()
                                    let txt = noteEditor.text
                                    if (root.notesEditingId) {
                                        Notes.updateNote(root.notesEditingId, txt)
                                    } else if (txt.trim().length > 0) {
                                        Notes.addNote(txt)
                                    }
                                    root.notesEditingId = ""
                                    root.notesViewMode = "list"
                                    root.notesShowPreview = false
                                    root.isUserTyping = false
                                }
                            }
                        }

                        // Auto-save status
                        StyledText {
                            Layout.fillWidth: true
                            text: noteAutoSaveTimer.running ? "saving..." : (root.notesEditingId ? "auto-saved ✓" : "new note")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: ColorUtils.applyAlpha("#ffffff", 0.35)
                        }

                        // Edit / Preview toggle
                        Rectangle {
                            implicitWidth: 70; implicitHeight: 24
                            radius: Appearance.rounding.full
                            color: previewToggleMa.containsMouse
                                ? ColorUtils.applyAlpha("#ffffff", 0.14)
                                : ColorUtils.applyAlpha("#ffffff", 0.07)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha("#ffffff", 0.12)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    text: root.notesShowPreview ? "edit" : "visibility"
                                    iconSize: 12
                                    color: ColorUtils.applyAlpha("#ffffff", 0.70)
                                }
                                StyledText {
                                    text: root.notesShowPreview ? "Edit" : "Preview"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Medium
                                    color: ColorUtils.applyAlpha("#ffffff", 0.70)
                                }
                            }
                            MouseArea {
                                id: previewToggleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.notesShowPreview = !root.notesShowPreview
                                    if (!root.notesShowPreview) {
                                        root.isUserTyping = true
                                        Qt.callLater(() => noteEditor.forceActiveFocus())
                                    } else {
                                        root.isUserTyping = false
                                    }
                                }
                            }
                        }
                    }

                    // Editor area — unified container
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Appearance.rounding.normal
                        color: ColorUtils.applyAlpha("#ffffff", 0.03)
                        border.width: 1
                        border.color: noteEditor.activeFocus
                            ? ColorUtils.applyAlpha("#ffffff", 0.18)
                            : ColorUtils.applyAlpha("#ffffff", 0.07)
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Background click to focus editor
                        MouseArea {
                            anchors.fill: parent
                            visible: !root.notesShowPreview
                            onClicked: {
                                noteEditor.forceActiveFocus()
                                noteEditor.cursorPosition = noteEditor.text.length
                            }
                        }

                        Flickable {
                            id: noteEditorFlick
                            anchors.fill: parent
                            contentWidth: width
                            contentHeight: Math.max(height, root.notesShowPreview ? (notePreviewCol.implicitHeight + 20) : (noteEditor.implicitHeight + 20))
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3 }

                            // ── Raw Markdown Editor ──
                            TextArea {
                                id: noteEditor
                                visible: !root.notesShowPreview
                                width: noteEditorFlick.width
                                topPadding: 10
                                bottomPadding: 10
                                leftPadding: 10
                                rightPadding: 10
                                wrapMode: TextArea.Wrap
                                background: null
                                selectByMouse: true
                                color: ColorUtils.applyAlpha("#ffffff", 0.88)
                                selectedTextColor: "#ffffff"
                                selectionColor: ColorUtils.applyAlpha("#ffffff", 0.20)
                                placeholderText: "# Note Title\n\n- List item\n**bold**, *italic*, `code`\n\n> blockquote"
                                placeholderTextColor: ColorUtils.applyAlpha("#ffffff", 0.20)
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.mono ?? Appearance.font.family.main

                                onActiveFocusChanged: {
                                    root.isUserTyping = activeFocus
                                }
                                onTextChanged: {
                                    noteAutoSaveTimer.restart()
                                }
                                Keys.onTabPressed: {
                                    noteEditor.insert(noteEditor.cursorPosition, "  ")
                                    event.accepted = true
                                }
                            }

                            // ── Live Markdown Preview (Full AI-grade Markdown, LaTeX, Tables, Code & Think blocks) ──
                            ColumnLayout {
                                id: notePreviewCol
                                visible: root.notesShowPreview
                                width: noteEditorFlick.width - 12
                                x: 6
                                y: 6
                                spacing: 6

                                StyledText {
                                    visible: !noteEditor.text || noteEditor.text.trim().length === 0
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10
                                    text: "*Start typing in Edit mode to preview rich content…*"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: ColorUtils.applyAlpha("#ffffff", 0.35)
                                    wrapMode: Text.Wrap
                                }

                                Repeater {
                                    model: ScriptModel {
                                        values: StringUtils.splitMarkdownBlocks(noteEditor.text || "")
                                    }
                                    delegate: DelegateChooser {
                                        id: previewBlockChooser
                                        role: "type"

                                        DelegateChoice {
                                            roleValue: "code"
                                            MessageCodeBlock {
                                                Layout.fillWidth: true
                                                editing: false
                                                renderMarkdown: true
                                                enableMouseSelection: true
                                                segmentContent: modelData.content
                                                segmentLang: modelData.lang
                                            }
                                        }
                                        DelegateChoice {
                                            roleValue: "think"
                                            MessageThinkBlock {
                                                Layout.fillWidth: true
                                                editing: false
                                                renderMarkdown: true
                                                enableMouseSelection: true
                                                segmentContent: modelData.content
                                                done: true
                                                completed: true
                                            }
                                        }
                                        DelegateChoice {
                                            roleValue: "text"
                                            MessageTextBlock {
                                                Layout.fillWidth: true
                                                editing: false
                                                renderMarkdown: true
                                                enableMouseSelection: true
                                                segmentContent: modelData.content
                                                done: true
                                                forceDisableChunkSplitting: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── C. FULL TO-DO LIST CANVAS (Real-Time Synchronized Task Manager) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: root.activeToolScreen === "todo"

                // 1. Task Creation Input Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Appearance.rounding.normal
                    color: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.40)
                    border.width: 1
                    border.color: todoTaskInput.activeFocus ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.70)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 8

                        MaterialSymbol {
                            text: "add_task"
                            iconSize: 17
                            color: Appearance.colors.colSubtext
                        }

                        TextField {
                            id: todoTaskInput
                            Layout.fillWidth: true
                            placeholderText: "Add a task & press Enter..."
                            placeholderTextColor: Appearance.colors.colSubtext
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            background: Item {}
                            selectByMouse: true
                            onAccepted: {
                                if (text.trim().length > 0) {
                                    Todo.addTask(text.trim())
                                    text = ""
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: todoAddBtnMa.containsMouse ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.20)
                            visible: todoTaskInput.text.trim().length > 0

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "arrow_forward"
                                iconSize: 14
                                color: Appearance.colors.colOnPrimary
                            }

                            MouseArea {
                                id: todoAddBtnMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (todoTaskInput.text.trim().length > 0) {
                                        Todo.addTask(todoTaskInput.text.trim())
                                        todoTaskInput.text = ""
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. Filter Pills Bar (All | Pending | Done)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "all", label: "All", count: (Todo.list ?? []).length },
                            { id: "pending", label: "Pending", count: (Todo.list ?? []).filter(t => !t.done).length },
                            { id: "done", label: "Done", count: (Todo.list ?? []).filter(t => t.done).length }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Appearance.rounding.small
                            color: root.todoFilter === modelData.id
                                ? Appearance.colors.colPrimary
                                : (pillFilterMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.50) : ColorUtils.transparentize(Appearance.colors.colLayer2, 0.60))
                            border.width: 1
                            border.color: root.todoFilter === modelData.id
                                ? Appearance.colors.colPrimary
                                : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.70)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: root.todoFilter === modelData.id ? Font.Bold : Font.Normal
                                    color: root.todoFilter === modelData.id ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }

                                StyledText {
                                    text: `(${modelData.count})`
                                    font.pixelSize: 10
                                    color: root.todoFilter === modelData.id ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                }
                            }

                            MouseArea {
                                id: pillFilterMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.todoFilter = modelData.id
                            }
                        }
                    }
                }

                // 3. Scrollable Task List
                Flickable {
                    id: todoListFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: todoItemsCol.implicitHeight + 10
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                    }

                    ColumnLayout {
                        id: todoItemsCol
                        width: todoListFlickable.width
                        spacing: 6

                        // Empty placeholder
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 120
                            visible: todoItemsCol.filteredTodoList.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.todoFilter === "done" ? "task_alt" : "checklist_rtl"
                                    iconSize: 28
                                    color: ColorUtils.applyAlpha(Appearance.colors.colSubtext, 0.40)
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.todoFilter === "done" ? "No completed tasks yet." : (root.todoFilter === "pending" ? "All tasks completed! 🎉" : "No tasks added yet.")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        readonly property var filteredTodoList: {
                            let raw = (Todo.list ?? [])
                            let result = []
                            for (let i = 0; i < raw.length; i++) {
                                let item = raw[i]
                                if (root.todoFilter === "pending" && item.done) continue
                                if (root.todoFilter === "done" && !item.done) continue
                                result.push({
                                    originalIndex: i,
                                    content: item.content || "",
                                    done: !!item.done
                                })
                            }
                            return result
                        }

                        Repeater {
                            model: todoItemsCol.filteredTodoList

                            delegate: Rectangle {
                                id: taskRowCard
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: Appearance.rounding.small
                                color: taskRowMa.containsMouse
                                    ? ColorUtils.transparentize(Appearance.colors.colLayer3, 0.40)
                                    : ColorUtils.transparentize(Appearance.colors.colLayer2, 0.60)
                                border.width: 1
                                border.color: modelData.done
                                    ? ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.85)
                                    : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                                    spacing: 8

                                    // Checkbox button
                                    Rectangle {
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        radius: 6
                                        color: modelData.done
                                            ? Appearance.colors.colPrimary
                                            : (chkMa.containsMouse ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.70) : "transparent")
                                        border.width: 1.5
                                        border.color: modelData.done ? Appearance.colors.colPrimary : Appearance.colors.colSubtext

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "check"
                                            iconSize: 14
                                            color: Appearance.colors.colOnPrimary
                                            visible: modelData.done
                                        }

                                        MouseArea {
                                            id: chkMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.done) {
                                                    Todo.markUnfinished(modelData.originalIndex)
                                                } else {
                                                    Todo.markDone(modelData.originalIndex)
                                                }
                                            }
                                        }
                                    }

                                    // Task text
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.content
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.strikeout: modelData.done
                                        font.weight: modelData.done ? Font.Normal : Font.DemiBold
                                        color: modelData.done ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }

                                    // Delete button
                                    Rectangle {
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        radius: 12
                                        color: delBtnMa.containsMouse ? ColorUtils.applyAlpha("#ef4444", 0.20) : "transparent"
                                        opacity: taskRowMa.containsMouse || delBtnMa.containsMouse ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 120 } }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "delete"
                                            iconSize: 14
                                            color: delBtnMa.containsMouse ? "#ef4444" : Appearance.colors.colSubtext
                                        }

                                        MouseArea {
                                            id: delBtnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Todo.deleteItem(modelData.originalIndex)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: taskRowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }
        }

        // Toggle Handle
        Rectangle {
            id: toggleHandle
            width: 16; height: 16; radius: 4
            color: Appearance.colors.colOnPrimaryContainer
            anchors { left: card.left; bottom: card.bottom; margins: 4 }
            opacity: (root.containsMouse || toggleArea.containsMouse) ? 0.5 : 0
            visible: opacity > 0 && !Config.options.background.widgetsLocked
            Behavior on opacity { NumberAnimation { duration: 150 } }

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.sizeMode === "compact" ? "expand" : "compress"
                iconSize: 11
                color: Appearance.colors.colPrimaryContainer
            }

            MouseArea {
                id: toggleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.sizeMode = root.sizeMode === "compact" ? "full" : "compact"
                    if (root.configEntry) root.configEntry.sizeMode = root.sizeMode
                }
            }
        }

        ResizeHandler {
            anchorItem: card
            hoverActive: root.containsMouse
            locked: Config.options.background.widgetsLocked
            currentWidth: root.implicitWidth
            currentHeight: root.implicitHeight
            resizeMode: "vertical"
            onResized: newHeight => {
                let threshold = (root.sectionMode === "wellbeing") ? 395 : 375
                root.sizeMode = (newHeight < threshold) ? "compact" : "full"
            }
            onResizeFinished: {
                if (root.configEntry) root.configEntry.sizeMode = root.sizeMode
            }
        }
    }
}
