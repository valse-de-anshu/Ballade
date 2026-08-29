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

AbstractBackgroundWidget {
    id: root
    configEntryName: "goals"
    hoverEnabled: true

    // ── Two size modes ──────────────────────────────────────
    property string sizeMode: configEntry?.sizeMode ?? "full"
    readonly property bool isCompact: sizeMode === "compact"

    implicitWidth: 260
    implicitHeight: isCompact ? 250 : 500

    Behavior on implicitHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    // ── Goal Data via Singleton Service ────────────────────
    readonly property var goalsList: Goals.goalsList
    property string expandedHorizon: "daily"
    property string compactHorizon: ""
    property bool isUserTyping: false
    property string schedulingGoalId: "" // Which goal has the calendar date picker open

    onIsUserTypingChanged: {
        GlobalStates.desktopWidgetKeyboardFocus = root.isUserTyping
    }

    // ── Symmetric 5-point orbit — 72° spacing starting from top (270°) ──
    readonly property var horizons: [
        { id: "daily",    name: "Daily",       icon: "today",              angleDeg: 270 }, // Top
        { id: "weekly",   name: "Weekly",      icon: "calendar_view_week", angleDeg: 342 }, // Upper-Right
        { id: "monthly",  name: "Monthly",     icon: "calendar_month",     angleDeg:  54 }, // Lower-Right
        { id: "yearly",   name: "Yearly",      icon: "workspace_premium",  angleDeg: 126 }, // Lower-Left
        { id: "longterm", name: "Long-Term",   icon: "rocket_launch",      angleDeg: 198 }  // Upper-Left
    ]

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
        let found = horizons.find(h => h.id === norm)
        return found ? found.name : (norm.charAt(0).toUpperCase() + norm.slice(1))
    }

    function hIcon(hId) {
        let norm = normalizeHorizon(hId)
        let found = horizons.find(h => h.id === norm)
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

    onGoalsListChanged: mainArc.requestPaint()

    // ════════════════════════════════════════════════════════
    // Frosted Glass Card Shell
    // ════════════════════════════════════════════════════════
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

        StyledRectangularShadow { target: card; z: -1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // ── TOP: ORBITAL RADAR SECTION ────────────────────
            // orbitCenter is a fixed 200×200 box — EVERYTHING is a child of it
            // so all coordinates share the same origin (0,0 = top-left)
            Item {
                id: orbitCenter
                Layout.alignment: Qt.AlignHCenter
                width: 200
                height: 200

                // Ring Canvas — centered in the 200×200 box
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

                        // Progress arc from Top (-90°)
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

                // Center text — anchored to center of orbitCenter box (100,100)
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

                // 5 orbit buttons — floating cleanly outside the ring with 14px gap
                Repeater {
                    id: orbitRepeater
                    model: root.horizons

                    delegate: Item {
                        required property var modelData
                        readonly property real orbitR: 74
                        readonly property real btnSize: 30
                        readonly property real rad: modelData.angleDeg * Math.PI / 180.0

                        width: btnSize
                        height: btnSize
                        // 100 = half of orbitCenter's 200×200
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
                                    root.expandedHorizon = (root.expandedHorizon === modelData.id) ? "" : modelData.id
                                }
                            }
                        }
                    }
                }
            }

            // ── SEPARATOR LINE ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.60)
                visible: !root.isCompact
            }

            // ── BOTTOM: SCROLLABLE ACCORDION GOAL LIST ────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                visible: !root.isCompact

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4

                    StyledText {
                        text: "All Goals"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    Item { Layout.fillWidth: true }
                }

                Flickable {
                    id: goalFlickable
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

                    ColumnLayout {
                        id: accordionContentCol
                        width: goalFlickable.width
                        spacing: 4

                        Repeater {
                            model: root.horizons

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
                                            root.expandedHorizon = (root.expandedHorizon === horizonSection.horizonId) ? "" : horizonSection.horizonId
                                        }
                                    }
                                }

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
            resizeMode: "vertical"
            onResized: newHeight => {
                root.sizeMode = (newHeight < 375) ? "compact" : "full"
            }
            onResizeFinished: {
                if (root.configEntry) root.configEntry.sizeMode = root.sizeMode
            }
        }
    }
}
