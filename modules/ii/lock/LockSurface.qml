pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.ii.bar as Bar
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import qs.modules.ii.background.widgets.resources
import qs.modules.ii.background.widgets.visualizer
import qs.modules.ii.background.widgets.calendar
import qs.modules.ii.background.widgets.worldclock
import qs.modules.ii.background.widgets.usercard
import qs.modules.ii.background.widgets.goals
import qs.modules.ii.background.widgets.images
import qs.modules.common.widgets.widgetCanvas

Item {
    id: root

    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock?.security?.requirePasswordToPower ?? false

    function getShapeFromName(name) {
        switch (name) {
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie7Sided
        }
    }

    readonly property string lockWallpaperSource: {
        if (Config.options.background.lockWall && Config.options.background.lockWall !== "") {
            let p = Config.options.background.lockWall;
            return p.startsWith("file://") ? p : "file://" + p;
        }
        let wPath = Wallpapers.confirmedPath || Appearance.effectiveWallpaperImagePath;
        if (!wPath) return "";
        return wPath.startsWith("file://") ? wPath : "file://" + wPath;
    }

    // ── 1. Wallpaper Backdrop with Subtle Cinematic Depth ───────────────────
    Item {
        id: lockBackdrop
        anchors.fill: parent
        z: -10

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer0Base || Appearance.colors.colLayer0 || "#121318"
        }

        Image {
            id: lockWallImg
            anchors.fill: parent
            source: root.lockWallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        FastBlur {
            id: lockBlurLayer
            anchors.fill: parent
            source: lockWallImg
            radius: (Config.options.lock.blur && Config.options.lock.blur.enable)
                ? Math.min(Config.options.lock.blur.radius ?? 32, 48)
                : 0
            visible: (Config.options.lock.blur && Config.options.lock.blur.enable)
        }

        // Elegant soft vignette so widgets and unlock controls pop with stunning contrast
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.20) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.05) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.42) }
            }
        }

        Loader {
            anchors.fill: parent
            active: Config.options.background.centeredWallpaper
            visible: active
            sourceComponent: Item {
                anchors.fill: parent

                MaterialShape {
                    id: lockCenteredShape
                    anchors.centerIn: parent
                    width: Config.options.background.centeredWallpaperSize
                    height: Config.options.background.centeredWallpaperSize
                    color: "transparent"
                    shape: root.getShapeFromName(Config.options.background.centeredWallpaperShape)

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: MaterialShape {
                            width: Config.options.background.centeredWallpaperSize
                            height: Config.options.background.centeredWallpaperSize
                            shape: root.getShapeFromName(Config.options.background.centeredWallpaperShape)
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: root.lockWallpaperSource
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                    }
                }
            }
        }
    }

    // ── Focus & Keyboard Handling ───────────────────────────────────────────
    function forceFieldFocus() {
        if (passwordInput) {
            passwordInput.forceActiveFocus();
        }
    }

    Connections {
        target: root.context
        function onShouldReFocus() {
            root.forceFieldFocus();
        }
    }

    MouseArea {
        id: lockBackgroundClickArea
        anchors.fill: parent
        z: -2
        acceptedButtons: Qt.LeftButton
        onPressed: root.forceFieldFocus()
    }

    property bool ctrlHeld: false

    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) {
            root.context.currentText = "";
            if (passwordInput) passwordInput.text = "";
            GlobalStates.screenUnlockFailed = false;
        }
        root.forceFieldFocus();
    }

    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        root.forceFieldFocus();
    }

    Component.onCompleted: {
        root.forceFieldFocus();
    }

    // ── 2. Unified Desktop Widgets Canvas (100% Identical to Home Screen) ───
    WidgetCanvas {
        id: lockWidgetCanvas
        z: 10
        anchors.fill: parent
        visible: (Config.options.lock && Config.options.lock.showWidgets !== undefined) ? Config.options.lock.showWidgets : true
        onPressed: mouse => root.forceFieldFocus()

        // Visualizer 1
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.visualizer.enable)
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Visualizer 2
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.visualizer2 && Config.options.background.widgets.visualizer2.enable)
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer2"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Custom Image
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.customImage.enable)
            sourceComponent: CustomImage {
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Extra Custom Images
        Repeater {
            model: Config.options.background.widgets.customImages
            delegate: FadeLoader {
                required property int index
                shown: Boolean(Config.options.lock.showWidgets)
                sourceComponent: ExtraCustomImage {
                    screenWidth: root.width
                    screenHeight: root.height
                    scaledScreenWidth: root.width
                    scaledScreenHeight: root.height
                    wallpaperScale: 1
                    imageIndex: index
                }
            }
        }

        // Calendar
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.calendar.enable)
            sourceComponent: CalendarWidget {
                configEntryName: "calendar"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Weather
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.weather.enable)
            sourceComponent: WeatherWidget {
                configEntryName: "weather"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Clock
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.clock.enable)
            sourceComponent: ClockWidget {
                configEntryName: "clock"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
                wallpaperSafetyTriggered: false
            }
        }

        // Goals & Notes
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.goals.enable)
            sourceComponent: GoalsWidget {
                configEntryName: "goals"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Media Player
        FadeLoader {
            id: mediaLoader
            property bool enableLoading: true
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.media.enable && enableLoading)
            sourceComponent: MediaWidget {
                configEntryName: "media"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // Media Studio (Image Converter)
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.images && Config.options.background.widgets.images.enable)
            sourceComponent: ImageConverterWidget {
                configEntryName: "images"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // System Resources
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.resources.enable)
            sourceComponent: ResourcesWidget {
                configEntryName: "resources"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // World Clock
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.worldClock.enable)
            sourceComponent: WorldClockWidget {
                configEntryName: "worldClock"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        // User Card
        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.background.widgets.userCard.enable)
            sourceComponent: UserCardWidget {
                configEntryName: "userCard"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }
    }

    // ── 3. Sleek Top-Right Status & Power Capsule ───────────────────────────
    Rectangle {
        id: statusCapsule
        z: 100
        anchors {
            top: parent.top
            right: parent.right
            margins: 20
        }
        implicitHeight: 38
        implicitWidth: statusRow.implicitWidth + 24
        radius: 19
        color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.45)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.12)

        RowLayout {
            id: statusRow
            anchors.centerIn: parent
            spacing: 10

            // Keyboard Layout
            RowLayout {
                spacing: 4
                MaterialSymbol {
                    text: "keyboard_alt"
                    iconSize: 15
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    text: HyprlandXkb.currentLayoutCode
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Fcitx SysTray
            Bar.SysTray {
                showSeparator: false
                showOverflowMenu: false
                pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
                visible: pinnedItems.length > 0
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Qt.rgba(255, 255, 255, 0.14)
            }

            // Battery Status
            RowLayout {
                visible: Battery.available
                spacing: 4
                MaterialSymbol {
                    text: Battery.isCharging ? "bolt" : "battery_android_full"
                    iconSize: 15
                    color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    text: Math.round(Battery.percentage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Divider (if battery visible)
            Rectangle {
                visible: Battery.available
                implicitWidth: 1
                implicitHeight: 14
                color: Qt.rgba(255, 255, 255, 0.14)
            }

            // Quick Power Actions
            RowLayout {
                spacing: 4

                // Suspend / Sleep
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: sleepHover.containsMouse
                        ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                        : "transparent"
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "dark_mode"
                        iconSize: 15
                        color: sleepHover.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    }
                    MouseArea {
                        id: sleepHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Session.suspend()
                    }
                    StyledToolTip {
                        extraVisibleCondition: sleepHover.containsMouse
                        text: Translation.tr("Sleep")
                    }
                }

                // Restart
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: (root.context.targetAction === LockContext.ActionEnum.Reboot || restartHover.containsMouse)
                        ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                        : "transparent"
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "restart_alt"
                        iconSize: 15
                        color: (root.context.targetAction === LockContext.ActionEnum.Reboot || restartHover.containsMouse)
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colOnSurfaceVariant
                    }
                    MouseArea {
                        id: restartHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.requirePasswordToPower) {
                                root.context.unlocked(LockContext.ActionEnum.Reboot);
                                return;
                            }
                            if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                                root.context.resetTargetAction();
                            } else {
                                root.context.targetAction = LockContext.ActionEnum.Reboot;
                                root.forceFieldFocus();
                            }
                        }
                    }
                    StyledToolTip {
                        extraVisibleCondition: restartHover.containsMouse
                        text: Translation.tr("Restart")
                    }
                }

                // Power Off
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: (root.context.targetAction === LockContext.ActionEnum.Poweroff || powerHover.containsMouse)
                        ? Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.22)
                        : "transparent"
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        iconSize: 15
                        color: (root.context.targetAction === LockContext.ActionEnum.Poweroff || powerHover.containsMouse)
                            ? Appearance.colors.colError
                            : Appearance.colors.colOnSurfaceVariant
                    }
                    MouseArea {
                        id: powerHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.requirePasswordToPower) {
                                root.context.unlocked(LockContext.ActionEnum.Poweroff);
                                return;
                            }
                            if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                                root.context.resetTargetAction();
                            } else {
                                root.context.targetAction = LockContext.ActionEnum.Poweroff;
                                root.forceFieldFocus();
                            }
                        }
                    }
                    StyledToolTip {
                        extraVisibleCondition: powerHover.containsMouse
                        text: Translation.tr("Shut Down")
                    }
                }
            }
        }
    }

    // ── 4. The Hero Element: Liquid Glass Unlock Island ─────────────────────
    Item {
        id: heroUnlockContainer
        z: 100
        anchors.centerIn: parent
        width: unlockColumn.implicitWidth
        height: unlockColumn.implicitHeight

        ColumnLayout {
            id: unlockColumn
            anchors.centerIn: parent
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            // User Avatar & Name
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                // Circular Avatar
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.40)
                    border.width: 1.5
                    border.color: Qt.rgba(255, 255, 255, 0.24)

                    readonly property string avatarSource: {
                        const pic = Config.options.profile?.avatarPicture ?? "";
                        if (pic && pic !== "") return pic.startsWith("file://") ? pic : "file://" + pic;
                        const p = Config.options.profile?.avatarPath ?? "";
                        if (p && p !== "") return p.startsWith("file://") ? p : "file://" + p;
                        return "";
                    }

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        anchors.margins: 2
                        source: parent.avatarSource
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: avatarImg.width
                                height: avatarImg.height
                                radius: width / 2
                            }
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: !avatarImg.visible
                        text: "person"
                        iconSize: 34
                        color: Appearance.colors.colPrimary
                    }
                }

                // Display Name / Username
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        const disp = Config.options.profile?.displayName ?? "";
                        if (disp && disp.length > 0) return disp;
                        return SystemInfo.realName || SystemInfo.username || "User";
                    }
                    font.pixelSize: Appearance.font.pixelSize.medium
                    font.weight: Font.DemiBold
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnLayer0 || "#ffffff"
                }
            }

            // Liquid Glass Password Capsule
            Rectangle {
                id: passwordCapsule
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 320
                implicitHeight: 48
                radius: 24
                color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.48)
                border.width: (passwordInput.activeFocus || GlobalStates.screenUnlockFailed) ? 1.5 : 1
                border.color: GlobalStates.screenUnlockFailed
                    ? Appearance.colors.colError
                    : (passwordInput.activeFocus ? Appearance.colors.colPrimary : Qt.rgba(255, 255, 255, 0.16))

                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                // Shake Animation on wrong password
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: passwordCapsule; property: "x"; to: passwordCapsule.x - 14; duration: 45; easing.type: Easing.OutQuad }
                    NumberAnimation { target: passwordCapsule; property: "x"; to: passwordCapsule.x + 14; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordCapsule; property: "x"; to: passwordCapsule.x - 7; duration: 35; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordCapsule; property: "x"; to: passwordCapsule.x + 7; duration: 35; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passwordCapsule; property: "x"; to: passwordCapsule.x; duration: 30; easing.type: Easing.OutQuad }
                }

                Connections {
                    target: GlobalStates
                    function onScreenUnlockFailedChanged() {
                        if (GlobalStates.screenUnlockFailed) {
                            shakeAnim.restart();
                            root.context.currentText = "";
                            if (passwordInput) passwordInput.text = "";
                            root.forceFieldFocus();
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 6
                    spacing: 8

                    // Left Icon
                    MaterialSymbol {
                        text: root.context.fingerprintsConfigured ? "fingerprint" : (root.context.currentText.length > 0 ? "key" : "lock")
                        iconSize: 18
                        color: root.context.currentText.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    }

                    // Password Input Field & Masked Dots
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        // Placeholder
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: root.context.currentText.length === 0
                            text: GlobalStates.screenUnlockFailed
                                ? Translation.tr("Incorrect password")
                                : (root.context.fingerprintsConfigured ? Translation.tr("Fingerprint or password") : Translation.tr("Enter password"))
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: GlobalStates.screenUnlockFailed ? Appearance.colors.colError : Appearance.colors.colSubtext
                        }

                        // Animated Shape Characters
                        Loader {
                            active: Config.options.lock?.materialShapeChars ?? true
                            anchors.fill: parent
                            visible: root.context.currentText.length > 0
                            sourceComponent: PasswordChars {
                                length: root.context.currentText.length
                                selectionStart: passwordInput.selectionStart
                                selectionEnd: passwordInput.selectionEnd
                                cursorPosition: passwordInput.cursorPosition
                            }
                        }

                        // Text Input
                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: (Config.options.lock?.materialShapeChars ?? true) ? "transparent" : Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.family: Appearance.font.family.main
                            enabled: !root.context.unlockInProgress
                            inputMethodHints: Qt.ImhSensitiveData

                            onTextChanged: {
                                root.context.currentText = text;
                            }
                            onAccepted: {
                                root.context.tryUnlock(root.ctrlHeld);
                            }

                            Connections {
                                target: root.context
                                function onCurrentTextChanged() {
                                    if (passwordInput.text !== root.context.currentText) {
                                        passwordInput.text = root.context.currentText;
                                    }
                                }
                            }
                        }
                    }

                    // Submit Action Button
                    Rectangle {
                        id: submitBtn
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: (root.context.currentText.length > 0 || submitHover.containsMouse)
                            ? Appearance.colors.colPrimary
                            : Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.22)

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: {
                                if (root.context.targetAction === LockContext.ActionEnum.Poweroff) return "power_settings_new";
                                if (root.context.targetAction === LockContext.ActionEnum.Reboot) return "restart_alt";
                                return root.ctrlHeld ? "coffee" : "arrow_forward";
                            }
                            iconSize: 18
                            color: (root.context.currentText.length > 0 || submitHover.containsMouse)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                        }

                        MouseArea {
                            id: submitHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.context.tryUnlock(root.ctrlHeld)
                        }
                    }
                }
            }

            // Subtle Hint Subtext
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (GlobalStates.screenUnlockFailed) return Translation.tr("Press Esc to clear");
                    if (root.ctrlHeld) return Translation.tr("Coffee break mode · Screen will stay awake");
                    if (root.context.targetAction === LockContext.ActionEnum.Poweroff) return Translation.tr("Enter password to shut down");
                    if (root.context.targetAction === LockContext.ActionEnum.Reboot) return Translation.tr("Enter password to restart");
                    return "";
                }
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: GlobalStates.screenUnlockFailed ? Appearance.colors.colError : Appearance.colors.colSubtext
                opacity: text.length > 0 ? 0.9 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }
            }
        }
    }
}
