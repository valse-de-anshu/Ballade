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
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── Section 1: Extra Custom Images ──────────────────────────────
        ContentSection {
            icon: "imagesmode"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Extra Custom Images")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // Existing images list
                Repeater {
                    id: imagesRepeater
                    model: Config.options.background.widgets.customImages

                    delegate: GroupedList {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: "Widget " + (index + 1)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            Item { Layout.fillWidth: true }

                            // Delete button
                            RippleButton {
                                implicitWidth: 32
                                implicitHeight: 32
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colErrorContainer
                                colBackgroundHover: Appearance.colors.colError
                                colRipple: Appearance.colors.colOnError
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: 18
                                    text: "delete"
                                    color: Appearance.colors.colOnErrorContainer
                                }
                                downAction: () => {
                                    var arr = Config.options.background.widgets.customImages.slice()
                                    arr.splice(index, 1)
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }

                        ConfigSwitch {
                            Layout.fillWidth: true
                            buttonIcon: "opacity"
                            text: Translation.tr("Add transparency")
                            checked: modelData.transparent ?? false
                            onCheckedChanged: {
                                var arr = Config.options.background.widgets.customImages.slice()
                                if (arr[index]) {
                                    arr[index] = Object.assign({}, arr[index], { transparent: checked })
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }

                        ConfigSwitch {
                            Layout.fillWidth: true
                            buttonIcon: "loop"
                            text: Translation.tr("Infinite Loop (Play continuously)")
                            checked: modelData.infiniteLoop ?? false
                            onCheckedChanged: {
                                var arr = Config.options.background.widgets.customImages.slice()
                                if (arr[index]) {
                                    arr[index] = Object.assign({}, arr[index], { infiniteLoop: checked })
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }

                        ConfigTextArea {
                            Layout.fillWidth: true
                            buttonIcon: "image"
                            text: Translation.tr("Image / GIF File Path")
                            placeholderText: Translation.tr("Paste absolute path, e.g. /home/user/Pictures/mygif.gif")
                            value: modelData.path ?? ""
                            onValueChanged: {
                                var arr = Config.options.background.widgets.customImages.slice()
                                if (arr[index]) {
                                    arr[index] = Object.assign({}, arr[index], { path: value })
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }

                        // Shape picker for this widget
                        ConfigSelectionShapeArray {
                            currentValue: modelData.shape ?? "Cookie4Sided"
                            shapeColor: Appearance.colors.colPrimary
                            backgroundColor: Appearance.colors.colPrimaryContainer
                            options: [
                                "Free", "VerticalRectangle", "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                                "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                                "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                                "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                                "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                            ]
                            onSelected: newValue => {
                                var arr = Config.options.background.widgets.customImages.slice()
                                if (arr[index]) {
                                    arr[index] = Object.assign({}, arr[index], { shape: newValue })
                                    Config.options.background.widgets.customImages = arr
                                }
                            }
                        }
                    }
                }

                // Add button
                RippleButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    implicitWidth: 196
                    implicitHeight: 44
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimary
                    colRipple: Appearance.colors.colOnPrimary
                    downAction: () => {
                        var arr = Config.options.background.widgets.customImages.slice()
                        arr.push({
                            enable: true,
                            placementStrategy: "free",
                            x: 400,
                            y: 100,
                            path: "",
                            shape: "Cookie4Sided",
                            size: 200,
                            transparent: false
                        })
                        Config.options.background.widgets.customImages = arr
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            iconSize: 20
                            text: "add"
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            text: "Add Image Widget"
                            color: Appearance.colors.colOnPrimaryContainer
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        // ── Section 2: User Card Custom Text ────────────────────────────
        ContentSection {
            icon: "person"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("User Card")

            GroupedList {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ConfigTextArea {
                        id: userCardTextField
                        Layout.fillWidth: true
                        buttonIcon: "edit_note"
                        text: Translation.tr("Custom Text")
                        placeholderText: Translation.tr("Leave empty to show weather instead")
                        value: Config.options.background.widgets.userCard.customText
                        onValueChanged: {
                            // Enforce 40 char limit
                            var clamped = value.length > 40 ? value.substring(0, 40) : value
                            if (clamped !== value) {
                                userCardTextField.value = clamped
                            } else {
                                Config.options.background.widgets.userCard.customText = clamped
                            }
                        }
                    }

                    // Character counter
                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: (Config.options.background.widgets.userCard.customText?.length ?? 0) + " / 40"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: (Config.options.background.widgets.userCard.customText?.length ?? 0) >= 40
                                   ? Appearance.colors.colError
                                   : Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        // ── Section 3: Wall Shape ───────────────────────────────────────
        ContentSection {
            icon: "wallpaper"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Wall Shape")

            GroupedList {
                Layout.fillWidth: true

                ConfigSelectionArray {
                    Layout.fillWidth: true
                    currentValue: Config.options.wallpaperSelector.shape || "slanted"
                    onSelected: newValue => {
                        Config.options.wallpaperSelector.shape = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Cyberpunk Slanted"),
                            icon: "category",
                            value: "slanted"
                        },
                        {
                            displayName: Translation.tr("Modern Rounded"),
                            icon: "crop_square",
                            value: "rounded"
                        },
                        {
                            displayName: Translation.tr("Cyberpunk Panoramic"),
                            icon: "panorama_wide_angle",
                            value: "panoramic"
                        }
                    ]
                }
            }
        }
    }
}
