import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.functions as CF

ContentPage {
    id: page
    forceWidth: true
    bottomContentPadding: 15

    FileDialog {
        id: audioFileDialog
        title: Translation.tr("Select Audio File")
        currentFolder: Qt.resolvedUrl("file://" + Directories.soundsPath)
        nameFilters: ["Audio files (*.flac *.wav *.mp3 *.ogg *.oga *.opus *.m4a)", "All files (*)"]
        property var targetField: null
        property var targetCallback: null
        onAccepted: {
            let path = selectedFile.toString().replace(/^file:\/\//, "")
            if (targetField) targetField.value = path
            if (targetCallback) targetCallback(path)
        }
    }

    function playSound(filePath, volumePercent, fallbackPath = "", category = "") {
        let target = (filePath && filePath.toString().trim().length > 0) ? filePath.toString().trim() : "";
        if (target.startsWith("file://")) target = target.substring(7);
        let fallback = (fallbackPath && fallbackPath.toString().trim().length > 0) ? fallbackPath.toString().trim() : "";
        if (fallback.startsWith("file://")) fallback = fallback.substring(7);

        let vol = Math.max(0, Math.min(100, volumePercent ?? 70));
        let sDir = (Directories.scriptPath || "").toString().replace(/^file:\/\//, "");
        let scriptPath = sDir + "/play-audio.sh";

        console.log(`[ServicesConfig] playSound triggered: target="${target}", vol=${vol}%, fallback="${fallback}", category="${category}", script="${scriptPath}"`);

        Quickshell.execDetached([
            "bash",
            scriptPath,
            "--file", target,
            "--volume", vol.toString(),
            "--fallback", fallback,
            "--category", category
        ]);
    }

    //This was intended to go into the results more deeply but in the end I didn't like it but I left it just in case lol
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
        Layout.fillHeight: true
        spacing: 20

        ContentSection {
            icon: "neurology"
            shape: MaterialShape.Shape.Ghostish
            title: Translation.tr("AI")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("System prompt")
                text: Config.options.ai.systemPrompt
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Qt.callLater(() => {
                        Config.options.ai.systemPrompt = text;
                    });
                }
            }
        }

        ContentSection {
            icon: "cell_tower"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Networking")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("User agent (for services that require it)")
                text: Config.options.networking.userAgent
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.networking.userAgent = text;
                }
            }
        }

        ContentSection {
            icon: "music_cast"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Music Recognition")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: musicRecCardContent.implicitHeight + 28

                ColumnLayout {
                    id: musicRecCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSpinBox {
                        icon: "timer_off"
                        text: Translation.tr("Total duration timeout (s)")
                        value: Config.options.musicRecognition.timeout
                        from: 10
                        to: 100
                        stepSize: 2
                        onValueChanged: {
                            Config.options.musicRecognition.timeout = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "av_timer"
                        text: Translation.tr("Polling interval (s)")
                        value: Config.options.musicRecognition.interval
                        from: 2
                        to: 10
                        stepSize: 1
                        onValueChanged: {
                            Config.options.musicRecognition.interval = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "file_open"
            shape: MaterialShape.Shape.Slanted
            title: Translation.tr("Save paths")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: savePathsCardContent.implicitHeight + 28

                ColumnLayout {
                    id: savePathsCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigTextArea {
                        id: videoRecordPathField
                        Layout.fillWidth: true
                        fieldWidth: 250
                        buttonIcon: "video_file"
                        text: Translation.tr("Video Recording Path")
                        value: Config.options.screenRecord.savePath
                        onValueChanged: {
                            videoRecordPathDebounceTimer.restart();
                        }

                        Timer {
                            id: videoRecordPathDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.screenRecord.savePath = videoRecordPathField.value;
                            }
                        }
                    }

                    ConfigTextArea {
                        id: screenshotPathField
                        Layout.fillWidth: true
                        fieldWidth: 250
                        buttonIcon: "screenshot_monitor"
                        text: Translation.tr("Screenshot Path (leave empty to just copy)")
                        value: Config.options.screenSnip.savePath
                        onValueChanged: {
                            screenshotPathDebounceTimer.restart();
                        }

                        Timer {
                            id: screenshotPathDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.screenSnip.savePath = screenshotPathField.value;
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "notifications"
            shape: MaterialShape.Shape.Superellipse
            title: Translation.tr("Notifications & Audio")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: notifCardContent.implicitHeight + 28

                ColumnLayout {
                    id: notifCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Play sound on new notifications")
                        checked: Config.options.sounds.notifications
                        onCheckedChanged: {
                            Config.options.sounds.notifications = checked;
                        }
                    }

                    // Volume Stepper Row with Minus/Plus and Live Preview
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("Notification Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.notificationVolume ?? 70) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        // Minus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.notificationVolume ?? 70;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.notificationVolume = nextVal;
                                page.playSound(Config.options.sounds.notificationSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/message.oga", "notification");
                            }
                        }

                        // Plus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.notificationVolume ?? 70;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.notificationVolume = nextVal;
                                page.playSound(Config.options.sounds.notificationSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/message.oga", "notification");
                            }
                        }
                    }

                    ConfigTextArea {
                        id: notifSoundPathField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "music_note"
                        text: Translation.tr("Notification Sound Path")
                        value: Config.options.sounds.notificationSoundPath
                        onValueChanged: notifSoundPathDebounceTimer.restart()

                        Timer {
                            id: notifSoundPathDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.sounds.notificationSoundPath = notifSoundPathField.value;
                            }
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(notifSoundPathField.value, Config.options.sounds.notificationVolume ?? 70, "/usr/share/sounds/freedesktop/stereo/message.oga", "notification")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Notification Sound");
                                audioFileDialog.targetField = notifSoundPathField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.notificationSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "alarm"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Alarm & Timer Sounds")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: alarmSoundCardContent.implicitHeight + 28

                ColumnLayout {
                    id: alarmSoundCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "alarm"
                        text: Translation.tr("Play audio sound when alarm triggers")
                        checked: Config.options.sounds.alarm ?? true
                        onCheckedChanged: {
                            Config.options.sounds.alarm = checked;
                        }
                    }

                    // Alarm Volume Stepper Row with Minus/Plus and Live Preview
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("Alarm Sound Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.alarmVolume ?? 80) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        // Minus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.alarmVolume ?? 80;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.alarmVolume = nextVal;
                                page.playSound(Config.options.sounds.alarmSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga", "alarm");
                            }
                        }

                        // Plus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.alarmVolume ?? 80;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.alarmVolume = nextVal;
                                page.playSound(Config.options.sounds.alarmSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga", "alarm");
                            }
                        }
                    }

                    ConfigTextArea {
                        id: alarmSoundPathField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "music_note"
                        text: Translation.tr("Alarm Sound Path")
                        value: Config.options.sounds.alarmSoundPath ?? ""
                        onValueChanged: alarmSoundPathDebounceTimer.restart()

                        Timer {
                            id: alarmSoundPathDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.sounds.alarmSoundPath = alarmSoundPathField.value;
                            }
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(alarmSoundPathField.value, Config.options.sounds.alarmVolume ?? 80, "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga", "alarm")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Alarm Sound");
                                audioFileDialog.targetField = alarmSoundPathField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.alarmSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // ── Pomodoro Sound Row ──
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colLayer0Border }

                    ConfigSwitch {
                        buttonIcon: "timer"
                        text: Translation.tr("Play sounds on Pomodoro transitions")
                        checked: Config.options.sounds.pomodoro ?? true
                        onCheckedChanged: {
                            Config.options.sounds.pomodoro = checked;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("Pomodoro Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.pomodoroVolume ?? 80) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.pomodoroVolume ?? 80;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.pomodoroVolume = nextVal;
                                page.playSound(Config.options.sounds.pomodoroSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/complete.oga", "pomodoro");
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.pomodoroVolume ?? 80;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.pomodoroVolume = nextVal;
                                page.playSound(Config.options.sounds.pomodoroSoundPath, nextVal, "/usr/share/sounds/freedesktop/stereo/complete.oga", "pomodoro");
                            }
                        }
                    }

                    ConfigTextArea {
                        id: pomodoroSoundPathField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "music_note"
                        text: Translation.tr("Pomodoro Sound Path")
                        value: Config.options.sounds.pomodoroSoundPath ?? ""
                        onValueChanged: pomodoroSoundPathDebounceTimer.restart()

                        Timer {
                            id: pomodoroSoundPathDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.sounds.pomodoroSoundPath = pomodoroSoundPathField.value;
                            }
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(pomodoroSoundPathField.value, Config.options.sounds.pomodoroVolume ?? 80, "/usr/share/sounds/freedesktop/stereo/complete.oga", "pomodoro")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Pomodoro Sound");
                                audioFileDialog.targetField = pomodoroSoundPathField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.pomodoroSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "power_settings_new"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("System Event Sounds")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: systemSoundCardContent.implicitHeight + 28

                ColumnLayout {
                    id: systemSoundCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Play sounds on system events (Shutdown, Lock, Sleep, Logout)")
                        checked: Config.options.sounds.enableSystemSounds ?? true
                        onCheckedChanged: {
                            Config.options.sounds.enableSystemSounds = checked;
                        }
                    }

                    // System Volume Stepper Row with Minus/Plus and Live Preview
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("System Sound Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.systemSoundVolume ?? 70) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        // Minus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.systemSoundVolume ?? 70;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.systemSoundVolume = nextVal;
                                page.playSound(Config.options.sounds.shutdownSoundPath, nextVal, `${Directories.soundsPath}/shutdown_sound.flac`, "shutdown");
                            }
                        }

                        // Plus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.systemSoundVolume ?? 70;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.systemSoundVolume = nextVal;
                                page.playSound(Config.options.sounds.shutdownSoundPath, nextVal, `${Directories.soundsPath}/shutdown_sound.flac`, "shutdown");
                            }
                        }
                    }

                    // Startup & Login Greeting Sound
                    ConfigSwitch {
                        buttonIcon: "wb_sunny"
                        text: Translation.tr("Play greeting on login / startup")
                        checked: Config.options.sounds.enableStartupSound ?? true
                        onCheckedChanged: {
                            Config.options.sounds.enableStartupSound = checked;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 8
                        MaterialSymbol {
                            text: "shuffle"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Randomize Greetings: Pointing to a directory automatically plays a random greeting on each startup.")
                            color: Appearance.colors.colOnSecondaryContainer
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }

                    ConfigTextArea {
                        id: startupSoundField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "wb_sunny"
                        text: Translation.tr("Startup Audio / Greeting Folder")
                        value: Config.options.sounds.startupSoundPath
                        placeholderText: Translation.tr("Single audio file or directory of rotating greetings")
                        onValueChanged: {
                            Config.options.sounds.startupSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: {
                                let p = startupSoundField.value || "";
                                let defDir = `${Directories.soundsPath}/login_greetings`;
                                let sDir = (Directories.scriptPath || "").toString().replace(/^file:\/\//, "");
                                let script = `p="${p}"; if [ -z "$p" ] || [ ! -e "$p" ]; then p="${defDir}"; fi; if [ -d "$p" ]; then file=$(find "$p" -maxdepth 1 -type f \\( -name "*.flac" -o -name "*.wav" -o -name "*.mp3" -o -name "*.ogg" -o -name "*.oga" \\) 2>/dev/null | shuf -n 1); else file="$p"; fi; if [ -n "$file" ] && [ -f "$file" ]; then bash "${sDir}/play-audio.sh" --file "$file" --volume "${Config.options.sounds.systemSoundVolume ?? 70}" --category "login_greetings"; fi`;
                                Quickshell.execDetached(["bash", "-c", script]);
                            }
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Startup Sound or Folder");
                                audioFileDialog.targetField = startupSoundField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.startupSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Shutdown & Reboot Sound
                    ConfigTextArea {
                        id: shutdownSoundField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "power_settings_new"
                        text: Translation.tr("Shutdown & Reboot Sound")
                        value: Config.options.sounds.shutdownSoundPath
                        placeholderText: Translation.tr("Path to shutdown sound file (.flac, .mp3, .wav)")
                        onValueChanged: {
                            Config.options.sounds.shutdownSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(shutdownSoundField.value, Config.options.sounds.systemSoundVolume ?? 70, `${Directories.soundsPath}/shutdown_sound.flac`, "shutdown")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Shutdown / Reboot Sound");
                                audioFileDialog.targetField = shutdownSoundField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.shutdownSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Lock Screen Sound
                    ConfigTextArea {
                        id: lockSoundField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "lock"
                        text: Translation.tr("Lock Screen Sound")
                        value: Config.options.sounds.lockSoundPath
                        placeholderText: Translation.tr("Path to lock sound file (leave empty for default)")
                        onValueChanged: {
                            Config.options.sounds.lockSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(lockSoundField.value, Config.options.sounds.systemSoundVolume ?? 70, "/usr/share/sounds/freedesktop/stereo/service-logout.oga", "lock")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Lock Screen Sound");
                                audioFileDialog.targetField = lockSoundField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.lockSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Logout Sound
                    ConfigTextArea {
                        id: logoutSoundField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "logout"
                        text: Translation.tr("Logout Sound")
                        value: Config.options.sounds.logoutSoundPath
                        placeholderText: Translation.tr("Path to logout sound file (leave empty for default)")
                        onValueChanged: {
                            Config.options.sounds.logoutSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(logoutSoundField.value, Config.options.sounds.systemSoundVolume ?? 70, "/usr/share/sounds/freedesktop/stereo/service-logout.oga", "logout")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Logout Sound");
                                audioFileDialog.targetField = logoutSoundField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.logoutSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Sleep / Suspend Sound
                    ConfigTextArea {
                        id: sleepSoundField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "bedtime"
                        text: Translation.tr("Sleep & Suspend Sound")
                        value: Config.options.sounds.sleepSoundPath
                        placeholderText: Translation.tr("Path to sleep sound file (leave empty for default)")
                        onValueChanged: {
                            Config.options.sounds.sleepSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(sleepSoundField.value, Config.options.sounds.systemSoundVolume ?? 70, "/usr/share/sounds/freedesktop/stereo/suspend-error.oga", "sleep")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Sleep / Suspend Sound");
                                audioFileDialog.targetField = sleepSoundField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.sleepSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "battery_charging_full"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Battery & Power Sound Events")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: batterySoundCardContent.implicitHeight + 28

                ColumnLayout {
                    id: batterySoundCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Play sounds on battery & charging events")
                        checked: Config.options.sounds.battery ?? true
                        onCheckedChanged: {
                            Config.options.sounds.battery = checked;
                        }
                    }

                    // Battery Volume Stepper Row with Minus/Plus and Live Preview
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("Battery Sound Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.batterySoundVolume ?? 70) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        // Minus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.batterySoundVolume ?? 70;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.batterySoundVolume = nextVal;
                                page.playSound(chargerPluggedField.value, nextVal, "/usr/share/sounds/ocean/stereo/power-plug.oga", "charger-in");
                            }
                        }

                        // Plus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.batterySoundVolume ?? 70;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.batterySoundVolume = nextVal;
                                page.playSound(chargerPluggedField.value, nextVal, "/usr/share/sounds/ocean/stereo/power-plug.oga", "charger-in");
                            }
                        }
                    }

                    // Charger Plugged In (Charging Now)
                    ConfigTextArea {
                        id: chargerPluggedField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "power"
                        text: Translation.tr("Charging Now (Plugged In)")
                        value: Config.options.sounds.chargerPluggedSoundPath
                        placeholderText: Translation.tr("Custom audio or empty for system default (power-plug)")
                        onValueChanged: {
                            Config.options.sounds.chargerPluggedSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(chargerPluggedField.value, Config.options.sounds.batterySoundVolume ?? 70, "/usr/share/sounds/ocean/stereo/power-plug.oga", "charger-in")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Charging (Plugged In) Sound");
                                audioFileDialog.targetField = chargerPluggedField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.chargerPluggedSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Charger Unplugged (Charge Cut Off)
                    ConfigTextArea {
                        id: chargerUnpluggedField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "power_off"
                        text: Translation.tr("Charge Cut Off (Unplugged)")
                        value: Config.options.sounds.chargerUnpluggedSoundPath
                        placeholderText: Translation.tr("Custom audio or empty for system default (power-unplug)")
                        onValueChanged: {
                            Config.options.sounds.chargerUnpluggedSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(chargerUnpluggedField.value, Config.options.sounds.batterySoundVolume ?? 70, "/usr/share/sounds/ocean/stereo/power-unplug.oga", "charger-out")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Charge Cut Off (Unplugged) Sound");
                                audioFileDialog.targetField = chargerUnpluggedField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.chargerUnpluggedSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // Battery Full
                    ConfigTextArea {
                        id: batteryFullField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "battery_charging_full"
                        text: Translation.tr("Battery Full Warning")
                        value: Config.options.sounds.batteryFullSoundPath
                        placeholderText: Translation.tr("Custom audio or empty for system default (complete)")
                        onValueChanged: {
                            Config.options.sounds.batteryFullSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(batteryFullField.value, Config.options.sounds.batterySoundVolume ?? 70, "/usr/share/sounds/freedesktop/stereo/complete.oga", "battery-full")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select Battery Full Warning Sound");
                                audioFileDialog.targetField = batteryFullField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.batteryFullSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "usb"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("USB Device Sound Events")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: usbCardContent.implicitHeight + 28

                ColumnLayout {
                    id: usbCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Play sounds on USB device connect / disconnect")
                        checked: Config.options.sounds.enableUsbSounds ?? true
                        onCheckedChanged: {
                            Config.options.sounds.enableUsbSounds = checked;
                        }
                    }

                    // USB Volume Stepper Row with Minus/Plus and Live Preview
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 10

                        OptionalMaterialSymbol {
                            icon: "volume_up"
                            iconSize: Appearance.font.pixelSize.larger
                        }

                        StyledText {
                            text: Translation.tr("USB Sound Volume")
                            color: Appearance.colors.colOnSecondaryContainer
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (Config.options.sounds.usbSoundVolume ?? 70) + "%"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 45
                            horizontalAlignment: Text.AlignRight
                        }

                        // Minus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "remove"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.usbSoundVolume ?? 70;
                                let nextVal = Math.max(0, current - 10);
                                Config.options.sounds.usbSoundVolume = nextVal;
                                page.playSound(usbPlugInField.value, nextVal, `${Directories.soundsPath}/usb-in.flac`, "usb-in");
                            }
                        }

                        // Plus Button
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSurfaceContainerHigh
                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighest
                            colRipple: Appearance.colors.colPrimary
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colOnSurface
                            }
                            onClicked: {
                                let current = Config.options.sounds.usbSoundVolume ?? 70;
                                let nextVal = Math.min(100, current + 10);
                                Config.options.sounds.usbSoundVolume = nextVal;
                                page.playSound(usbPlugInField.value, nextVal, `${Directories.soundsPath}/usb-in.flac`, "usb-in");
                            }
                        }
                    }

                    // USB Plug In
                    ConfigTextArea {
                        id: usbPlugInField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "usb"
                        text: Translation.tr("USB Plug In Sound")
                        value: Config.options.sounds.usbPlugInSoundPath
                        placeholderText: Translation.tr("Path to USB connect audio file")
                        onValueChanged: {
                            Config.options.sounds.usbPlugInSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(usbPlugInField.value, Config.options.sounds.usbSoundVolume ?? 70, `${Directories.soundsPath}/usb-in.flac`, "usb-in")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select USB Plug In Sound");
                                audioFileDialog.targetField = usbPlugInField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.usbPlugInSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }

                    // USB Plug Out
                    ConfigTextArea {
                        id: usbPlugOutField
                        Layout.fillWidth: true
                        fieldWidth: 175
                        buttonIcon: "usb_off"
                        text: Translation.tr("USB Plug Out Sound")
                        value: Config.options.sounds.usbPlugOutSoundPath
                        placeholderText: Translation.tr("Path to USB disconnect audio file")
                        onValueChanged: {
                            Config.options.sounds.usbPlugOutSoundPath = value;
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "play_arrow"
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: page.playSound(usbPlugOutField.value, Config.options.sounds.usbSoundVolume ?? 70, `${Directories.soundsPath}/usb-out.flac`, "usb-out")
                        }

                        GroupButton {
                            baseWidth: height
                            buttonRadius: Appearance.rounding.small
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: Appearance.font.pixelSize.larger
                                text: "folder_open"
                                color: Appearance.colors.colOnLayer1
                            }
                            onClicked: {
                                audioFileDialog.title = Translation.tr("Select USB Plug Out Sound");
                                audioFileDialog.targetField = usbPlugOutField;
                                audioFileDialog.targetCallback = (p) => { Config.options.sounds.usbPlugOutSoundPath = p; };
                                audioFileDialog.open();
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "search"
            shape: MaterialShape.Shape.Cookie6Sided
            title: Translation.tr("Search")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: searchCardContent.implicitHeight + 28

                ColumnLayout {
                    id: searchCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
                        checked: Config.options.search.sloppy
                        onCheckedChanged: {
                            Config.options.search.sloppy = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Prefixes")

                Rectangle {
                    Layout.fillWidth: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    implicitHeight: prefixesCardContent.implicitHeight + 28

                    ColumnLayout {
                        id: prefixesCardContent
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 14
                        }
                        spacing: 12

                        ConfigRow {
                            uniform: true
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "bolt"
                                fieldWidth: 100
                                text: Translation.tr("Action")
                                value: Config.options.search.prefix.action
                                onValueChanged: {
                                    Config.options.search.prefix.action = value;
                                }
                            }
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "content_paste"
                                fieldWidth: 100
                                text: Translation.tr("Clipboard")
                                value: Config.options.search.prefix.clipboard
                                onValueChanged: {
                                    Config.options.search.prefix.clipboard = value;
                                }
                            }
                        }

                        ConfigRow {
                            uniform: true
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "mood"
                                fieldWidth: 100
                                text: Translation.tr("Emojis")
                                value: Config.options.search.prefix.emojis
                                onValueChanged: {
                                    Config.options.search.prefix.emojis = value;
                                }
                            }
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "emoji_symbols"
                                fieldWidth: 100
                                text: Translation.tr("Icons")
                                value: Config.options.search.prefix.symbols
                                onValueChanged: {
                                    Config.options.search.prefix.symbols = value;
                                }
                            }
                        }

                        ConfigRow {
                            uniform: true
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "terminal"
                                fieldWidth: 100
                                text: Translation.tr("Shell command")
                                value: Config.options.search.prefix.shellCommand
                                onValueChanged: {
                                    Config.options.search.prefix.shellCommand = value;
                                }
                            }
                            ConfigTextArea {
                                Layout.fillWidth: true
                                fieldWidth: 100
                                buttonIcon: "travel_explore"
                                text: Translation.tr("Web search")
                                value: Config.options.search.prefix.webSearch
                                onValueChanged: {
                                    Config.options.search.prefix.webSearch = value;
                                }
                            }
                        }

                        ConfigRow {
                            uniform: true
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "apps"
                                fieldWidth: 100
                                text: Translation.tr("Apps")
                                value: Config.options.search.prefix.app
                                onValueChanged: {
                                    Config.options.search.prefix.app = value;
                                }
                            }
                            ConfigTextArea {
                                Layout.fillWidth: true
                                buttonIcon: "keyboard_command_key"
                                fieldWidth: 100
                                text: Translation.tr("Keybinds")
                                value: Config.options.search.prefix.keybinds
                                onValueChanged: {
                                    Config.options.search.prefix.keybinds = value;
                                }
                            }
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Web search")

                Rectangle {
                    Layout.fillWidth: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    implicitHeight: webSearchCardContent.implicitHeight + 28

                    ColumnLayout {
                        id: webSearchCardContent
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 14
                        }
                        spacing: 12

                        ConfigTextArea {
                            id: baseUrlField
                            Layout.fillWidth: true
                            fieldWidth: 320
                            buttonIcon: "travel_explore"
                            text: Translation.tr("Base URL")
                            value: Config.options.search.engineBaseUrl
                            onValueChanged: {
                                baseUrlDebounceTimer.restart();
                            }

                            Timer {
                                id: baseUrlDebounceTimer
                                interval: 600
                                repeat: false
                                onTriggered: {
                                    Config.options.search.engineBaseUrl = baseUrlField.value;
                                }
                            }
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "deployed_code_update"
            title: Translation.tr("System updates (Arch only)")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: updatesCardContent.implicitHeight + 28

                ColumnLayout {
                    id: updatesCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "update"
                        text: Translation.tr("Enable update checks")
                        checked: Config.options.updates.enableCheck
                        onCheckedChanged: {
                            Config.options.updates.enableCheck = checked;
                        }
                    }

                    ConfigSpinBox {
                        icon: "av_timer"
                        text: Translation.tr("Check interval (mins)")
                        value: Config.options.updates.checkInterval
                        from: 60
                        to: 1440
                        stepSize: 60
                        onValueChanged: {
                            Config.options.updates.checkInterval = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "weather_mix"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Weather")

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                implicitHeight: weatherCardContent.implicitHeight + 28

                ColumnLayout {
                    id: weatherCardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    ConfigSwitch {
                        buttonIcon: "assistant_navigation"
                        text: Translation.tr("Enable GPS based location")
                        checked: Config.options.bar.weather.enableGPS
                        onCheckedChanged: {
                            Config.options.bar.weather.enableGPS = checked;
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "thermometer"
                        text: Translation.tr("Fahrenheit unit")
                        checked: Config.options.bar.weather.useUSCS
                        onCheckedChanged: {
                            Config.options.bar.weather.useUSCS = checked;
                        }
                    }
                    ConfigSpinBox {
                        icon: "av_timer"
                        text: Translation.tr("Polling interval (m)")
                        value: Config.options.bar.weather.fetchInterval
                        from: 5
                        to: 50
                        stepSize: 5
                        onValueChanged: {
                            Config.options.bar.weather.fetchInterval = value;
                        }
                    }
                    ConfigTextArea {
                        id: cityField
                        Layout.fillWidth: true
                        buttonIcon: "location_city"
                        text: Translation.tr("City name")
                        value: Config.options.bar.weather.city
                        onValueChanged: cityDebounceTimer.restart()

                        Timer {
                            id: cityDebounceTimer
                            interval: 1000
                            running: false
                            onTriggered: Config.options.bar.weather.city = cityField.value
                        }
                    }
                }
            }
        }
        WorldMap {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
        }
    }
}
