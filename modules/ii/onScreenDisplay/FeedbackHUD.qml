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
    property string hudText: "144 Hz"
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    function triggerHud(icon, text) {
        root.hudIcon = icon;
        root.hudText = text;

        if (hudLoader.item) {
            hudLoader.item.resetTimer();
        }
        root.hudVisible = true;
    }

    function showRefreshRate(rate) {
        var hz = String(rate).trim();
        var is60 = hz.indexOf("60") !== -1;
        triggerHud("desktop_windows", is60 ? "60 Hz" : "144 Hz");
        Audio.playSystemSound("bell");
        HyprlandData.updateMonitors();
    }

    function showCamera(enabled) {
        var isEn = (enabled === true || enabled === "true" || enabled === "1" || enabled === "on");
        triggerHud(isEn ? "videocam" : "videocam_off", isEn ? Translation.tr("Camera On") : Translation.tr("Camera Off"));
        Notifications.playNotificationSound();
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
                bottom: 45
            }

            implicitWidth: hudContent.implicitWidth + 20
            implicitHeight: hudContent.implicitHeight + 20
            visible: true

            function resetTimer() {
                fadeOutAnim.stop();
                hudContent.opacity = 1.0;
                hideTimer.restart();
            }

            Timer {
                id: hideTimer
                interval: 1800
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
                duration: 180
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
                    hudContent.scale = 0.92;
                    popInAnim.start();
                }

                ParallelAnimation {
                    id: popInAnim
                    NumberAnimation {
                        target: hudContent
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: hudContent
                        property: "scale"
                        from: 0.92
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                StyledRectangularShadow {
                    target: capsuleBg
                }

                Rectangle {
                    id: capsuleBg
                    radius: Appearance.rounding.full
                    color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.92)
                    border.width: 1
                    border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.28)

                    implicitHeight: 38
                    implicitWidth: contentRow.implicitWidth + 28

                    RowLayout {
                        id: contentRow
                        anchors.centerIn: parent
                        spacing: 9

                        MaterialSymbol {
                            text: root.hudIcon
                            iconSize: 19
                            color: Appearance.colors.colPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: root.hudText
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "feedbackHud"

        function showRefreshRate(rate: string): void {
            root.showRefreshRate(rate);
        }

        function showCamera(state: string): void {
            root.showCamera(state);
        }
    }
}
