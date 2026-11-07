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
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

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

    Item {
        id: lockBackdrop
        anchors.fill: parent
        z: -10

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer0Base || Appearance.colors.colLayer0 || "#181825"
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
            radius: Config.options.lock.blur.radius ?? 48
            visible: Config.options.lock.blur.enable
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer0 || "#181825"
            opacity: Config.options.lock.blur.enable ? 0.35 : 0.15
        }

        Loader {
            anchors.fill: parent
            active: (Config.options.lock?.centeredWallpaper?.enable ?? false) || Config.options.background.centeredWallpaperOnlyWhenLocked
            visible: active
            sourceComponent: Item {
                anchors.fill: parent

                readonly property int shapeSize: Config.options.lock?.centeredWallpaper?.size ?? 400
                readonly property string shapeName: Config.options.lock?.centeredWallpaper?.shape ?? "Cookie7Sided"

                MaterialShape {
                    id: lockCenteredShape
                    anchors.centerIn: parent
                    width: parent.shapeSize
                    height: parent.shapeSize
                    color: "transparent"
                    shape: root.getShapeFromName(parent.shapeName)

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: MaterialShape {
                            width: parent.shapeSize
                            height: parent.shapeSize
                            shape: root.getShapeFromName(parent.shapeName)
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

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: context
        function onShouldReFocus() {
            forceFieldFocus();
        }
    }
    MouseArea {
        id: lockBackgroundClickArea
        anchors.fill: parent
        z: -2
        acceptedButtons: Qt.LeftButton
        onPressed: root.forceFieldFocus()
    }

    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Init
    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    // Key presses
    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = true;
        }
        if (event.key === Qt.Key_Escape) { // Esc to clear
            root.context.currentText = "";
        } 
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) {
            root.ctrlHeld = false;
        }
        forceFieldFocus();
    }

    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: {
    //         context.unlocked(LockContext.ActionEnum.Unlock);
    //         GlobalStates.screenLocked = false;
    //     }
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    // Lock screen widgets area: identical to desktop WidgetCanvas
    WidgetCanvas {
        id: lockWidgetCanvas
        z: 10
        anchors.fill: parent
        visible: true
        onPressed: mouse => root.forceFieldFocus()

        FadeLoader {
            shown: Boolean((Config.options.lock.widgets?.visualizer && Config.options.lock.widgets.visualizer.enable)
                    || (Config.options.background.widgets?.visualizer && Config.options.background.widgets.visualizer.enable))
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean((Config.options.lock.widgets?.visualizer2 && Config.options.lock.widgets.visualizer2.enable)
                    || (Config.options.background.widgets?.visualizer2 && Config.options.background.widgets.visualizer2.enable))
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer2"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

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

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && ((Config.options.lock.widgets.clock && Config.options.lock.widgets.clock.enable)
                    || (Config.options.background.widgets.clock && Config.options.background.widgets.clock.enable)))
            sourceComponent: ClockWidget {
                configEntryName: "clock"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
                wallpaperSafetyTriggered: false
            }
        }

        FadeLoader {
            id: mediaLoader
            property bool enableLoading: true
            shown: Boolean(Config.options.lock.showWidgets && ((Config.options.lock.widgets.media && Config.options.lock.widgets.media.enable)
                    || (Config.options.background.widgets.media && Config.options.background.widgets.media.enable)) && enableLoading)
            sourceComponent: MediaWidget {
                configEntryName: "media"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.weather && Config.options.lock.widgets.weather.enable)
            sourceComponent: WeatherWidget {
                configEntryName: "weather"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.calendar && Config.options.lock.widgets.calendar.enable)
            sourceComponent: CalendarWidget {
                configEntryName: "calendar"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.goals && Config.options.lock.widgets.goals.enable)
            sourceComponent: GoalsWidget {
                configEntryName: "goals"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.userCard && Config.options.lock.widgets.userCard.enable)
            sourceComponent: UserCardWidget {
                configEntryName: "userCard"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.resources && Config.options.lock.widgets.resources.enable)
            sourceComponent: ResourcesWidget {
                configEntryName: "resources"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && ((Config.options.lock.widgets.images && Config.options.lock.widgets.images.enable)
                    || (Config.options.background.widgets.images && Config.options.background.widgets.images.enable)))
            sourceComponent: ImageConverterWidget {
                configEntryName: "images"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.lock.showWidgets && Config.options.lock.widgets.worldClock && Config.options.lock.widgets.worldClock.enable)
            sourceComponent: WorldClockWidget {
                configEntryName: "worldClock"
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }
    }

    // Time pill (inline left)
    Toolbar {
        id: timeIsland
        z: 100
        anchors {
            right: leftIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            icon: "schedule"
            text: DateTime.time
        }
    }

    // Main toolbar: password box
    Toolbar {
        id: mainIsland
        z: 100
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Fingerprint
        Loader {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            active: root.context.fingerprintsConfigured
            visible: active

            sourceComponent: MaterialSymbol {
                id: fingerprintIcon
                fill: 1
                text: "fingerprint"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ToolbarTextField {
            id: passwordBox
            Layout.rightMargin: -Layout.leftMargin
            placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")

            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
            selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: {
                root.context.tryUnlock(ctrlHeld);
            }
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }

            Keys.onPressed: event => {
                root.context.resetClearTimer();
            }
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }
            }

            // Shake when wrong password
            ErrorShakeAnimation {
                id: wrongPasswordShakeAnim
                target: passwordBox
            }
            Connections {
                target: GlobalStates
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed) wrongPasswordShakeAnim.restart();
                }
            }

            // We're drawing dots manually
            property bool materialShapeChars: Config.options.lock.materialShapeChars
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
            Loader {
                active: passwordBox.materialShapeChars
                anchors {
                    fill: parent
                    leftMargin: passwordBox.padding
                    rightMargin: passwordBox.padding
                }
                sourceComponent: PasswordChars {
                    length: root.context.currentText.length
                    selectionStart: passwordBox.selectionStart
                    selectionEnd: passwordBox.selectionEnd
                    cursorPosition: passwordBox.cursorPosition
                }
            }
        }

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: {
                    if (root.context.targetAction === LockContext.ActionEnum.Unlock) {
                        return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Poweroff) {
                        return "power_settings_new";
                    } else if (root.context.targetAction === LockContext.ActionEnum.Reboot) {
                        return "restart_alt";
                    }
                }
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    // Left toolbar
    Toolbar {
        id: leftIsland
        z: 100
        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        // Username
        IconAndTextPair {
            Layout.leftMargin: 8
            icon: "account_circle"
            text: SystemInfo.username
        }

        // Keyboard layout (Xkb)
        Loader {
            Layout.rightMargin: 8
            Layout.fillHeight: true

            active: true
            visible: active

            sourceComponent: Row {
                spacing: 8

                MaterialSymbol {
                    id: keyboardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: "keyboard_alt"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: StyledText {
                        text: HyprlandXkb.currentLayoutCode
                        color: Appearance.colors.colOnSurfaceVariant
                        animateChange: true
                    }
                }
            }
        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 10
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter(i => i.id == "Fcitx")
            visible: pinnedItems.length > 0
        }
    }

    // Right toolbar
    Toolbar {
        id: rightIsland
        z: 100
        anchors {
            left: mainIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            id: sleepButton
            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton
            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton
            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
    }

    // Date & Month pill (inline right)
    Toolbar {
        id: dateIsland
        z: 100
        anchors {
            left: rightIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            icon: "calendar_today"
            text: Qt.locale().toString(DateTime.clock.date, "dddd, d MMMM")
        }
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn
        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction

        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
