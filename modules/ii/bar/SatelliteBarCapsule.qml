pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    visible: CalendarService.pinnedTargets.length > 0
    implicitHeight: visible ? Appearance.sizes.baseBarHeight : 0
    implicitWidth: visible ? capsulePill.implicitWidth : 0

    property int currentTargetIndex: 0
    readonly property int clampedIndex: CalendarService.pinnedTargets.length > 0
        ? Math.max(0, Math.min(root.currentTargetIndex, CalendarService.pinnedTargets.length - 1))
        : 0

    readonly property var activeTarget: CalendarService.pinnedTargets.length > 0
        ? CalendarService.pinnedTargets[root.clampedIndex]
        : null

    function cycleNextTarget() {
        if (CalendarService.pinnedTargets.length > 1) {
            root.currentTargetIndex = (root.clampedIndex + 1) % CalendarService.pinnedTargets.length;
        }
    }

    readonly property var countdown: {
        const item = root.activeTarget;
        if (!item || !item.date) {
            return {
                days: 0,
                badgeText: "",
                title: "",
                dateText: "",
                valid: false
            };
        }

        const parts = item.date.split("-");
        if (parts.length < 3) {
            return {
                days: 0,
                badgeText: "",
                title: item.title || "",
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
                visible: CalendarService.pinnedTargets.length > 1
                text: `(${root.clampedIndex + 1}/${CalendarService.pinnedTargets.length})`
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
                    popup.open();
                }
            }

            onWheel: wheel => {
                root.cycleNextTarget();
            }
        }
    }

    // Interactive Detailed Popup (Spacious, clean, single summary card, zero icons)
    StyledPopup {
        id: popup
        hoverTarget: mouseArea

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            implicitWidth: 320

            // Header: "Summary"
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: Translation.tr("Summary")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    visible: CalendarService.pinnedTargets.length > 1
                    text: `${root.clampedIndex + 1} / ${CalendarService.pinnedTargets.length}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }
            }

            // Active Summary Card (Single unified card, zero duplicate list below)
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

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.countdown.dateText.length > 0 || CalendarService.pinnedTargets.length > 0

                        StyledText {
                            visible: root.countdown.dateText.length > 0
                            text: Translation.tr("Target Date: ") + root.countdown.dateText
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Item { Layout.fillWidth: true }

                        // Unpin action if currently pinned
                        StyledText {
                            visible: CalendarService.pinnedTargets.length > 0
                            text: Translation.tr("Unpin")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: unpinActiveMouse.containsMouse ? Appearance.colors.colError : Appearance.colors.colSubtext

                            MouseArea {
                                id: unpinActiveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.activeTarget && root.activeTarget.date) {
                                        CalendarService.unpinTarget(root.activeTarget.date, root.activeTarget.title);
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
