pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "images"

    property list<var> formatOptions: [
        // Animation & Video
        { displayName: "ANIMATE (Frames → Video)", value: "animate", icon: "movie", shortName: "ANIMATE" },
        { displayName: "MP4 (Video / Frames)",     value: "mp4",     icon: "videocam", shortName: "MP4" },
        { displayName: "GIF (Animated GIF)",       value: "gif",     icon: "gif",      shortName: "GIF" },
        // Daily / Web Images
        { displayName: "WEBP (Modern Web)",        value: "webp",    icon: "motion_photos_on", shortName: "WEBP" },
        { displayName: "PNG (Lossless)",           value: "png",     icon: "image",     shortName: "PNG" },
        { displayName: "JPG (Photo)",              value: "jpg",     icon: "photo",     shortName: "JPG" },
        { displayName: "PDF (Multi-page Doc)",     value: "pdf",     icon: "picture_as_pdf", shortName: "PDF" },
        { displayName: "AVIF (Next-Gen)",          value: "avif",    icon: "hd",        shortName: "AVIF" },
        { displayName: "ICO (App Icon)",           value: "ico",     icon: "star",      shortName: "ICO" },
        // Professional / Specialized
        { displayName: "BMP (Bitmap)",             value: "bmp",     icon: "grid_on",   shortName: "BMP" },
        { displayName: "TIFF (Print / Raw)",       value: "tiff",    icon: "photo_library", shortName: "TIFF" },
        { displayName: "HEIC (Apple Photo)",       value: "heic",    icon: "camera",    shortName: "HEIC" },
        { displayName: "JXL (JPEG XL)",            value: "jxl",     icon: "tune",      shortName: "JXL" },
        { displayName: "PSD (Photoshop)",          value: "psd",     icon: "brush",     shortName: "PSD" },
        { displayName: "TGA (Targa)",              value: "tga",     icon: "sports_esports", shortName: "TGA" },
        { displayName: "PPM (Portable Pixmap)",    value: "ppm",     icon: "terminal",  shortName: "PPM" },
    ]

    property list<var> fpsOptions: [
        { displayName: "24 FPS", value: 24 },
        { displayName: "30 FPS", value: 30 },
        { displayName: "60 FPS", value: 60 },
        { displayName: "15 FPS", value: 15 },
        { displayName: "12 FPS", value: 12 },
    ]

    property list<var> sizeOptions: [
        { displayName: "No Limit", value: 0 },
        { displayName: "50 KB",    value: 50 * 1024 },
        { displayName: "200 KB",   value: 200 * 1024 },
        { displayName: "500 KB",   value: 500 * 1024 },
        { displayName: "1 MB",     value: 1024 * 1024 },
        { displayName: "2 MB",     value: 2 * 1024 * 1024 },
        { displayName: "5 MB",     value: 5 * 1024 * 1024 },
        { displayName: "10 MB",    value: 10 * 1024 * 1024 },
        { displayName: "25 MB",    value: 25 * 1024 * 1024 },
        { displayName: "50 MB",    value: 50 * 1024 * 1024 },
        { displayName: "Custom...", value: -1 }
    ]

    property string selectedFormat: "webp"
    property int selectedFps: 24
    property int selectedSizeLimit: 0
    property string selectedSizeLabel: "No Limit"

    readonly property bool isAnimationFormat: selectedFormat === "animate" || selectedFormat === "mp4" || selectedFormat === "gif"

    readonly property string modeDescription: {
        switch (selectedFormat) {
            case "gif":     return "Convert video clips or photos into an animated GIF"
            case "animate": return "Assemble multiple frame images into a smooth MP4 video"
            case "mp4":     return "Convert videos or frame sequences into MP4 video"
            case "pdf":     return "Merge multiple images or documents into a single PDF"
            case "webp":    return "Convert images or video frames to compact WebP"
            case "png":     return "Convert to lossless transparent PNG"
            case "jpg":     return "Convert to standard compressed JPG photo"
            case "avif":    return "Convert to ultra-compact modern AVIF format"
            case "ico":     return "Convert image into 256x256 desktop App Icon"
            default:        return "Convert dropped media to " + selectedFormat.toUpperCase()
        }
    }

    property bool customLimitActive: false
    property string customNum: "500"
    property string customUnit: "KB" // "KB" or "MB"

    property string dropStatus: "idle"   // idle | hover | converting | done | error
    property string statusMessage: ""

    readonly property var acceptedExtensions: [
        "png","jpg","jpeg","webp","avif","bmp","gif","tiff","tif","ico","tga","heic","heif","jxl","psd","ppm","mp4","webm","mkv","mov","avi","flv"
    ]
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/ballade/scripts/images/convert_image.py"

    property var fileQueue: []
    property int queueTotal: 0
    property int queueDone: 0
    property var batchPaths: []

    // Dynamic Auto-Resizing width calculation based on text content
    readonly property real headerRequiredWidth: (titleIcon?.implicitWidth ?? 18) + (titleText?.implicitWidth ?? 120) + (badgeRect?.implicitWidth ?? 80) + 48
    readonly property real statusRequiredWidth: (dropText?.implicitWidth ?? 140) + 64
    readonly property real descRequiredWidth: (descText?.implicitWidth ?? 160) + 64
    readonly property real bottomRequiredWidth: isAnimationFormat
        ? ((formatCombo?.implicitWidth ?? 130) + (fpsCombo?.implicitWidth ?? 85) + (customLimitActive ? 140 : (sizeCombo?.implicitWidth ?? 95)) + 48)
        : ((formatCombo?.implicitWidth ?? 130) + (customLimitActive ? 140 : (sizeCombo?.implicitWidth ?? 95)) + 40)

    property real targetWidgetWidth: Math.max(340, headerRequiredWidth, statusRequiredWidth, descRequiredWidth, bottomRequiredWidth)

    implicitWidth: targetWidgetWidth
    implicitHeight: 252

    Behavior on implicitWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    function applyCustomLimit() {
        var raw = parseFloat(root.customNum);
        if (isNaN(raw) || raw <= 0) {
            root.selectedSizeLimit = 0;
            root.selectedSizeLabel = "No Limit";
            return;
        }
        if (root.customUnit === "MB") {
            root.selectedSizeLimit = Math.round(raw * 1024 * 1024);
            root.selectedSizeLabel = raw + " MB";
        } else {
            root.selectedSizeLimit = Math.round(raw * 1024);
            root.selectedSizeLabel = raw + " KB";
        }
    }

    Process {
        id: converter
        property string inputPath: ""
        property string outputPath: ""
        command: [
            "python3",
            root.scriptPath,
            "--input", inputPath,
            "--output", outputPath,
            "--format", root.selectedFormat,
            "--fps", root.selectedFps.toString(),
            "--max-bytes", root.selectedSizeLimit.toString()
        ]
        onExited: (exitCode) => {
            root.queueDone++
            if (exitCode !== 0) {
                root.dropStatus = "error"
                root.statusMessage = "Failed: " + inputPath.replace(/.*\//, "")
                root.fileQueue = []
                root.queueTotal = 0
                root.queueDone = 0
                resetTimer.start()
                return
            }
            if (root.fileQueue.length > 0) {
                root.statusMessage = "Converting " + (root.queueDone + 1) + " / " + root.queueTotal + "..."
                processNext()
            } else {
                root.dropStatus = "done"
                root.statusMessage = root.queueTotal === 1
                    ? "Saved: " + outputPath.replace(/.*\//, "")
                    : root.queueTotal + " files converted"
                root.queueTotal = 0
                root.queueDone = 0
                resetTimer.start()
            }
        }
    }

    Process {
        id: batchMaker
        property string outputPath: ""
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.dropStatus = "done"
                root.statusMessage = "Saved: " + outputPath.replace(/.*\//, "")
            } else {
                root.dropStatus = "error"
                root.statusMessage = "Batch conversion failed"
            }
            root.batchPaths = []
            resetTimer.start()
        }
    }

    Timer {
        id: resetTimer
        interval: 3500
        repeat: false
        onTriggered: root.dropStatus = "idle"
    }

    function processNext() {
        var next = root.fileQueue[0]
        root.fileQueue = root.fileQueue.slice(1)
        converter.inputPath = next
        const tag = root.selectedSizeLimit > 0 ? ("_" + root.selectedSizeLabel.replace(/\s+/g, "").toLowerCase()) : ""
        const outExt = root.selectedFormat === "animate" ? "mp4" : root.selectedFormat
        converter.outputPath = next.replace(/\.[^/.]+$/, "") + tag + "_converted." + outExt
        converter.running = true
    }

    function enqueueFiles(urls) {
        var valid = []
        for (var i = 0; i < urls.length; i++) {
            var cleanPath = urls[i].toString().replace(/^file:\/\//, "")
            var ext = cleanPath.split(".").pop().toLowerCase()
            if (root.acceptedExtensions.indexOf(ext) !== -1)
                valid.push(cleanPath)
        }
        if (valid.length === 0) {
            root.dropStatus = "error"
            root.statusMessage = "Unsupported format"
            resetTimer.start()
            return
        }

        root.dropStatus = "converting"

        const tag = root.selectedSizeLimit > 0 ? ("_" + root.selectedSizeLabel.replace(/\s+/g, "").toLowerCase()) : ""

        if (root.selectedFormat === "pdf") {
            root.batchPaths = valid
            root.statusMessage = valid.length === 1
                ? "Creating PDF..."
                : "Merging " + valid.length + " pages..."
            var outPdf = valid[0].replace(/\.[^/.]+$/, "") + (valid.length > 1 ? "_merged" : "_converted") + tag + ".pdf"
            batchMaker.outputPath = outPdf
            batchMaker.command = ["python3", root.scriptPath, "--pdf", outPdf, "--max-bytes", root.selectedSizeLimit.toString()].concat(valid)
            batchMaker.running = true
            return
        }

        if (root.selectedFormat === "animate" || (root.selectedFormat === "mp4" && valid.length > 1)) {
            root.batchPaths = valid
            root.statusMessage = "Compiling " + valid.length + " frames (" + root.selectedFps + " FPS)..."
            var outAnim = valid[0].replace(/\.[^/.]+$/, "") + "_animated" + tag + ".mp4"
            batchMaker.outputPath = outAnim
            batchMaker.command = ["python3", root.scriptPath, "--animate", outAnim, "--fps", root.selectedFps.toString(), "--max-bytes", root.selectedSizeLimit.toString()].concat(valid)
            batchMaker.running = true
            return
        }

        root.fileQueue = valid.slice(1)
        root.queueTotal = valid.length
        root.queueDone = 0
        root.statusMessage = valid.length > 1 ? "Converting 1 / " + valid.length + "..." : "Converting..."
        converter.inputPath = valid[0]
        const outExt = root.selectedFormat === "animate" ? "mp4" : root.selectedFormat
        converter.outputPath = valid[0].replace(/\.[^/.]+$/, "") + tag + "_converted." + outExt
        converter.running = true
    }

    StyledRectangularShadow {
        target: contentItem
        z: -2
    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.18)
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding?.large ?? 22
        clip: true

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 10

            // Header Bar
            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    id: titleIcon
                    text: root.isAnimationFormat ? "movie" : "auto_fix_high"
                    iconSize: 18
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    id: titleText
                    text: root.isAnimationFormat ? "Media & Animation Studio" : "Media & Format Converter"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                // Live Format & Target Size Badge
                Rectangle {
                    id: badgeRect
                    radius: 8
                    color: Appearance.colors.colPrimaryContainer
                    implicitHeight: 22
                    implicitWidth: badgeText.implicitWidth + 12

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.selectedFormat.toUpperCase() + (root.isAnimationFormat ? (" · " + root.selectedFps + "FPS") : "") + (root.selectedSizeLimit > 0 ? (" · " + root.selectedSizeLabel) : "")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.customLimitActive = !root.customLimitActive
                            if (root.customLimitActive) root.applyCustomLimit()
                        }
                    }
                }
            }

            // Drop Area Card
            Rectangle {
                id: dropZone
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding?.normal ?? 16
                color: {
                    switch (root.dropStatus) {
                        case "hover":      return Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.16)
                        case "converting": return Qt.rgba(Appearance.colors.colSecondary.r, Appearance.colors.colSecondary.g, Appearance.colors.colSecondary.b, 0.16)
                        case "done":       return Qt.rgba(Appearance.colors.colTertiary.r, Appearance.colors.colTertiary.g, Appearance.colors.colTertiary.b, 0.20)
                        case "error":      return Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.20)
                        default:           return ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.45)
                    }
                }
                border.color: {
                    switch (root.dropStatus) {
                        case "hover":      return Appearance.colors.colPrimary
                        case "converting": return Appearance.colors.colSecondary
                        case "done":       return Appearance.colors.colTertiary
                        case "error":      return Appearance.colors.colError
                        default:           return Appearance.colors.colLayer0Border
                    }
                }
                border.width: root.dropStatus === "hover" ? 2 : 1

                Behavior on color        { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                Behavior on border.color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    width: parent.width - 20

                    MaterialLoadingIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.dropStatus === "converting"
                        loading: root.dropStatus === "converting"
                        colBg: Appearance.colors.colPrimary
                        colShape: Appearance.colors.colOnPrimary
                        implicitSize: 32
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.dropStatus !== "converting"
                        iconSize: 26
                        fill: root.dropStatus === "done" ? 1 : 0
                        color: {
                            switch (root.dropStatus) {
                                case "hover": return Appearance.colors.colPrimary
                                case "done":  return Appearance.colors.colTertiary
                                case "error": return Appearance.colors.colError
                                default:      return Appearance.colors.colPrimary
                            }
                        }
                        text: {
                            switch (root.dropStatus) {
                                case "hover": return "file_download"
                                case "done":  return "check_circle"
                                case "error": return "error"
                                default:      return root.isAnimationFormat ? "movie_filter" : "cloud_upload"
                            }
                        }
                    }

                    StyledText {
                        id: dropText
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        color: {
                            switch (root.dropStatus) {
                                case "hover":  return Appearance.colors.colPrimary
                                case "done":   return Appearance.colors.colTertiary
                                case "error":  return Appearance.colors.colError
                                default:       return Appearance.colors.colOnLayer0
                            }
                        }
                        opacity: root.dropStatus === "idle" ? 0.95 : 1.0
                        text: {
                            switch (root.dropStatus) {
                                case "idle":       return root.selectedFormat === "animate" ? "Drop frames to compile animation" : "Drop files to convert to " + root.selectedFormat.toUpperCase()
                                case "hover":      return "Release to start conversion"
                                case "converting": return root.statusMessage
                                case "done":       return root.statusMessage
                                case "error":      return root.statusMessage
                                default:           return ""
                            }
                        }
                    }

                    // Mode Intro / Description Subtitle
                    StyledText {
                        id: descText
                        visible: root.dropStatus === "idle"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Normal
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.80
                        text: root.modeDescription
                    }
                }

                DropArea {
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: (drag) => {
                        drag.accept(Qt.CopyAction)
                        root.dropStatus = "hover"
                    }
                    onExited: {
                        if (root.dropStatus === "hover")
                            root.dropStatus = "idle"
                    }
                    onDropped: (drop) => {
                        if (drop.hasUrls && drop.urls.length > 0) {
                            root.enqueueFiles(drop.urls)
                        } else {
                            root.dropStatus = "error"
                            root.statusMessage = "Could not read dropped file"
                            resetTimer.start()
                        }
                    }
                }
            }

            // Bottom Controls Row
            RowLayout {
                id: bottomControlsRow
                Layout.fillWidth: true
                spacing: 8

                // Target Format Selector
                StyledComboBox {
                    id: formatCombo
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonIcon: "swap_horiz"
                    buttonRadius: 10
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.70)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.formatOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedFormat) return i;
                        }
                        return 0;
                    }
                    onActivated: (index) => {
                        root.selectedFormat = model[index].value
                    }
                }

                // FPS Selector (shown when animation/video/gif format is selected)
                StyledComboBox {
                    id: fpsCombo
                    visible: root.isAnimationFormat
                    Layout.fillWidth: false
                    implicitWidth: 95
                    implicitHeight: 36
                    buttonIcon: "speed"
                    buttonRadius: 10
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.70)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.fpsOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedFps) return i;
                        }
                        return 0;
                    }
                    onActivated: (index) => {
                        root.selectedFps = model[index].value
                    }
                }

                // Standard Presets Dropdown (always available for ALL formats)
                StyledComboBox {
                    id: sizeCombo
                    visible: !root.customLimitActive
                    Layout.fillWidth: false
                    implicitWidth: 105
                    implicitHeight: 36
                    buttonIcon: "compress"
                    buttonRadius: 10
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.70)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.sizeOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        if (root.customLimitActive) return model.length - 1;
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedSizeLimit) return i;
                        }
                        return 0;
                    }
                    onActivated: (index) => {
                        if (model[index].value === -1) {
                            root.customLimitActive = true
                            root.applyCustomLimit()
                        } else {
                            root.customLimitActive = false
                            root.selectedSizeLimit = model[index].value
                            root.selectedSizeLabel = model[index].displayName
                        }
                    }
                }

                // Custom Limit Inline Bar (shown when custom mode is active)
                RowLayout {
                    visible: root.customLimitActive
                    Layout.fillWidth: false
                    implicitWidth: 140
                    spacing: 4

                    // Number Input
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                        border.width: 1
                        border.color: numInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                        TextInput {
                            id: numInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            verticalAlignment: TextInput.AlignVCenter
                            color: Appearance.colors.colOnSurface
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.family: Appearance.font.family.main
                            selectByMouse: true
                            text: root.customNum
                            validator: DoubleValidator { bottom: 0.1; top: 9999.0; decimals: 2 }
                            onTextChanged: {
                                root.customNum = text
                                root.applyCustomLimit()
                            }
                        }
                    }

                    // Unit Toggle Pill (KB / MB)
                    Rectangle {
                        implicitHeight: 36
                        implicitWidth: 46
                        radius: 10
                        color: Appearance.colors.colPrimaryContainer
                        border.width: 1
                        border.color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.3)

                        StyledText {
                            anchors.centerIn: parent
                            text: root.customUnit
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.customUnit = (root.customUnit === "KB" ? "MB" : "KB")
                                root.applyCustomLimit()
                            }
                        }
                    }

                    // Revert / Close Button
                    Rectangle {
                        implicitHeight: 36
                        implicitWidth: 32
                        radius: 10
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.customLimitActive = false
                                root.selectedSizeLimit = 0
                                root.selectedSizeLabel = "No Limit"
                            }
                        }
                    }
                }
            }
        }
    }
}