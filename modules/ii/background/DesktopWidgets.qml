pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.images
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.goals

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: widgetsRoot

        required property var modelData
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]

        visible: !GlobalStates.screenLocked && ((!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen)

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:desktopWidgets"
        WlrLayershell.keyboardFocus: GlobalStates.desktopWidgetKeyboardFocus
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        Timer {
            id: mediaTimer
            interval: 100
            repeat: false
            onTriggered: {
                if (mediaLoader.item) mediaLoader.enableLoading = true
            }
        }

        WidgetCanvas {
            id: widgetCanvas
            z: 10
            anchors.fill: parent

            transitions: Transition {
                PropertyAnimation {
                    properties: "width,height"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                AnchorAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.visualizer.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: VisualizerWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.customImage.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: CustomImage {
                    screenWidth:        widgetsRoot.screen.width
                    screenHeight:       widgetsRoot.screen.height
                    scaledScreenWidth:  widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale:     1
                }
            }

            Repeater {
                model: Config.options.background.widgets.customImages
                delegate: FadeLoader {
                    required property int index
                    shown: (Config.options.background.screenList.length === 0
                            || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                    sourceComponent: ExtraCustomImage {
                        screenWidth:        widgetsRoot.screen.width
                        screenHeight:       widgetsRoot.screen.height
                        scaledScreenWidth:  widgetsRoot.screen.width
                        scaledScreenHeight: widgetsRoot.screen.height
                        wallpaperScale:     1
                        imageIndex:         index
                    }
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.calendar.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: CalendarWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.weather.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: WeatherWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.clock.enable
                    && (GlobalStates.screenLocked
                        || Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: ClockWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                    wallpaperSafetyTriggered: false
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.goals.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: GoalsWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
            FadeLoader {
                id: mediaLoader
                property bool enableLoading: true
                shown: Config.options.background.widgets.media.enable && enableLoading
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: MediaWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
                onLoaded: {
                    if (item && item.requestReset) {
                        item.requestReset.connect(() => {
                            mediaLoader.enableLoading = false
                            mediaTimer.running = true
                        })
                    }
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.images.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: ImageConverterWidget {
                    screenWidth:        widgetsRoot.screen.width
                    screenHeight:       widgetsRoot.screen.height
                    scaledScreenWidth:  widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale:     1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.resources.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: ResourcesWidget {
                    screenWidth:        widgetsRoot.screen.width
                    screenHeight:       widgetsRoot.screen.height
                    scaledScreenWidth:  widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale:     1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.worldClock.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: WorldClockWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
            FadeLoader {
                shown: Config.options.background.widgets.userCard.enable
                    && (Config.options.background.screenList.length === 0
                        || Config.options.background.screenList.includes(widgetsRoot.screen.name))
                sourceComponent: UserCardWidget {
                    screenWidth: widgetsRoot.screen.width
                    screenHeight: widgetsRoot.screen.height
                    scaledScreenWidth: widgetsRoot.screen.width
                    scaledScreenHeight: widgetsRoot.screen.height
                    wallpaperScale: 1
                }
            }
        }

        MouseArea {
            id: desktopRightClickArea
            anchors.fill: parent
            z: -2
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                GlobalStates.desktopMenuScreen = widgetsRoot.screen
                GlobalStates.desktopMenuX = mouse.x
                GlobalStates.desktopMenuY = mouse.y
                GlobalStates.desktopMenuOpen = true
            }
        }
    }
}
