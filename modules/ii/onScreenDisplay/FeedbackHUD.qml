import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool hudVisible: false
    property string hudIcon: "desktop_windows"
    property string hudTitle: "Display Refresh Rate"
    property string hudValue: "144 Hz"
    property string hudSubtext: "Ultra Smooth Mode"
    property color hudAccentColor: Appearance.colors.colPrimary
    property string hudStatusBadge: "144 Hz"

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    function triggerHud(icon, title, value, subtext, accentColor, badge) {
        root.hudIcon = icon;
        root.hudTitle = title;
        root.hudValue = value;
        root.hudSubtext = subtext;
        root.hudAccentColor = accentColor;
        root.hudStatusBadge = badge;

        if (hudLoader.item) {
            hudLoader.item.resetTimer();
        }
        root.hudVisible = true;
    }

    function showRefreshRate(rate) {
        var hz = String(rate).trim();
        if (hz.indexOf("60") !== -1) {
            triggerHud(
                "desktop_windows",
                Translation.tr("Display Mode"),
                "60 Hz",
                Translation.tr("Standard • Power Saving"),
                Appearance.colors.colSecondary,
                "60 Hz"
            );
        } else {
            triggerHud(
                "desktop_windows",
                Translation.tr("Display Mode"),
                "144 Hz",
                Translation.tr("Ultra Smooth • High Refresh"),
                Appearance.colors.colPrimary,
                "144 Hz"
            );
        }
    }

    function showCamera(enabled) {
        var isEn = (enabled === true || enabled === "true" || enabled === "1" || enabled === "on");
        if (isEn) {
            triggerHud(
                "videocam",
                Translation.tr("Camera Privacy"),
                Translation.tr("Camera Enabled"),
                Translation.tr("Hardware switch is ON"),
                "#4CAF50",
                "ACTIVE"
            );
        } else {
            triggerHud(
                "videocam_off",
                Translation.tr("Camera Privacy"),
                Translation.tr("Camera Disabled"),
                Translation.tr("Hardware switch is OFF"),
                "#F44336",
                "MUTED"
            );
        }
    }

    Loader {
        id: hudLoader
        active: root.hudVisible

        sourceComponent: PanelWindow {
            id: hudWindow
            color: "transparent"
            screen: root.focusedScreen

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    hudWindow.screen = root.focusedScreen;
                }
            }

            WlrLayershell.namespace: "quickshell:feedbackHud"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            anchors {
                bottom: true
            }

            margins {
                bottom: 60
            }

            implicitWidth: hudContent.implicitWidth + 30
            implicitHeight: hudContent.implicitHeight + 30
            visible: true

            function resetTimer() {
                fadeOutAnim.stop();
                hudContent.opacity = 1.0;
                hideTimer.restart();
            }

            Timer {
                id: hideTimer
                interval: 2200
                repeat: false
                running: true
                onTriggered: {
                    fadeOutAnim.start();
                }
            }

            NumberAnimation {
                id: fadeOutAnim
                target: hudContent
                property: "opacity"
                to: 0.0
                duration: 220
                easing.type: Easing.InCubic
                onFinished: {
                    root.hudVisible = false;
                }
            }

            Item {
                id: hudContent
                anchors.centerIn: parent
                implicitWidth: capsuleBg.implicitWidth
                implicitHeight: capsuleBg.implicitHeight

                Component.onCompleted: {
                    hudContent.opacity = 0;
                    hudContent.scale = 0.88;
                    popInAnim.start();
                }

                ParallelAnimation {
                    id: popInAnim
                    NumberAnimation {
                        target: hudContent
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: hudContent
                        property: "scale"
                        from: 0.88
                        to: 1.0
                        duration: 220
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }

                StyledRectangularShadow {
                    target: capsuleBg
                }

                Rectangle {
                    id: capsuleBg
                    radius: Appearance.rounding.full
                    color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.94)
                    border.width: 1
                    border.color: ColorUtils.applyAlpha(root.hudAccentColor, 0.4)

                    implicitWidth: innerRow.implicitWidth + 36
                    implicitHeight: innerRow.implicitHeight + 20

                    RowLayout {
                        id: innerRow
                        anchors.centerIn: parent
                        spacing: 14

                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: 22
                            color: ColorUtils.applyAlpha(root.hudAccentColor, 0.16)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha(root.hudAccentColor, 0.3)

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.hudIcon
                                iconSize: 24
                                color: root.hudAccentColor
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter

                            StyledText {
                                text: root.hudTitle
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: root.hudValue
                                font.pixelSize: Appearance.font.pixelSize.large
                                color: Appearance.colors.colOnLayer0
                                font.weight: Font.Bold
                            }

                            StyledText {
                                visible: root.hudSubtext !== ""
                                text: root.hudSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller - 1
                                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.65)
                            }
                        }

                        Rectangle {
                            Layout.leftMargin: 8
                            Layout.alignment: Qt.AlignVCenter
                            radius: Appearance.rounding.full
                            color: root.hudAccentColor
                            implicitHeight: 26
                            implicitWidth: badgeLabel.implicitWidth + 18

                            StyledText {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: root.hudStatusBadge
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimary ?? "#ffffff"
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "feedbackHud"

        function show(icon: string, title: string, value: string, badge: string): void {
            root.triggerHud(icon, title, value, "", Appearance.colors.colPrimary, badge);
        }

        function showRefreshRate(rate: string): void {
            root.showRefreshRate(rate);
        }

        function showCamera(state: string): void {
            root.showCamera(state);
        }
    }
}
