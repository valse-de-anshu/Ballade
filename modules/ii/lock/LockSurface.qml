import QtQuick
import QtQuick.Layouts
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
        visible: (Config.options.lock && Config.options.lock.showWidgets !== undefined) ? Config.options.lock.showWidgets : true

        component LockWidgetWrapper: Item {
            id: wrapper
            required property string widgetKey
            default property alias content: loader.sourceComponent
            property alias item: loader.item

            readonly property var lockCfg: (Config.options.lock && Config.options.lock.widgets) ? Config.options.lock.widgets[widgetKey] : null
            readonly property var desktopCfg: (Config.options.background && Config.options.background.widgets) ? Config.options.background.widgets[widgetKey] : null

            readonly property bool isEnabled: ((Config.options.lock && Config.options.lock.showWidgets !== undefined) ? Config.options.lock.showWidgets : true)
                && (lockCfg ? (lockCfg.enable !== undefined ? lockCfg.enable : false) : (widgetKey === "clock" || widgetKey === "media"))

            readonly property bool isInteractive: (lockCfg && lockCfg.interactive !== undefined)
                ? lockCfg.interactive
                : (widgetKey === "media" || widgetKey === "calendar" || widgetKey === "goals" || widgetKey === "weather")

            readonly property string positionMode: (lockCfg && lockCfg.position)
                ? lockCfg.position
                : (widgetKey === "clock" ? "center" : (widgetKey === "media" ? "bottomLeft" : "default"))

            visible: isEnabled && opacity > 0
            opacity: isEnabled ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            readonly property real itemW: loader.item ? (loader.item.width > 0 ? loader.item.width : (loader.item.implicitWidth > 0 ? loader.item.implicitWidth : 300)) : 300
            readonly property real itemH: loader.item ? (loader.item.height > 0 ? loader.item.height : (loader.item.implicitHeight > 0 ? loader.item.implicitHeight : 200)) : 200

            width: itemW
            height: itemH

            readonly property real computedX: {
                switch (positionMode) {
                    case "center":
                    case "top":
                    case "bottom":
                        return Math.round((root.width - itemW) / 2);
                    case "topLeft":
                        return 48;
                    case "topRight":
                        return Math.round(root.width - itemW - 48);
                    case "bottomLeft":
                        return 48;
                    case "bottomRight":
                        return Math.round(root.width - itemW - 48);
                    case "custom":
                        return (lockCfg && lockCfg.x !== undefined) ? lockCfg.x : 0;
                    case "default":
                    default:
                        return (desktopCfg && desktopCfg.x !== undefined) ? desktopCfg.x : 48;
                }
            }
            readonly property real computedY: {
                switch (positionMode) {
                    case "center":
                        return Math.round((root.height - itemH) / 2 - 40);
                    case "top":
                    case "topLeft":
                    case "topRight":
                        return 48;
                    case "bottom":
                    case "bottomLeft":
                    case "bottomRight":
                        return Math.round(root.height - itemH - 120);
                    case "custom":
                        return (lockCfg && lockCfg.y !== undefined) ? lockCfg.y : 0;
                    case "default":
                    default:
                        return (desktopCfg && desktopCfg.y !== undefined) ? desktopCfg.y : 48;
                }
            }

            x: computedX
            y: computedY

            Loader {
                id: loader
                active: wrapper.isEnabled
                onLoaded: {
                    if (item) {
                        item.draggable = false;
                        item.x = 0;
                        item.y = 0;
                    }
                }
            }

            Binding {
                target: loader.item
                property: "x"
                value: 0
                when: Boolean(loader.item)
            }
            Binding {
                target: loader.item
                property: "y"
                value: 0
                when: Boolean(loader.item)
            }
            Binding {
                target: loader.item
                property: "targetX"
                value: 0
                when: Boolean(loader.item && loader.item.targetX !== undefined)
            }
            Binding {
                target: loader.item
                property: "targetY"
                value: 0
                when: Boolean(loader.item && loader.item.targetY !== undefined)
            }
            Binding {
                target: loader.item
                property: "draggable"
                value: false
                when: Boolean(loader.item && loader.item.draggable !== undefined)
            }

            // Click interceptor when non-interactive: forwards click to password focus
            MouseArea {
                anchors.fill: parent
                enabled: !wrapper.isInteractive
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: mouse => root.forceFieldFocus()
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
