pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "images"

    // Balanced, constant geometry — zero jiggle or size shifting
    implicitWidth: 240
    implicitHeight: 156

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
        { displayName: "No Limit",  value: 0 },
        { displayName: "Custom...", value: -1 },
        { displayName: "50 KB",     value: 50 * 1024 },
        { displayName: "200 KB",    value: 200 * 1024 },
        { displayName: "500 KB",    value: 500 * 1024 },
        { displayName: "1 MB",      value: 1024 * 1024 },
        { displayName: "2 MB",      value: 2 * 1024 * 1024 },
        { displayName: "5 MB",      value: 5 * 1024 * 1024 },
        { displayName: "10 MB",     value: 10 * 1024 * 1024 },
        { displayName: "25 MB",     value: 25 * 1024 * 1024 },
        { displayName: "50 MB",     value: 50 * 1024 * 1024 }
    ]

    property string selectedFormat: "webp"
    property int selectedFps: 24
    property int selectedSizeLimit: 0
    property string selectedSizeLabel: "No Limit"

    readonly property bool isAnimationFormat: selectedFormat === "animate" || selectedFormat === "mp4" || selectedFormat === "gif"

    property bool customLimitActive: false
    property string customNum: "500"
    property string customUnit: "KB" // "KB" or "MB"

    property bool isUserTyping: false
    onIsUserTypingChanged: {
        GlobalStates.desktopWidgetKeyboardFocus = isUserTyping
    }
    Component.onDestruction: {
        if (root.isUserTyping) {
            GlobalStates.desktopWidgetKeyboardFocus = false
        }
    }

    function activateCustomInput() {
        root.customLimitActive = true
        root.applyCustomLimit()
        root.isUserTyping = true
        GlobalStates.desktopWidgetKeyboardFocus = true
        Qt.callLater(() => {
            if (numInput) {
                numInput.forceActiveFocus()
                numInput.selectAll()
            }
        })
    }

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
        if (!root.customLimitActive) return
        var raw = parseFloat(root.customNum)
        if (isNaN(raw) || raw <= 0) {
            root.selectedSizeLimit = 0
            root.selectedSizeLabel = "Custom"
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
        root.isUserTyping = false
        if (numInput) numInput.focus = false
        GlobalStates.desktopWidgetKeyboardFocus = false
    }

    function stageFiles(urls) {
        var valid = []
        for (var i = 0; i < urls.length; i++) {
            var raw = urls[i].toString().trim()
            if (!raw) continue
            var unquoted = raw.replace(/^file:\/\//, "")
            try {
                unquoted = decodeURIComponent(unquoted)
            } catch (e) {}
            var cleanPath = unquoted.trim().replace(/^['"]|['"]$/g, "")
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
        statProc.running = false
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
            batchMaker.running = false
            batchMaker.running = true
            return
        }

        if (root.selectedFormat === "animate" || (valid.length > 1 && (root.selectedFormat === "mp4" || root.selectedFormat === "gif"))) {
            root.batchPaths = valid
            const isGif = root.selectedFormat === "gif"
            const outExt = isGif ? "gif" : "mp4"
            root.statusMessage = "Compiling " + valid.length + " frames (" + root.selectedFps + " FPS)..."
            var outAnim = valid[0].replace(/\.[^/.]+$/, "") + "_animated" + tag + "." + outExt
            batchMaker.outputPath = outAnim
            batchMaker.command = ["python3", root.scriptPath, "--animate", outAnim, "--fps", root.selectedFps.toString(), "--max-bytes", root.selectedSizeLimit.toString()].concat(valid)
            batchMaker.running = false
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
        converter.running = false
        converter.running = true
    }

    FileDialog {
        id: fileChooserDialog
        title: Translation.tr("Select Media or Image Files to Convert")
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "Media files (*.png *.jpg *.jpeg *.webp *.avif *.gif *.mp4 *.webm *.mkv *.mov *.avi *.bmp *.tiff *.tif *.ico *.heic *.heif *.jxl *.psd *.ppm *.tga)",
            "Images (*.png *.jpg *.jpeg *.webp *.avif *.gif *.bmp *.tiff *.tif *.ico *.heic *.heif *.jxl *.psd *.ppm *.tga)",
            "Videos (*.mp4 *.webm *.mkv *.mov *.avi *.flv)",
            "All files (*)"
        ]
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
        command: [
            "bash", "-c",
            "if wl-paste -l 2>/dev/null | grep -q '^image/'; then " +
            "  mkdir -p /tmp/quickshell/media && out=\"/tmp/quickshell/media/clipboard_$(date +%s%N).png\" && wl-paste > \"$out\" && echo \"$out\"; " +
            "else " +
            "  wl-paste -t text/uri-list 2>/dev/null || wl-paste 2>/dev/null; " +
            "fi"
        ]
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
        property string lastError: ""
        command: [
            "python3",
            root.scriptPath,
            "--input", inputPath,
            "--output", outputPath,
            "--format", root.selectedFormat,
            "--fps", root.selectedFps.toString(),
            "--max-bytes", root.selectedSizeLimit.toString()
        ]
        stderr: StdioCollector {
            onDataChanged: {
                if (text && text.trim().length > 0) {
                    converter.lastError = text.trim()
                }
            }
        }
        onExited: (exitCode) => {
            root.queueDone++
            if (exitCode !== 0) {
                root.dropStatus = "error"
                var errMsg = converter.lastError ? converter.lastError.split("\n").pop() : "Failed"
                if (errMsg.length > 35) errMsg = errMsg.substring(0, 32) + "..."
                root.statusMessage = errMsg
                console.warn("[ImageConverter] Error converting " + inputPath + ": " + converter.lastError)
                root.fileQueue = []
                root.queueTotal = 0
                root.queueDone = 0
                resetTimer.start()
                return
            }
            converter.lastError = ""
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
        property string lastError: ""
        stderr: StdioCollector {
            onDataChanged: {
                if (text && text.trim().length > 0) {
                    batchMaker.lastError = text.trim()
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                batchMaker.lastError = ""
                root.dropStatus = "done"
                root.statusMessage = "Saved: " + outputPath.replace(/.*\//, "")
            } else {
                root.dropStatus = "error"
                var errMsg = batchMaker.lastError ? batchMaker.lastError.split("\n").pop() : "Conversion failed"
                if (errMsg.length > 35) errMsg = errMsg.substring(0, 32) + "..."
                root.statusMessage = errMsg
                console.warn("[ImageConverter] Batch error: " + batchMaker.lastError)
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
        converter.running = false
        converter.running = true
    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: Appearance.rounding?.large ?? 20
        property color fill: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            0.12
        )
        color: (Config.options?.background?.widgets?.glass?.enable && fill.a > 0) ? "transparent" : fill
        border.width: root.dropStatus === "hover" ? 1 : 0
        border.color: root.dropStatus === "hover" ? Appearance.colors.colPrimary : "transparent"
        clip: true

        WindowGlass {
            anchors.fill: parent
            cardRadius: contentItem.radius
            tint: contentItem.fill
            glassEnabled: (Config.options?.background?.widgets?.glass?.enable ?? false)
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 6

            // 1. Sleek Icon-Only Header Bar (Zero redundant text)
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 22
                spacing: 6

                MaterialSymbol {
                    text: root.stagedFiles.length > 0 ? "local_fire_department" : "auto_fix_high"
                    iconSize: 18
                    color: root.stagedFiles.length > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                }

                // Staged media filename badge (only visible when staged)
                StyledText {
                    visible: root.stagedFiles.length > 0
                    Layout.fillWidth: true
                    text: root.stagedFiles.length > 1
                        ? (root.stagedFiles.length + " files")
                        : (root.detectedFileName + (root.stagedFileSize > 0 ? (" · " + root.formatBytes(root.stagedFileSize)) : ""))
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                    color: Appearance.colors.colOnLayer1
                }

                Item {
                    visible: root.stagedFiles.length === 0
                    Layout.fillWidth: true
                }

                // Clear / Reset Button
                Rectangle {
                    visible: root.stagedFiles.length > 0
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: Appearance.rounding.full
                    color: clearHover.containsMouse
                        ? Appearance.colors.colErrorContainer
                        : Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.16)
                    border.width: 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 13
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

                // Quick Paste Button
                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: Appearance.rounding.full
                    color: pasteHover.containsMouse
                        ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                        : Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.16)
                    border.width: 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_paste"
                        iconSize: 13
                        color: pasteHover.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
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
            }

            // 2. Direct Format Selector (No arrow, full width, minimal)
            StyledComboBox {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: 10
                btnPadding: 10
                colBackground: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)
                colBackgroundHover: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
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

            // 3. Settings Row: FPS & Size Limit
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 32
                spacing: 6

                // FPS Selector (only for animated / video formats)
                StyledComboBox {
                    visible: root.isAnimationFormat
                    Layout.fillWidth: true
                    implicitHeight: 32
                    buttonIcon: "speed"
                    buttonRadius: 10
                    btnPadding: 8
                    colBackground: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)
                    colBackgroundHover: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
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

                // Size Limit Dropdown
                StyledComboBox {
                    visible: !root.customLimitActive
                    Layout.fillWidth: true
                    implicitHeight: 32
                    buttonIcon: "compress"
                    buttonRadius: 10
                    btnPadding: 10
                    colBackground: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)
                    colBackgroundHover: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                    colBackgroundActive: Appearance.colors.colPrimaryContainer
                    model: root.sizeOptions
                    textRole: "displayName"
                    valueRole: "value"
                    currentIndex: {
                        if (root.customLimitActive) {
                            for (var j = 0; j < model.length; j++) {
                                if (model[j].value === -1) return j
                            }
                        }
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === root.selectedSizeLimit) return i
                        }
                        return 0
                    }
                    onActivated: (index) => {
                        if (model[index].value === -1) {
                            root.activateCustomInput()
                        } else {
                            root.customLimitActive = false
                            root.selectedSizeLimit = model[index].value
                            root.selectedSizeLabel = model[index].displayName
                            root.isUserTyping = false
                            if (numInput) numInput.focus = false
                            GlobalStates.desktopWidgetKeyboardFocus = false
                        }
                    }
                }

                // Custom Limit Input Pill
                RowLayout {
                    visible: root.customLimitActive
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)
                        border.width: numInput.activeFocus ? 1 : 0
                        border.color: numInput.activeFocus ? Appearance.colors.colPrimary : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            MaterialSymbol {
                                text: "tune"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                            }

                            TextInput {
                                id: numInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                color: Appearance.colors.colOnSurface
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.main
                                selectByMouse: true
                                text: root.customNum
                                validator: RegularExpressionValidator {
                                    regularExpression: /^[0-9]*\.?[0-9]{0,2}$/
                                }
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                onTextChanged: {
                                    root.customNum = text
                                    root.applyCustomLimit()
                                }
                                onAccepted: {
                                    root.applyCustomLimit()
                                    root.isUserTyping = false
                                    numInput.focus = false
                                    GlobalStates.desktopWidgetKeyboardFocus = false
                                }
                                onActiveFocusChanged: {
                                    root.isUserTyping = activeFocus
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                root.isUserTyping = true
                                GlobalStates.desktopWidgetKeyboardFocus = true
                                Qt.callLater(() => {
                                    numInput.forceActiveFocus()
                                })
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: 36
                        radius: 10
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
                        Layout.fillHeight: true
                        implicitWidth: 26
                        radius: 10
                        color: Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 13
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.customLimitActive = false
                                root.selectedSizeLimit = 0
                                root.selectedSizeLabel = "No Limit"
                                root.isUserTyping = false
                                numInput.focus = false
                                GlobalStates.desktopWidgetKeyboardFocus = false
                            }
                        }
                    }
                }
            }

            // 4. Compact Action Button
            Rectangle {
                id: bakeButton
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Appearance.rounding.full
                color: {
                    if (root.dropStatus === "converting") return Appearance.colors.colSecondary
                    if (root.dropStatus === "done")       return Appearance.colors.colTertiary
                    if (root.dropStatus === "error")      return Appearance.colors.colErrorContainer
                    if (root.stagedFiles.length > 0)     return bakeHover.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                    return bakeHover.containsMouse
                        ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.22)
                        : Qt.rgba(Appearance.colors.colLayer0Base.r, Appearance.colors.colLayer0Base.g, Appearance.colors.colLayer0Base.b, 0.14)
                }

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
                        implicitSize: 16
                    }

                    MaterialSymbol {
                        visible: root.dropStatus !== "converting"
                        text: {
                            if (root.dropStatus === "done") return "check_circle"
                            if (root.dropStatus === "error") return "warning"
                            if (root.stagedFiles.length > 0) return "local_fire_department"
                            return "add"
                        }
                        iconSize: 16
                        color: {
                            if (root.stagedFiles.length > 0 || root.dropStatus === "done") return Appearance.colors.colOnPrimary
                            if (root.dropStatus === "error") return Appearance.colors.colOnErrorContainer
                            return Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    StyledText {
                        text: {
                            if (root.dropStatus === "converting") return root.fileQueue.length > 0 ? ("Baking " + (root.queueDone + 1) + " / " + root.queueTotal) : "Baking..."
                            if (root.dropStatus === "done")       return "Complete"
                            if (root.dropStatus === "error")      return "Failed"
                            if (root.stagedFiles.length > 0)     return "Convert"
                            return "Choose File"
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: {
                            if (root.stagedFiles.length > 0 || root.dropStatus === "done") return Appearance.colors.colOnPrimary
                            if (root.dropStatus === "error") return Appearance.colors.colOnErrorContainer
                            return Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }

                MouseArea {
                    id: bakeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isUserTyping = false
                        if (numInput) numInput.focus = false
                        GlobalStates.desktopWidgetKeyboardFocus = false
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
            onEntered: (drag) => {
                drag.accept(Qt.CopyAction)
                root.dropStatus = "hover"
            }
            onExited: {
                if (root.dropStatus === "hover")
                    root.dropStatus = root.stagedFiles.length > 0 ? "staged" : "idle"
            }
            onDropped: (drop) => {
                var urls = []
                if (drop.hasUrls && drop.urls.length > 0) {
                    urls = drop.urls
                } else if (drop.hasText && drop.text.length > 0) {
                    var lines = drop.text.trim().split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        var l = lines[i].trim()
                        if (l) urls.push(l)
                    }
                }
                if (urls.length > 0) {
                    root.stageFiles(urls)
                } else {
                    root.dropStatus = "error"
                    root.statusMessage = "Could not read dropped file"
                    resetTimer.start()
                }
            }
        }
    }
}