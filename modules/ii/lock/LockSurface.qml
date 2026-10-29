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

MouseArea {
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
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
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

    // Lock screen widgets area
    Item {
        id: lockWidgetsArea
        anchors.fill: parent
        z: 0
        readonly property bool isWidgetCanvas: true
        function setDragging(active) {}
        function setCenterActive(xActive, yActive) {}
        visible: (Config.options.lock && Config.options.lock.showWidgets !== undefined) ? Config.options.lock.showWidgets : true

        component LockWidgetWrapper: Item {
            id: wrapper
            required property string widgetKey
            default property alias content: loader.sourceComponent
            property alias item: loader.item

            readonly property var lockCfg: (Config.options.lock && Config.options.lock.widgets) ? Config.options.lock.widgets[widgetKey] : null
            readonly property bool isEnabled: ((Config.options.lock && Config.options.lock.showWidgets !== undefined) ? Config.options.lock.showWidgets : true)
                && (lockCfg ? (lockCfg.enable !== undefined ? lockCfg.enable : false) : (widgetKey === "clock" || widgetKey === "media"))

            visible: isEnabled && opacity > 0
            opacity: isEnabled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            anchors.fill: parent

            Loader {
                id: loader
                anchors.fill: parent
                active: wrapper.isEnabled && (GlobalStates.screenLocked || GlobalStates.unlocking)
            }

            Binding {
                target: loader.item
                property: "isLockWidget"
                value: true
                when: Boolean(loader.item && loader.item.isLockWidget !== undefined)
            }
        }

        LockWidgetWrapper {
            widgetKey: "clock"
            ClockWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
                wallpaperSafetyTriggered: false
            }
        }

        LockWidgetWrapper {
            widgetKey: "media"
            MediaWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "weather"
            WeatherWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "calendar"
            CalendarWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "goals"
            GoalsWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "userCard"
            UserCardWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "resources"
            ResourcesWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "worldClock"
            WorldClockWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        LockWidgetWrapper {
            widgetKey: "visualizer"
            VisualizerWidget {
                isLockWidget: true
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
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
