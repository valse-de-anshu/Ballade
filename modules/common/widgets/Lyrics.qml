pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"
    property color dimColor: Qt.rgba(1, 1, 1, 0.35)
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer
    property int textAlignment: Text.AlignLeft

    implicitWidth: 200
    implicitHeight: 200

    function restartLyrics() {
        LyricsService.restartLyrics();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LyricsService.status !== "ok"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 40
                    implicitHeight: 40

                    MaterialLoadingIndicator {
                        anchors.fill: parent
                        loading: LyricsService.status === "loading"
                        colBg: root.indicatorColor
                        colShape: root.indicatorShapeColor
                        implicitSize: 40
                        visible: LyricsService.status === "loading"
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_off"
                        iconSize: 28
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
                            return LyricsService.ccMode ? Translation.tr("Fetching YouTube subtitles...") : Translation.tr("Searching lyrics...")
                        } else if (LyricsService.status === "no_info") {
                            return Translation.tr("No media playing")
                        } else {
                            return LyricsService.ccMode ? Translation.tr("No subtitles found") : Translation.tr("No lyrics available")
                        }
                    }
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.dimColor
                }

                // If not found in lyrics mode, offer to try CC / Subtitles!
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: LyricsService.status === "not_found" && !LyricsService.ccMode
                    implicitWidth: 140
                    implicitHeight: 28
                    radius: Appearance.rounding.full
                    color: tryCcMa.containsMouse ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colPrimaryContainer

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            text: "closed_caption"
                            iconSize: 14
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            text: "Try Captions / CC"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LyricsService.status === "ok"
            spacing: 6

            Repeater {
                model: 7
                delegate: StyledText {
                    id: lyricSlot
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: root.textAlignment
                    wrapMode: Text.WordWrap
                    text: LyricsService.slots[index] ?? ""
                    readonly property int dist: Math.abs(index - LyricsService.before)
                    readonly property bool isPast: index < LyricsService.before
                    font.pixelSize: {
                        if (dist === 0) return Appearance.font.pixelSize.normal
                        if (dist === 1) return Appearance.font.pixelSize.small
                        return Appearance.font.pixelSize.smaller
                    }
                    font.weight: dist === 0 ? Font.Bold : Font.Normal
                    opacity: {
                        if (dist === 0) return 1.0
                        if (dist === 1) return isPast ? 0.35 : 0.70
                        if (dist === 2) return isPast ? 0.15 : 0.40
                        return isPast ? 0.08 : 0.20
                    }
                    color: dist === 0 ? root.activeColor : root.textColor
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let lineIdx = LyricsService.activeIndex - LyricsService.before + index
                            if (lineIdx >= 0 && lineIdx < LyricsService.lyricsLines.length) {
                                LyricsService.seekTo(LyricsService.lyricsLines[lineIdx].time)
                            }
                        }
                    }
                }
            }
        }
    }
}