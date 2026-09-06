import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.ii.settings.pages
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Item {
    id: root
    property real contentPadding: 8
    property int currentPage: 0
    property bool showingProfile: false

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return
            
            let parts = GlobalStates.settingsPage.split(":");
            let pageName = parts[0].toLowerCase();
            let searchTerm = parts.length > 1 ? parts[1] : "";

            // Aliases for backward compatibility
            if (pageName === "desktop" || pageName === "wallpaper" || pageName === "background") pageName = "appearance";
            if (pageName === "lock" || pageName === "lockscreen") pageName = "lock screen";
            if (pageName === "sound" || pageName === "audio") pageName = "sounds";
            if (pageName === "overlay" || pageName === "crosshair" || pageName === "snip") pageName = "utilities";
            if (pageName === "custom widgets") pageName = "widgets";

            const idx = root.pages.findIndex(p => p.name.toLowerCase() === pageName);
            
            if (idx >= 0) {
                root.currentPage = idx;
                root.showingProfile = false;
                
                if (searchTerm !== "") {
                    let loader = pagesRepeater.itemAt(idx);
                    if (loader && loader.item && typeof loader.item.goTo === "function") {
                        loader.item.goTo(searchTerm);
                    } else if (loader) {
                        loader.onLoaded.connect(function() {
                            if (loader.item && typeof loader.item.goTo === "function") {
                                loader.item.goTo(searchTerm);
                            }
                        });
                    }
                }
            }
            GlobalStates.settingsPage = "";
        }
    }

    onCurrentPageChanged: {
        const page = (root.pages && root.pages[currentPage]) ? root.pages[currentPage] : null;
        const pageName = (page && page.name) ? page.name : "";
        if (pageName === Translation.tr("About")) {
            if (SystemInfo.cpu === "") SystemInfo.refresh()
            Updates.refresh()
        }
    }
    
    property var pages: {
        let list = [
            { name: Translation.tr("Quick"),        icon: "instant_mix",        component: Qt.resolvedUrl("pages/QuickConfig.qml") },
            { name: Translation.tr("Appearance"),   icon: "palette",            component: Qt.resolvedUrl("pages/AppearanceConfig.qml") },
            { name: Translation.tr("Bar"),          icon: "toast",              iconRotation: 180, component: Qt.resolvedUrl("pages/BarConfig.qml") },
            { name: Translation.tr("Interface"),    icon: "bottom_app_bar",     component: Qt.resolvedUrl("pages/InterfaceConfig.qml") },
            { name: Translation.tr("Lock Screen"),  icon: "lock",               component: Qt.resolvedUrl("pages/LockConfig.qml") },
            { name: Translation.tr("Widgets"),      icon: "widgets",            component: Qt.resolvedUrl("pages/WidgetsConfig.qml") },
            { name: Translation.tr("Utilities"),    icon: "screenshot_frame_2", component: Qt.resolvedUrl("pages/UtilitiesConfig.qml") },
            { name: Translation.tr("Sounds"),       icon: "volume_up",          component: Qt.resolvedUrl("pages/SoundsConfig.qml") },
            { name: Translation.tr("Services"),     icon: "hub",                component: Qt.resolvedUrl("pages/ServicesConfig.qml") },
            { name: Translation.tr("General"),      icon: "tune",               component: Qt.resolvedUrl("pages/GeneralConfig.qml") },
        ]
        if (WM.compositor === "hyprland") {
            list.push({ name: Translation.tr("Hyprland"), icon: "select_window_2", component: Qt.resolvedUrl("pages/HyprlandConfig.qml") })
        }
        if (WM.compositor === "niri") {
            list.push({ name: Translation.tr("Niri"), icon: "select_window_2", component: Qt.resolvedUrl("pages/NiriConfig.qml") })
        }
        list.push({ name: Translation.tr("About"), icon: "info", component: Qt.resolvedUrl("pages/About.qml") })
        return list
    }

    Component.onCompleted: {
        Config.readWriteDelay = 0
        Qt.callLater(() => {
            for (let i = 0; i < root.pages.length; i++) {
                let loader = pagesRepeater.itemAt(i)
                if (loader) loader.active = true
            }
            if (profileLoader) profileLoader.active = true
        })
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: contentPadding
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: contentPadding

            Rectangle {
                id: navRailWrapper
                Layout.fillHeight: true
                Layout.margins: 0
                implicitWidth: navRail.expanded ? 225 : fab.baseSize
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 20 }
                    spacing: 10
                    expanded: root.width > 900

                    Item {
                        visible: navRail.expanded
                        Layout.fillWidth: true
                        Layout.margins: 5
                        Layout.topMargin: 15
                        implicitHeight: 48 // matches avatarRect height

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                id: avatarRect
                                width: 48
                                height: 48
                                radius: width / 2
                                color: Appearance.colors.colPrimaryContainer

                                Image {
                                    id: avatarImage
                                    anchors.fill: parent
                                    source: {
                                        const pic = Config.options.profile.avatarPicture
                                        if (pic && pic.length > 0) return pic.startsWith("file://") ? pic : ("file://" + pic)
                                        const p = Config.options.profile.avatarPath
                                        if (p && p.length > 0 && /\.(png|jpg|jpeg|webp|svg)$/i.test(p)) return p.startsWith("file://") ? p : ("file://" + p)
                                        return "file:///home/" + (Quickshell.env("USER") ?? "user") + "/.face"
                                    }
                                    sourceSize.width: avatarImage.width * 2
                                    sourceSize.height: avatarImage.height * 2
                                    fillMode: Image.PreserveAspectCrop
                                    visible: avatarImage.status === Image.Ready
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: avatarRect.width
                                            height: avatarRect.height
                                            radius: avatarRect.radius
                                        }
                                    }
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "account_circle"
                                    iconSize: 32
                                    color: Appearance.colors.colOnPrimaryContainer
                                    visible: avatarImage.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                StyledText {
                                    text: Config.options.profile.displayName === "" ? SystemInfo.username : Config.options.profile.displayName
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 140
                                }

                                StyledText {
                                    id: distroText
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 140

                                    text: {
                                        const d = Config.options.profile.descriptionText
                                        if (d === "::uptime::") return Translation.tr("Up • %1").arg(DateTime.uptime)
                                        return SystemInfo.distroName
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showingProfile = !root.showingProfile
                        }
                    }

                    Rectangle {
                        width: 185
                        Layout.topMargin: -5
                        height: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Appearance.colors.colOutline }
                            GradientStop { position: 0.8; color: Appearance.colors.colOutline }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.15
                    }

                    FloatingActionButton {
                        id: fab
                        Layout.topMargin: 2
                        Layout.bottomMargin: 6
                        property bool justCopied: false
                        iconText: justCopied ? "check" : "edit"
                        buttonText: justCopied ? Translation.tr("Path copied") : Translation.tr("Config file")
                        expanded: navRail.expanded
                        downAction: () => {
                            const p = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            Quickshell.execDetached(["bash", "-c", `if command -v code >/dev/null 2>&1; then code "${p}"; elif command -v kitty >/dev/null 2>&1 && command -v micro >/dev/null 2>&1; then kitty -e micro "${p}"; else xdg-open "${p}"; fi`]);
                        }
                        altAction: () => {
                            Quickshell.clipboardText = CF.FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                            fab.justCopied = true;
                            revertTextTimer.restart()
                        }
                        Timer {
                            id: revertTextTimer
                            interval: 1500
                            onTriggered: fab.justCopied = false
                        }
                        StyledToolTip {
                            text: Translation.tr("Open the shell config file\nAlternatively right-click to copy path")
                        }
                    }

                    StyledFlickable {
                        id: navRailFlickable
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: navRailTabs.implicitHeight + 20
                        contentWidth: width
                        clip: true

                        NavigationRailTabArray {
                            id: navRailTabs
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: implicitHeight
                            currentIndex: root.currentPage
                            expanded: navRail.expanded
                            colToggled: root.showingProfile ? "transparent" : Appearance.colors.colSecondaryContainer
                            Repeater {
                                model: root.pages
                                NavigationRailButton {
                                    required property var index
                                    required property var modelData
                                    baseSize: 46
                                    toggled: root.currentPage === index && !root.showingProfile
                                    onPressed: {
                                        root.currentPage = index
                                        root.showingProfile = false
                                    }
                                    expanded: navRail.expanded
                                    buttonIcon: modelData.icon
                                    buttonIconRotation: modelData.iconRotation || 0
                                    buttonText: modelData.name
                                    showToggledHighlight: false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut

                Item {
                    anchors.fill: parent

                    Repeater {
                        id: pagesRepeater
                        model: root.pages
                        Loader {
                            id: pageLoader
                            required property var modelData
                            required property var index
                            source: modelData.component

                            active: Config.ready && (root.currentPage === index || item !== null)

                            anchors.fill: parent

                            property bool isActive: root.currentPage === index && !root.showingProfile
                            opacity: isActive ? 1 : 0
                            enabled: isActive
                            visible: isActive
                            anchors.topMargin: isActive ? 0 : 12

                            onLoaded: {
                                if (root.currentPage === index) {
                                    GlobalStates.currentPageInstance = item;
                                }
                            }

                            onIsActiveChanged: {
                                if (isActive && item) {
                                    GlobalStates.currentPageInstance = item;
                                } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                    GlobalStates.currentPageInstance = null;
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            Behavior on anchors.topMargin {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Loader {
                        id: profileLoader
                        active: false
                        anchors.fill: parent
                        source: Qt.resolvedUrl("pages/Profile.qml")

                        property bool isActive: root.showingProfile
                        opacity: isActive ? 1 : 0
                        enabled: isActive
                        visible: isActive
                        anchors.topMargin: isActive ? 0 : 12

                        onIsActiveChanged: {
                            if (isActive && item) {
                                GlobalStates.currentPageInstance = item;
                            } else if (!isActive && GlobalStates.currentPageInstance === item) {
                                GlobalStates.currentPageInstance = null;
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}