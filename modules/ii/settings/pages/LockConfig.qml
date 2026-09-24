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

            // ── Clock & Password Display ────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Clock & Password Display")
                GroupedList {
                    ConfigSwitch {
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Center clock")
                        checked: Config.options.lock.centerClock
                        onCheckedChanged: { Config.options.lock.centerClock = checked }
                    }
                    ConfigSwitch {
                        buttonIcon: "info"
                        text: Translation.tr('Show "Locked" text')
                        checked: Config.options.lock.showLockedText
                        onCheckedChanged: { Config.options.lock.showLockedText = checked }
                    }
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
                    ConfigSwitch {
                        visible: Config.options.background.lockWall !== ""
                        buttonIcon: "image"
                        text: Translation.tr("Custom lock screen wallpaper active")
                        checked: Config.options.background.lockWall !== ""
                        onCheckedChanged: {
                            if (!checked) {
                                Config.options.background.lockWall = "";
                            }
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

        // ── 2. Lock Screen Widgets ──────────────────────────────────────────
        ContentSection {
            icon: "widgets"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Lock Screen Widgets")
            visible: Config.options.lock.showWidgets

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Configure which widgets appear when your screen is locked, choose their layout positions, and decide whether you can interact with them (e.g. media player controls, calendar) or have clicks pass through to focus password input.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            LockWidgetConfigBlock {
                widgetKey: "clock"
                widgetTitle: Translation.tr("Clock")
                widgetIcon: "schedule"
            }

            LockWidgetConfigBlock {
                widgetKey: "media"
                widgetTitle: Translation.tr("Media Player")
                widgetIcon: "music_note"
            }

            LockWidgetConfigBlock {
                widgetKey: "calendar"
                widgetTitle: Translation.tr("Calendar")
                widgetIcon: "calendar_month"
            }

            LockWidgetConfigBlock {
                widgetKey: "weather"
                widgetTitle: Translation.tr("Weather")
                widgetIcon: "cloud"
            }

            LockWidgetConfigBlock {
                widgetKey: "visualizer"
                widgetTitle: Translation.tr("GPU / Audio Visualizer")
                widgetIcon: "equalizer"
            }

            LockWidgetConfigBlock {
                widgetKey: "userCard"
                widgetTitle: Translation.tr("User Profile Card")
                widgetIcon: "person"
            }

            LockWidgetConfigBlock {
                widgetKey: "goals"
                widgetTitle: Translation.tr("Goals & Tasks")
                widgetIcon: "checklist"
            }

            LockWidgetConfigBlock {
                widgetKey: "resources"
                widgetTitle: Translation.tr("System Resources")
                widgetIcon: "memory"
            }

            LockWidgetConfigBlock {
                widgetKey: "worldClock"
                widgetTitle: Translation.tr("World Clock")
                widgetIcon: "public"
            }
        }
    }

    component LockWidgetConfigBlock: ContentSubsection {
        id: block
        required property string widgetKey
        required property string widgetTitle
        required property string widgetIcon

        readonly property var cfg: (Config.options.lock && Config.options.lock.widgets) ? Config.options.lock.widgets[widgetKey] : null

        title: widgetTitle

        GroupedList {
            ConfigSwitch {
                buttonIcon: block.widgetIcon
                text: Translation.tr("Show on lock screen")
                checked: Boolean(block.cfg && block.cfg.enable)
                onCheckedChanged: {
                    if (block.cfg && block.cfg.enable !== checked) {
                        block.cfg.enable = checked;
                        Config.save();
                    }
                }
            }

            ConfigSwitch {
                visible: Boolean(block.cfg && block.cfg.enable)
                buttonIcon: "touch_app"
                text: Translation.tr("Allow interaction on lock screen")
                checked: Boolean(block.cfg && block.cfg.interactive)
                onCheckedChanged: {
                    if (block.cfg && block.cfg.interactive !== checked) {
                        block.cfg.interactive = checked;
                        Config.save();
                    }
                }
            }

            ConfigComboBox {
                visible: Boolean(block.cfg && block.cfg.enable)
                Layout.fillWidth: true
                buttonIcon: "place"
                text: Translation.tr("Position")
                fieldWidth: 160
                model: [
                    { displayName: Translation.tr("Desktop Position"), icon: "desktop_windows", value: "default" },
                    { displayName: Translation.tr("Center"), icon: "filter_center_focus", value: "center" },
                    { displayName: Translation.tr("Top"), icon: "vertical_align_top", value: "top" },
                    { displayName: Translation.tr("Top Left"), icon: "north_west", value: "topLeft" },
                    { displayName: Translation.tr("Top Right"), icon: "north_east", value: "topRight" },
                    { displayName: Translation.tr("Bottom"), icon: "vertical_align_bottom", value: "bottom" },
                    { displayName: Translation.tr("Bottom Left"), icon: "south_west", value: "bottomLeft" },
                    { displayName: Translation.tr("Bottom Right"), icon: "south_east", value: "bottomRight" },
                    { displayName: Translation.tr("Custom (X / Y)"), icon: "tune", value: "custom" },
                ]
                currentValue: (block.cfg && block.cfg.position) ? block.cfg.position : "default"
                onSelected: newValue => {
                    if (block.cfg && block.cfg.position !== newValue) {
                        block.cfg.position = newValue;
                        Config.save();
                    }
                }
            }

            ConfigSpinBox {
                visible: Boolean(block.cfg && block.cfg.enable && block.cfg.position === "custom")
                icon: "swap_horiz"
                text: Translation.tr("X Position")
                value: (block.cfg && block.cfg.x !== undefined) ? block.cfg.x : 0
                from: 0; to: 7680; stepSize: 10
                onValueChanged: {
                    if (block.cfg && block.cfg.x !== value) {
                        block.cfg.x = value;
                        Config.save();
                    }
                }
            }

            ConfigSpinBox {
                visible: Boolean(block.cfg && block.cfg.enable && block.cfg.position === "custom")
                icon: "swap_vert"
                text: Translation.tr("Y Position")
                value: (block.cfg && block.cfg.y !== undefined) ? block.cfg.y : 0
                from: 0; to: 4320; stepSize: 10
                onValueChanged: {
                    if (block.cfg && block.cfg.y !== value) {
                        block.cfg.y = value;
                        Config.save();
                    }
                }
            }
        }
    }
}
