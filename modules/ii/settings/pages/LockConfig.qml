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
    }
}
