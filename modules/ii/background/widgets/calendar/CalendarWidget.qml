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

    property string sizeMode: root.configEntry.sizeMode ?? "2x2"

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
    readonly property var today: new Date()
    property var selectedDate: new Date()
    property var viewingDate: new Date()

    function updateViewingMonth() {
        let d = new Date()
        d.setDate(1)
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
    // User Events / Scratchpad Persistent Storage
    // ----------------------------------------------------
    property var userEvents: []
    property bool isAddingEvent: false
    property string newEventText: ""

    // ----------------------------------------------------
    // External Satellite Companion & Target Countdown
    // ----------------------------------------------------
    property var targetData: ({ date: "", title: "", type: "festival" })
    property bool isSelectingTarget: false
    property real satelliteX: 16
    property real satelliteY: -58

    FileView {
        id: targetFileView
        path: Qt.resolvedUrl(Directories.config + "/calendar_target.json")
        onLoaded: {
            try {
                const parsed = JSON.parse(targetFileView.text())
                if (parsed && typeof parsed === "object" && parsed.date) {
                    root.targetData = parsed
                }
            } catch (e) {}
        }
    }

    function clearTarget() {
        root.targetData = { date: "", title: "", type: "festival" }
        targetFileView.setText("")
    }

    function saveTarget(dateKey, title, type) {
        root.targetData = {
            date: dateKey,
            title: title || "",
            type: type || "festival"
        }
        targetFileView.setText(JSON.stringify(root.targetData))
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
        saveTarget(key, title, type)
    }

    function getTargetCountdown() {
        if (!root.targetData || !root.targetData.date) {
            return { days: 0, text: "No Target Set", title: "Tap + or 📌 to pin any note", dateText: "", type: "festival", valid: false }
        }
        var parts = root.targetData.date.split("-")
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
            title: root.targetData.title || target.toLocaleDateString(Qt.locale(), "MMMM d"),
            dateText: target.toLocaleDateString(Qt.locale(), "d MMM yyyy"),
            type: root.targetData.type || "festival",
            valid: true
        }
    }

    onIsAddingEventChanged: {
        GlobalStates.desktopWidgetKeyboardFocus = root.isAddingEvent
    }

    function addEvent(dateKey, text) {
        if (!text || text.trim() === "") return
        var item = {
            id: Date.now().toString() + "-" + Math.floor(Math.random() * 10000),
            date: dateKey,
            text: text.trim(),
            createdAt: Date.now()
        }
        var updated = userEvents.slice(0)
        updated.push(item)
        root.userEvents = updated
        eventsFileView.setText(JSON.stringify(root.userEvents))
        updateViewingMonth()
        root.isAddingEvent = false
        root.newEventText = ""

        // If target date matches the date where user wrote note, auto-sync message!
        if (root.targetData && root.targetData.date === dateKey) {
            root.saveTarget(dateKey, text.trim(), "user")
        }
    }

    function deleteEvent(id) {
        var updated = userEvents.filter(e => e.id !== id)
        root.userEvents = updated
        eventsFileView.setText(JSON.stringify(root.userEvents))
        updateViewingMonth()
    }

    function getEventsForDate(date) {
        var key = formatDateKey(date)
        return userEvents.filter(e => e.date === key)
    }

    function hasUserEventOnDate(year, month, day) {
        var mm = month < 10 ? "0" + month : "" + month
        var dd = day < 10 ? "0" + day : "" + day
        var key = year + "-" + mm + "-" + dd
        return userEvents.some(e => e.date === key)
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
        var found = root.userEvents.find(e => e.date === key)
        return found ? found.text : ""
    }

    FileView {
        id: eventsFileView
        path: Qt.resolvedUrl(Directories.config + "/calendar_events.json")
        onLoaded: {
            const fileContents = eventsFileView.text()
            try {
                const parsed = JSON.parse(fileContents)
                root.userEvents = Array.isArray(parsed) ? parsed : []
                updateViewingMonth()
            } catch (e) {
                root.userEvents = []
                eventsFileView.setText(JSON.stringify([]))
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.userEvents = []
                eventsFileView.setText(JSON.stringify([]))
            }
        }
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
            return {
                day: d,
                month: m,
                year: y,
                currentMonth: isCurMonth,
                isToday: isTodayDate,
                hasNational: hasNat,
                hasFestival: hasFest,
                hasUserEvent: hasUsr,
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
        color: root.sizeMode === "2x2" ? ColorUtils.applyAlpha("#000000", 0.72) : Appearance.colors.colLayer0
        border.width: 1
        border.color: root.sizeMode === "2x2" ? ColorUtils.applyAlpha("#ffffff", 0.12) : Appearance.colors.colLayer0Border
        clip: true

        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        StyledRectangularShadow {
            target: card
            z: -2
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
            Rectangle {
                anchors.fill: parent
                radius: card.radius
                color: Appearance.colors.colPrimaryContainer

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: parent.height * 0.35
                        color: Appearance.colors.colPrimary
                        topLeftRadius: card.radius
                        topRightRadius: card.radius

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            StyledText {
                                text: root.today.toLocaleDateString(Qt.locale(), "MMM").toUpperCase()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimary
                            }
                            StyledText {
                                text: root.today.toLocaleDateString(Qt.locale(), "ddd").toUpperCase()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimary
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
                            color: Appearance.colors.colOnPrimaryContainer
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
                    color: ColorUtils.applyAlpha("#000000", 0.40)
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
                                    type: h.type
                                })),
                                personal.map(p => ({
                                    id: p.id,
                                    title: p.text,
                                    subtitle: "Personal Note",
                                    icon: "schedule",
                                    isHoliday: false,
                                    type: "user"
                                }))
                            )

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                implicitHeight: eventCol.implicitHeight + 16
                                radius: 8
                                color: ColorUtils.applyAlpha("#18181e", 0.7)
                                border.width: 1
                                border.color: ColorUtils.applyAlpha("#ffffff", 0.08)

                                RowLayout {
                                    id: eventRow
                                    anchors {
                                        fill: parent
                                        leftMargin: 8
                                        rightMargin: 8
                                        topMargin: 8
                                        bottomMargin: 8
                                    }
                                    spacing: 8

                                    Rectangle {
                                        implicitWidth: 3
                                        Layout.fillHeight: true
                                        radius: 1.5
                                        color: modelData.type === "national" ? "#f87171"
                                             : modelData.type === "user" ? "#38bdf8"
                                             : "#fbbf24"
                                    }

                                    ColumnLayout {
                                        id: eventCol
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.title
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.Medium
                                            color: "#ffffff"
                                            wrapMode: Text.Wrap
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                            text: modelData.subtitle
                                            font.pixelSize: 10
                                            color: "#94a3b8"
                                            wrapMode: Text.Wrap
                                            lineHeight: 1.2
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4

                                        // Pin Specific Event to Satellite Companion
                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 12
                                            readonly property bool isPinned: root.targetData
                                                && root.targetData.date === root.formatDateKey(root.selectedDate)
                                                && root.targetData.title === modelData.title
                                            color: isPinned ? ColorUtils.applyAlpha("#38bdf8", 0.25) : (pinMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.15) : "transparent")

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "push_pin"
                                                iconSize: 13
                                                color: parent.isPinned ? "#38bdf8" : (pinMouse.containsMouse ? "#ffffff" : "#64748b")
                                            }

                                            MouseArea {
                                                id: pinMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (parent.isPinned) {
                                                        root.clearTarget()
                                                    } else {
                                                        root.saveTarget(root.formatDateKey(root.selectedDate), modelData.title, modelData.type)
                                                    }
                                                }
                                            }
                                        }

                                        // Delete Personal Note
                                        Rectangle {
                                            visible: !modelData.isHoliday
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 12
                                            color: delMouse.containsMouse ? ColorUtils.applyAlpha("#ef4444", 0.20) : "transparent"

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "close"
                                                iconSize: 13
                                                color: delMouse.containsMouse ? "#fca5a5" : "#888892"
                                            }

                                            MouseArea {
                                                id: delMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.targetData && root.targetData.title === modelData.title) {
                                                        root.clearTarget()
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
                                color: root.isAddingEvent ? ColorUtils.applyAlpha("#000000", 0.6) : (addEventMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.12) : ColorUtils.applyAlpha("#ffffff", 0.07))
                                border.width: 1
                                border.color: root.isAddingEvent ? ColorUtils.applyAlpha("#ffffff", 0.3) : ColorUtils.applyAlpha("#ffffff", 0.12)

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

                                                // Multi-Event Indicators (Red, Yellow, Blue Co-existing Symmetrically)
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    spacing: 2
                                                    implicitHeight: 3.5

                                                    readonly property int totalActive: (modelData.hasNational ? 1 : 0) + (modelData.hasFestival ? 1 : 0) + (modelData.hasUserEvent ? 1 : 0)
                                                    readonly property real barWidth: totalActive === 3 ? 5 : totalActive === 2 ? 8 : 16

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

    // ====================================================
    // SATELLITE COMPANION COUNTDOWN MICRO-CAPSULE (MINIMAL & AESTHETIC)
    // ====================================================
    Item {
        id: satelliteWrapper
        z: 100
        visible: root.sizeMode === "2x2" || root.sizeMode === "1x2"
        x: root.satelliteX
        y: root.satelliteY
        width: satelliteCard.width
        height: satelliteCard.height

        readonly property var countdown: root.getTargetCountdown()

        // Minimalist Frosted Glass Capsule
        Rectangle {
            id: satelliteCard
            implicitWidth: capsuleRow.implicitWidth + 20
            implicitHeight: 34
            radius: 17
            color: ColorUtils.applyAlpha("#121217", 0.76)
            border.width: 1
            border.color: root.isSelectingTarget ? ColorUtils.applyAlpha("#38bdf8", 0.5) : ColorUtils.applyAlpha("#ffffff", 0.10)

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Drag Mouse Area
            MouseArea {
                id: satelliteDragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: satelliteWrapper
                drag.axis: Drag.XAndYAxis
                onReleased: {
                    root.satelliteX = satelliteWrapper.x
                    root.satelliteY = satelliteWrapper.y
                }
            }

            RowLayout {
                id: capsuleRow
                anchors.centerIn: parent
                spacing: 8

                // Minimalist Countdown Token Pill
                Rectangle {
                    implicitHeight: 22
                    implicitWidth: tokenText.implicitWidth + 12
                    radius: 11
                    color: ColorUtils.applyAlpha("#ffffff", 0.08)
                    border.width: 1
                    border.color: ColorUtils.applyAlpha("#ffffff", 0.06)

                    StyledText {
                        id: tokenText
                        anchors.centerIn: parent
                        text: !satelliteWrapper.countdown.valid ? "PIN"
                            : satelliteWrapper.countdown.days === 0 ? "TODAY"
                            : satelliteWrapper.countdown.days === 1 ? "1d left"
                            : satelliteWrapper.countdown.days > 1 ? (satelliteWrapper.countdown.days + "d left")
                            : (Math.abs(satelliteWrapper.countdown.days) + "d ago")
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#e2e8f0"
                    }
                }

                // Event Title & Subtle Date Tag
                RowLayout {
                    spacing: 6
                    Layout.maximumWidth: 260

                    StyledText {
                        Layout.maximumWidth: 180
                        text: root.isSelectingTarget
                            ? "Select any calendar date..."
                            : (satelliteWrapper.countdown.title || "No event message")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: root.isSelectingTarget ? "#38bdf8" : "#ffffff"
                        elide: Text.ElideRight
                    }

                    StyledText {
                        visible: satelliteWrapper.countdown.dateText !== "" && !root.isSelectingTarget
                        text: "• " + satelliteWrapper.countdown.dateText
                        font.pixelSize: 10
                        color: "#71717a"
                    }
                }

                // Compact Minimalist Action Button
                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: actionMouse.containsMouse ? ColorUtils.applyAlpha("#ffffff", 0.14) : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.isSelectingTarget ? "check" : (satelliteWrapper.countdown.valid ? "close" : "add")
                        iconSize: 13
                        color: root.isSelectingTarget ? "#38bdf8" : (actionMouse.containsMouse ? "#ffffff" : "#71717a")
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSelectingTarget) {
                                root.isSelectingTarget = false
                            } else if (satelliteWrapper.countdown.valid) {
                                root.clearTarget()
                            } else {
                                root.isSelectingTarget = true
                            }
                        }
                    }
                }
            }
        }
    }
}

