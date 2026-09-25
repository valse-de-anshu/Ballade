import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    implicitHeight: col.implicitHeight + 16

    readonly property color colLayer0Base: (Appearance.colors && Appearance.colors.colLayer0Base)
        ? Appearance.colors.colLayer0Base
        : Appearance.colors.colLayer0

    function formatShapeName(name) {
        if (!name) return ""
        return name
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .replace(/([A-Za-z])([0-9])/g, '$1 $2')
            .replace(/([0-9])([A-Za-z])/g, '$1 $2')
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(root.colLayer0Base.r, root.colLayer0Base.g, root.colLayer0Base.b, 0.22)
        border.width: 0
        border.color: "transparent"

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 10 }
        spacing: 6

        // Enable Switch
        ConfigSwitch {
            id: enableSwitch
            Layout.fillWidth: true
            buttonIcon: "crop_square"
            text: Translation.tr("Centered Wallpaper")
            checked: Config.options.background.centeredWallpaper
            onCheckedChanged: {
                if (Config.options.background.centeredWallpaper !== checked) {
                    Config.options.background.centeredWallpaper = checked
                }
            }
        }

        // Lock screen only switch
        ConfigSwitch {
            id: lockOnlySwitch
            Layout.fillWidth: true
            buttonIcon: "lock"
            text: Translation.tr("Only When Locked")
            checked: Config.options.background.centeredWallpaperOnlyWhenLocked
            onCheckedChanged: {
                if (Config.options.background.centeredWallpaperOnlyWhenLocked !== checked) {
                    Config.options.background.centeredWallpaperOnlyWhenLocked = checked
                }
            }
            enabled: Config.options.background.centeredWallpaper
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.3
        }

        // Size slider
        ConfigSlider {
            id: sizeSlider
            Layout.fillWidth: true
            text: Translation.tr("Size")
            textWidth: 45
            value: Config.options.background.centeredWallpaperSize
            usePercentTooltip: false
            buttonIcon: "aspect_ratio"
            from: 200
            to: 1800
            stepSize: 10
            stopIndicatorValues: [400, 800, 1200, 1600]
            enabled: Config.options.background.centeredWallpaper
            onMoved: {
                Config.options.background.centeredWallpaperSize = Math.round(value)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.3
        }

        // Shapes Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 6

            MaterialSymbol {
                text: "category"
                iconSize: 18
                color: Appearance.colors.colSubtext
            }

            StyledText {
                text: Translation.tr("Shapes")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }

        // Shapes Grid
        ConfigSelectionShapeArray {
            id: shapesGrid
            Layout.fillWidth: true
            enabled: Config.options.background.centeredWallpaper
            opacity: Config.options.background.centeredWallpaper ? 1.0 : 0.4
            currentValue: Config.options.background.centeredWallpaperShape
            shapeColor: Appearance.colors.colPrimary
            backgroundColor: Appearance.colors.colLayer1
            options: [
                "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
            ]
            onSelected: newValue => {
                Config.options.background.centeredWallpaperShape = newValue
                if (!Config.options.background.centeredWallpaper) {
                    Config.options.background.centeredWallpaper = true
                }
            }
        }
    }

    Connections {
        target: Config.options.background
        function onCenteredWallpaperChanged() {
            if (enableSwitch.checked !== Config.options.background.centeredWallpaper) {
                enableSwitch.checked = Config.options.background.centeredWallpaper
            }
        }
        function onCenteredWallpaperOnlyWhenLockedChanged() {
            if (lockOnlySwitch.checked !== Config.options.background.centeredWallpaperOnlyWhenLocked) {
                lockOnlySwitch.checked = Config.options.background.centeredWallpaperOnlyWhenLocked
            }
        }
        function onCenteredWallpaperShapeChanged() {
            if (shapesGrid.currentValue !== Config.options.background.centeredWallpaperShape) {
                shapesGrid.currentValue = Config.options.background.centeredWallpaperShape
            }
        }
        function onCenteredWallpaperSizeChanged() {
            if (!sizeSlider.pressed && Math.round(sizeSlider.value) !== Config.options.background.centeredWallpaperSize) {
                sizeSlider.value = Config.options.background.centeredWallpaperSize
            }
        }
    }
}
