pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "../background/widgets/calendar/IndianCalendar.js" as IndianCalendar

Item {
    id: root

    implicitHeight: Appearance.sizes.baseBarHeight
    implicitWidth: capsulePill.implicitWidth

    property var pinnedTargets: []
    property var userEvents: []
    property int currentTargetIndex: 0

    // Load custom pinned targets from calendar_target.json
    FileView {
        id: targetFileView
        path: Qt.resolvedUrl(Directories.config + "/calendar_target.json")
        watchChanges: true
        onLoaded: root.loadTargets()
        onLoadFailed: root.loadTargets()
    }

    // Load calendar notes/events from calendar_events.json
    FileView {
        id: eventsFileView
        path: Qt.resolvedUrl(Directories.config + "/calendar_events.json")
        watchChanges: true
        onLoaded: root.loadEvents()
        onLoadFailed: root.loadEvents()
    }

    Timer {
        id: midnightRefreshTimer
        interval: 60000 // Refresh every minute to keep countdown and day accurate
        repeat: true
        running: true
        onTriggered: {
            root.loadTargets();
            root.loadEvents();
        }
    }

    function loadTargets() {
        try {
            if (targetFileView.loaded && targetFileView.text().trim().length > 0) {
                const parsed = JSON.parse(targetFileView.text());
                if (parsed && typeof parsed === "object") {
                    if (Array.isArray(parsed.targets) && parsed.targets.length > 0) {
                        root.pinnedTargets = parsed.targets;
                        if (root.currentTargetIndex >= parsed.targets.length) {
                            root.currentTargetIndex = 0;
                        }
                        return;
                    } else if (parsed.date) {
                        root.pinnedTargets = [{
                            date: parsed.date,
                            title: parsed.title || "",
                            type: parsed.type || "festival"
                        }];
                        return;
                    }
                }
            }
        } catch(e) {}
        root.pinnedTargets = [];
    }

    function loadEvents() {
        try {
            if (eventsFileView.loaded && eventsFileView.text().trim().length > 0) {
                const parsed = JSON.parse(eventsFileView.text());
                if (Array.isArray(parsed)) {
                    root.userEvents = parsed;
                    return;
                }
            }
        } catch(e) {}
        root.userEvents = [];
    }

    function unpinTarget(dateKey, title) {
        if (!root.pinnedTargets || root.pinnedTargets.length === 0) return;
        let list = root.pinnedTargets.filter(t => !(t.date === dateKey && t.title === title));
        root.pinnedTargets = list;
        if (root.currentTargetIndex >= list.length) {
            root.currentTargetIndex = Math.max(0, list.length - 1);
        }
        saveTargets();
    }

    function saveTargets() {
        try {
            let currentPayload = {};
            if (targetFileView.loaded && targetFileView.text().trim().length > 0) {
                currentPayload = JSON.parse(targetFileView.text()) || {};
            }
            currentPayload.targets = root.pinnedTargets || [];
            targetFileView.setText(JSON.stringify(currentPayload, null, 2));
        } catch(e) {
            targetFileView.setText(JSON.stringify({ targets: root.pinnedTargets || [] }, null, 2));
        }
    }

    // Determine the active item to display (Strictly synchronized with Calendar)
    readonly property var activeTarget: {
        // 1. Pinned targets from calendar take top priority
        if (root.pinnedTargets.length > 0) {
            const idx = Math.min(root.currentTargetIndex, root.pinnedTargets.length - 1);
            return root.pinnedTargets[idx];
        }

        // 2. Upcoming user event from calendar_events.json (TODAY or FUTURE only, NEVER ancient past notes)
        const now = new Date();
        const nowKey = formatDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
        if (root.userEvents.length > 0) {
            const futureEvents = root.userEvents.filter(ev => ev.date >= nowKey);
            if (futureEvents.length > 0) {
                futureEvents.sort((a, b) => a.date.localeCompare(b.date));
                return {
                    date: futureEvents[0].date,
                    title: futureEvents[0].text || "Note",
                    type: "user"
                };
            }
        }

        // 3. Nearest upcoming festival / holiday from IndianCalendar (TODAY or FUTURE only)
        try {
            const y = now.getFullYear();
            const yearMap = IndianCalendar._getYearCached ? IndianCalendar._getYearCached(y) : IndianCalendar.getYearEvents(y);
            if (yearMap && typeof yearMap === "object") {
                const keys = Object.keys(yearMap).filter(k => k >= nowKey).sort();
                if (keys.length > 0) {
                    const firstKey = keys[0];
                    const list = yearMap[firstKey];
                    if (Array.isArray(list) && list.length > 0) {
                        return {
                            date: firstKey,
                            title: list[0].title || "Holiday",
                            type: list[0].type || "festival"
                        };
                    }
                }
            }
        } catch(e) {}

        // 4. Default placeholder when nothing is pinned
        return {
            date: "",
            title: Translation.tr("Tap to pin note"),
            type: "festival"
        };
    }

    function formatDateKey(y, m, d) {
        return y + "-" + (m < 10 ? "0" + m : m) + "-" + (d < 10 ? "0" + d : d);
    }

    readonly property var countdown: {
        const item = root.activeTarget;
        if (!item || !item.date) {
            return {
                days: 0,
                badgeText: "PIN",
                title: item ? item.title : Translation.tr("Tap to pin note"),
                dateText: "",
                valid: false
            };
        }

        const parts = item.date.split("-");
        if (parts.length < 3) {
            return {
                days: 0,
                badgeText: "PIN",
                title: item.title,
                dateText: "",
                valid: false
            };
        }

        const target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        const now = new Date();
        const nowMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const targetMidnight = new Date(target.getFullYear(), target.getMonth(), target.getDate());
        const diffTime = targetMidnight.getTime() - nowMidnight.getTime();
        const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

        let badge = "";
        if (diffDays === 0) badge = "TODAY";
        else if (diffDays === 1) badge = "1d left";
        else if (diffDays > 1) badge = diffDays + "d left";
        else if (diffDays === -1) badge = "1d ago";
        else badge = Math.abs(diffDays) + "d ago";

        return {
            days: diffDays,
            badgeText: badge,
            title: item.title || target.toLocaleDateString(Qt.locale(), "MMMM d"),
            dateText: target.toLocaleDateString(Qt.locale(), "d MMM"),
            valid: true
        };
    }

    function cycleNextTarget() {
        if (root.pinnedTargets.length > 1) {
            root.currentTargetIndex = (root.currentTargetIndex + 1) % root.pinnedTargets.length;
        }
    }

    // Satellite Top Bar Area: Pure, clean text (NO icons, NO gray pill covering)
    Rectangle {
        id: capsulePill
        anchors.centerIn: parent
        implicitHeight: 28
        implicitWidth: contentRow.implicitWidth + 16
        radius: Appearance.rounding.full

        // Seamless transparent background; gentle damped highlight only on hover
        color: mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
        border.width: 0

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            // Countdown Status Text (Pure text, high contrast, zero gray oval badge)
            StyledText {
                text: root.countdown.badgeText
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                color: {
                    if (!root.countdown.valid) return Appearance.colors.colSubtext;
                    if (root.countdown.days === 0) return Appearance.colors.colPrimary;
                    if (root.countdown.days > 0) return Appearance.colors.colSecondary;
                    return Appearance.colors.colSubtext;
                }
            }

            // Summary Title Text
            StyledText {
                text: root.countdown.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                Layout.maximumWidth: 220
            }

            // Date Tag Text
            StyledText {
                visible: root.countdown.dateText.length > 0
                text: "• " + root.countdown.dateText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            // Target Index Indicator (Pure text)
            StyledText {
                visible: root.pinnedTargets.length > 1
                text: `(${root.currentTargetIndex + 1}/${root.pinnedTargets.length})`
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.DemiBold
                color: Appearance.colors.colSubtext
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.cycleNextTarget();
                } else {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }
            }

            onWheel: wheel => {
                root.cycleNextTarget();
            }
        }
    }

    // Interactive Detailed Popup (Spacious, beautifully padded, zero icons)
    StyledPopup {
        id: popup
        hoverTarget: mouseArea

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14
            implicitWidth: 380

            // Header (Clean typography, zero icons)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: Translation.tr("Satellite Summary")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    visible: root.pinnedTargets.length > 1
                    text: `${root.currentTargetIndex + 1} / ${root.pinnedTargets.length}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }
            }

            // Active Countdown Card (Generous padding, clean typography, zero icons)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 0

                ColumnLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            text: root.countdown.badgeText
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: {
                                if (!root.countdown.valid) return Appearance.colors.colSubtext;
                                if (root.countdown.days === 0) return Appearance.colors.colPrimary;
                                if (root.countdown.days > 0) return Appearance.colors.colSecondary;
                                return Appearance.colors.colSubtext;
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.countdown.title
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                            wrapMode: Text.WordWrap
                        }
                    }

                    StyledText {
                        visible: root.countdown.dateText.length > 0
                        text: Translation.tr("Target Date: ") + root.countdown.dateText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Pinned Targets List
            ColumnLayout {
                visible: root.pinnedTargets.length > 0
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: Translation.tr("Pinned Targets (%1)").arg(root.pinnedTargets.length)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: root.pinnedTargets
                    delegate: Rectangle {
                        id: targetRowDelegate
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: targetRow.implicitHeight + 14
                        radius: Appearance.rounding.small
                        color: targetRowDelegate.index === root.currentTargetIndex
                            ? Appearance.colors.colLayer2
                            : (rowMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")

                        readonly property var cd: getRowCountdown(targetRowDelegate.modelData)

                        function getRowCountdown(item) {
                            if (!item || !item.date) return { days: 0, text: "PIN", dateText: "" };
                            const parts = item.date.split("-");
                            if (parts.length < 3) return { days: 0, text: "PIN", dateText: "" };
                            const target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                            const now = new Date();
                            const nowMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                            const targetMidnight = new Date(target.getFullYear(), target.getMonth(), target.getDate());
                            const diffDays = Math.round((targetMidnight.getTime() - nowMidnight.getTime()) / (1000 * 60 * 60 * 24));
                            return {
                                days: diffDays,
                                text: diffDays === 0 ? "TODAY" : (diffDays > 0 ? `${diffDays}d` : `${Math.abs(diffDays)}d ago`),
                                dateText: target.toLocaleDateString(Qt.locale(), "d MMM")
                            };
                        }

                        RowLayout {
                            id: targetRow
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            StyledText {
                                text: targetRowDelegate.cd ? targetRowDelegate.cd.text : ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Bold
                                color: (targetRowDelegate.cd && targetRowDelegate.cd.days === 0)
                                    ? Appearance.colors.colPrimary
                                    : ((targetRowDelegate.cd && targetRowDelegate.cd.days > 0) ? Appearance.colors.colSecondary : Appearance.colors.colSubtext)
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: targetRowDelegate.modelData ? (targetRowDelegate.modelData.title || targetRowDelegate.modelData.date || "") : ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: targetRowDelegate.cd ? targetRowDelegate.cd.dateText : ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }

                            // Unpin button (pure text)
                            StyledText {
                                text: Translation.tr("Unpin")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Medium
                                color: unpinMouse.containsMouse ? Appearance.colors.colError : Appearance.colors.colSubtext

                                MouseArea {
                                    id: unpinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (targetRowDelegate.modelData) {
                                            root.unpinTarget(targetRowDelegate.modelData.date, targetRowDelegate.modelData.title);
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: {
                                root.currentTargetIndex = targetRowDelegate.index;
                            }
                        }
                    }
                }
            }

            // Quick hint footer (Pure text, zero icons)
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Click to toggle calendar • Scroll to cycle targets")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
