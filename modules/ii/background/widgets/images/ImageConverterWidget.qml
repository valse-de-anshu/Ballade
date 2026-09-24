pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
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

    // Balanced, constant geometry — zero jiggle or size shifting
    implicitWidth: 350
    implicitHeight: 284

    property list<var> formatOptions: [
        // Animation & Video
        { displayName: "ANIMATE", value: "animate", icon: "movie", shortName: "ANIMATE" },
        { displayName: "MP4",     value: "mp4",     icon: "videocam", shortName: "MP4" },
        { displayName: "GIF",     value: "gif",     icon: "gif",      shortName: "GIF" },
        // Daily / Web Images
        { displayName: "WEBP",    value: "webp",    icon: "motion_photos_on", shortName: "WEBP" },
        { displayName: "PNG",     value: "png",     icon: "image",     shortName: "PNG" },
        { displayName: "JPG",     value: "jpg",     icon: "photo",     shortName: "JPG" },
        { displayName: "PDF",     value: "pdf",     icon: "picture_as_pdf", shortName: "PDF" },
        { displayName: "AVIF",    value: "avif",    icon: "hd",        shortName: "AVIF" },
        { displayName: "ICO",     value: "ico",     icon: "star",      shortName: "ICO" },
        // Professional / Specialized
        { displayName: "BMP",     value: "bmp",     icon: "grid_on",   shortName: "BMP" },
        { displayName: "TIFF",    value: "tiff",    icon: "photo_library", shortName: "TIFF" },
        { displayName: "HEIC",    value: "heic",    icon: "camera",    shortName: "HEIC" },
        { displayName: "JXL",     value: "jxl",     icon: "tune",      shortName: "JXL" },
        { displayName: "PSD",     value: "psd",     icon: "brush",     shortName: "PSD" },
        { displayName: "TGA",     value: "tga",     icon: "sports_esports", shortName: "TGA" },
        { displayName: "PPM",     value: "ppm",     icon: "terminal",  shortName: "PPM" },
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
            case "animate": return "Assemble image frames into an MP4 video sequence"
            case "mp4":     return "Convert videos or compile frames into MP4 video"
            case "pdf":     return "Merge multiple images or documents into a single PDF"
            case "webp":    return "Convert images or video frames to modern WebP"
            case "png":     return "Convert to lossless transparent PNG image"
            case "jpg":     return "Convert to standard compressed JPG photo"
            case "avif":    return "Convert to ultra-compact modern AVIF format"
            case "ico":     return "Convert image into 256x256 desktop App Icon"
            default:        return "Convert media to " + selectedFormat.toUpperCase()
        }
    }

    property bool customLimitActive: false
    property string customNum: "500"
    property string customUnit: "KB" // "KB" or "MB"

    // Staging and execution states
    property var stagedFiles: []
    property string detectedFormat: ""
    property string detectedFileName: ""
    property real stagedFileSize: 0

    property string dropStatus: "idle"   // idle | staged | hover | converting | done | error
    property string statusMessage: ""

    readonly property var acceptedExtensions: [
        "png","jpg","jpeg","webp","avif","bmp","gif","tiff","tif","ico","tga","heic","heif","jxl","psd","ppm","mp4","webm","mkv","mov","avi","flv"
    ]
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/ballade/scripts/images/convert_image.py"

    property var fileQueue: []
    property int queueTotal: 0
    property int queueDone: 0
    property var batchPaths: []

    function formatBytes(bytes) {
        if (!bytes || bytes <= 0) return ""
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
    }

    function applyCustomLimit() {
        var raw = parseFloat(root.customNum)
        if (isNaN(raw) || raw <= 0) {
            root.selectedSizeLimit = 0
            root.selectedSizeLabel = "No Limit"
            return
        }
        if (root.customUnit === "MB") {
            root.selectedSizeLimit = Math.round(raw * 1024 * 1024)
            root.selectedSizeLabel = raw + " MB"
        } else {
            root.selectedSizeLimit = Math.round(raw * 1024)
            root.selectedSizeLabel = raw + " KB"
        }
    }

    function clearStaged() {
        root.stagedFiles = []
        root.detectedFormat = ""
        root.detectedFileName = ""
        root.stagedFileSize = 0
        root.dropStatus = "idle"
        root.statusMessage = ""
    }

    function stageFiles(urls) {
        var valid = []
        for (var i = 0; i < urls.length; i++) {
            var cleanPath = urls[i].toString().replace(/^file:\/\//, "").trim()
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

        root.stagedFiles = valid
        root.detectedFormat = valid[0].split(".").pop().toUpperCase()
        root.detectedFileName = valid[0].replace(/.*\//, "")
        root.dropStatus = "staged"
        root.statusMessage = valid.length === 1 ? "Ready to bake" : (valid.length + " files ready")

        // Read input file size
        statProc.targetPath = valid[0]
        statProc.running = true
    }

    function pasteFromClipboard() {
        pasteProc.running = false
        pasteProc.running = true
    }

    function startBake() {
        if (root.stagedFiles.length === 0) return
        root.dropStatus = "converting"
        const tag = root.selectedSizeLimit > 0 ? ("_" + root.selectedSizeLabel.replace(/\s+/g, "").toLowerCase()) : ""
        const valid = root.stagedFiles

        if (root.selectedFormat === "pdf") {
            root.batchPaths = valid
            root.statusMessage = valid.length === 1 ? "Creating PDF..." : "Merging " + valid.length + " pages..."
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
        root.statusMessage = valid.length > 1 ? "Baking 1 / " + valid.length + "..." : "Baking conversion..."
        converter.inputPath = valid[0]
        const outExt = root.selectedFormat === "animate" ? "mp4" : root.selectedFormat
        converter.outputPath = valid[0].replace(/\.[^/.]+$/, "") + tag + "_converted." + outExt
        converter.running = true
    }

    FileDialog {
        id: fileChooserDialog
        title: Translation.tr("Select Media or Image Files to Convert")
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            if (selectedFiles && selectedFiles.length > 0) {
                root.stageFiles(selectedFiles)
            }
        }
    }

    Process {
        id: statProc
        property string targetPath: ""
        command: ["stat", "-c", "%s", targetPath]
        stdout: StdioCollector {
            onDataChanged: {
                let b = parseInt(text.trim())
                if (!isNaN(b)) root.stagedFileSize = b
            }
        }
    }

    Process {
        id: pasteProc
        command: ["bash", "-c", "wl-paste -t text/uri-list 2>/dev/null || wl-paste 2>/dev/null"]
        stdout: StdioCollector {
            onDataChanged: {
                let t = text.trim()
                if (!t) return
                let lines = t.split("\n")
                let urls = []
                for (let i = 0; i < lines.length; i++) {
                    let l = lines[i].trim()
                    if (l.length > 0) urls.push(l)
                }
                if (urls.length > 0) {
                    root.stageFiles(urls)
                }
            }
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
                root.statusMessage = "Baking " + (root.queueDone + 1) + " / " + root.queueTotal + "..."
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
                root.statusMessage = "Conversion failed"
            }
            root.batchPaths = []
            resetTimer.start()
        }
    }

    Timer {
        id: resetTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (root.dropStatus === "done" || root.dropStatus === "error") {
                root.clearStaged()
            }
        }
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

    Rectangle {
        id: contentItem
        anchors.fill: parent
        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1, 0.62)
        border.width: 1
        border.color: ColorUtils.applyAlpha("#ffffff", 0.16)
        radius: Appearance.rounding?.large ?? 20
        clip: true

        // Frosted glass ambient highlight & gradient sheen
        Rectangle {
            anchors.fill: parent
            radius: contentItem.radius
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: ColorUtils.applyAlpha("#ffffff", 0.08) }
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 1.0; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.04) }
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // 1. Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: root.stagedFiles.length > 0 ? "local_fire_department" : "auto_fix_high"
                    iconSize: 18
                    color: root.stagedFiles.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                }

                StyledText {
                    text: "Media Studio"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                // Quick Paste Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 22
                    radius: 6
                    color: pasteHover.containsMouse ? Appearance.colors.colLayer1Hover : ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.40)
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_paste"
                        iconSize: 14
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    MouseArea {
                        id: pasteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pasteFromClipboard()
                    }

                    StyledToolTip {
                        extraVisibleCondition: pasteHover.containsMouse
                        text: "Paste file from clipboard"
                    }
                }

                // Clear / Reset Button
                Rectangle {
                    visible: root.stagedFiles.length > 0
                    implicitWidth: 26
                    implicitHeight: 22
                    radius: 6
                    color: clearHover.containsMouse ? Appearance.colors.colErrorContainer : ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.40)
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 14
                        color: clearHover.containsMouse ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSurfaceVariant
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearStaged()
                    }

                    StyledToolTip {
                        extraVisibleCondition: clearHover.containsMouse
                        text: "Clear selected files"
                    }
                }
            }

            // 2. Conversion Flow Card: Balanced 50/50 Split [ Input Media -> Converting To ]
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 78
                radius: 12
                color: root.dropStatus === "hover"
                    ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15)
                    : ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.45)
                border.width: root.dropStatus === "hover" ? 2 : 1
                border.color: root.dropStatus === "hover" ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                clip: true

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 6

                    // Left Box: Real Media File (Exactly 50% width, strictly clipped)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: 8
                        clip: true
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.50)
                        border.width: 1
                        border.color: root.stagedFiles.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                        ColumnLayout {
                            anchors {
                                fill: parent
                                margins: 6
                            }
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: "REAL MEDIA FILE"
                                font.pixelSize: Appearance.font.pixelSize.smallest - 1
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                color: Appearance.colors.colPrimary
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                MaterialSymbol {
                                    text: root.stagedFiles.length > 0
                                        ? (/\.(mp4|webm|mkv|mov|avi)$/i.test(root.detectedFileName) ? "movie" : "image")
                                        : "add_photo_alternate"
                                    iconSize: 20
                                    color: root.stagedFiles.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: root.stagedFiles.length > 0
                                            ? (root.stagedFiles.length > 1 ? (root.stagedFiles.length + " frames") : root.detectedFileName)
                                            : "Tap or drop file"
                                        font.pixelSize: Appearance.font.pixelSize.smallie
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideMiddle
                                        color: Appearance.colors.colOnLayer1
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: root.stagedFiles.length > 0
                                            ? (root.detectedFormat + (root.stagedFileSize > 0 ? (" · " + root.formatBytes(root.stagedFileSize)) : ""))
                                            : "Browse media"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: fileChooserDialog.open()
                        }
                    }

                    // Middle Connector Arrow
                    Rectangle {
                        Layout.fillWidth: false
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: Appearance.colors.colPrimaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            iconSize: 13
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    // Right Box: Converting To (Exactly 50% width, strictly clipped)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: 8
                        clip: true
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.50)
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border

                        ColumnLayout {
                            anchors {
                                fill: parent
                                margins: 6
                            }
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: "CONVERTING TO"
                                font.pixelSize: Appearance.font.pixelSize.smallest - 1
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                color: Appearance.colors.colSecondary
                            }

                            Item { Layout.fillHeight: true }

                            StyledComboBox {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitWidth: 0
                                implicitHeight: 32
                                buttonRadius: 6
                                colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.60)
                                colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.80)
                                colBackgroundActive: Appearance.colors.colPrimaryContainer
                                model: root.formatOptions
                                textRole: "shortName"
                                valueRole: "value"
                                currentIndex: {
                                    for (var i = 0; i < model.length; i++) {
                                        if (model[i].value === root.selectedFormat) return i
                                    }
                                    return 0
                                }
                                onActivated: (index) => {
                                    root.selectedFormat = model[index].value
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }

            // 3. Fine-tuning Options Row: Perfectly Balanced Ratios
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // FPS Selector (only for animated / video formats)
                StyledComboBox {
                    visible: root.isAnimationFormat
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitWidth: 0
                    implicitHeight: 32
                    buttonIcon: "speed"
                    buttonRadius: 6
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.70)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.fpsOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedFps) return i
                        }
                        return 0
                    }
                    onActivated: (index) => {
                        root.selectedFps = model[index].value
                    }
                }

                // Size Limit Dropdown (Balanced 50% or 100% width)
                StyledComboBox {
                    visible: !root.customLimitActive
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitWidth: 0
                    implicitHeight: 32
                    buttonIcon: "compress"
                    buttonRadius: 6
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.70)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.sizeOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        if (root.customLimitActive) return model.length - 1
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedSizeLimit) return i
                        }
                        return 0
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

                // Custom Limit Input (Takes exact slot)
                RowLayout {
                    visible: root.customLimitActive
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 6
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)
                        border.width: 1
                        border.color: numInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                        TextInput {
                            id: numInput
                            anchors.fill: parent
                            anchors.leftMargin: 6
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

                    Rectangle {
                        implicitHeight: 32
                        implicitWidth: 38
                        radius: 6
                        color: Appearance.colors.colPrimaryContainer

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

                    Rectangle {
                        implicitHeight: 32
                        implicitWidth: 26
                        radius: 6
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.50)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 14
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

            // 4. Short Intro / Status Caption
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.dropStatus === "error"
                    ? Appearance.colors.colError
                    : (root.dropStatus === "done" ? Appearance.colors.colTertiary : Appearance.colors.colOnSurfaceVariant)
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
                text: {
                    switch (root.dropStatus) {
                        case "converting": return root.statusMessage
                        case "done":       return root.statusMessage
                        case "error":      return root.statusMessage
                        case "staged":     return root.statusMessage + " · Click Bake to convert"
                        default:           return root.modeDescription
                    }
                }
            }

            // 5. The Prominent "Bake" Button
            Rectangle {
                id: bakeButton
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Appearance.rounding?.normal ?? 10
                color: {
                    if (root.dropStatus === "converting") return Appearance.colors.colSecondary
                    if (root.dropStatus === "done")       return Appearance.colors.colTertiary
                    if (root.stagedFiles.length > 0)     return bakeHover.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                    return ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, 0.40)
                }
                border.width: 1
                border.color: root.stagedFiles.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialLoadingIndicator {
                        visible: root.dropStatus === "converting"
                        loading: root.dropStatus === "converting"
                        colBg: Appearance.colors.colPrimary
                        colShape: Appearance.colors.colOnPrimary
                        implicitSize: 20
                    }

                    MaterialSymbol {
                        visible: root.dropStatus !== "converting"
                        text: {
                            if (root.dropStatus === "done") return "check_circle"
                            if (root.stagedFiles.length > 0) return "local_fire_department"
                            return "touch_app"
                        }
                        iconSize: 18
                        color: {
                            if (root.stagedFiles.length > 0 || root.dropStatus === "done") return Appearance.colors.colOnPrimary
                            return Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    StyledText {
                        text: {
                            if (root.dropStatus === "converting") return "Baking in progress..."
                            if (root.dropStatus === "done")       return "Baking Complete!"
                            if (root.stagedFiles.length > 0)     return "Bake (" + root.selectedFormat.toUpperCase() + ")"
                            return "Select or Drop a Media File First"
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: {
                            if (root.stagedFiles.length > 0 || root.dropStatus === "done") return Appearance.colors.colOnPrimary
                            return Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }

                MouseArea {
                    id: bakeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.stagedFiles.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.dropStatus === "converting") return
                        if (root.stagedFiles.length > 0) {
                            root.startBake()
                        } else {
                            fileChooserDialog.open()
                        }
                    }
                }
            }
        }

        // Full-Card Drag & Drop Area
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: (drag) => {
                drag.accept(Qt.CopyAction)
                root.dropStatus = "hover"
            }
            onExited: {
                if (root.dropStatus === "hover")
                    root.dropStatus = root.stagedFiles.length > 0 ? "staged" : "idle"
            }
            onDropped: (drop) => {
                if (drop.hasUrls && drop.urls.length > 0) {
                    root.stageFiles(drop.urls)
                } else {
                    root.dropStatus = "error"
                    root.statusMessage = "Could not read dropped file"
                    resetTimer.start()
                }
            }
        }
    }
}