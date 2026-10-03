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

    readonly property bool isPopupActive: popup.active
    visible: CalendarService.pinnedTargets.length > 0 || isPopupActive
    implicitHeight: visible ? Appearance.sizes.baseBarHeight : 0
    implicitWidth: visible ? Math.min(230, capsulePill.implicitWidth) : 0
    Layout.fillWidth: false
    Layout.maximumWidth: 230
    Layout.minimumWidth: 80

    property int currentTargetIndex: 0
    readonly property int clampedIndex: CalendarService.pinnedTargets.length > 0
        ? Math.max(0, Math.min(root.currentTargetIndex, CalendarService.pinnedTargets.length - 1))
        : 0

    readonly property var activeTarget: CalendarService.pinnedTargets.length > 0
        ? CalendarService.pinnedTargets[root.clampedIndex]
        : null

    property bool popupHovered: false
    property bool isPopupOpen: false

    function cycleNextTarget() {
        if (CalendarService.pinnedTargets.length > 1) {
            root.currentTargetIndex = (root.clampedIndex + 1) % CalendarService.pinnedTargets.length;
        }
    }

    function cyclePrevTarget() {
        if (CalendarService.pinnedTargets.length > 1) {
            root.currentTargetIndex = (root.clampedIndex - 1 + CalendarService.pinnedTargets.length) % CalendarService.pinnedTargets.length;
        }
    }

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: {
            root.popupHovered = false;
        }
    }

    Connections {
        target: CalendarService
        function onTargetsChanged() {
            if (CalendarService.pinnedTargets.length === 0) {
                root.isPopupOpen = false;
                root.popupHovered = false;
            }
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
        implicitWidth: Math.min(230, contentRow.implicitWidth + 16)
        width: Math.min(parent.width > 0 ? parent.width : implicitWidth, implicitWidth)
        height: implicitHeight
        radius: Appearance.rounding.full
        clip: true

        // Seamless transparent background; gentle damped highlight only on hover
        color: (mouseArea.containsMouse || root.popupHovered || root.isPopupOpen) ? Appearance.colors.colLayer1Hover : "transparent"
        border.width: 0

        opacity: CalendarService.pinnedTargets.length > 0 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 16)
            spacing: 6

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
                Layout.fillWidth: true
                Layout.maximumWidth: 120
                Layout.minimumWidth: 40
            }

            // Date Tag Text
            StyledText {
                visible: root.countdown.dateText.length > 0 && capsulePill.width >= 200
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

            onEntered: {
                closeTimer.stop();
                root.popupHovered = true;
            }

            onExited: {
                closeTimer.restart();
            }

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.cycleNextTarget();
                } else {
                    root.isPopupOpen = !root.isPopupOpen;
                }
            }

            onWheel: wheel => {
                if (wheel.angleDelta.y < 0) {
                    root.cycleNextTarget();
                } else if (wheel.angleDelta.y > 0) {
                    root.cyclePrevTarget();
                }
            }
        }
    }

    // Interactive Detailed Popup (Spacious, clean, single summary card, zero icons)
    StyledPopup {
        id: popup
        hoverTarget: mouseArea
        shouldBeOpen: (root.popupHovered || root.isPopupOpen) && CalendarService.pinnedTargets.length > 0

        Item {
            id: popupContent
            anchors.centerIn: parent
            implicitWidth: 320
            implicitHeight: popupCol.implicitHeight
            width: implicitWidth
            height: implicitHeight

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        closeTimer.stop();
                        root.popupHovered = true;
                    } else {
                        closeTimer.restart();
                    }
                }
            }

            WheelHandler {
                onWheel: event => {
                    if (event.angleDelta.y < 0) {
                        root.cycleNextTarget();
                    } else if (event.angleDelta.y > 0) {
                        root.cyclePrevTarget();
                    }
                }
            }

            ColumnLayout {
                id: popupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 12

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

                    RowLayout {
                        visible: CalendarService.pinnedTargets.length > 1
                        spacing: 6

                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: prevMouse.containsMouse ? ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.1) : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: "‹"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: prevMouse.containsMouse ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cyclePrevTarget()
                            }
                        }

                        StyledText {
                            text: `${root.clampedIndex + 1} / ${CalendarService.pinnedTargets.length}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colSubtext
                        }

                        Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: nextMouse.containsMouse ? ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.1) : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: "›"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: nextMouse.containsMouse ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cycleNextTarget()
                            }
                        }
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
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 10

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
                            Rectangle {
                                visible: CalendarService.pinnedTargets.length > 0
                                implicitWidth: unpinText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: unpinActiveMouse.containsMouse ? ColorUtils.applyAlpha(Appearance.colors.colError, 0.15) : "transparent"

                                StyledText {
                                    id: unpinText
                                    anchors.centerIn: parent
                                    text: Translation.tr("Unpin")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: unpinActiveMouse.containsMouse ? Appearance.colors.colError : Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    id: unpinActiveMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    propagateComposedEvents: false
                                    onClicked: mouse => {
                                        mouse.accepted = true;
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
}
