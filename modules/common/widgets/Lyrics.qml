pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property color textColor: Qt.rgba(1, 1, 1, 0.55)
    property color activeColor: "#ffffff"
    property color dimColor: Qt.rgba(1, 1, 1, 0.32)
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer
    property int textAlignment: isWide ? Text.AlignLeft : Text.AlignHCenter
    readonly property bool isWide: width >= 360

    implicitWidth: 260
    implicitHeight: 320

    function restartLyrics() {
        LyricsService.restartLyrics();
    }

    // ── 1. ACTIVE LYRICS LIST VIEW (Pure Alpha Mask Dissolve) ────────────────
    Item {
        anchors.fill: parent
        visible: LyricsService.status === "ok" && LyricsService.lyricsLines.length > 0
        clip: true

        ListView {
            id: lyricsList
            anchors.fill: parent
            anchors.leftMargin: root.isWide ? 16 : 8
            anchors.rightMargin: root.isWide ? 16 : 8
            clip: true
            model: LyricsService.lyricsLines
            currentIndex: LyricsService.activeIndex
            highlightMoveDuration: 450
            preferredHighlightBegin: height * 0.36
            preferredHighlightEnd: height * 0.44
            highlightRangeMode: ListView.ApplyRange
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1800

            // Pure Alpha OpacityMask: lyrics fade to absolute transparency at edges without dark blocks!
            layer.enabled: Boolean(lyricsList.count > 0)
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: lyricsList.width
                    height: lyricsList.height
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.14; color: "#ffffffff" }
                        GradientStop { position: 0.86; color: "#ffffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            Connections {
                target: LyricsService
                function onActiveIndexChanged() {
                    if (lyricsList.count > 0 && LyricsService.activeIndex >= 0 && LyricsService.activeIndex < lyricsList.count) {
                        lyricsList.positionViewAtIndex(LyricsService.activeIndex, ListView.Center)
                    }
                }
            }

            // Top spacer
            header: Item {
                width: lyricsList.width
                height: lyricsList.height * 0.32
            }

            // Bottom spacer
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
                        if (delegateItem.isCurrent) return root.isWide ? 23 : 18
                        if (delegateItem.dist === 1) return root.isWide ? 17 : 14.5
                        if (delegateItem.dist === 2) return root.isWide ? 15 : 13
                        return root.isWide ? 13.5 : 11.5
                    }
                    font.weight: delegateItem.isCurrent ? Font.Bold : (delegateItem.dist <= 1 ? Font.DemiBold : Font.Normal)

                    color: delegateItem.isCurrent ? root.activeColor : root.textColor

                    opacity: {
                        if (delegateItem.isCurrent) return 1.0
                        if (delegateItem.dist === 1) return delegateItem.isPast ? 0.34 : 0.62
                        if (delegateItem.dist === 2) return delegateItem.isPast ? 0.16 : 0.34
                        if (delegateItem.dist === 3) return delegateItem.isPast ? 0.05 : 0.16
                        return 0.03
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
    }

    // ── 2. MINIMALIST STATUS / FALLBACK STAGE ─────────────────────────────────
    Item {
        anchors.fill: parent
        visible: LyricsService.status !== "ok" || LyricsService.lyricsLines.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 36

                MaterialLoadingIndicator {
                    anchors.fill: parent
                    loading: LyricsService.status === "loading"
                    colBg: root.indicatorColor
                    colShape: root.indicatorShapeColor
                    implicitSize: 36
                    visible: LyricsService.status === "loading"
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: 26
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
                        return LyricsService.ccMode ? Translation.tr("No captions found") : Translation.tr("Lyrics unavailable")
                    }
                }
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.dimColor
            }

            // Minimal luxury chip: Try Captions / CC
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: LyricsService.status === "not_found" && !LyricsService.ccMode
                implicitWidth: 120
                implicitHeight: 26
                radius: 13
                color: tryCcMa.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.12)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol {
                        text: "closed_caption"
                        iconSize: 13
                        color: "#ffffff"
                    }
                    StyledText {
                        text: "Try Captions"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: "#ffffff"
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