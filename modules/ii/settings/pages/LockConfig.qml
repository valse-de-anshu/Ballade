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

    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        spacing: 20

        // ── 1. Lock Screen Behavior ─────────────────────────────────────────
        ContentSection {
            icon: "lock"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Lock Screen")

            GroupedList {
                ConfigSwitch {
                    buttonIcon: "lock_open"
                    text: Translation.tr("Use Hyprlock")
                    checked: Config.options.lock.useHyprlock
                    onCheckedChanged: { Config.options.lock.useHyprlock = checked }
                }
                ConfigSwitch {
                    buttonIcon: "desktop_windows"
                    text: Translation.tr("Launch on startup")
                    checked: Config.options.lock.launchOnStartup
                    onCheckedChanged: { Config.options.lock.launchOnStartup = checked }
                }
                ConfigSwitch {
                    buttonIcon: "dock_to_bottom"
                    text: Translation.tr("Show top bar and bottom bar")
                    checked: Config.options.lock.showToolbars
                    onCheckedChanged: { Config.options.lock.showToolbars = checked }
                }
                ConfigSwitch {
                    buttonIcon: "widgets"
                    text: Translation.tr("Show desktop widgets on lock screen")
                    checked: Config.options.lock.showWidgets
                    onCheckedChanged: { Config.options.lock.showWidgets = checked }
                }
                ConfigSwitch {
                    buttonIcon: "music_note"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show media player info")
                    checked: Config.options.lock.showMedia
                    onCheckedChanged: { Config.options.lock.showMedia = checked }
                }
            }

            // ── Security ────────────────────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Security")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "settings_power"
                        text: Translation.tr("Require password to power off/restart")
                        checked: Config.options.lock.security.requirePasswordToPower
                        onCheckedChanged: { Config.options.lock.security.requirePasswordToPower = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "key_vertical"
                        text: Translation.tr("Also unlock keyring")
                        checked: Config.options.lock.security.unlockKeyring
                        onCheckedChanged: { Config.options.lock.security.unlockKeyring = checked }
                    }
                }
            }

            // ── Password Display ───────────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Password Display")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "shapes"
                        text: Translation.tr("Use varying shapes for password characters")
                        checked: Config.options.lock.materialShapeChars
                        onCheckedChanged: { Config.options.lock.materialShapeChars = checked }
                    }
                }
            }

            // ── Lock Screen Wallpaper ───────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Wallpaper")
                GroupedList {
                    ConfigSwitch {
                        id: syncWallpaperSwitch
                        buttonIcon: "sync"
                        text: Translation.tr("Use same wallpaper for desktop and lock screen")
                        checked: Config.options.background.lockWall === ""
                        onCheckedChanged: {
                            if (checked) {
                                Config.options.background.lockWall = "";
                            }
                        }
                    }
                    RippleButtonWithIcon {
                        visible: Config.options.background.lockWall === ""
                        Layout.fillWidth: true
                        materialIcon: "wallpaper"
                        mainText: Translation.tr("Choose custom lock screen wallpaper")
                        onClicked: {
                            GlobalStates.wallpaperSelectorTarget = "lockWall";
                            GlobalStates.wallpaperSelectorOpen = true;
                        }
                    }
                    ConfigSwitch {
                        visible: Config.options.background.lockWall !== ""
                        buttonIcon: "image"
                        text: Translation.tr("Custom lock wallpaper: ") + (Config.options.background.lockWall.split("/").pop() || Translation.tr("Active"))
                        checked: Config.options.background.lockWall !== ""
                        onCheckedChanged: {
                            if (!checked) {
                                Config.options.background.lockWall = "";
                            }
                        }
                    }
                    RippleButtonWithIcon {
                        visible: Config.options.background.lockWall !== ""
                        Layout.fillWidth: true
                        materialIcon: "restart_alt"
                        mainText: Translation.tr("Reset to desktop wallpaper")
                        onClicked: {
                            Config.options.background.lockWall = "";
                        }
                    }
                }
            }

            // ── Centered Wallpaper on Lock Screen ────────────────────────────
            ContentSubsection {
                title: Translation.tr("Centered Wallpaper")
                GroupedList {
                    ConfigSwitch {
                        id: lockCenteredSwitch
                        buttonIcon: "crop_square"
                        text: Translation.tr("Enable centered wallpaper")
                        checked: Config.options.background.centeredWallpaper
                        onCheckedChanged: {
                            if (Config.options.background.centeredWallpaper !== checked) {
                                Config.options.background.centeredWallpaper = checked;
                            }
                        }
                    }
                    ConfigSwitch {
                        id: lockOnlySwitch
                        buttonIcon: "lock"
                        text: Translation.tr("Show only when locked")
                        checked: Config.options.background.centeredWallpaperOnlyWhenLocked
                        enabled: Config.options.background.centeredWallpaper
                        onCheckedChanged: {
                            if (Config.options.background.centeredWallpaperOnlyWhenLocked !== checked) {
                                Config.options.background.centeredWallpaperOnlyWhenLocked = checked;
                            }
                        }
                    }
                }

                GroupedList {
                    visible: Config.options.background.centeredWallpaper
                    ConfigSelectionShapeArray {
                        id: lockShapeArray
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
                        }
                    }
                }

                GroupedList {
                    visible: Config.options.background.centeredWallpaper
                    ConfigSlider {
                        id: lockSizeSlider
                        text: Translation.tr("Size")
                        value: Config.options.background.centeredWallpaperSize
                        usePercentTooltip: false
                        buttonIcon: "aspect_ratio"
                        from: 200
                        to: 1800
                        stepSize: 10
                        stopIndicatorValues: [400, 800, 1200, 1600]
                        onMoved: {
                            Config.options.background.centeredWallpaperSize = Math.round(value)
                        }
                    }
                }

                Connections {
                    target: Config.options.background
                    function onCenteredWallpaperChanged() {
                        if (lockCenteredSwitch.checked !== Config.options.background.centeredWallpaper) {
                            lockCenteredSwitch.checked = Config.options.background.centeredWallpaper;
                        }
                    }
                    function onCenteredWallpaperOnlyWhenLockedChanged() {
                        if (lockOnlySwitch.checked !== Config.options.background.centeredWallpaperOnlyWhenLocked) {
                            lockOnlySwitch.checked = Config.options.background.centeredWallpaperOnlyWhenLocked;
                        }
                    }
                    function onCenteredWallpaperShapeChanged() {
                        if (lockShapeArray.currentValue !== Config.options.background.centeredWallpaperShape) {
                            lockShapeArray.currentValue = Config.options.background.centeredWallpaperShape;
                        }
                    }
                    function onCenteredWallpaperSizeChanged() {
                        if (!lockSizeSlider.pressed && Math.round(lockSizeSlider.value) !== Config.options.background.centeredWallpaperSize) {
                            lockSizeSlider.value = Config.options.background.centeredWallpaperSize;
                        }
                    }
                }
            }

            // ── Lock Screen Blur ────────────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Lock Screen Blur")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "blur_on"
                        text: Translation.tr("Enable blur")
                        checked: Config.options.lock.blur.enable
                        onCheckedChanged: { Config.options.lock.blur.enable = checked }
                    }
                    ConfigSpinBox {
                        visible: Config.options.lock.blur.enable
                        icon: "blur_linear"
                        text: Translation.tr("Blur intensity")
                        value: Config.options.lock.blur.radius
                        from: 10; to: 200; stepSize: 5
                        onValueChanged: { Config.options.lock.blur.radius = value }
                    }
                    ConfigSpinBox {
                        visible: Config.options.lock.blur.enable
                        icon: "deblur"
                        text: Translation.tr("Samples (Quality)")
                        value: Config.options.lock.blur.size
                        from: 20; to: 200; stepSize: 10
                        onValueChanged: { Config.options.lock.blur.size = value }
                    }
                    ConfigSpinBox {
                        visible: Config.options.lock.blur.enable
                        icon: "loupe"
                        text: Translation.tr("Extra wallpaper zoom (%)")
                        value: Config.options.lock.blur.extraZoom * 100
                        from: 1; to: 150; stepSize: 2
                        onValueChanged: { Config.options.lock.blur.extraZoom = value / 100 }
                    }
                }
            }
        }
    }
}
