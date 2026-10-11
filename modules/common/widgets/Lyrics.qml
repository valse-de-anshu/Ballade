pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property color textColor: Qt.rgba(1, 1, 1, 0.70)
    property color activeColor: "#ffffff"
    property color dimColor: Qt.rgba(1, 1, 1, 0.38)
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer
    property color fadeColor: Appearance.colors.colLayer0Base
    property int textAlignment: isWide ? Text.AlignLeft : Text.AlignHCenter
    readonly property bool isWide: width >= 360

    implicitWidth: 260
    implicitHeight: 320

    function restartLyrics() {
        LyricsService.restartLyrics();
    }

    // ── 1. ACTIVE LYRICS LIST VIEW (Apple Music Style) ──────────────────────
    Item {
        anchors.fill: parent
        visible: LyricsService.status === "ok" && LyricsService.lyricsLines.length > 0
        clip: true

        ListView {
            id: lyricsList
            anchors.fill: parent
            anchors.leftMargin: root.isWide ? 20 : 12
            anchors.rightMargin: root.isWide ? 20 : 12
            clip: true
            model: LyricsService.lyricsLines
            currentIndex: LyricsService.activeIndex
            highlightMoveDuration: 400
            preferredHighlightBegin: height * 0.36
            preferredHighlightEnd: height * 0.44
            highlightRangeMode: ListView.ApplyRange
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1800

            Connections {
                target: LyricsService
                function onActiveIndexChanged() {
                    if (lyricsList.count > 0 && LyricsService.activeIndex >= 0 && LyricsService.activeIndex < lyricsList.count) {
                        lyricsList.positionViewAtIndex(LyricsService.activeIndex, ListView.Center)
                    }
                }
            }

            // Top spacer so the first line can be comfortably centered
            header: Item {
                width: lyricsList.width
                height: lyricsList.height * 0.32
            }

            // Bottom spacer so the last line can be comfortably centered
            footer: Item {
                width: lyricsList.width
                height: lyricsList.height * 0.45
            }

            delegate: Item {
                id: delegateItem
                required property int index
                required property var modelData

                readonly property bool isCurrent: index === LyricsService.activeIndex
                readonly property int dist: Math.abs(index - LyricsService.activeIndex)
                readonly property bool isPast: index < LyricsService.activeIndex

                width: lyricsList.width
                implicitHeight: lyricText.implicitHeight + (root.isWide ? 22 : 14)

                StyledText {
                    id: lyricText
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 10, 680)
                    horizontalAlignment: root.textAlignment
                    wrapMode: Text.WordWrap
                    text: delegateItem.modelData.text || "♪"

                    font.pixelSize: {
                        if (delegateItem.isCurrent) return root.isWide ? 24 : 18.5
                        if (delegateItem.dist === 1) return root.isWide ? 18 : 15
                        if (delegateItem.dist === 2) return root.isWide ? 16 : 13.5
                        return root.isWide ? 14.5 : 12
                    }
                    font.weight: delegateItem.isCurrent ? Font.Bold : (delegateItem.dist <= 1 ? Font.DemiBold : Font.Normal)

                    color: delegateItem.isCurrent ? root.activeColor : root.textColor

                    opacity: {
                        if (delegateItem.isCurrent) return 1.0
                        if (delegateItem.dist === 1) return delegateItem.isPast ? 0.42 : 0.72
                        if (delegateItem.dist === 2) return delegateItem.isPast ? 0.20 : 0.42
                        return delegateItem.isPast ? 0.08 : 0.22
                    }

                    scale: delegateItem.isCurrent ? 1.02 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (delegateItem.modelData && delegateItem.modelData.time !== undefined) {
                            LyricsService.seekTo(delegateItem.modelData.time)
                        }
                    }
                }
            }
        }

        // Top soft edge dissolve
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: root.isWide ? 56 : 38
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(root.fadeColor, 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            z: 3
        }

        // Bottom soft edge dissolve
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.isWide ? 56 : 38
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: ColorUtils.transparentize(root.fadeColor, 0.05) }
            }
            z: 3
        }
    }

    // ── 2. MINIMALIST STATUS / FALLBACK STAGE ─────────────────────────────────
    Item {
        anchors.fill: parent
        visible: LyricsService.status !== "ok" || LyricsService.lyricsLines.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 44

                MaterialLoadingIndicator {
                    anchors.fill: parent
                    loading: LyricsService.status === "loading"
                    colBg: root.indicatorColor
                    colShape: root.indicatorShapeColor
                    implicitSize: 44
                    visible: LyricsService.status === "loading"
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: 32
                    color: root.dimColor
                    visible: LyricsService.status !== "loading"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: LyricsService.restartLyrics()
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (LyricsService.status === "loading") {
                        return LyricsService.ccMode ? Translation.tr("Syncing captions...") : Translation.tr("Finding lyrics...")
                    } else if (LyricsService.status === "no_info") {
                        return Translation.tr("No media playing")
                    } else {
                        return LyricsService.ccMode ? Translation.tr("No captions available") : Translation.tr("Lyrics not available")
                    }
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.dimColor
            }

            // Minimal luxury chip: Try Captions / CC
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: LyricsService.status === "not_found" && !LyricsService.ccMode
                implicitWidth: 140
                implicitHeight: 30
                radius: 15
                color: tryCcMa.containsMouse ? ColorUtils.transparentize(root.activeColor, 0.8) : ColorUtils.transparentize(root.activeColor, 0.9)
                border.width: 1
                border.color: ColorUtils.transparentize(root.activeColor, 0.75)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        text: "closed_caption"
                        iconSize: 15
                        color: root.activeColor
                    }
                    StyledText {
                        text: "Try Captions"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: root.activeColor
                    }
                }

                MouseArea {
                    id: tryCcMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: LyricsService.toggleCC()
                }
            }
        }
    }
}