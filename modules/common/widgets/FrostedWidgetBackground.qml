import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions

/**
 * Aesthetic Frosted Glass Background for Desktop Widgets & Bar.
 * Features:
 *   - GPU-accelerated wallpaper FastBlur with OpacityMask
 *   - Configurable alignment for bars (Image.AlignTop/AlignBottom) or widgets (AlignVCenter)
 *   - Asynchronous image loading with A/B crossfading on wallpaper switch
 *   - Video/live wallpaper support via Images.getStaticWallpaperImage
 *   - Smooth frosted glass ambient tint & optional diffuse surface sheen
 *   - Clean rounded glass border without any harsh artifacts
 *   - pureGlass mode: skip wallpaper sampling, use only translucent tint (for desktop widgets)
 */
Item {
    id: root

    property real radius: Appearance.rounding?.verylarge ?? 30
    property real blurRadius: 44
    property real tintOpacity: 0.38
    property color tintColor: Appearance.colors.colLayer0
    property color borderColor: ColorUtils.applyAlpha("#ffffff", 0.12)
    property bool showBorder: true
    property bool showSurfaceSheen: false
    property bool showTint: true
    property string wallpaperPathOverride: ""
    // Set true to skip wallpaper sampling entirely — pure translucent glass tint only
    property bool pureGlass: false

    property int imageVerticalAlignment: Image.AlignVCenter
    property int imageHorizontalAlignment: Image.AlignHCenter
    property int sourceWidth: 0
    property int sourceHeight: 0
    property size imageSourceSize: Qt.size(sourceWidth, sourceHeight)

    // Invisible source container for FastBlur (not used in pureGlass mode)
    Item {
        id: bgImageContainer
        anchors.fill: parent
        visible: false

        readonly property string effectiveSource: {
            if (root.pureGlass) return "";
            var path = root.wallpaperPathOverride !== ""
                ? root.wallpaperPathOverride
                : ((typeof GlobalStates !== "undefined" && GlobalStates.screenLocked && Config.options.background.lockWall !== "")
                    ? Config.options.background.lockWall
                    : (Wallpapers?.previewPath || Wallpapers?.confirmedPath || Config.options.background.wallpaperPath));
            if (!path) return "";
            var img = Images.getStaticWallpaperImage(path, Config.options.background.thumbnailPath);
            return img ? (img.startsWith("file://") ? img : "file://" + img) : "";
        }

        Image {
            id: bgImageA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: root.imageVerticalAlignment
            horizontalAlignment: root.imageHorizontalAlignment
            sourceSize.width: root.sourceWidth > 0 ? root.sourceWidth : (root.imageSourceSize.width > 0 ? root.imageSourceSize.width : 0)
            sourceSize.height: root.sourceHeight > 0 ? root.sourceHeight : (root.imageSourceSize.height > 0 ? root.imageSourceSize.height : 0)
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
            verticalAlignment: root.imageVerticalAlignment
            horizontalAlignment: root.imageHorizontalAlignment
            sourceSize.width: root.sourceWidth > 0 ? root.sourceWidth : (root.imageSourceSize.width > 0 ? root.imageSourceSize.width : 0)
            sourceSize.height: root.sourceHeight > 0 ? root.sourceHeight : (root.imageSourceSize.height > 0 ? root.imageSourceSize.height : 0)
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

    // Blurred wallpaper backdrop (source for OpacityMask)
    FastBlur {
        id: blurredBg
        anchors.fill: parent
        source: bgImageContainer
        radius: root.blurRadius
        visible: false
    }

    // Dedicated layer mask item for OpacityMask to cleanly clip corners
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "black"
            antialiasing: true
        }
    }

    // Blurred wallpaper backdrop masked cleanly to rounded shape (skipped in pureGlass mode)
    OpacityMask {
        id: maskedBlurredBg
        anchors.fill: parent
        source: blurredBg
        maskSource: maskItem
        visible: !root.pureGlass
    }

    // In pureGlass mode: simple dark translucent base instead of wallpaper blur
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.pureGlass
        color: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            0.18
        )
    }

    // Frosted Glass Base Tint (Theme-Harmonized Dark Scrim)
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.showTint
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: ColorUtils.applyAlpha(ColorUtils.mix(root.tintColor, Appearance.colors.colPrimary, 0.94), root.pureGlass ? root.tintOpacity * 0.4 : root.tintOpacity * 0.90)
            }
            GradientStop {
                position: 1.0
                color: ColorUtils.applyAlpha(ColorUtils.mix(root.tintColor, Appearance.colors.colScrim, 0.82), root.pureGlass ? root.tintOpacity * 0.5 : root.tintOpacity * 1.10)
            }
        }
    }

    // Subtle top-edge glass highlight (pureGlass mode only)
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.pureGlass
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0;  color: ColorUtils.applyAlpha("#ffffff", 0.06) }
            GradientStop { position: 0.35; color: "transparent" }
        }
    }

    // Optional Diffuse Surface Sheen
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.showSurfaceSheen
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: ColorUtils.applyAlpha("#ffffff", 0.08)
            }
            GradientStop {
                position: 0.45
                color: ColorUtils.applyAlpha("#ffffff", 0.02)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }

    // Subtle ambient chromatic accent glow
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Appearance.colors.colPrimary
        opacity: 0.04
    }

    // Clean, continuous rounded glass border
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.borderColor
        visible: root.showBorder
    }
}
