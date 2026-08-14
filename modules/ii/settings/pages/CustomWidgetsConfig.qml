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

        // ── Section 3: Wall Shape (HyprPicker Shape & Animation Specs) ──
        ContentSection {
            icon: "wallpaper"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Wall Shape")

            GroupedList {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ConfigSelectionArray {
                        text: Translation.tr("Active Wall Shape")
                        icon: "shapes"
                        Layout.fillWidth: true
                        currentValue: Config.options.wallpaperSelector.shape || "slanted"
                        onSelected: newValue => {
                            Config.options.wallpaperSelector.shape = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Slanted"),
                                icon: "category",
                                value: "slanted"
                            },
                            {
                                displayName: Translation.tr("Superellipse"),
                                icon: "crop_square",
                                value: "superellipse"
                            },
                            {
                                displayName: Translation.tr("Arch"),
                                icon: "door_front",
                                value: "arch"
                            },
                            {
                                displayName: Translation.tr("Starburst"),
                                icon: "star",
                                value: "starburst"
                            },
                            {
                                displayName: Translation.tr("Diamond"),
                                icon: "diamond",
                                value: "diamond"
                            }
                        ]
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Appearance.colors.colLayer0Border }

                    // Card 1: Slanted Cyber
                    RippleButton {
                        Layout.fillWidth: true
                        height: card1Col.implicitHeight + 20
                        radius: 12
                        colBackground: Config.options.wallpaperSelector.shape === "slanted" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.width: Config.options.wallpaperSelector.shape === "slanted" ? 2 : 1
                        border.color: Config.options.wallpaperSelector.shape === "slanted" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        onClicked: Config.options.wallpaperSelector.shape = "slanted"

                        ColumnLayout {
                            id: card1Col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                StyledText {
                                    text: "1. Cinematic Slanted"
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Config.options.wallpaperSelector.shape === "slanted" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                }
                                Rectangle {
                                    radius: 4
                                    height: 18
                                    width: Config.options.wallpaperSelector.shape === "slanted" ? 64 : 50
                                    color: Config.options.wallpaperSelector.shape === "slanted" ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Config.options.wallpaperSelector.shape === "slanted" ? "Active ✓" : "Select"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Config.options.wallpaperSelector.shape === "slanted" ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "• Dynamic -12° shear angle with 18px rounded corners.\n• C++ StrictlyEnforceRange centering with 160ms OutCubic distance scaling (1.0 center focus → 0.45 edge taper)."
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Card 2: Organic Superellipse
                    RippleButton {
                        Layout.fillWidth: true
                        height: card2Col.implicitHeight + 20
                        radius: 12
                        colBackground: Config.options.wallpaperSelector.shape === "superellipse" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.width: Config.options.wallpaperSelector.shape === "superellipse" ? 2 : 1
                        border.color: Config.options.wallpaperSelector.shape === "superellipse" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        onClicked: Config.options.wallpaperSelector.shape = "superellipse"

                        ColumnLayout {
                            id: card2Col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                StyledText {
                                    text: "2. Organic Superellipse (Cookie 4-Sided)"
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Config.options.wallpaperSelector.shape === "superellipse" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                }
                                Rectangle {
                                    radius: 4
                                    height: 18
                                    width: Config.options.wallpaperSelector.shape === "superellipse" ? 64 : 50
                                    color: Config.options.wallpaperSelector.shape === "superellipse" ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Config.options.wallpaperSelector.shape === "superellipse" ? "Active ✓" : "Select"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Config.options.wallpaperSelector.shape === "superellipse" ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "• Material You 4-sided continuous squircle with 34px smooth curvature.\n• Subtle breathing scale pulse on active item with floating ambient elevation."
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Card 3: Cathedral Arch
                    RippleButton {
                        Layout.fillWidth: true
                        height: card3Col.implicitHeight + 20
                        radius: 12
                        colBackground: Config.options.wallpaperSelector.shape === "arch" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.width: Config.options.wallpaperSelector.shape === "arch" ? 2 : 1
                        border.color: Config.options.wallpaperSelector.shape === "arch" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        onClicked: Config.options.wallpaperSelector.shape = "arch"

                        ColumnLayout {
                            id: card3Col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                StyledText {
                                    text: "3. Cathedral Arch (Gothic Dome)"
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Config.options.wallpaperSelector.shape === "arch" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                }
                                Rectangle {
                                    radius: 4
                                    height: 18
                                    width: Config.options.wallpaperSelector.shape === "arch" ? 64 : 50
                                    color: Config.options.wallpaperSelector.shape === "arch" ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Config.options.wallpaperSelector.shape === "arch" ? "Active ✓" : "Select"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Config.options.wallpaperSelector.shape === "arch" ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "• Semicircular dome top arch with 28px rounded top curvature.\n• Vertical parallax rise on hover (+8px Y lift) with smoothstep edge falloff."
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Card 4: Starburst Scallop
                    RippleButton {
                        Layout.fillWidth: true
                        height: card4Col.implicitHeight + 20
                        radius: 12
                        colBackground: Config.options.wallpaperSelector.shape === "starburst" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.width: Config.options.wallpaperSelector.shape === "starburst" ? 2 : 1
                        border.color: Config.options.wallpaperSelector.shape === "starburst" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        onClicked: Config.options.wallpaperSelector.shape = "starburst"

                        ColumnLayout {
                            id: card4Col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                StyledText {
                                    text: "4. Starburst Scallop (Cookie 7-Sided)"
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Config.options.wallpaperSelector.shape === "starburst" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                }
                                Rectangle {
                                    radius: 4
                                    height: 18
                                    width: Config.options.wallpaperSelector.shape === "starburst" ? 64 : 50
                                    color: Config.options.wallpaperSelector.shape === "starburst" ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Config.options.wallpaperSelector.shape === "starburst" ? "Active ✓" : "Select"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Config.options.wallpaperSelector.shape === "starburst" ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "• Multi-petal organic rounded flower scallop with 7-point symmetry.\n• Micro-rotational settle (±1.5°) on selection with instant thumbnail caching."
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Card 5: Cyber Diamond
                    RippleButton {
                        Layout.fillWidth: true
                        height: card5Col.implicitHeight + 20
                        radius: 12
                        colBackground: Config.options.wallpaperSelector.shape === "diamond" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        border.width: Config.options.wallpaperSelector.shape === "diamond" ? 2 : 1
                        border.color: Config.options.wallpaperSelector.shape === "diamond" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        onClicked: Config.options.wallpaperSelector.shape = "diamond"

                        ColumnLayout {
                            id: card5Col
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                spacing: 8
                                StyledText {
                                    text: "5. Cyber Diamond (Puffy Diamond)"
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Config.options.wallpaperSelector.shape === "diamond" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                                }
                                Rectangle {
                                    radius: 4
                                    height: 18
                                    width: Config.options.wallpaperSelector.shape === "diamond" ? 64 : 50
                                    color: Config.options.wallpaperSelector.shape === "diamond" ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Config.options.wallpaperSelector.shape === "diamond" ? "Active ✓" : "Select"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Config.options.wallpaperSelector.shape === "diamond" ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "• 45° rotated rounded rhombus with curved vertices and neon edge highlight.\n• Horizontal magnetic snapping with 180ms easeOutBack focal transition."
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
