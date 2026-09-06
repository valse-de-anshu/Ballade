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
        // Daily / Regular
        { displayName: "WEBP", value: "webp", icon: "motion_photos_on" },
        { displayName: "PNG",  value: "png",  icon: "image" },
        { displayName: "JPG",  value: "jpg",  icon: "photo" },
        { displayName: "PDF",  value: "pdf",  icon: "picture_as_pdf" },
        // Occasional / Web & Icons
        { displayName: "AVIF", value: "avif", icon: "hd" },
        { displayName: "GIF",  value: "gif",  icon: "gif" },
        { displayName: "ICO",  value: "ico",  icon: "star" },
        { displayName: "BMP",  value: "bmp",  icon: "grid_on" },
        // Professional / Specialized
        { displayName: "TIFF", value: "tiff", icon: "photo_library" },
        { displayName: "HEIC", value: "heic", icon: "camera" },
        { displayName: "JXL",  value: "jxl",  icon: "tune" },
        { displayName: "PSD",  value: "psd",  icon: "brush" },
        { displayName: "TGA",  value: "tga",  icon: "sports_esports" },
        { displayName: "PPM",  value: "ppm",  icon: "terminal" },
    ]

    property list<var> sizeOptions: [
        { displayName: "No Limit", value: 0 },
        { displayName: "4 KB",     value: 4 * 1024 },
        { displayName: "50 KB",    value: 50 * 1024 },
        { displayName: "200 KB",   value: 200 * 1024 },
        { displayName: "500 KB",   value: 500 * 1024 },
        { displayName: "1 MB",     value: 1024 * 1024 },
        { displayName: "2 MB",     value: 2 * 1024 * 1024 },
        { displayName: "5 MB",     value: 5 * 1024 * 1024 },
        { displayName: "10 MB",    value: 10 * 1024 * 1024 },
        { displayName: "Custom...", value: -1 }
    ]

    property string selectedFormat: "webp"
    property int selectedSizeLimit: 0
    property string selectedSizeLabel: "No Limit"

    property bool customLimitActive: false
    property string customNum: "500"
    property string customUnit: "KB" // "KB" or "MB"

    property string dropStatus: "idle"   // idle | hover | converting | done | error
    property string statusMessage: ""

    readonly property var acceptedExtensions: [
        "png","jpg","jpeg","webp","avif","bmp","gif","tiff","tif","ico","tga","heic","heif","jxl","psd","ppm"
    ]
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/ballade/scripts/images/convert_image.py"

    property var fileQueue: []
    property int queueTotal: 0
    property int queueDone: 0
    property var batchPaths: []

    implicitWidth:  310
    implicitHeight: 232

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
        id: pdfMaker
        property string outputPath: ""
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.dropStatus = "done"
                root.statusMessage = root.batchPaths.length === 1
                    ? "Saved: " + outputPath.replace(/.*\//, "")
                    : root.batchPaths.length + " pages → PDF"
            } else {
                root.dropStatus = "error"
                root.statusMessage = "PDF conversion failed"
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
        converter.outputPath = next.replace(/\.[^/.]+$/, "") + tag + "_converted." + root.selectedFormat
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
            pdfMaker.outputPath = outPdf
            pdfMaker.command = ["python3", root.scriptPath, "--pdf", outPdf, "--max-bytes", root.selectedSizeLimit.toString()].concat(valid)
            pdfMaker.running = true
            return
        }

        root.fileQueue = valid.slice(1)
        root.queueTotal = valid.length
        root.queueDone = 0
        root.statusMessage = valid.length > 1 ? "Converting 1 / " + valid.length + "..." : "Converting..."
        converter.inputPath = valid[0]
        converter.outputPath = valid[0].replace(/\.[^/.]+$/, "") + tag + "_converted." + root.selectedFormat
        converter.running = true
    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding?.large ?? 22
        border.width: 1
        border.color: Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.12)

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 10

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "auto_fix_high"
                    iconSize: 18
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: "Image Converter"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                Item { Layout.fillWidth: true }

                // Live Format & Target Size Badge
                Rectangle {
                    radius: 8
                    color: Appearance.colors.colPrimaryContainer
                    implicitHeight: 22
                    implicitWidth: badgeText.implicitWidth + 12

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.selectedFormat.toUpperCase() + (root.selectedSizeLimit > 0 ? (" · " + root.selectedSizeLabel) : "")
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
                        case "hover":      return Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.12)
                        case "converting": return Qt.rgba(Appearance.colors.colSecondary.r, Appearance.colors.colSecondary.g, Appearance.colors.colSecondary.b, 0.12)
                        case "done":       return Qt.rgba(Appearance.colors.colTertiary.r, Appearance.colors.colTertiary.g, Appearance.colors.colTertiary.b, 0.15)
                        case "error":      return Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.15)
                        default:           return Appearance.colors.colSurfaceContainerLow
                    }
                }
                border.color: {
                    switch (root.dropStatus) {
                        case "hover":      return Appearance.colors.colPrimary
                        case "converting": return Appearance.colors.colSecondary
                        case "done":       return Appearance.colors.colTertiary
                        case "error":      return Appearance.colors.colError
                        default:           return Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.15)
                    }
                }
                border.width: root.dropStatus === "hover" ? 2 : 1

                Behavior on color        { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                Behavior on border.color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    width: parent.width - 24

                    MaterialLoadingIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.dropStatus === "converting"
                        loading: root.dropStatus === "converting"
                        colBg: Appearance.colors.colPrimary
                        colShape: Appearance.colors.colOnPrimary
                        implicitSize: 34
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.dropStatus !== "converting"
                        iconSize: 28
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
                                default:      return "cloud_upload"
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        color: {
                            switch (root.dropStatus) {
                                case "hover":  return Appearance.colors.colPrimary
                                case "done":   return Appearance.colors.colTertiary
                                case "error":  return Appearance.colors.colError
                                default:       return Appearance.colors.colOnLayer1
                            }
                        }
                        opacity: root.dropStatus === "idle" ? 0.75 : 1.0
                        text: {
                            switch (root.dropStatus) {
                                case "idle":       return "Drop images to convert"
                                case "hover":      return "Release to start"
                                case "converting": return root.statusMessage
                                case "done":       return root.statusMessage
                                case "error":      return root.statusMessage
                                default:           return ""
                            }
                        }
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
                Layout.fillWidth: true
                spacing: 8

                // Format Selector (supports extensive formats)
                StyledComboBox {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonIcon: "photo"
                    buttonRadius: 10
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colSurfaceContainer
                    colBackgroundActive: Appearance.colors.colSurfaceContainerHigh
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

                // Standard Presets Dropdown (shown when custom mode is inactive)
                StyledComboBox {
                    visible: !root.customLimitActive
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonIcon: "compress"
                    buttonRadius: 10
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colSurfaceContainer
                    colBackgroundActive: Appearance.colors.colSurfaceContainerHigh
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
                    Layout.fillWidth: true
                    spacing: 4

                    // Number Input
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        color: Appearance.colors.colSurfaceContainerLow
                        border.width: 1
                        border.color: numInput.activeFocus ? Appearance.colors.colPrimary : Qt.rgba(Appearance.colors.colOutline.r, Appearance.colors.colOutline.g, Appearance.colors.colOutline.b, 0.2)

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
                        color: Appearance.colors.colSurfaceContainerLow

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