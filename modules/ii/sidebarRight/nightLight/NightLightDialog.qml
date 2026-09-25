import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    property var screen: (root.QsWindow && root.QsWindow.window) ? root.QsWindow.window.screen : null
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    backgroundWidth: 360

    WindowDialogTitle {
        text: Translation.tr("Eye protection")
    }

    WindowDialogSeparator {}

    StyledFlickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: Math.min(contentCol.implicitHeight, 460)
        contentHeight: contentCol.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: contentCol
            width: flickable.width
            spacing: 10

            WindowDialogSectionHeader {
                text: Translation.tr("Night Light")
            }

            GroupedList {
                itemVerticalPadding: 6
                bgcolor: Appearance.colors.colSurfaceContainerHigh  

                ConfigSwitch {
                    iconSize: Appearance.font.pixelSize.larger
                    buttonIcon: "check"
                    text: Translation.tr("Enable now")
                    checked: Hyprsunset.temperatureActive
                    onCheckedChanged: {
                        Hyprsunset.toggleTemperature(checked)
                    }
                }

                ConfigSwitch {
                    iconSize: Appearance.font.pixelSize.larger
                    buttonIcon: "night_sight_auto"
                    text: Translation.tr("Automatic")
                    checked: Config.options.light.night.automatic
                    onCheckedChanged: {
                        Config.options.light.night.automatic = checked;
                    }
                }

                WindowDialogSlider {
                    text: Translation.tr("Temperature")
                    from: 6500
                    to: 1200
                    stopIndicatorValues: [5000, to]
                    value: Config.options.light.night.colorTemperature
                    onMoved: Config.options.light.night.colorTemperature = value
                    tooltipContent: `${Math.round(value)}K`
                }
            }

            WindowDialogSectionHeader {
                text: Translation.tr("Anti-flashbang (experimental)")
            }

            GroupedList {
                itemVerticalPadding: 6
                bgcolor: Appearance.colors.colSurfaceContainerHigh

                ConfigSwitch {
                    iconSize: Appearance.font.pixelSize.larger
                    buttonIcon: "filter"
                    text: Translation.tr("Content adjustment")
                    checked: HyprlandAntiFlashbangShader.enabled
                    onCheckedChanged: {
                        if (checked) HyprlandAntiFlashbangShader.enable()
                        else HyprlandAntiFlashbangShader.disable()
                    }
                    StyledToolTip {
                        text: Translation.tr("<b>Dims screen content</b> as needed.<br><br>Pros: Immediately responsive<br>Cons: Expensive and can hurt color accuracy<br><br><i>Uses a Hyprland screen shader</i>")
                    }
                }

                ConfigSwitch {
                    iconSize: Appearance.font.pixelSize.larger
                    buttonIcon: "light_mode"
                    text: Translation.tr("Brightness adjustment")
                    checked: Config.options.light.antiFlashbang.enable
                    onCheckedChanged: {
                        Config.options.light.antiFlashbang.enable = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Adapts the <b>display (physical screen) brightness</b><br><br>Pros: Less expensive, retains colors<br>Cons: Not immediately responsive<br><br><i>Adjusts display brightness after each Hyprland IPC event</i>")
                    }
                }
            }

            WindowDialogSectionHeader {
                text: Translation.tr("Brightness")
            }

            GroupedList {
                itemVerticalPadding: 6
                bgcolor: Appearance.colors.colSurfaceContainerHigh  

                WindowDialogSlider {
                    from: 0.05
                    to: 1.0
                    value: (root.brightnessMonitor && root.brightnessMonitor.brightness !== undefined) ? root.brightnessMonitor.brightness : 1.0
                    onMoved: if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(value)
                    tooltipContent: `${Math.round(value * 100)}%`
                }
            }

            WindowDialogSectionHeader {
                text: Translation.tr("Gamma")
            }

            GroupedList {
                itemVerticalPadding: 6
                bgcolor: Appearance.colors.colSurfaceContainerHigh

                WindowDialogSlider {
                    from: Hyprsunset.gammaLowerLimit / 100
                    to: 1.0
                    value: Hyprsunset.gamma / 100
                    onMoved: Hyprsunset.setGamma(value * 100)
                    tooltipContent: `${Math.round(value * 100)}%`
                }
            }
        }
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
