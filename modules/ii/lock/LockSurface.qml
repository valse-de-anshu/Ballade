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
import Quickshell
import Quickshell.Hyprland
import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.visualizer
import qs.modules.common.widgets.widgetCanvas

Item {
    id: root

    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock?.security?.requirePasswordToPower ?? false

    readonly property string lockWallpaperSource: {
        let p = Config.options.background.lockWall;
        if (p && p !== "") return p.startsWith("file://") ? p : "file://" + p;
        let wPath = Wallpapers.confirmedPath || Appearance.effectiveWallpaperImagePath || Config.options.background.wallpaperPath;
        if (!wPath) return "";
        return wPath.startsWith("file://") ? wPath : "file://" + wPath;
    }

    // ── 1. Wallpaper Backdrop ───────────────────────────────────────────────
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
            asynchronous: false
            cache: true
        }

        FastBlur {
            id: lockBlurLayer
            anchors.fill: parent
            source: lockWallImg
            radius: (Config.options.lock.blur && Config.options.lock.blur.enable)
                ? Math.min(Config.options.lock.blur.radius ?? 16, 24)
                : 0
            visible: (Config.options.lock.blur && Config.options.lock.blur.enable)
        }

        // Soft natural vignette for subtle depth
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.16) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.02) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.28) }
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

    // ── 2. Visualizers (Only Audio Visualizers Active) ───────────────────────
    WidgetCanvas {
        id: lockWidgetCanvas
        z: 10
        anchors.fill: parent
        onPressed: mouse => root.forceFieldFocus()

        FadeLoader {
            shown: Boolean(Config.options.background.widgets.visualizer.enable)
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }

        FadeLoader {
            shown: Boolean(Config.options.background.widgets.visualizer2 && Config.options.background.widgets.visualizer2.enable)
            sourceComponent: VisualizerWidget {
                configEntryName: "visualizer2"
                screenWidth: root.width
                screenHeight: root.height
                scaledScreenWidth: root.width
                scaledScreenHeight: root.height
                wallpaperScale: 1
            }
        }
    }

    // ── 3. The Centerpiece: Liquid Glass Lock Card ───────────────────────────
    Rectangle {
        id: glassLockCard
        z: 100
        anchors.centerIn: parent
        implicitWidth: 380
        implicitHeight: cardContent.implicitHeight + 48
        radius: 32
        clip: true

        property color fill: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            0.20
        )
        color: (Config.options?.background?.widgets?.glass?.enable && fill.a > 0) ? "transparent" : fill

        // Subtle natural glass border (NO cheap 2D highlighter / glowing line)
        border.width: 1
        border.color: ColorUtils.applyAlpha(ColorUtils.mix(Appearance.colors.colPrimary, "#ffffff", 0.35), 0.12)

        // The Real Liquid Lens Glass Engine
        WindowGlass {
            anchors.fill: parent
            cardRadius: glassLockCard.radius
            fullscreenSurface: true
            glassEnabled: (Config.options?.background?.widgets?.glass?.enable ?? true)
            tint: glassLockCard.fill
        }

        // Shake Animation on wrong password
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: glassLockCard; property: "x"; to: glassLockCard.x - 14; duration: 45; easing.type: Easing.OutQuad }
            NumberAnimation { target: glassLockCard; property: "x"; to: glassLockCard.x + 14; duration: 45; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glassLockCard; property: "x"; to: glassLockCard.x - 7; duration: 35; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glassLockCard; property: "x"; to: glassLockCard.x + 7; duration: 35; easing.type: Easing.InOutQuad }
            NumberAnimation { target: glassLockCard; property: "x"; to: glassLockCard.x; duration: 30; easing.type: Easing.OutQuad }
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

        ColumnLayout {
            id: cardContent
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 24
            }
            spacing: 16

            // ── Aesthetic Clock Section ─────────────────────────────────────
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                // Refined Time Typography
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    StyledText {
                        text: DateTime.hoursStr
                        font.pixelSize: 64
                        font.weight: Font.DemiBold
                        font.family: Appearance.font.family.title || Appearance.font.family.main
                        color: Appearance.colors.colOnLayer0 || "#ffffff"
                    }

                    StyledText {
                        text: ":"
                        font.pixelSize: 58
                        font.weight: Font.Normal
                        font.family: Appearance.font.family.title || Appearance.font.family.main
                        color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.85)
                        Layout.topMargin: -4
                    }

                    StyledText {
                        text: DateTime.minutesStr
                        font.pixelSize: 64
                        font.weight: Font.DemiBold
                        font.family: Appearance.font.family.title || Appearance.font.family.main
                        color: Appearance.colors.colOnLayer0 || "#ffffff"
                    }
                }

                // Date Badge
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    MaterialSymbol {
                        text: "calendar_today"
                        iconSize: 13
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: DateTime.collapsedCalendarFormat
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0 || "#ffffff"
                    }
                }

                // Custom Quote (Configured by user: "i like the way u smile")
                StyledText {
                    visible: Config.options.background?.widgets?.clock?.quote?.enable ?? true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 2
                    text: "“ " + (Config.options.background?.widgets?.clock?.quote?.text ?? "i like the way u smile") + " ”"
                    font.italic: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 || "#ffffff", 0.65)
                }
            }

            // Subtle Glass Optical Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: ColorUtils.applyAlpha("#ffffff", 0.08)
            }

            // ── Liquid Glass Password Input Pill ────────────────────────────
            Rectangle {
                id: passwordPill
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 22
                color: Qt.rgba(
                    Appearance.colors.colLayer0Base.r,
                    Appearance.colors.colLayer0Base.g,
                    Appearance.colors.colLayer0Base.b,
                    0.24
                )
                // Natural soft glass border (NO bright 2D neon line)
                border.width: 1
                border.color: GlobalStates.screenUnlockFailed
                    ? Appearance.colors.colError
                    : ColorUtils.applyAlpha("#ffffff", passwordInput.activeFocus ? 0.22 : 0.10)

                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 6
                    spacing: 8

                    // Lock Icon
                    MaterialSymbol {
                        text: root.context.fingerprintsConfigured ? "fingerprint" : (root.context.currentText.length > 0 ? "lock_open" : "lock")
                        iconSize: 17
                        color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 || "#ffffff", 0.65)
                    }

                    // Password Field
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: root.context.currentText.length === 0
                            text: GlobalStates.screenUnlockFailed
                                ? Translation.tr("Incorrect password")
                                : (root.context.fingerprintsConfigured ? Translation.tr("Fingerprint or password") : Translation.tr("Enter password"))
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: GlobalStates.screenUnlockFailed
                                ? Appearance.colors.colError
                                : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 || "#ffffff", 0.38)
                        }

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

                    // Submit Button
                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 16
                        color: (root.context.currentText.length > 0 || submitHover.containsMouse)
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha("#ffffff", 0.08)

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
                            iconSize: 16
                            color: (root.context.currentText.length > 0 || submitHover.containsMouse)
                                ? Appearance.colors.colOnPrimary
                                : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 || "#ffffff", 0.50)
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

            // Subtle Hint
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (GlobalStates.screenUnlockFailed) return Translation.tr("Press Esc to clear");
                    if (root.ctrlHeld) return Translation.tr("Coffee break mode · Screen will stay awake");
                    return Translation.tr("Esc to clear · Enter to unlock");
                }
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: GlobalStates.screenUnlockFailed
                    ? Appearance.colors.colError
                    : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0 || "#ffffff", 0.40)
            }
        }
    }
}
