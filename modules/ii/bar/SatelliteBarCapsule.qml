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

    // Determine the active item to display
    readonly property var activeTarget: {
        // 1. Pinned targets take top priority
        if (root.pinnedTargets.length > 0) {
            const idx = Math.min(root.currentTargetIndex, root.pinnedTargets.length - 1);
            return root.pinnedTargets[idx];
        }

        // 2. Nearest upcoming user event from calendar_events.json
        const now = new Date();
        const nowKey = formatDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
        if (root.userEvents.length > 0) {
            // Find events today or in future
            const futureEvents = root.userEvents.filter(ev => ev.date >= nowKey);
            if (futureEvents.length > 0) {
                futureEvents.sort((a, b) => a.date.localeCompare(b.date));
                return {
                    date: futureEvents[0].date,
                    title: futureEvents[0].text || "Note",
                    type: "user"
                };
            }
            // If only past events, take the most recent
            const sorted = [...root.userEvents].sort((a, b) => b.date.localeCompare(a.date));
            return {
                date: sorted[0].date,
                title: sorted[0].text || "Note",
                type: "user"
            };
        }

        // 3. Nearest upcoming festival / holiday from IndianCalendar
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

        // 4. Default placeholder
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

    // Satellite Capsule Pill
    Rectangle {
        id: capsulePill
        anchors.centerIn: parent
        implicitHeight: 28
        implicitWidth: contentRow.implicitWidth + 18
        radius: Appearance.rounding.full

        color: mouseArea.containsMouse
            ? Appearance.colors.colLayer1Hover
            : ColorUtils.transparentize(Appearance.colors.colLayer1, 0.35)
        border.width: 1
        border.color: mouseArea.containsMouse
            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.45)
            : ColorUtils.applyAlpha(ColorUtils.mix(Appearance.colors.colPrimary, "#ffffff", 0.35), 0.16)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            // Countdown Status Badge Pill
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 20
                implicitWidth: badgeTextLabel.implicitWidth + 10
                radius: 10
                color: {
                    if (!root.countdown.valid) {
                        return ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18);
                    }
                    if (root.countdown.days === 0) {
                        return ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25);
                    }
                    if (root.countdown.days > 0) {
                        return ColorUtils.applyAlpha("#38bdf8", 0.18);
                    }
                    return ColorUtils.applyAlpha("#94a3b8", 0.16);
                }
                border.width: 1
                border.color: {
                    if (!root.countdown.valid) {
                        return ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.40);
                    }
                    if (root.countdown.days === 0) {
                        return ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.60);
                    }
                    if (root.countdown.days > 0) {
                        return ColorUtils.applyAlpha("#38bdf8", 0.45);
                    }
                    return ColorUtils.applyAlpha("#94a3b8", 0.30);
                }

                StyledText {
                    id: badgeTextLabel
                    anchors.centerIn: parent
                    text: root.countdown.badgeText
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: {
                        if (!root.countdown.valid || root.countdown.days === 0) {
                            return Appearance.colors.colPrimary;
                        }
                        if (root.countdown.days > 0) {
                            return "#38bdf8";
                        }
                        return "#94a3b8";
                    }
                }
            }

            // Summary Title & Date Tag
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 5

                StyledText {
                    text: root.countdown.title
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }

                StyledText {
                    visible: root.countdown.dateText.length > 0
                    text: "•  " + root.countdown.dateText
                    font.pixelSize: 11
                    color: Appearance.colors.colSubtext
                }
            }

            // Multiple targets indicator
            Rectangle {
                visible: root.pinnedTargets.length > 1
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 16
                implicitWidth: countText.implicitWidth + 8
                radius: 8
                color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15)

                StyledText {
                    id: countText
                    anchors.centerIn: parent
                    text: `${root.currentTargetIndex + 1}/${root.pinnedTargets.length}`
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
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

    // Interactive Detailed Popup
    StyledPopup {
        id: popup
        hoverTarget: mouseArea

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            implicitWidth: 280

            StyledPopupHeaderRow {
                icon: "satellite_alt"
                label: Translation.tr("Satellite Summary")
            }

            // Active Countdown Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 16
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: popupBadgeText.implicitWidth + 10
                            radius: 9
                            color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.2)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.5)

                            StyledText {
                                id: popupBadgeText
                                anchors.centerIn: parent
                                text: root.countdown.badgeText
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Appearance.colors.colPrimary
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.countdown.title
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        visible: root.countdown.dateText.length > 0
                        text: Translation.tr("Target Date: ") + root.countdown.dateText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Pinned Targets List
            ColumnLayout {
                visible: root.pinnedTargets.length > 0
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Pinned Targets (%1):").arg(root.pinnedTargets.length)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

                Repeater {
                    model: root.pinnedTargets
                    delegate: RowLayout {
                        id: targetRow
                        Layout.fillWidth: true
                        spacing: 6
                        readonly property var cd: getRowCountdown(modelData)

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

                        StyledText {
                            text: targetRow.cd.text
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: targetRow.cd.days === 0 ? Appearance.colors.colPrimary : "#38bdf8"
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.date
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: targetRow.cd.dateText
                            font.pixelSize: 10
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // Quick hint footer
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 24
                radius: Appearance.rounding.small
                color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.08)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        text: "touch_app"
                        iconSize: 13
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Click for calendar • Scroll to cycle")
                        font.pixelSize: 10
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
