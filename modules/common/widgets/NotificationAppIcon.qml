import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale
    readonly property bool isActualImage: typeof root.image === "string" && root.image !== "" && (root.image.startsWith("/") || root.image.startsWith("file://") || root.image.startsWith("data:") || root.image.startsWith("image://") || root.image.startsWith("http://") || root.image.startsWith("https://"))
    readonly property string resolvedIconPath: {
        if (!root.appIcon || root.appIcon === "") return "";
        let path = Quickshell.iconPath(root.appIcon);
        return (path && path !== "image-missing") ? path : "";
    }

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        active: !root.isActualImage && root.resolvedIconPath === ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                if (guessedIcon !== defaultIcon) return guessedIcon;
                const appIconGuessed = NotificationUtils.findSuitableMaterialSymbol(root.appIcon || "")
                if (appIconGuessed !== defaultIcon) return appIconGuessed;
                return (root.urgency == NotificationUrgency.Critical) ? "priority_high" : defaultIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        active: !root.isActualImage && root.resolvedIconPath !== ""
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: true
            source: root.resolvedIconPath
        }
    }
    Loader {
        id: notifImageLoader
        active: root.isActualImage
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Image {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.image
                fillMode: Image.PreserveAspectCrop
                cache: true
                antialiasing: true
                asynchronous: true

                width: size
                height: size
                sourceSize.width: size
                sourceSize.height: size

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: true
                    source: Quickshell.iconPath(root.appIcon, "image-missing")
                }
            }
        }
    }
}