import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: 8
    property real horizontalPadding: 12

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: 8

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showBrightness
            sourceComponent: QuickSlider {
                materialSymbol: "brightness_medium"
                secondaryMaterialSymbol: "wb_twilight"
                stopIndicatorValues: Hyprsunset.gamma !== 100 && root.brightnessMonitor?.brightness !== 0 ? [0.3 + root.brightnessMonitor?.brightness * 0.7] : []
                value: Hyprsunset.gamma === 100 ? 0.3 + root.brightnessMonitor?.brightness * 0.7 : (Hyprsunset.gamma - Hyprsunset.gammaLowerLimit) / (100 - Hyprsunset.gammaLowerLimit) * 0.3
                tooltipContent: Hyprsunset.gamma === 100 ? `${Math.round(root.brightnessMonitor?.brightness * 100)}%` : `${Translation.tr("Gamma")} ${Hyprsunset.gamma}%`
                onMoved: {
                    if (value >= 0.3) {
                        // 0.3 - 1.0 brightness
                        root.brightnessMonitor.setBrightness((value - 0.3) / 0.7);
                        if (Hyprsunset.gamma !== 100) {
                            Hyprsunset.setGamma(100);
                        }
                    } else {
                        // 0 - 0.3 gamma
                        if (root.brightnessMonitor.brightness !== 0) {
                            root.brightnessMonitor.setBrightness(0);
                        }
                        Hyprsunset.setGamma((value / 0.3 * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit));
                    }
                }
            }
        }

        Loader {
            anchors { left: parent.left; right: parent.right }
            visible: active
            active: Config.options.sidebar.quickSliders.showVolume
            sourceComponent: QuickSlider {
                materialSymbol: "volume_up"
                value: Audio.sink?.audio?.volume ?? 0
                tooltipContent: `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
                onMoved: {
                    if (Audio.sink?.audio)
                        Audio.sink.audio.volume = value
                }
            }
        }

        Loader {
            anchors { left: parent.left; right: parent.right }
            visible: active
            active: Config.options.sidebar.quickSliders.showMic
            sourceComponent: QuickSlider {
                materialSymbol: "mic"
                value: Audio.source?.audio?.volume ?? 0
                tooltipContent: `${Math.round((Audio.source?.audio?.volume ?? 0) * 100)}%`
                onMoved: {
                    if (Audio.source?.audio)
                        Audio.source.audio.volume = value
                }
            }
        }
    }

    component QuickSlider: Item { 
        id: quickSlider
        required property string materialSymbol
        property string secondaryMaterialSymbol: ""
        property real from: 0.0
        property real to: 1.0
        property real value: 0.0
        readonly property real visualPosition: Math.max(0.0, Math.min(1.0, (value - from) / (to - from)))
        property string tooltipContent: `${Math.round(visualPosition * 100)}%`
        property var stopIndicatorValues: []
        property var dividerValues: []
        property real stepSize: 0.02
        readonly property bool pressed: sliderArea.pressed

        signal moved()

        implicitHeight: 38
        Layout.fillWidth: true

        function updateFromMouse(mouseX) {
            let clamped = Math.max(0.0, Math.min(1.0, mouseX / trackBg.width));
            quickSlider.value = from + clamped * (to - from);
            quickSlider.moved();
        }

        Rectangle {
            id: trackBg
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer2 || Appearance.colors.colSecondaryContainer
            opacity: 0.85
            clip: true

            border.width: 0
            border.color: "transparent"

            // Smooth full fill bar
            Rectangle {
                id: fillTrack
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.max(0, Math.min(trackBg.width, trackBg.width * quickSlider.visualPosition))
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary

                Behavior on width {
                    enabled: !quickSlider.pressed
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
            }

            // Left-aligned icon with adaptive contrast color
            Row {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                MaterialSymbol {
                    id: mainIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: quickSlider.materialSymbol
                    iconSize: 20
                    color: quickSlider.visualPosition >= 0.16
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colOnSurface

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                MaterialSymbol {
                    id: secondaryIcon
                    visible: quickSlider.secondaryMaterialSymbol.length > 0 && quickSlider.visualPosition < 0.3
                    anchors.verticalCenter: parent.verticalCenter
                    text: quickSlider.secondaryMaterialSymbol
                    iconSize: 16
                    color: quickSlider.visualPosition >= 0.28
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colOnSurfaceVariant

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            // Right-aligned clean percentage label
            Text {
                id: valueLabel
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: quickSlider.tooltipContent
                font {
                    family: Appearance.font.family.main
                    pixelSize: 12
                    bold: true
                }
                color: quickSlider.visualPosition >= 0.88
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnSurfaceVariant

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        // Mouse interaction: click, drag, wheel scroll
        MouseArea {
            id: sliderArea
            anchors.fill: parent
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            hoverEnabled: true

            onPressed: (mouse) => {
                quickSlider.updateFromMouse(mouse.x);
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    quickSlider.updateFromMouse(mouse.x);
                }
            }

            onWheel: (event) => {
                let delta = event.angleDelta.y > 0 ? quickSlider.stepSize : -quickSlider.stepSize;
                let next = Math.max(quickSlider.from, Math.min(quickSlider.to, quickSlider.value + delta));
                quickSlider.value = next;
                quickSlider.moved();
            }
        }

        StyledToolTip {
            extraVisibleCondition: quickSlider.pressed
            text: quickSlider.tooltipContent
        }
    }
}
