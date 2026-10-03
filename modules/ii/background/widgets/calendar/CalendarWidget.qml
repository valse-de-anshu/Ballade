import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.ii.background.widgets
import "IndianCalendar.js" as IndianCalendar

AbstractBackgroundWidget {
    id: root
    configEntryName: "calendar"
    hoverEnabled: true

    readonly property real cardSpacing: 12
    readonly property real singleWidth: 132
    readonly property real cardHeight: 120

    readonly property real snapWidth1: singleWidth            
    readonly property real snapWidth2: singleWidth * 2 + cardSpacing  
    readonly property real snapWidth3: 640  

    property string sizeMode: (root.configEntry && root.configEntry.sizeMode) ? root.configEntry.sizeMode : "2x2"

    Connections {
        target: root.configEntry
        function onSizeModeChanged() {
            if (root.configEntry && root.configEntry.sizeMode) {
                root.sizeMode = root.configEntry.sizeMode
            }
        }
        function onSatelliteXChanged() {
            if (root.configEntry && typeof root.configEntry.satelliteX === "number") {
                root.satelliteX = root.configEntry.satelliteX
            }
        }
        function onSatelliteYChanged() {
            if (root.configEntry && typeof root.configEntry.satelliteY === "number") {
                root.satelliteY = root.configEntry.satelliteY
            }
        }
        function onSatelliteRotationChanged() {
            if (root.configEntry && typeof root.configEntry.satelliteRotation === "number") {
                root.satelliteRotation = root.configEntry.satelliteRotation
            }
        }
    }

    property real widgetWidth: {
        switch (root.sizeMode) {
            case "1x1": return snapWidth1
            case "1x2": return snapWidth2
            default:    return snapWidth3
        }
    }

    function modeForWidth(value) {
        var mid1 = (snapWidth1 + snapWidth2) / 2
        var mid2 = (snapWidth2 + snapWidth3) / 2
        if (value < mid1) return "1x1"
        if (value < mid2) return "1x2"
        return "2x2"
    }

    property int monthShift: 0
    readonly property var today: (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date : new Date()
    readonly property string todayKey: formatDateKey(root.today)
    property var selectedDate: root.today
    property var viewingDate: new Date()

    onTodayKeyChanged: {
        if (root.monthShift === 0) {
            root.selectedDate = root.today
            updateViewingMonth()
        }
    }

    function updateViewingMonth() {
        let now = (typeof DateTime !== "undefined" && DateTime.clock) ? DateTime.clock.date : new Date()
        let d = new Date(now.getFullYear(), now.getMonth(), 1)
        d.setMonth(d.getMonth() + root.monthShift)
        root.viewingDate = d
        root.weeks = root.getMonthMatrix(d)
    }

    onMonthShiftChanged: {
        updateViewingMonth()
    }

    Component.onCompleted: {
        updateViewingMonth()
    }

    function formatDateKey(date) {
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        var mm = m < 10 ? "0" + m : "" + m
        var dd = d < 10 ? "0" + d : "" + d
        return y + "-" + mm + "-" + dd
    }

    function getWeekNumber(d) {
        var date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var dayNum = date.getUTCDay() || 7
        date.setUTCDate(date.getUTCDate() + 4 - dayNum)
        var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
        return Math.ceil((((date - yearStart) / 86400000) + 1) / 7)
    }

    // ----------------------------------------------------
    // User Events & Pinned Targets via CalendarService Singleton
    // ----------------------------------------------------
    readonly property var userEvents: CalendarService.userEvents
    property bool isAddingEvent: false
    property string newEventText: ""

    readonly property var pinnedTargets: CalendarService.pinnedTargets
    readonly property var targetData: (pinnedTargets && pinnedTargets.length > 0)
        ? pinnedTargets[0]
        : ({ date: "", title: "", type: "festival" })
    property bool isSelectingTarget: false

    Connections {
        target: CalendarService
        function onTargetsChanged() {
            // Instantly react to pin/unpin changes
        }
        function onEventsChanged() {
            root.updateViewingMonth()
        }
    }

    function isEventPinned(dateKey, title) {
        return CalendarService.isEventPinned(dateKey, title)
    }

    function pinTarget(dateKey, title, type) {
        CalendarService.pinTarget(dateKey, title, type)
    }

    function unpinTarget(dateKey, title) {
        CalendarService.unpinTarget(dateKey, title)
    }

    function clearTarget() {
        CalendarService.clearTargets()
    }

    function saveTarget(dateKey, title, type) {
        pinTarget(dateKey, title, type)
    }

    function setTargetFromDate(d) {
        var key = formatDateKey(d)
        var userEvs = root.getEventsForDate(d)
        var holidays = IndianCalendar.getDayEvents(d.getFullYear(), d.getMonth() + 1, d.getDate())
        var title = ""
        var type = "festival"

        if (userEvs.length > 0) {
            title = userEvs[0].text
            type = "user"
        } else if (holidays.length > 0) {
            title = holidays[0].title
            type = holidays[0].type
        } else {
            title = d.toLocaleDateString(Qt.locale(), "MMMM d")
            type = "festival"
        }
        if (isEventPinned(key, title)) {
            unpinTarget(key, title)
        } else {
            pinTarget(key, title, type)
        }
    }

    function getCountdownFor(item) {
        if (!item || !item.date) {
            return { days: 0, text: "No Target Set", title: "Tap + or 📌 to pin any note", dateText: "", type: "festival", valid: false }
        }
        var parts = item.date.split("-")
        if (parts.length < 3) {
            return { days: 0, text: "No Target Set", title: "Tap + to select target date", dateText: "", type: "festival", valid: false }
        }
        var target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
        var now = new Date()
        var nowMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        var targetMidnight = new Date(target.getFullYear(), target.getMonth(), target.getDate())
        var diffTime = targetMidnight.getTime() - nowMidnight.getTime()
        var diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24))

        var label = ""
        if (diffDays === 0) label = "TODAY"
        else if (diffDays === 1) label = "1 DAY LEFT"
        else if (diffDays > 1) label = diffDays + " DAYS LEFT"
        else if (diffDays === -1) label = "YESTERDAY"
        else label = Math.abs(diffDays) + " DAYS AGO"

        return {
            days: diffDays,
            text: label,
            title: item.title || target.toLocaleDateString(Qt.locale(), "MMMM d"),
            dateText: target.toLocaleDateString(Qt.locale(), "d MMM yyyy"),
            type: item.type || "festival",
            valid: true
        }
    }

    function getTargetCountdown() {
        return getCountdownFor(root.targetData)
    }

    onIsAddingEventChanged: {
        GlobalStates.desktopWidgetKeyboardFocus = root.isAddingEvent
    }

    function addEvent(dateKey, text) {
        if (!text || text.trim() === "") return
        CalendarService.addEvent(dateKey, text)
        root.isAddingEvent = false
        root.newEventText = ""
        root.updateViewingMonth()

        // If target date matches the date where user wrote note, auto-sync message!
        if (root.targetData && root.targetData.date === dateKey) {
            root.saveTarget(dateKey, text.trim(), "user")
        }
    }

    function deleteEvent(id) {
        CalendarService.deleteEvent(id)
        root.updateViewingMonth()
    }

    function getEventsForDate(date) {
        var key = formatDateKey(date)
        return CalendarService.getEventsForDate(key)
    }

    function hasUserEventOnDate(year, month, day) {
        var mm = month < 10 ? "0" + month : "" + month
        var dd = day < 10 ? "0" + day : "" + day
        var key = year + "-" + mm + "-" + dd
        return CalendarService.hasUserEventOnDate(key)
    }

    function getFirstHoliday(y, m, d) {
        var events = IndianCalendar.getDayEvents(y, m, d)
        if (!events || events.length === 0) return ""
        return events[0].title
    }

    function getHolidayType(y, m, d) {
        var events = IndianCalendar.getDayEvents(y, m, d)
        if (!events || events.length === 0) return ""
        return events[0].type
    }

    function getFirstUserEvent(y, m, d) {
        var mm = m < 10 ? "0" + m : "" + m
        var dd = d < 10 ? "0" + d : "" + d
        var key = y + "-" + mm + "-" + dd
        var evs = CalendarService.getEventsForDate(key)
        return (evs && evs.length > 0) ? evs[0].text : ""
    }

    // ----------------------------------------------------
    // Goals Integration via Goals Singleton Service
    // ----------------------------------------------------
    readonly property var calendarGoals: Goals.goalsList

    onCalendarGoalsChanged: {
        updateViewingMonth()
    }

    function toggleGoalCompletion(goalId) {
        Goals.toggleGoal(goalId)
        updateViewingMonth()
    }

    function removeGoalFromCalendar(goalId) {
        Goals.removeGoalCalendarDate(goalId)
        updateViewingMonth()
    }

    function getGoalsForDate(date) {
        var key = formatDateKey(date)
        return Goals.goalsList.filter(g => (g.calendarDate && g.calendarDate === key))
    }

    function hasGoalOnDate(year, month, day) {
        var mm = month < 10 ? "0" + month : "" + month
        var dd = day < 10 ? "0" + day : "" + day
        var key = year + "-" + mm + "-" + dd
        return Goals.goalsList.some(g => (g.calendarDate && g.calendarDate === key))
    }

    function getMonthMatrix(date) {
        const year  = date.getFullYear()
        const month = date.getMonth()
        const firstOfMonth   = new Date(year, month, 1)
        const startOffset    = (firstOfMonth.getDay() + 6) % 7
        const daysInMonth    = new Date(year, month + 1, 0).getDate()
        const daysInPrevMonth = new Date(year, month, 0).getDate()

        function createCell(d, m, y, isCurMonth, isTodayDate) {
            var dayEvents = IndianCalendar.getDayEvents(y, m, d)
            var hasNat = dayEvents.some(e => e.type === "national")
            var hasFest = dayEvents.some(e => e.type === "festival" || e.type === "restricted" || e.type === "jayanti" || e.type === "observance" || e.type === "financial")
            var hasUsr = root.hasUserEventOnDate(y, m, d)
            var hasGol = root.hasGoalOnDate(y, m, d)
            return {
                day: d,
                month: m,
                year: y,
                currentMonth: isCurMonth,
                isToday: isTodayDate,
                hasNational: hasNat,
                hasFestival: hasFest,
                hasUserEvent: hasUsr,
                hasGoal: hasGol,
                hasHoliday: dayEvents.length > 0,
                firstHoliday: dayEvents.length > 0 ? dayEvents[0].title : "",
                holidayType: dayEvents.length > 0 ? dayEvents[0].type : "",
                firstUserEvent: getFirstUserEvent(y, m, d)
            }
        }

        let cells = []
        for (let i = 0; i < startOffset; i++) {
            let pDay = daysInPrevMonth - startOffset + i + 1
            let prevMonth = month === 0 ? 12 : month
            let prevYear = month === 0 ? year - 1 : year
            cells.push(createCell(pDay, prevMonth, prevYear, false, false))
        }

        for (let d = 1; d <= daysInMonth; d++) {
            const isToday = monthShift === 0
                && d === today.getDate()
                && month === today.getMonth()
                && year  === today.getFullYear()
            const curMonthNum = month + 1
            cells.push(createCell(d, curMonthNum, year, true, isToday))
        }

        let nextDay = 1
        let nextMonthNum = month === 11 ? 1 : month + 2
        let nextYearNum = month === 11 ? year + 1 : year
        while (cells.length < 42) {
            cells.push(createCell(nextDay, nextMonthNum, nextYearNum, false, false))
            nextDay++
        }

        let weeks = []
        for (let i = 0; i < cells.length; i += 7)
            weeks.push(cells.slice(i, i + 7))
        return weeks
    }

    function getCurrentWeek() {
        const matrix = getMonthMatrix(viewingDate)
        for (let w = 0; w < matrix.length; w++) {
            if (matrix[w].some(c => c.isToday)) return matrix[w]
        }
        return matrix[0]
    }

    property var weeks: getMonthMatrix(viewingDate)

    implicitWidth:  card.implicitWidth
    implicitHeight: card.implicitHeight

    Behavior on widgetWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    Rectangle {
        id: card
        implicitWidth: root.widgetWidth
        implicitHeight: root.sizeMode === "1x1" ? root.cardHeight
                      : root.sizeMode === "1x2" ? root.cardHeight
                      : 350
        radius: Appearance.rounding?.verylarge ?? 30
        color: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            0.12
        )
        border.width: 0
        border.color: "transparent"
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (root.sizeMode === "1x1") return oneByOneContent
                if (root.sizeMode === "1x2") return oneByTwoContent
                return twoByTwoContent
            }
        }

        // ----------------------------------------------------
        // 1x1 Compact Mode
        // ----------------------------------------------------
        Component {
            id: oneByOneContent
            Item {
                anchors.fill: parent

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: parent.height * 0.35
                        color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.25)
                        topLeftRadius: card.radius
                        topRightRadius: card.radius

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            StyledText {
                                text: root.today.toLocaleDateString(Qt.locale(), "MMM").toUpperCase()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: root.today.toLocaleDateString(Qt.locale(), "ddd").toUpperCase()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colPrimary
                                opacity: 0.7
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        StyledText {
                            anchors.centerIn: parent
                            text: root.today.getDate()
                            font.pixelSize: 52
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------
        // 1x2 Week Strip Mode
        // ----------------------------------------------------
        Component {
            id: oneByTwoContent
            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 8

                Rectangle {
                    Layout.leftMargin: 3
                    implicitHeight: 28
                    implicitWidth: monthText.implicitWidth + 20
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary

                    StyledText {
                        id: monthText
                        anchors.centerIn: parent
                        text: root.today.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimary
                    }
                }

                Grid {
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 0
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    Repeater {
                        model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                        delegate: Item {
                            implicitWidth: (card.implicitWidth - 28) / 7
                            implicitHeight: 20
                            StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.5
                            }
                        }
                    }

                    Repeater {
                        model: root.getCurrentWeek()
                        delegate: Item {
                            required property var modelData
                            implicitWidth: (card.implicitWidth - 28) / 7
                            implicitHeight: 28

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28; height: 28
                                radius: 14
                                color: modelData.isToday ? Appearance.colors.colPrimary : "transparent"

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                    color: modelData.isToday
                                        ? Appearance.colors.colOnPrimary
                                        : Appearance.colors.colOnLayer0
                                    opacity: modelData.currentMonth ? 1.0 : 0.3
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ----------------------------------------------------
        // Full Dual-Pane Mode (Aesthetic Frosted Glass Minimal UI)
        // ----------------------------------------------------
        Component {
            id: twoByTwoContent
            RowLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 16

                // ==========================================
                // LEFT PANEL: Clean Agenda & Quick Scratchpad
                // ==========================================
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    radius: (Appearance.rounding?.verylarge ?? 30) - 10
                    color: ColorUtils.applyAlpha("#ffffff", 0.04)
                    border.width: 1
                    border.color: ColorUtils.applyAlpha("#ffffff", 0.08)

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 10

                        // Date & Week Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: root.selectedDate.getDate()
                                font.pixelSize: 34
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -2

                                StyledText {
                                    text: root.selectedDate.toLocaleDateString(Qt.locale(), "dddd")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }

                                RowLayout {
                                    spacing: 4
                                    StyledText {
                                        text: root.selectedDate.toLocaleDateString(Qt.locale(), "MMM yyyy")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: "#888892"
                                    }
                                    StyledText {
                                        text: "•"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: "#55555c"
                                    }
                                    StyledText {
                                        text: "W" + root.getWeekNumber(root.selectedDate)
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Bold
                                        color: "#e2e8f0"
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: ColorUtils.applyAlpha("#ffffff", 0.08)
                        }

                        // Agenda / Events Scroll Area
                        ListView {
                            id: agendaList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6

                            readonly property var holidays: IndianCalendar.getEventsForDate(root.selectedDate)
                            readonly property var personal: root.getEventsForDate(root.selectedDate)
                            readonly property var dayGoals: root.calendarGoals.filter(g => (g.calendarDate && g.calendarDate === root.formatDateKey(root.selectedDate)))

                            function getCleanSubtitle(h) {
                                if (!h.desc) {
                                    return h.type === "national" ? "National Holiday" : ""
                                }
                                var cleaned = h.desc.replace(/\[[A-Z]{2,3}\]/g, "").trim()
                                // If it starts with a dash or colon, clean it
                                cleaned = cleaned.replace(/^[-—:]\s*/, "")
                                return cleaned
                            }

                            model: [].concat(
                                holidays.map(h => ({
                                    id: "h-" + h.title,
                                    title: h.title,
                                    subtitle: agendaList.getCleanSubtitle(h),
                                    icon: h.icon || "event",
                                    isHoliday: true,
                                    isGoal: false,
                                    type: h.type
                                })),
                                personal.map(p => ({
                                    id: p.id,
                                    title: p.text,
                                    subtitle: "Personal Note",
                                    icon: "schedule",
                                    isHoliday: false,
                                    isGoal: false,
                                    type: "user"
                                })),
                                dayGoals.map(g => ({
                                    id: g.id,
                                    title: g.title,
                                    subtitle: "GOAL • " + (g.horizon ? g.horizon.toUpperCase() : "GENERAL"),
                                    icon: g.completed ? "task_alt" : "radio_button_unchecked",
                                    isHoliday: false,
                                    isGoal: true,
                                    completed: g.completed,
                                    type: "goal"
                                }))
                            )

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                implicitHeight: eventCol.implicitHeight + 18
                                radius: 8
                                color: ColorUtils.applyAlpha("#ffffff", 0.06)
                                border.width: 1
                                border.color: ColorUtils.applyAlpha("#ffffff", 0.09)

                                RowLayout {
                                    id: eventRow
                                    anchors {
                                        fill: parent
                                        leftMargin: 8; rightMargin: 8
                                        topMargin: 8; bottomMargin: 8
                                    }
                                    spacing: 8

                                    // Left accent bar — theme primary for goals
                                    Rectangle {
                                        implicitWidth: 3
                                        Layout.fillHeight: true
                                        radius: 1.5
                                        color: modelData.type === "national" ? "#f87171"
                                             : modelData.type === "user" ? "#38bdf8"
                                             : modelData.type === "goal" ? Appearance.colors.colPrimary.toString()
                                             : "#fbbf24"
                                    }

                                    // Goal: circle-in-circle checkbox (same as GoalsWidget, no green)
                                    Rectangle {
                                        visible: modelData.isGoal === true
                                        implicitWidth: 18; implicitHeight: 18
                                        radius: 9
                                        color: "transparent"
                                        border.width: 1.5
                                        border.color: Boolean(modelData?.completed)
                                            ? Appearance.colors.colPrimary.toString()
                                            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.40)

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 8; height: 8; radius: 4
                                            visible: Boolean(modelData?.completed)
                                            color: Appearance.colors.colPrimary
                                        }

                                        // Isolated click — does not scroll jump
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            propagateComposedEvents: false
                                            onClicked: mouse => {
                                                mouse.accepted = true
                                                root.toggleGoalCompletion(modelData.id)
                                            }
                                        }
                                    }

                                    // Detailed Title & Subtitle/Description column
                                    ColumnLayout {
                                        id: eventCol
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.title
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.Medium
                                            font.strikeout: Boolean(modelData?.isGoal && modelData?.completed)
                                            color: Boolean(modelData?.isGoal && modelData?.completed) ? "#64748b" : "#ffffff"
                                            wrapMode: Text.Wrap
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                            text: modelData.subtitle
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: modelData.isGoal ? Font.Bold : Font.Normal
                                            color: modelData.isGoal ? Appearance.colors.colPrimary : "#94a3b8"
                                            wrapMode: Text.Wrap
                                            lineHeight: 1.2
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4

                                        // Pin Specific Event to Satellite Companion
                                        Rectangle {
                                            implicitWidth: 24; implicitHeight: 24; radius: 12
                                            readonly property bool isPinned: root.isEventPinned(root.formatDateKey(root.selectedDate), modelData.title)
                                            color: isPinned ? ColorUtils.applyAlpha("#38bdf8", 0.25) : (pinMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.15) : "transparent")

                                            MaterialSymbol {
                                                anchors.centerIn: parent; text: "push_pin"; iconSize: 13
                                                color: parent.isPinned ? "#38bdf8" : (pinMouse.containsMouse ? "#ffffff" : "#64748b")
                                            }

                                            MouseArea {
                                                id: pinMouse
                                                anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let dKey = root.formatDateKey(root.selectedDate)
                                                    if (parent.isPinned) {
                                                        root.unpinTarget(dKey, modelData.title)
                                                    } else {
                                                        root.pinTarget(dKey, modelData.title, modelData.type)
                                                    }
                                                }
                                            }
                                        }

                                        // Unlink / Remove Goal from Calendar (link_off icon)
                                        Rectangle {
                                            visible: modelData.isGoal === true
                                            implicitWidth: 24; implicitHeight: 24; radius: 12
                                            color: unmentionGoalMouse.containsMouse ? ColorUtils.applyAlpha("#ef4444", 0.20) : "transparent"

                                            MaterialSymbol {
                                                anchors.centerIn: parent; text: "link_off"; iconSize: 13
                                                color: unmentionGoalMouse.containsMouse ? "#fca5a5" : "#888892"
                                            }

                                            MouseArea {
                                                id: unmentionGoalMouse
                                                anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.removeGoalFromCalendar(modelData.id)
                                            }
                                        }

                                        // Delete Personal Note
                                        Rectangle {
                                            visible: !modelData.isHoliday && !modelData.isGoal
                                            implicitWidth: 24; implicitHeight: 24; radius: 12
                                            color: delMouse.containsMouse ? ColorUtils.applyAlpha("#ef4444", 0.20) : "transparent"

                                            MaterialSymbol {
                                                anchors.centerIn: parent; text: "close"; iconSize: 13
                                                color: delMouse.containsMouse ? "#fca5a5" : "#888892"
                                            }

                                            MouseArea {
                                                id: delMouse
                                                anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let dKey = root.formatDateKey(root.selectedDate)
                                                    if (root.isEventPinned(dKey, modelData.title)) {
                                                        root.unpinTarget(dKey, modelData.title)
                                                    }
                                                    root.deleteEvent(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty State
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: parent.count === 0 && !root.isAddingEvent
                                spacing: 4

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "event_available"
                                    iconSize: 22
                                    color: "#55555c"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No events on this day"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: "#666670"
                                }
                            }
                        }

                            // Quick Add Event Box / Button
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: root.isAddingEvent ? 32 : 30
                                radius: 8
                                color: root.isAddingEvent ? ColorUtils.applyAlpha(Appearance.colors.colLayer2, 0.45) : (addEventMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.10) : ColorUtils.applyAlpha("#ffffff", 0.05))
                                border.width: 1
                                border.color: root.isAddingEvent ? Appearance.colors.colPrimary : ColorUtils.applyAlpha("#ffffff", 0.10)

                                Behavior on implicitHeight { NumberAnimation { duration: 150 } }

                                Timer {
                                    id: focusTimer1
                                    interval: 40
                                    repeat: false
                                    onTriggered: {
                                        if (root.isAddingEvent) {
                                            eventTextInput.forceActiveFocus()
                                        }
                                    }
                                }

                                Timer {
                                    id: focusTimer2
                                    interval: 120
                                    repeat: false
                                    onTriggered: {
                                        if (root.isAddingEvent) {
                                            eventTextInput.forceActiveFocus()
                                        }
                                    }
                                }

                                // Normal "+ Add Event" Pill
                                RowLayout {
                                    anchors.centerIn: parent
                                    visible: !root.isAddingEvent
                                    spacing: 6

                                    MaterialSymbol {
                                        text: "add"
                                        iconSize: 14
                                        color: "#e2e8f0"
                                    }
                                    StyledText {
                                        text: "Add Event"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Bold
                                        color: "#e2e8f0"
                                    }
                                }

                                // Input Mode
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 8; rightMargin: 4 }
                                    visible: root.isAddingEvent
                                    spacing: 4
                                    z: 1

                                    TextField {
                                        id: eventTextInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: "#ffffff"
                                        placeholderText: "Type note..."
                                        placeholderTextColor: "#71717a"
                                        background: null
                                        clip: true
                                        selectByMouse: true
                                        focus: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        onVisibleChanged: {
                                            if (visible) {
                                                forceActiveFocus()
                                                cursorPosition = text.length
                                            }
                                        }
                                        onAccepted: {
                                            if (text && text.trim() !== "") {
                                                root.addEvent(root.formatDateKey(root.selectedDate), text)
                                                text = ""
                                            }
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "check"
                                        iconSize: 16
                                        color: "#22c55e"

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (eventTextInput.text && eventTextInput.text.trim() !== "") {
                                                    root.addEvent(root.formatDateKey(root.selectedDate), eventTextInput.text)
                                                    eventTextInput.text = ""
                                                }
                                            }
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 15
                                        color: "#94a3b8"

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.isAddingEvent = false
                                                eventTextInput.text = ""
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    visible: root.isAddingEvent
                                    z: 0
                                    onClicked: {
                                        eventTextInput.forceActiveFocus()
                                    }
                                }

                                MouseArea {
                                    id: addEventMouse
                                    anchors.fill: parent
                                    visible: !root.isAddingEvent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        GlobalStates.desktopWidgetKeyboardFocus = true
                                        root.isAddingEvent = true
                                        eventTextInput.forceActiveFocus()
                                        focusTimer1.restart()
                                        focusTimer2.restart()
                                    }
                                }
                            }
                    }
                }

                // ==========================================
                // RIGHT PANEL: Symmetrical Aligned Month Grid
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    // Navigation Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: "#ffffff"
                            text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        }

                        // Aesthetic Solid Neutral "Today" Button
                        Rectangle {
                            implicitWidth: 74
                            implicitHeight: 28
                            radius: 14
                            color: todayBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.15) : ColorUtils.applyAlpha("#ffffff", 0.08)
                            border.width: 1
                            border.color: todayBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.3) : ColorUtils.applyAlpha("#ffffff", 0.15)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialSymbol {
                                    text: "today"
                                    iconSize: 13
                                    color: "#e2e8f0"
                                }

                                StyledText {
                                    text: "Today"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Bold
                                    color: "#e2e8f0"
                                }
                            }

                            MouseArea {
                                id: todayBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.monthShift = 0
                                    root.selectedDate = new Date()
                                }
                            }
                        }

                        // Aesthetic Solid Neutral Previous Month Button
                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 14
                            color: prevBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.15) : ColorUtils.applyAlpha("#ffffff", 0.08)
                            border.width: 1
                            border.color: prevBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.3) : ColorUtils.applyAlpha("#ffffff", 0.15)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "chevron_left"
                                iconSize: Appearance.font.pixelSize.normal
                                color: "#e2e8f0"
                            }
                            MouseArea {
                                id: prevBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.monthShift--
                            }
                        }

                        // Aesthetic Solid Neutral Next Month Button
                        Rectangle {
                            implicitWidth: 28; implicitHeight: 28; radius: 14
                            color: nextBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.15) : ColorUtils.applyAlpha("#ffffff", 0.08)
                            border.width: 1
                            border.color: nextBtnMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.3) : ColorUtils.applyAlpha("#ffffff", 0.15)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "chevron_right"
                                iconSize: Appearance.font.pixelSize.normal
                                color: "#e2e8f0"
                            }
                            MouseArea {
                                id: nextBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.monthShift++
                            }
                        }
                    }

                    // Weekdays Header (Symmetrical Columns)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                            delegate: Item {
                                Layout.fillWidth: true
                                implicitHeight: 18

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Bold
                                    color: (index >= 5) ? "#e2e8f0" : "#71717a"
                                }
                            }
                        }
                    }

                    // Calendar Grid with Visible Event Pills (Strictly Aligned & Symmetrical)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        Repeater {
                            model: root.weeks
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Repeater {
                                    model: parent.modelData
                                    delegate: Item {
                                        id: cellItem
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        readonly property bool isSelected: {
                                            return modelData.day === root.selectedDate.getDate()
                                                && modelData.month === (root.selectedDate.getMonth() + 1)
                                                && modelData.year === root.selectedDate.getFullYear()
                                        }

                                        Rectangle {
                                            id: cellBg
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            radius: 8
                                            color: cellItem.isSelected
                                                ? ColorUtils.applyAlpha("#ffffff", 0.12)
                                                : (cellMouseArea.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.05) : "transparent")
                                            border.width: cellItem.isSelected ? 1 : 0
                                            border.color: ColorUtils.applyAlpha("#ffffff", 0.25)

                                             ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                spacing: 2

                                                // Day Number (Centered Target)
                                                Item {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    implicitWidth: 22
                                                    implicitHeight: 22

                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: 22
                                                        height: 22
                                                        radius: 11
                                                        color: modelData.isToday ? "#ffffff" : "transparent"
                                                    }

                                                    StyledText {
                                                        anchors.centerIn: parent
                                                        text: modelData.day
                                                        font.pixelSize: 11
                                                        font.weight: modelData.isToday || cellItem.isSelected ? Font.Bold : Font.Normal
                                                        color: modelData.isToday ? "#000000" : "#ffffff"
                                                        opacity: modelData.currentMonth ? 1.0 : 0.25
                                                    }
                                                }

                                                // Multi-Event Indicators (Red, Yellow, Blue, Green Co-existing Symmetrically)
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    spacing: 2
                                                    implicitHeight: 3.5

                                                    readonly property int totalActive: (modelData.hasNational ? 1 : 0) + (modelData.hasFestival ? 1 : 0) + (modelData.hasUserEvent ? 1 : 0) + (modelData.hasGoal ? 1 : 0)
                                                    readonly property real barWidth: totalActive >= 4 ? 4 : totalActive === 3 ? 5 : totalActive === 2 ? 8 : 16

                                                    // Red Indicator: National Gazetted Holiday
                                                    Rectangle {
                                                        visible: modelData.hasNational
                                                        implicitWidth: parent.barWidth
                                                        implicitHeight: 3.5
                                                        radius: 1.75
                                                        color: "#f87171"
                                                    }

                                                    // Yellow Indicator: Indian Festival / Restricted Holiday / Observance
                                                    Rectangle {
                                                        visible: modelData.hasFestival
                                                        implicitWidth: parent.barWidth
                                                        implicitHeight: 3.5
                                                        radius: 1.75
                                                        color: "#fbbf24"
                                                    }

                                                    // Blue Indicator: User Personal Note / Event
                                                    Rectangle {
                                                        visible: modelData.hasUserEvent
                                                        implicitWidth: parent.barWidth
                                                        implicitHeight: 3.5
                                                        radius: 1.75
                                                        color: "#38bdf8"
                                                    }

                                                    // Green Indicator: Scheduled Goal
                                                    Rectangle {
                                                        visible: modelData.hasGoal
                                                        implicitWidth: parent.barWidth
                                                        implicitHeight: 3.5
                                                        radius: 1.75
                                                        color: "#34d399"
                                                    }
                                                }

                                                Item { Layout.fillHeight: true }
                                            }

                                            MouseArea {
                                                id: cellMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var sel = new Date(modelData.year, modelData.month - 1, modelData.day)
                                                    root.selectedDate = sel
                                                    if (root.isSelectingTarget) {
                                                        root.setTargetFromDate(sel)
                                                        root.isSelectingTarget = false
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

        // Toggle Handle
        Rectangle {
            id: toggleHandle
            width: 16; height: 16; radius: 4
            color: Appearance.colors.colOnPrimaryContainer
            anchors { left: card.left; bottom: card.bottom; margins: 4 }
            opacity: (root.containsMouse || toggleArea.containsMouse) && root.sizeMode !== "1x1" ? 0.5 : 0
            visible: opacity > 0 && !Config.options.background.widgetsLocked
            Behavior on opacity { NumberAnimation { duration: 150 } }

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.sizeMode === "1x2" ? "calendar_view_month" : "calendar_view_week"
                iconSize: 11
                color: Appearance.colors.colPrimaryContainer
            }

            MouseArea {
                id: toggleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.sizeMode = root.sizeMode === "2x2" ? "1x2" : "2x2"
                    root.configEntry.sizeMode = root.sizeMode
                }
            }
        }

        ResizeHandler {
            anchorItem: card
            hoverActive: root.containsMouse
            locked: Config.options.background.widgetsLocked
            currentWidth: root.widgetWidth
            onResized: (newWidth) => {
                root.sizeMode = root.modeForWidth(newWidth)
            }
            onResizeFinished: {
                root.configEntry.sizeMode = root.sizeMode
            }
        }
    }

}

