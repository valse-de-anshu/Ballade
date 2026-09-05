import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 20

        // ── 1. Screen Snipping & Region Selector ────────────────────────────
        ContentSection {
            icon: "screenshot_frame_2"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Screen Snipping & Region Selector")

            GroupedList {
                ConfigTextArea {
                    id: screenshotPathField
                    Layout.fillWidth: true
                    buttonIcon: "screenshot_monitor"
                    text: Translation.tr("Screenshot Save Path (leave empty to only copy to clipboard)")
                    value: Config.options.screenSnip.savePath
                    onValueChanged: screenshotPathDebounceTimer.restart()
                    Timer {
                        id: screenshotPathDebounceTimer
                        interval: 600
                        running: false
                        onTriggered: Config.options.screenSnip.savePath = screenshotPathField.value
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Hint target regions")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "select_window"
                        text: Translation.tr("Windows")
                        checked: Config.options.regionSelector.targetRegions.windows
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.windows = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "right_panel_open"
                        text: Translation.tr("Layers")
                        checked: Config.options.regionSelector.targetRegions.layers
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.layers = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "nearby"
                        text: Translation.tr("Content")
                        checked: Config.options.regionSelector.targetRegions.content
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.content = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Google Lens")
                GroupedList {
                    ConfigSelectionArray {
                        text: Translation.tr("Selection Type")
                        icon: "ink_selection"
                        currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                        onSelected: newValue => {
                            Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                        }
                        options: [
                            { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                            { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                        ]
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Rectangular selection")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "point_scan"
                        text: Translation.tr("Show aim lines")
                        checked: Config.options.regionSelector.rect.showAimLines
                        onCheckedChanged: {
                            Config.options.regionSelector.rect.showAimLines = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Circle selection")
                GroupedList {
                    ConfigSpinBox {
                        icon: "eraser_size_3"
                        text: Translation.tr("Stroke width")
                        value: Config.options.regionSelector.circle.strokeWidth
                        from: 1
                        to: 20
                        stepSize: 1
                        onValueChanged: {
                            Config.options.regionSelector.circle.strokeWidth = value;
                        }
                    }

                    ConfigSpinBox {
                        icon: "screenshot_frame_2"
                        text: Translation.tr("Padding")
                        value: Config.options.regionSelector.circle.padding
                        from: 0
                        to: 100
                        stepSize: 5
                        onValueChanged: {
                            Config.options.regionSelector.circle.padding = value;
                        }
                    }
                }
            }
        }

        // ── 2. Screen Recording ─────────────────────────────────────────────
        ContentSection {
            icon: "video_camera_front"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Screen Recording")

            GroupedList {
                ConfigTextArea {
                    id: videoRecordPathField
                    Layout.fillWidth: true
                    buttonIcon: "video_file"
                    text: Translation.tr("Video Recording Save Path")
                    value: Config.options.screenRecord.savePath
                    onValueChanged: videoRecordPathDebounceTimer.restart()
                    Timer {
                        id: videoRecordPathDebounceTimer
                        interval: 600
                        running: false
                        onTriggered: Config.options.screenRecord.savePath = videoRecordPathField.value
                    }
                }
            }
        }

        // ── 3. Crosshair ────────────────────────────────────────────────────
        ContentSection {
            icon: "point_scan"
            shape: MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Crosshair Overlay")

            Rectangle {
                id: crosshairCard
                Layout.fillWidth: true
                implicitHeight: crosshairCol.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: crosshairCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    ConfigTextArea {
                        id: crosshairCodeField
                        Layout.fillWidth: true
                        buttonIcon: "point_scan"
                        text: Translation.tr("Crosshair code")
                        placeholderText: Translation.tr("Crosshair code (in Valorant format)")
                        value: Config.options.crosshair.code
                        onValueChanged: crosshairCodeDebounceTimer.restart()
                        Timer {
                            id: crosshairCodeDebounceTimer
                            interval: 1000
                            running: false
                            onTriggered: Config.options.crosshair.code = crosshairCodeField.value
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.leftMargin: 8
                            Layout.fillWidth: true
                            text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                        RippleButtonWithIcon {
                            id: editorButton
                            Layout.fillWidth: true
                            Layout.rightMargin: 6
                            Layout.preferredHeight: 40
                            buttonRadius: Appearance.rounding.normal
                            materialIcon: "open_in_new"
                            mainText: Translation.tr("Open editor")
                            onClicked: {
                                Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                            }
                        }
                    }
                }
            }
        }

        // ── 4. Screen Overlay & Floating Image ──────────────────────────────
        ContentSection {
            icon: "select_window"
            shape: MaterialShape.Shape.SoftBurst
            title: Translation.tr("Overlay & Floating Image")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "high_density"
                    text: Translation.tr("Enable opening zoom animation")
                    checked: Config.options.overlay.openingZoomAnimation
                    onCheckedChanged: {
                        Config.options.overlay.openingZoomAnimation = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "texture"
                    text: Translation.tr("Darken screen")
                    checked: Config.options.overlay.darkenScreen
                    onCheckedChanged: {
                        Config.options.overlay.darkenScreen = checked;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Floating Image")
                GroupedList {
                    ConfigTextArea {
                        id: floatingImageSourceField
                        Layout.fillWidth: true
                        buttonIcon: "imagesmode"
                        text: Translation.tr("Image source URL / path")
                        value: Config.options.overlay.floatingImage.imageSource
                        onValueChanged: floatingImageSourceDebounceTimer.restart()
                        Timer {
                            id: floatingImageSourceDebounceTimer
                            interval: 1000
                            running: false
                            onTriggered: Config.options.overlay.floatingImage.imageSource = floatingImageSourceField.value
                        }
                    }
                }
            }
        }
    }
}
