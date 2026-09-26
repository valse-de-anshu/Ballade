import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "userCard"
    hoverEnabled: true

    readonly property string bannerPath: {
        if (Config.options?.sidebar?.bannerImage && Config.options.sidebar.bannerImage !== "")
            return Config.options.sidebar.bannerImage;
        return (Config.options?.background?.wallpaperPath) ? Config.options.background.wallpaperPath : "";
    }
    readonly property bool bannerIsVideo: Boolean(bannerPath) && /\.(mp4|webm|mkv|avi|mov)$/i.test(bannerPath)

    readonly property real snapWidth3: 276
    readonly property real snapWidth4: 420
    readonly property real snapHeight3: 252

    property string sizeMode: (root.configEntry && root.configEntry.sizeMode === "2x3") ? "2x3" : "2x2"

    property real widgetWidth: root.sizeMode === "2x3" ? snapWidth4 : snapWidth3
    property real widgetHeight: snapHeight3

    function modeForDimensions(w, _h) {
        const threshold = root.sizeMode === "2x3" ? 335 : 365
        return w >= threshold ? "2x3" : "2x2"
    }

    property int avatarSize: 64
    property int blurMargin: 18
    property string hostname: SystemInfo.hostname
    property string username: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
    property string userDisplay: username.length > 10 ? username : (username + "@" + hostname)
    property var currentQuip: weatherQuip()

    function weatherQuip() {
        const desc = (Weather.data && Weather.data.description ? Weather.data.description : "").toLowerCase();
        const temp = (Weather.data && Weather.data.temp) ? Weather.data.temp : "--";
        if (desc.includes("rain"))
            return { text: `• raining, grab a coffee`, icon: "coffee" };
        if (desc.includes("clear"))
            return { text: `• good day to touch grass`, icon: "eco" };
        if (desc.includes("cloud"))
            return { text: `• a bit cloudy today`, icon: "cloud" };
        if (desc.includes("snow"))
            return { text: `• snowing`, icon: "ac_unit" };
        const weatherDesc = (Weather.data && Weather.data.description) ? Weather.data.description : "";
        return { text: `• ${weatherDesc}`, icon: "thermostat" };
    }

    function greetingFor(hour) {
        if (hour < 12) return "Good Morning"
        if (hour < 18) return "Good Afternoon"
        return "Good Evening"
    }

    readonly property string greetingText: greetingFor(DateTime.hour24)
    readonly property string todayString: "Today • " + DateTime.clock.date.toLocaleDateString(Qt.locale(), "dddd d MMM")

    readonly property string welcomingMessage: {
        const custom = (Config.options.background.widgets.userCard && Config.options.background.widgets.userCard.customText)
            ? Config.options.background.widgets.userCard.customText.trim()
            : ""
        if (custom.length > 0) return custom
        const hour = DateTime.hour24
        if (hour >= 18 || hour < 4) return "Welcome home darling, you worked so hard today ♡"
        if (hour >= 12) return "Welcome back honey! Come relax, I missed you ♡"
        return "Good morning my love! Have a wonderful day ahead ♡"
    }

    implicitWidth:  card.implicitWidth
    implicitHeight: card.implicitHeight

    Behavior on widgetWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    component AvatarImage: Image {
        source: Config.options.profile.avatarPath !== ""
            ? "file://" + Config.options.profile.avatarPicture
            : "file:///home/" + (Quickshell.env("USER") ? Quickshell.env("USER") : "user") + "/.face"
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: if (status === Image.Error) visible = false
    }

    Rectangle {
        id: card
        implicitWidth: root.widgetWidth
        implicitHeight: root.widgetHeight
        radius: (Appearance.rounding && Appearance.rounding.verylarge) ? Appearance.rounding.verylarge : 30
        color: "transparent"

        Loader {
            anchors.fill: parent
            sourceComponent: root.sizeMode === "2x3" ? twoByThreeContent : twoByTwoContent
        }

        // 2x2 (original design)
        Component {
            id: twoByTwoContent
            Item {
                id: outerRect
                implicitWidth: root.snapWidth3
                implicitHeight: root.snapHeight3

                Item {
                    id: bgImage
                    anchors.fill: parent
                    visible: false

                    // Only feeds the FastBlur used when widget blur is off
                    property string effectiveSource: Config.options.background.widgets.blurWidgets ? "" : "file://" + (GlobalStates.screenLocked && Config.options.background.lockWall !== ""
                        ? Config.options.background.lockWall
                        : Config.options.background.wallpaperPath)

                    Image {
                        id: bgImageA
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(root.snapWidth3, root.snapHeight3)
                        asynchronous: true
                        cache: false
                        opacity: 1
                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                        }
                    }
                    Image {
                        id: bgImageB
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(root.snapWidth3, root.snapHeight3)
                        asynchronous: true
                        cache: false
                        opacity: 0
                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                        }
                    }

                    property bool usingA: true

                    onEffectiveSourceChanged: {
                        if (usingA) {
                            bgImageB.source = effectiveSource
                            bgImageB.opacity = 1
                            bgImageA.opacity = 0
                        } else {
                            bgImageA.source = effectiveSource
                            bgImageA.opacity = 1
                            bgImageB.opacity = 0
                        }
                        usingA = !usingA
                    }

                    Component.onCompleted: {
                        bgImageA.source = effectiveSource
                    }
                }

                FastBlur {
                    id: blurredBg
                    anchors.fill: bgImage
                    visible: !Config.options.background.widgets.blurWidgets 
                    source: bgImage
                    radius: 48
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: outerRect.width
                            height: outerRect.height
                            radius: (Appearance.rounding && Appearance.rounding.verylarge) ? Appearance.rounding.verylarge : 30
                        }
                    }

                }

                Rectangle {
                    anchors.fill: blurredBg
                    radius: (Appearance.rounding && Appearance.rounding.verylarge) ? Appearance.rounding.verylarge : 30
                    color: Appearance.colors.colScrim
                    opacity: 0.1
                }

                Rectangle {
                    id: contentBox
                    x: root.blurMargin
                    y: root.avatarSize / 2 + root.blurMargin + 30
                    width: 240
                    color: Appearance.colors.colPrimaryContainer
                    radius: Appearance.rounding.large
                    implicitHeight: contentColumn.implicitHeight + 30

                    ColumnLayout {
                        id: contentColumn
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 16
                        }
                        Layout.topMargin: root.avatarSize / 2 + 4
                        spacing: 10

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.avatarSize / 2
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2
                                iconSize: Appearance.font.pixelSize.normal
                                text: root.currentQuip.icon
                                color: Appearance.colors.colOnPrimaryContainer
                                opacity: 0.85
                            }

                            StyledText {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnPrimaryContainer
                                opacity: 0.85
                                text: root.currentQuip.text
                            }
                        } 

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colOnPrimaryContainer

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        iconSize: Appearance.font.pixelSize.normal
                                        text: "lock"
                                        color: Appearance.colors.colPrimaryContainer
                                    }
                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colPrimaryContainer
                                        text: GlobalStates.screenLocked ? "Locked" : "Lock"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.screenLocked = true
                                }
                            }

                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: 20
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.colors.colOnPrimaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: Appearance.font.pixelSize.normal
                                    text: "settings"
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.settingsOpen = true
                                }
                            }

                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 40
                                radius: 20
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.colors.colOnPrimaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: Appearance.font.pixelSize.normal
                                    text: "power_settings_new"
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.sessionOpen = true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: avatarRect
                    x: root.blurMargin + 16
                    y: contentBox.y - root.avatarSize / 2
                    width: root.avatarSize + 10
                    height: root.avatarSize + 10
                    radius: width / 2
                    color: Appearance.colors.colPrimaryContainer
                    border.width: 3
                    border.color: Appearance.colors.colLayer1
                    z: 2

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        anchors.margins: 3
                        source: Config.options.profile.avatarPath !== ""
                            ? "file://" + Config.options.profile.avatarPicture
                            : "file:///home/" + (Quickshell.env("USER") ? Quickshell.env("USER") : "user") + "/.face"
                        sourceSize.width: avatarImage.width * 2
                        sourceSize.height: avatarImage.height * 2
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: avatarRect.width - 6
                                height: avatarRect.height - 6
                                radius: (avatarRect.width - 6) / 2
                            }
                        }
                        onStatusChanged: {
                            if (status === Image.Error)
                                visible = false
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "account_circle"
                        iconSize: 32
                        color: Appearance.colors.colOnPrimaryContainer
                        visible: avatarImage.status === Image.Error
                    }
                }

                ColumnLayout {
                    x: avatarRect.x + avatarRect.width + 13
                    y: avatarRect.y + (avatarRect.height - implicitHeight) / 2 + 20
                    spacing: 0
                    z: 2
                    width: outerRect.width - x - root.blurMargin

                    StyledText {
                        Layout.fillWidth: true
                        text: root.userDisplay
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: "Up • " + DateTime.uptime
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        opacity: 0.6
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // 2x3
        Component {
            id: twoByThreeContent
            Item {
                id: outerRect3
                implicitWidth: root.snapWidth4
                implicitHeight: root.snapHeight3

                Rectangle {
                    id: cardBg
                    anchors.fill: parent
                    radius: (Appearance.rounding && Appearance.rounding.verylarge) ? Appearance.rounding.verylarge : 30
                    color: Qt.rgba(
                        Appearance.colors.colLayer0Base.r,
                        Appearance.colors.colLayer0Base.g,
                        Appearance.colors.colLayer0Base.b,
                        0.12
                    )
                    border.width: 0
                    border.color: "transparent"
                    clip: true

                    Item {
                        id: heroWrap
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: cardBg.height * 0.62
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: heroWrap.width
                                height: heroWrap.height
                                topLeftRadius: cardBg.radius
                                topRightRadius: cardBg.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#ffffff" }
                                    GradientStop { position: 0.55; color: "#ffffff" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }

                        StyledImage {
                            anchors.fill: parent
                            source: root.bannerIsVideo
                                ? Images.getStaticWallpaperImage(root.bannerPath, Config.options.background.thumbnailPath)
                                : root.bannerPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize: Qt.size(root.snapWidth4, heroWrap.height)
                        }

                        MediaPlayer {
                            id: cardVideoPlayer
                            source: root.bannerIsVideo ? (root.bannerPath.startsWith("file://") ? root.bannerPath : "file://" + root.bannerPath) : ""
                            videoOutput: cardVideoOutput
                            loops: MediaPlayer.Infinite
                            audioOutput: null

                            readonly property bool shouldPlay: root.bannerIsVideo && !GlobalStates.screenLocked && !(ToplevelManager?.activeToplevel?.fullscreen ?? false)

                            function updatePlayback() {
                                if (shouldPlay) play(); else pause();
                            }

                            Component.onCompleted: updatePlayback()
                            onMediaStatusChanged: {
                                if ((mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) && shouldPlay) {
                                    play();
                                }
                            }
                            onSourceChanged: {
                                if (source.toString() !== "" && shouldPlay) {
                                    play();
                                }
                            }
                        }

                        Connections {
                            target: GlobalStates
                            function onScreenLockedChanged() {
                                cardVideoPlayer.updatePlayback();
                            }
                        }

                        Connections {
                            target: ToplevelManager
                            function onActiveToplevelChanged() {
                                cardVideoPlayer.updatePlayback();
                            }
                        }

                        Connections {
                            target: root
                            function onBannerIsVideoChanged() {
                                cardVideoPlayer.updatePlayback();
                            }
                            function onBannerPathChanged() {
                                cardVideoPlayer.updatePlayback();
                            }
                        }

                        VideoOutput {
                            id: cardVideoOutput
                            anchors.fill: parent
                            fillMode: VideoOutput.PreserveAspectCrop
                            visible: root.bannerIsVideo
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.RightButton
                            onClicked: (event) => {
                                if (event.button === Qt.RightButton) {
                                    Config.options.sidebar.bannerImage = "";
                                }
                            }
                        }
                    }

                    // Tr settings button
                    Rectangle {
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 12
                        }
                        width: 34
                        height: 34
                        radius: width / 2
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.15)
                        z: 3

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "settings"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer0
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.settingsOpen = true
                        }
                    }

                    // Avatar overlapping
                    Rectangle {
                        id: avatarRect3
                        x: 16
                        y: heroWrap.height - 70
                        width: root.avatarSize + 10
                        height: root.avatarSize + 10
                        radius: width / 2
                        color: Appearance.colors.colPrimaryContainer
                        border.width: 3
                        border.color: Appearance.colors.colLayer1
                        z: 2

                        Image {
                            id: avatarImage3
                            anchors.fill: parent
                            anchors.margins: 3
                            source: Config.options.profile.avatarPath !== ""
                                ? "file://" + Config.options.profile.avatarPicture
                                : "file:///home/" + (Quickshell.env("USER") ? Quickshell.env("USER") : "user") + "/.face"
                            sourceSize.width: avatarImage3.width * 2
                            sourceSize.height: avatarImage3.height * 2
                            fillMode: Image.PreserveAspectCrop
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: avatarRect3.width - 6
                                    height: avatarRect3.height - 6
                                    radius: (avatarRect3.width - 6) / 2
                                }
                            }
                            onStatusChanged: if (status === Image.Error) visible = false
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "account_circle"
                            iconSize: 32
                            color: Appearance.colors.colOnPrimaryContainer
                            visible: avatarImage3.status === Image.Error
                        }
                    }

                    // Labels + stats + lock/power
                    ColumnLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: avatarRect3.bottom
                            bottom: parent.bottom
                            leftMargin: 16
                            rightMargin: 22
                            topMargin: 6
                            bottomMargin: 14
                        }
                        spacing: 3

                        StyledText {
                            Layout.fillWidth: true
                            Layout.topMargin: -6
                            Layout.leftMargin: 4
                            text: root.userDisplay
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 8

                                MaterialSymbol {
                                    text: "favorite"
                                    iconSize: 18
                                    color: Appearance.colors.colPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: root.welcomingMessage
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.italic: true
                                    color: Appearance.colors.colOnPrimaryContainer
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 90
                                implicitHeight: 36
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colOnPrimaryContainer

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        iconSize: Appearance.font.pixelSize.normal
                                        text: "lock"
                                        color: Appearance.colors.colPrimaryContainer
                                    }
                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colPrimaryContainer
                                        text: GlobalStates.screenLocked ? "Locked" : "Lock"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.screenLocked = true
                                }
                            }

                            Rectangle {
                                implicitWidth: 36
                                implicitHeight: 36
                                radius: 18
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.colors.colOnPrimaryContainer

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: Appearance.font.pixelSize.normal
                                    text: "power_settings_new"
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalStates.sessionOpen = true
                                }
                            }
                        }
                    }
                }
            }
        }

        ResizeHandler {
            anchorItem: card
            hoverActive: root.containsMouse
            locked: Config.options.background.widgetsLocked
            currentWidth: root.widgetWidth
            currentHeight: root.widgetHeight
            resizeMode: "horizontal"
            onResized: (newW) => {
                root.sizeMode = root.modeForDimensions(newW, root.widgetHeight)
            }
            onResizeFinished: {
                if (root.configEntry) {
                    root.configEntry.sizeMode = root.sizeMode
                }
            }
        }
    }
}