import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Hyprland

ContentPage {
    id: page
    forceWidth: true

    function goTo(term) {
        const t = term.toLowerCase().trim()

        function findTarget(rootItem) {
            for (let i = 0; i < rootItem.children.length; i++) {
                let child = rootItem.children[i]
                if (child.title && child.title.toLowerCase().includes(t)) {
                    return child
                }
            }

            for (let i = 0; i < rootItem.children.length; i++) {
                let found = findTarget(rootItem.children[i])
                if (found) return found
            }
            return null
        }

        let target = findTarget(mainLayout)
        if (target) {
            let pos = target.mapToItem(mainLayout, 0, 0)
            page.contentY = Math.max(0, pos.y - 0)
        }
    }

    function displayPathFor(path) {
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(path)
            ? Config.options.background.thumbnailPath
            : path
    }

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        // ── 1. Wallpaper & Desktop Effects ──────────────────────────────────
        ContentSection {
            icon: "panorama"
            title: Translation.tr("Wallpaper & Effects")
            shape: MaterialShape.Shape.Clover4Leaf

            Rectangle {
                Layout.fillWidth: true
                visible: WM.compositor !== "niri"
                implicitHeight: wrapperCol.implicitHeight + 16
                topLeftRadius: Appearance.rounding.verylarge
                topRightRadius: Appearance.rounding.verylarge
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: wrapperCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Carousel {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        largeItemWidthRatio: 0.5
                        mediumItemWidthRatio: 0.485
                        itemSpacing: 8
                        model: [
                            page.displayPathFor(Config.options.background.wallpaperPath),
                            page.displayPathFor(
                                Config.options.background.lockWall !== ""
                                    ? Config.options.background.lockWall
                                    : Config.options.background.wallpaperPath
                            )
                        ]
                        wheelEnabled: false
                        dragEnabled: false
                        clickAction: (index, modelData) => {
                            GlobalStates.wallpaperSelectorTarget = index === 1 ? "lockWall" : "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "desktop_windows"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Desktop")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "lock"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Lockscreen")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }

            GroupedList {
                Layout.topMargin: -2

                ConfigSwitch {
                    id: syncWallpaperSwitch
                    buttonIcon: "sync"
                    text: Translation.tr("Use same wallpaper for both")
                    checked: Config.options.background.lockWall === ""
                    onCheckedChanged: {
                        if (checked) {
                            Config.options.background.lockWall = "";
                        }
                    }
                }

                ConfigSwitch {
                    buttonIcon: "preview"
                    text: Translation.tr("Preview wallpaper")
                    checked: Config.options.background.enableWallpaperPreview
                    onCheckedChanged: {
                        Config.options.background.enableWallpaperPreview = checked;
                    }
                }

                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Wallpaper change interval (min)")
                    value: Config.options.wallpaperSelector.changeInterval / 60000
                    from: 0
                    to: 1440
                    stepSize: 5
                    onValueChanged: {
                        Config.options.wallpaperSelector.changeInterval = value * 60000;
                    }
                }

                ConfigComboBox {
                    Layout.fillWidth: true
                    buttonIcon: "texture"
                    text: Translation.tr("Transitions")
                    fieldWidth: 50
                    model: [
                        { displayName: Translation.tr("None"), icon: "block", value: "" },
                        { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
                        { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
                        { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
                        { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
                        { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
                        { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
                        { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
                        { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                    ]
                    currentValue: Config.options.background.wallpaperAnimation
                    onSelected: newValue => {
                        Config.options.background.wallpaperAnimation = newValue;
                    }
                }
            }

            // ── Desktop Blur Controls ───────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Desktop Wallpaper Blur")
                Layout.fillWidth: true

                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "blur_on"
                        text: Translation.tr("Blur desktop wallpaper")
                        checked: Config.options.background.showBlur
                        onCheckedChanged: {
                            Config.options.background.showBlur = checked;
                        }
                    }

                    ConfigSpinBox {
                        visible: Config.options.background.showBlur
                        icon: "blur_linear"
                        text: Translation.tr("Blur intensity")
                        value: Config.options.background.blurRadius
                        from: 2
                        to: 128
                        stepSize: 4
                        onValueChanged: {
                            Config.options.background.blurRadius = value;
                        }
                    }

                    ConfigSelectionArray {
                        visible: Config.options.background.showBlur
                        text: Translation.tr("Split blur amount")
                        icon: "split_scene"
                        currentValue: Config.options.background.splitRatio
                        options: [
                            { "displayName": "25%",  "icon": "thumbnail_bar",    "value": "25" },
                            { "displayName": "50%",  "icon": "side_navigation",  "value": "50" },
                            { "displayName": "100%", "icon": "fullscreen",       "value": "100" },
                        ]
                        onSelected: newValue => {
                            Config.options.background.splitRatio = newValue
                        }
                    }

                    ConfigSelectionArray {
                        visible: Config.options.background.showBlur && Config.options.background.splitRatio !== "100"
                        text: Translation.tr("Split blur side")
                        icon: "align_horizontal_left"
                        currentValue: Config.options.background.splitSide
                        options: [
                            { "displayName": Translation.tr("Left"),  "icon": "align_horizontal_left",  "value": "left" },
                            { "displayName": Translation.tr("Right"), "icon": "align_horizontal_right", "value": "right" },
                        ]
                        onSelected: newValue => {
                            Config.options.background.splitSide = newValue
                        }
                    }
                }
            }

            // ── Centered Wallpaper ──────────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Centered wallpaper")
                Layout.fillWidth: true

                GroupedList {
                    ConfigSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "check"
                        text: Translation.tr("Enable centered wallpaper")
                        checked: Config.options.background.centeredWallpaper
                        onCheckedChanged: {
                            Config.options.background.centeredWallpaper = checked;
                        }
                    }
                    ConfigSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "lock"
                        text: Translation.tr("Show only when locked")
                        checked: Config.options.background.centeredWallpaperOnlyWhenLocked
                        onCheckedChanged: {
                            Config.options.background.centeredWallpaperOnlyWhenLocked = checked;
                        }
                        enabled: Config.options.background.centeredWallpaper && WM.compositor !== "niri"
                    }
                }

                GroupedList {
                    Layout.topMargin: 0
                    visible: Config.options.background.centeredWallpaper
                    ConfigSelectionShapeArray {
                        currentValue: Config.options.background.centeredWallpaperShape
                        shapeColor: Appearance.colors.colPrimary
                        backgroundColor: Appearance.colors.colPrimaryContainer
                        options: [
                            "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                            "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                            "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                            "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                            "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                        ]
                        onSelected: newValue => {
                            Config.options.background.centeredWallpaperShape = newValue
                        }
                    }

                    ConfigSlider {
                        visible: Config.options.background.centeredWallpaper
                        text: Translation.tr("Size")
                        value: Config.options.background.centeredWallpaperSize
                        usePercentTooltip: false
                        buttonIcon: "aspect_ratio"
                        from: 400
                        to: 800
                        onValueChanged: {
                            Config.options.background.centeredWallpaperSize = value
                        }
                    }
                }
            }
        }

        // ── 2. Wallpaper Selector & Folders ─────────────────────────────────
        ContentSection {
            icon: "wallpaper"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Wallpaper Selector & Folders")

            GroupedList {
                ConfigSelectionArray {
                    text: Translation.tr("Selector layout behavior")
                    currentValue: Config.options.wallpaperSelector.behavior || "standard"
                    onSelected: newValue => {
                        Config.options.wallpaperSelector.behavior = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Modern Rounded"), icon: "view_list", value: "standard" },
                        { displayName: Translation.tr("Cyberpunk Panoramic"), icon: "panorama_wide_angle", value: "panoramic" }
                    ]
                }

                ConfigSelectionArray {
                    text: Translation.tr("Card Shape")
                    currentValue: Config.options.wallpaperSelector.shape || "cyberpunk"
                    onSelected: newValue => {
                        Config.options.wallpaperSelector.shape = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Cyberpunk"), icon: "category", value: "cyberpunk" },
                        { displayName: Translation.tr("Card"), icon: "crop_square", value: "card" }
                    ]
                }

                ConfigSwitch {
                    buttonIcon: "folder_open"
                    text: Translation.tr("Use system file dialog")
                    checked: Config.options.wallpaperSelector.useSystemFileDialog
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.useSystemFileDialog = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "home"
                    text: Translation.tr("Show home directory path")
                    checked: Config.options.wallpaperSelector.showHomePath
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showHomePath = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "close"
                    text: Translation.tr("Close after selection")
                    checked: Config.options.wallpaperSelector.closeAfterSelection
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.closeAfterSelection = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur background behind selector")
                    checked: Config.options.wallpaperSelector.showBlurBackground
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showBlurBackground = checked;
                    }
                }

                ConfigSpinBox {
                    icon: "view_column"
                    text: Translation.tr("Columns in grid view")
                    value: Config.options.wallpaperSelector.columns
                    from: 2
                    to: 8
                    stepSize: 1
                    onValueChanged: {
                        Config.options.wallpaperSelector.columns = value;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "search"
                    text: Translation.tr("Show search bar")
                    checked: Config.options.wallpaperSelector.showSearchbar
                    onCheckedChanged: {
                        Config.options.wallpaperSelector.showSearchbar = checked;
                    }
                }

                ConfigTextArea {
                    id: userWallpapersPathField
                    Layout.fillWidth: true
                    fieldWidth: 340
                    buttonIcon: "image"
                    text: Translation.tr("Image wallpapers folder")
                    description: Translation.tr("Folder for static image wallpapers")
                    placeholderText: Translation.tr("Path to image wallpapers folder")
                    value: Config.options.wallpaperSelector.userPath
                    onValueChanged: userWallpapersPathDebounce.restart()
                    Timer {
                        id: userWallpapersPathDebounce
                        interval: 600
                        running: false
                        onTriggered: Config.options.wallpaperSelector.userPath = userWallpapersPathField.value
                    }
                }

                ConfigTextArea {
                    id: liveWallpapersPathField
                    Layout.fillWidth: true
                    fieldWidth: 340
                    buttonIcon: "video_library"
                    text: Translation.tr("Live wallpapers folder")
                    description: Translation.tr("Folder for animated video wallpapers")
                    placeholderText: Translation.tr("Path to animated/video wallpapers folder")
                    value: Config.options.wallpaperSelector.liveWallpapersPath
                    onValueChanged: liveWallpapersPathDebounce.restart()
                    Timer {
                        id: liveWallpapersPathDebounce
                        interval: 600
                        running: false
                        onTriggered: Config.options.wallpaperSelector.liveWallpapersPath = liveWallpapersPathField.value
                    }
                }
            }
        }

        // ── 3. Typography & Fonts ───────────────────────────────────────────
        ContentSection {
            icon: "text_format"
            shape: MaterialShape.Shape.Arrow
            title: Translation.tr("Fonts & Typography")

            GroupedList {
                ConfigTextArea {
                    id: mainFontField
                    Layout.fillWidth: true
                    buttonIcon: "font_download"
                    text: Translation.tr("Font family name (e.g., Google Sans Flex)")
                    value: Config.options.appearance.fonts.main
                    onValueChanged: mainFontDebounceTimer.restart()
                    Timer {
                        id: mainFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.main = mainFontField.value
                    }
                }

                ConfigTextArea {
                    id: numbersFontField
                    Layout.fillWidth: true
                    buttonIcon: "123"
                    text: Translation.tr("Numbers family name")
                    value: Config.options.appearance.fonts.numbers
                    onValueChanged: numbersFontDebounceTimer.restart()
                    Timer {
                        id: numbersFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.numbers = numbersFontField.value
                    }
                }

                ConfigTextArea {
                    id: titleFontField
                    Layout.fillWidth: true
                    buttonIcon: "title"
                    text: Translation.tr("Title family name")
                    value: Config.options.appearance.fonts.title
                    onValueChanged: titleFontDebounceTimer.restart()
                    Timer {
                        id: titleFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.title = titleFontField.value
                    }
                }

                ConfigTextArea {
                    id: monospaceFontField
                    Layout.fillWidth: true
                    buttonIcon: "space_bar"
                    text: Translation.tr("Monospace font name (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.monospace
                    onValueChanged: monospaceFontDebounceTimer.restart()
                    Timer {
                        id: monospaceFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.monospace = monospaceFontField.value
                    }
                }

                ConfigTextArea {
                    id: iconNerdFontField
                    Layout.fillWidth: true
                    buttonIcon: "emoticon"
                    text: Translation.tr("Nerd Fonts Icons (e.g., JetBrains Mono NF)")
                    value: Config.options.appearance.fonts.iconNerd
                    onValueChanged: iconNerdFontDebounceTimer.restart()
                    Timer {
                        id: iconNerdFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.iconNerd = iconNerdFontField.value
                    }
                }

                ConfigTextArea {
                    id: readingFontField
                    Layout.fillWidth: true
                    buttonIcon: "book_ribbon"
                    text: Translation.tr("Reading font name (e.g., Readex Pro)")
                    value: Config.options.appearance.fonts.reading
                    onValueChanged: readingFontDebounceTimer.restart()
                    Timer {
                        id: readingFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.reading = readingFontField.value
                    }
                }

                ConfigTextArea {
                    id: expressiveFontField
                    Layout.fillWidth: true
                    buttonIcon: "mood_heart"
                    text: Translation.tr("Expressive font name (e.g., Space Grotesk)")
                    value: Config.options.appearance.fonts.expressive
                    onValueChanged: expressiveFontDebounceTimer.restart()
                    Timer {
                        id: expressiveFontDebounceTimer
                        interval: 1000
                        running: false
                        onTriggered: Config.options.appearance.fonts.expressive = expressiveFontField.value
                    }
                }
            }
        }

        // ── 4. Color Generation & Wallpaper Theming ─────────────────────────
        ContentSection {
            icon: "colors"
            title: Translation.tr("Color Generation & Theming")
            shape: MaterialShape.Shape.VerySunny

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "hardware"
                    text: Translation.tr("Shell & utilities")
                    checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
                }
                ConfigSwitch {
                    buttonIcon: "tv_options_input_settings"
                    text: Translation.tr("Qt apps")
                    checked: Config.options.appearance.wallpaperTheming.enableQtApps
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
                }
                ConfigSwitch {
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    checked: Config.options.appearance.wallpaperTheming.enableTerminal
                    onCheckedChanged: { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
                }
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Force dark mode in terminal")
                        checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                        onCheckedChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                    }
                }
                ConfigSpinBox {
                    icon: "invert_colors"
                    text: Translation.tr("Terminal: Harmony (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
                }
                ConfigSpinBox {
                    icon: "gradient"
                    text: Translation.tr("Terminal: Harmonize threshold")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
                }
                ConfigSpinBox {
                    icon: "format_color_text"
                    text: Translation.tr("Terminal: Foreground boost (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                    from: 0; to: 100; stepSize: 10
                    onValueChanged: { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
                }
            }
        }
    }
}
