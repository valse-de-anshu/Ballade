import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: ColorUtils.applyAlpha("#ffffff", 0.12)
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    readonly property int bgStyle: Config.options.bar.backgroundStyle ?? 1

    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        clip: true

        // =========================================================================
        // STYLE 0: CLASSIC (Original Ballade Bar)
        // Solid colLayer0 with original border, 100% faithful to the default setup
        // =========================================================================
        Rectangle {
            anchors.fill: parent
            radius: barBackground.radius
            visible: Config.options.bar.showBackground && root.bgStyle === 0
            color: Appearance.colors.colLayer0
            border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
            border.color: Appearance.colors.colLayer0Border
        }

        // =========================================================================
        // STYLE 1: FROSTED (Natural Wallpaper Blur)
        // True wallpaper base with soft FastBlur and gentle non-sharp glass rim
        // =========================================================================
        FrostedWidgetBackground {
            anchors.fill: parent
            visible: Config.options.bar.showBackground && root.bgStyle === 1
            radius: barBackground.radius
            blurRadius: 36
            tintOpacity: 0.28
            showSurfaceSheen: false
            imageVerticalAlignment: Config.options.bar.bottom ? Image.AlignBottom : Image.AlignTop
            sourceWidth: root.screen?.width ?? (Screen.width > 0 ? Screen.width : 1920)
            borderColor: Config.options.bar.cornerStyle === 1 ? ColorUtils.applyAlpha("#ffffff", 0.10) : "transparent"
            showBorder: Config.options.bar.cornerStyle === 1
        }

        // =========================================================================
        // STYLE 2: WALLPAPER (Crystal Wallpaper Glass)
        // Pure wallpaper base with light blur and minimal tint so wallpaper shines brightly
        // =========================================================================
        FrostedWidgetBackground {
            anchors.fill: parent
            visible: Config.options.bar.showBackground && root.bgStyle === 2
            radius: barBackground.radius
            blurRadius: 24
            tintOpacity: 0.12
            showSurfaceSheen: true
            imageVerticalAlignment: Config.options.bar.bottom ? Image.AlignBottom : Image.AlignTop
            sourceWidth: root.screen?.width ?? (Screen.width > 0 ? Screen.width : 1920)
            borderColor: Config.options.bar.cornerStyle === 1 ? ColorUtils.applyAlpha("#ffffff", 0.12) : "transparent"
            showBorder: Config.options.bar.cornerStyle === 1
        }

        // =========================================================================
        // STYLE 3: ATMOSPHERE (Atmospheric Wallpaper Vignette)
        // Wallpaper base with soft blur, feathered gradient fading seamlessly to 0%
        // Completely borderless, no box cutoffs, icons float weightlessly
        // =========================================================================
        Item {
            anchors.fill: parent
            visible: Config.options.bar.showBackground && root.bgStyle === 3

            FrostedWidgetBackground {
                anchors.fill: parent
                radius: barBackground.radius
                blurRadius: 44
                tintOpacity: 0.0
                showTint: false
                showBorder: false
                imageVerticalAlignment: Config.options.bar.bottom ? Image.AlignBottom : Image.AlignTop
                sourceWidth: root.screen?.width ?? (Screen.width > 0 ? Screen.width : 1920)
            }

            // Soft atmospheric dusk gradient that melts into the desktop
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: !Config.options.bar.bottom ? 0.0 : 1.0
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.40)
                    }
                    GradientStop {
                        position: !Config.options.bar.bottom ? 0.65 : 0.35
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.15)
                    }
                    GradientStop {
                        position: !Config.options.bar.bottom ? 1.0 : 0.0
                        color: "transparent"
                    }
                }
            }
        }

        // =========================================================================
        // STYLE 4: SMOKED (Velvety Translucent Wallpaper)
        // Deeper blur with soft velvety tint and subtle theme warmth
        // Softens busy wallpaper imagery without losing wallpaper depth
        // =========================================================================
        Item {
            anchors.fill: parent
            visible: Config.options.bar.showBackground && root.bgStyle === 4

            FrostedWidgetBackground {
                anchors.fill: parent
                radius: barBackground.radius
                blurRadius: 50
                tintOpacity: 0.40
                showSurfaceSheen: false
                imageVerticalAlignment: Config.options.bar.bottom ? Image.AlignBottom : Image.AlignTop
                sourceWidth: root.screen?.width ?? (Screen.width > 0 ? Screen.width : 1920)
                borderColor: Config.options.bar.cornerStyle === 1 ? ColorUtils.applyAlpha("#ffffff", 0.07) : "transparent"
                showBorder: Config.options.bar.cornerStyle === 1
            }

            // Subtle theme warmth
            Rectangle {
                anchors.fill: parent
                radius: barBackground.radius
                color: Appearance.colors.colPrimary
                opacity: 0.04
            }
        }

        // =========================================================================
        // STYLE 5: LUMINOUS (Prismatic Glass)
        // Wallpaper base with medium blur and gentle diffuse surface lighting sheen
        // =========================================================================
        FrostedWidgetBackground {
            anchors.fill: parent
            visible: Config.options.bar.showBackground && root.bgStyle === 5
            radius: barBackground.radius
            blurRadius: 34
            tintOpacity: 0.22
            showSurfaceSheen: true
            imageVerticalAlignment: Config.options.bar.bottom ? Image.AlignBottom : Image.AlignTop
            sourceWidth: root.screen?.width ?? (Screen.width > 0 ? Screen.width : 1920)
            borderColor: Config.options.bar.cornerStyle === 1 ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.20) : "transparent"
            showBorder: Config.options.bar.cornerStyle === 1
        }

        // Clean subtle edge glass border when cornerStyle === 0 (Hug style) across frosted styles
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: !Config.options.bar.bottom ? parent.bottom : undefined
                top: Config.options.bar.bottom ? parent.top : undefined
            }
            height: 1
            color: ColorUtils.applyAlpha("#ffffff", 0.08)
            visible: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 0 && (root.bgStyle !== 0 && root.bgStyle !== 3)
        }
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
        id: barLeftSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Brightness.decreaseBrightness()
        onScrollUp: Brightness.increaseBrightness()
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        // Visual content
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: Hyprsunset.gamma === 100 ? "light_mode" : "wb_twilight"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            LeftSidebarButton { // Left sidebar button
                id: leftSidebarButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            }

            ActiveWindow {
                Layout.leftMargin: 10 + (leftSidebarButton.visible ? 0 : Appearance.rounding.screenRounding)
                Layout.rightMargin: Appearance.rounding.screenRounding
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.useShortenedForm === 0
            }
        }
    }

    Row { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(root.centerSideModuleWidth, childrenRect.width)

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                visible: root.useShortenedForm < 2
                Layout.fillWidth: true
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: workspacesWidget.widgetPadding ?? 0

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    // Right-click to toggle overview
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        MouseArea {
            id: rightCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(root.centerSideModuleWidth, childrenRect.width)
            implicitHeight: rightCenterGroupContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent

                ClockWidget {
                    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }

                UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }

                BatteryIndicator {
                    visible: (root.useShortenedForm < 2 && Battery.available)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
        id: barRightSideMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        // Visual content
        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            RippleButton { // Right sidebar button
                id: rightSidebarButton

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: Appearance.rounding.screenRounding
                Layout.fillWidth: false

                implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

                buttonRadius: Appearance.rounding.full
                colBackground: barRightSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                toggled: GlobalStates.sidebarRightOpen
                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                Behavior on colText {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                onPressed: {
                    GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                }

                RowLayout {
                    id: indicatorsRowLayout
                    anchors.centerIn: parent
                    property real realSpacing: 15
                    spacing: 0

                    Revealer {
                        reveal: Audio.sink?.audio?.muted ?? false
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        MaterialSymbol {
                            text: "volume_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    Revealer {
                        reveal: Audio.source?.audio?.muted ?? false
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        MaterialSymbol {
                            text: "mic_off"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    HyprlandXkbIndicator {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                        color: rightSidebarButton.colText
                    }
                    Revealer {
                        reveal: Notifications.silent || Notifications.unread > 0
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                        implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        NotificationUnreadCount {
                            id: notificationUnreadCount
                        }
                    }
                    MaterialSymbol {
                        text: Network.materialSymbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    MaterialSymbol {
                        Layout.leftMargin: indicatorsRowLayout.realSpacing
                        visible: BluetoothStatus.available
                        text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                }
            }

            SysTray {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Weather
            Loader {
                Layout.leftMargin: 4
                active: Config.options.bar.weather.enable

                sourceComponent: BarGroup {
                    WeatherBar {}
                }
            }
        }
    }
}
