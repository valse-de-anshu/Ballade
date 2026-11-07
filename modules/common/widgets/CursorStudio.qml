pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    spacing: 16
    Layout.fillWidth: true

    property int selectedActionIndex: 0
    readonly property var currentAction: (SystemTheming.cursorActions && SystemTheming.cursorActions.length > selectedActionIndex)
        ? SystemTheming.cursorActions[selectedActionIndex]
        : null
    readonly property string selectedActionKey: currentAction ? currentAction.key : "default"
    readonly property string selectedActionOverride: Config.options.appearance?.cursor?.overrides?.[selectedActionKey] || ""
    readonly property bool selectedActionIsOverridden: selectedActionOverride !== "" && selectedActionOverride !== "Default"
    readonly property bool selectedActionIsCustomFile: typeof selectedActionOverride === "string" && (selectedActionOverride.startsWith("/") || selectedActionOverride.startsWith("file://"))
    readonly property string customFileName: selectedActionIsCustomFile
        ? selectedActionOverride.replace(/^file:\/\//, "").split("/").pop()
        : ""

    readonly property int totalOverridesCount: {
        const o = Config.options.appearance?.cursor?.overrides
        return o ? Object.keys(o).filter(k => o[k] && o[k] !== "Default").length : 0
    }

    // In-panel custom icon browser state
    property bool customExplorerOpen: false
    property string customExplorerFolder: Directories.downloads + "/shorekeeper_47394874a2_VSTHEMES-ORG/Cursors"
    property string anyCursorSourceTheme: SystemTheming.currentCursorTheme || "Shorekeeper"

    // Debounce timer for smooth cursor size slider IPC updates
    Timer {
        id: cursorSizeDebounceTimer
        interval: 90
        repeat: false
        onTriggered: {
            SystemTheming.setCursorSize(Math.round(cursorSizeSlider.value))
        }
    }

    // Drag and Drop support anywhere in CursorStudio
    DropArea {
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.hasUrls && drop.urls.length > 0) {
                const url = drop.urls[0].toString()
                const clean = url.replace(/^file:\/\//, "")
                SystemTheming.setCustomCursorFile(root.selectedActionKey, clean)
                drop.acceptProposedAction()
            }
        }
    }

    // ── 1. Master Base Theme & Size Card (with smooth slider & live px indicator) ──
    GroupedList {
        Layout.fillWidth: true

        ConfigComboBox {
            buttonIcon: "mouse"
            text: Translation.tr("Base cursor theme")
            description: Translation.tr("Default cursor pack inherited by all pointer states")
            model: {
                let themes = SystemTheming.cursorThemes.slice()
                if (SystemTheming.currentCursorTheme && !themes.includes(SystemTheming.currentCursorTheme)) {
                    themes.push(SystemTheming.currentCursorTheme)
                }
                themes.sort()
                return themes.map(t => ({ displayName: t, value: t }))
            }
            currentValue: SystemTheming.currentCursorTheme
            onSelected: newValue => {
                SystemTheming.applyCursorTheme(newValue, SystemTheming.currentCursorSize)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            ConfigSlider {
                id: cursorSizeSlider
                Layout.fillWidth: true
                buttonIcon: "zoom_in"
                text: Translation.tr("Cursor size")
                from: 16
                to: 64
                stepSize: 4
                usePercentTooltip: false
                value: SystemTheming.currentCursorSize
                onMoved: {
                    cursorSizeDebounceTimer.restart()
                }
                onPressedChanged: {
                    if (!pressed) {
                        SystemTheming.setCursorSize(Math.round(value))
                    }
                }
            }

            // Crisp live badge showing exact pixel size
            Rectangle {
                implicitWidth: sizeLabel.implicitWidth + 16
                implicitHeight: 26
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimaryContainer

                StyledText {
                    id: sizeLabel
                    anchors.centerIn: parent
                    text: `${Math.round(cursorSizeSlider.value)} px`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }
    }

    // ── 2. Unified Visual Cursor Studio Card ──────────────────────────────────
    ContentSubsection {
        title: Translation.tr("Cursor Studio")

        Rectangle {
            Layout.fillWidth: true
            radius: Appearance.rounding.normal
            color: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.70)
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            implicitHeight: studioMainCol.implicitHeight + 28

            ColumnLayout {
                id: studioMainCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 14

                // Palette Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: Translation.tr("Active Pointer Palette")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Click any pointer state to select it, then choose an icon below:")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }
                    }

                    RippleButton {
                        visible: root.totalOverridesCount > 0
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        padding: 8
                        onClicked: SystemTheming.resetAllCursorOverrides()

                        contentItem: RowLayout {
                            spacing: 6
                            MaterialSymbol {
                                text: "restart_alt"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Reset All")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colPrimary
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                // Grid of 17 symmetrical active cursor tiles (refined Material 3 selection)
                Flow {
                    id: paletteFlow
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: SystemTheming.cursorActions
                        delegate: RippleButton {
                            id: tileBtn
                            required property var modelData
                            required property int index

                            width: Math.floor((paletteFlow.width - (paletteFlow.spacing * 5)) / 6)
                            implicitHeight: 86

                            readonly property string tileKey: modelData.key
                            readonly property string tileOverride: Config.options.appearance?.cursor?.overrides?.[tileKey] || ""
                            readonly property bool isOverridden: tileOverride !== "" && tileOverride !== "Default"
                            readonly property string previewPath: (SystemTheming.cursorPreviewVersion, SystemTheming.getOverridePreview(tileOverride, tileKey))
                            readonly property bool isSelected: root.selectedActionIndex === index

                            buttonRadius: Appearance.rounding.normal
                            colBackground: isSelected
                                ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                                : Appearance.colors.colLayer1
                            colBackgroundHover: isSelected
                                ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)
                                : Appearance.colors.colLayer1Hover

                            onClicked: {
                                root.selectedActionIndex = index
                            }

                            contentItem: Item {
                                anchors.fill: parent

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    // Symmetrical centered icon preview
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Image {
                                            id: tileImg
                                            anchors.centerIn: parent
                                            width: 40
                                            height: 40
                                            fillMode: Image.PreserveAspectFit
                                            source: tileBtn.previewPath
                                            smooth: true
                                            mipmap: true
                                            cache: false
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            visible: tileImg.status !== Image.Ready
                                            text: tileBtn.modelData.icon || "mouse"
                                            iconSize: 26
                                            color: tileBtn.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }

                                        // Subtle accent dot for customized actions
                                        Rectangle {
                                            visible: tileBtn.isOverridden
                                            anchors {
                                                top: parent.top
                                                right: parent.right
                                                topMargin: 2
                                                rightMargin: 2
                                            }
                                            width: 7
                                            height: 7
                                            radius: 3.5
                                            color: Appearance.colors.colPrimary
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: tileBtn.modelData.shortLabel || tileBtn.modelData.label
                                        font.pixelSize: 11
                                        font.weight: tileBtn.isSelected ? Font.Bold : Font.Normal
                                        horizontalAlignment: Text.AlignHCenter
                                        color: tileBtn.isSelected
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                    }
                                }

                                // Refined active indicator pill at bottom
                                Rectangle {
                                    visible: tileBtn.isSelected
                                    anchors {
                                        bottom: parent.bottom
                                        bottomMargin: 3
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width: 26
                                    height: 3
                                    radius: 1.5
                                    color: Appearance.colors.colPrimary
                                }
                            }
                        }
                    }
                }

                // Clean divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                    opacity: 0.35
                }

                // Section: Available Icons for Selected Action
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            text: root.currentAction
                                ? `${Translation.tr("Available Icons for")} ${root.currentAction.label}`
                                : Translation.tr("Available Icons")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnSecondaryContainer
                        }

                        StyledText {
                            text: Translation.tr("Click any icon below to apply immediately, or browse custom files from disk:")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RippleButton {
                        visible: root.selectedActionIsOverridden
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        padding: 6
                        onClicked: SystemTheming.resetCursorOverride(root.selectedActionKey)

                        contentItem: RowLayout {
                            spacing: 4
                            MaterialSymbol {
                                text: "undo"
                                iconSize: 16
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: Translation.tr("Reset to Default")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // Visual Icon Choice Tray
                Flow {
                    id: visualIconsFlow
                    Layout.fillWidth: true
                    spacing: 8

                    // 1. "Default (Inherited)" Visual Tile
                    RippleButton {
                        id: defaultCard
                        width: 84
                        implicitHeight: 86
                        readonly property bool isCurrent: !root.selectedActionIsOverridden
                        readonly property string iconSrc: (SystemTheming.cursorPreviewVersion, SystemTheming.getCursorPreview(SystemTheming.currentCursorTheme, root.selectedActionKey))

                        buttonRadius: Appearance.rounding.normal
                        colBackground: defaultCard.isCurrent
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                            : Appearance.colors.colLayer2
                        colBackgroundHover: defaultCard.isCurrent
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)
                            : Appearance.colors.colLayer2Hover

                        onClicked: {
                            SystemTheming.resetCursorOverride(root.selectedActionKey)
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Image {
                                        anchors.centerIn: parent
                                        width: 38
                                        height: 38
                                        fillMode: Image.PreserveAspectFit
                                        source: defaultCard.iconSrc
                                        smooth: true
                                        mipmap: true
                                        cache: false
                                    }

                                    MaterialSymbol {
                                        visible: defaultCard.isCurrent
                                        anchors { top: parent.top; right: parent.right }
                                        text: "check_circle"
                                        iconSize: 16
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Default")
                                    font.pixelSize: 11
                                    font.weight: defaultCard.isCurrent ? Font.Bold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    color: defaultCard.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                visible: defaultCard.isCurrent
                                anchors {
                                    bottom: parent.bottom
                                    bottomMargin: 3
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: 22
                                height: 3
                                radius: 1.5
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    // 2. Installed Themes Visual Tiles
                    Repeater {
                        model: {
                            let themes = SystemTheming.cursorThemes.slice()
                            if (SystemTheming.currentCursorTheme && !themes.includes(SystemTheming.currentCursorTheme)) {
                                themes.push(SystemTheming.currentCursorTheme)
                            }
                            const priority = ["Shorekeeper", "Columbina-Animated", "Columbina-Static", "catppuccin-mocha-dark-cursors", "macOS", "macOS-White", "Nordzy-cursors", "Bibata-Modern-Classic", "Gloomi_x"]
                            themes.sort((a, b) => {
                                let ia = priority.indexOf(a)
                                let ib = priority.indexOf(b)
                                if (ia !== -1 && ib !== -1) return ia - ib
                                if (ia !== -1) return -1
                                if (ib !== -1) return 1
                                return a.localeCompare(b)
                            })
                            return themes
                        }
                        delegate: RippleButton {
                            id: themeCard
                            required property string modelData

                            width: 84
                            implicitHeight: 86

                            readonly property bool isCurrent: root.selectedActionOverride === modelData || root.selectedActionOverride === (modelData + ":" + root.selectedActionKey)
                            readonly property string iconSrc: (SystemTheming.cursorPreviewVersion, SystemTheming.getCursorPreview(modelData, root.selectedActionKey))

                            buttonRadius: Appearance.rounding.normal
                            colBackground: themeCard.isCurrent
                                ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                                : Appearance.colors.colLayer2
                            colBackgroundHover: themeCard.isCurrent
                                ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)
                                : Appearance.colors.colLayer2Hover

                            onClicked: {
                                if (modelData === SystemTheming.currentCursorTheme) {
                                    SystemTheming.resetCursorOverride(root.selectedActionKey)
                                } else {
                                    SystemTheming.setCursorOverride(root.selectedActionKey, modelData)
                                }
                            }

                            contentItem: Item {
                                anchors.fill: parent

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Image {
                                            anchors.centerIn: parent
                                            width: 38
                                            height: 38
                                            fillMode: Image.PreserveAspectFit
                                            source: themeCard.iconSrc
                                            smooth: true
                                            mipmap: true
                                            cache: false
                                        }

                                        MaterialSymbol {
                                            visible: themeCard.isCurrent
                                            anchors { top: parent.top; right: parent.right }
                                            text: "check_circle"
                                            iconSize: 16
                                            color: Appearance.colors.colPrimary
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: themeCard.modelData
                                        font.pixelSize: 11
                                        font.weight: themeCard.isCurrent ? Font.Bold : Font.Normal
                                        horizontalAlignment: Text.AlignHCenter
                                        color: themeCard.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    visible: themeCard.isCurrent
                                    anchors {
                                        bottom: parent.bottom
                                        bottomMargin: 3
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    width: 22
                                    height: 3
                                    radius: 1.5
                                    color: Appearance.colors.colPrimary
                                }
                            }
                        }
                    }

                    // 3. Custom File Visual Tile (visible when a custom disk file is active)
                    RippleButton {
                        id: customFileCard
                        visible: root.selectedActionIsCustomFile
                        width: 84
                        implicitHeight: 86

                        readonly property string iconSrc: (SystemTheming.cursorPreviewVersion, SystemTheming.getCursorPreview("custom", root.selectedActionKey))

                        buttonRadius: Appearance.rounding.normal
                        colBackground: ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)

                        onClicked: {
                            root.customExplorerOpen = !root.customExplorerOpen
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Image {
                                        anchors.centerIn: parent
                                        width: 38
                                        height: 38
                                        fillMode: Image.PreserveAspectFit
                                        source: customFileCard.iconSrc
                                        smooth: true
                                        mipmap: true
                                        cache: false
                                    }

                                    MaterialSymbol {
                                        anchors { top: parent.top; right: parent.right }
                                        text: "check_circle"
                                        iconSize: 16
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.customFileName
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.colors.colPrimary
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                anchors {
                                    bottom: parent.bottom
                                    bottomMargin: 3
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: 22
                                height: 3
                                radius: 1.5
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    // 4. "+ Custom from Disk" Button (Toggles In-Panel Explorer)
                    RippleButton {
                        id: addFromDiskCard
                        width: 84
                        implicitHeight: 86

                        buttonRadius: Appearance.rounding.normal
                        colBackground: root.customExplorerOpen
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.35)
                            : Appearance.colors.colLayer2
                        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.55)

                        onClicked: {
                            root.customExplorerOpen = !root.customExplorerOpen
                        }

                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.customExplorerOpen ? "folder_open" : "add_photo_alternate"
                                    iconSize: 28
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.customExplorerOpen ? Translation.tr("Close") : Translation.tr("Custom...")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                color: Appearance.colors.colPrimary
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Clean divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                    opacity: 0.35
                }

                // Section: Pick Any Cursor from Any Theme to use as this action
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                text: root.currentAction
                                    ? `${Translation.tr("Use Any Cursor Style as")} ${root.currentAction.label}`
                                    : Translation.tr("Use Any Cursor Style")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnSecondaryContainer
                            }

                            StyledText {
                                text: Translation.tr("Link any pointer style (arrows, crosshairs, anime sprites, grab, etc.) to this action:")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Theme selector chips / scroll row
                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        contentWidth: themePillsRow.implicitWidth
                        contentHeight: 38
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        RowLayout {
                            id: themePillsRow
                            spacing: 6

                            Repeater {
                                model: {
                                    let themes = SystemTheming.cursorThemes.slice()
                                    if (SystemTheming.currentCursorTheme && !themes.includes(SystemTheming.currentCursorTheme)) {
                                        themes.push(SystemTheming.currentCursorTheme)
                                    }
                                    const priority = ["Shorekeeper", "Columbina-Animated", "Columbina-Static", "catppuccin-mocha-dark-cursors", "macOS", "macOS-White", "Nordzy-cursors", "Bibata-Modern-Classic", "Gloomi_x"]
                                    themes.sort((a, b) => {
                                        let ia = priority.indexOf(a)
                                        let ib = priority.indexOf(b)
                                        if (ia !== -1 && ib !== -1) return ia - ib
                                        if (ia !== -1) return -1
                                        if (ib !== -1) return 1
                                        return a.localeCompare(b)
                                    })
                                    return themes
                                }
                                delegate: RippleButton {
                                    id: themePill
                                    required property string modelData
                                    readonly property bool isSelected: root.anyCursorSourceTheme === modelData

                                    buttonRadius: Appearance.rounding.full
                                    colBackground: isSelected
                                        ? Appearance.colors.colPrimaryContainer
                                        : Appearance.colors.colLayer2
                                    colBackgroundHover: isSelected
                                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.8)
                                        : Appearance.colors.colLayer2Hover
                                    padding: 6

                                    onClicked: {
                                        root.anyCursorSourceTheme = modelData
                                    }

                                    contentItem: RowLayout {
                                        spacing: 5
                                        MaterialSymbol {
                                            text: themePill.isSelected ? "check" : "palette"
                                            iconSize: 14
                                            color: themePill.isSelected
                                                ? Appearance.colors.colOnPrimaryContainer
                                                : Appearance.colors.colSubtext
                                        }
                                        StyledText {
                                            text: themePill.modelData
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: themePill.isSelected ? Font.Bold : Font.Normal
                                            color: themePill.isSelected
                                                ? Appearance.colors.colOnPrimaryContainer
                                                : Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Grid of all 17 cursor icons available in root.anyCursorSourceTheme
                    Flow {
                        id: anyCursorFlow
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: SystemTheming.cursorActions
                            delegate: RippleButton {
                                id: anyCursorBtn
                                required property var modelData

                                width: 84
                                implicitHeight: 86

                                readonly property string targetOverride: root.anyCursorSourceTheme + ":" + modelData.key
                                readonly property bool isSelected: root.selectedActionOverride === anyCursorBtn.targetOverride
                                readonly property string iconSrc: (SystemTheming.cursorPreviewVersion, SystemTheming.getCursorPreview(root.anyCursorSourceTheme, modelData.key))

                                buttonRadius: Appearance.rounding.normal
                                colBackground: anyCursorBtn.isSelected
                                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                                    : Appearance.colors.colLayer2
                                colBackgroundHover: anyCursorBtn.isSelected
                                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)
                                    : Appearance.colors.colLayer2Hover

                                onClicked: {
                                    if (anyCursorBtn.isSelected) {
                                        SystemTheming.resetCursorOverride(root.selectedActionKey)
                                    } else {
                                        SystemTheming.setCursorOverride(root.selectedActionKey, anyCursorBtn.targetOverride)
                                    }
                                }

                                contentItem: Item {
                                    anchors.fill: parent

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 4

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            Image {
                                                anchors.centerIn: parent
                                                width: 38
                                                height: 38
                                                fillMode: Image.PreserveAspectFit
                                                source: anyCursorBtn.iconSrc
                                                smooth: true
                                                mipmap: true
                                                cache: false
                                            }

                                            MaterialSymbol {
                                                visible: anyCursorBtn.isSelected
                                                anchors { top: parent.top; right: parent.right }
                                                text: "check_circle"
                                                iconSize: 16
                                                color: Appearance.colors.colPrimary
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: anyCursorBtn.modelData.shortLabel || anyCursorBtn.modelData.label
                                            font.pixelSize: 11
                                            font.weight: anyCursorBtn.isSelected ? Font.Bold : Font.Normal
                                            horizontalAlignment: Text.AlignHCenter
                                            color: anyCursorBtn.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        visible: anyCursorBtn.isSelected
                                        anchors {
                                            bottom: parent.bottom
                                            bottomMargin: 3
                                            horizontalCenter: parent.horizontalCenter
                                        }
                                        width: 22
                                        height: 3
                                        radius: 1.5
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 3. Embedded In-Panel Custom Icon Explorer ─────────────────────────
                // Zero window collisions, immune to Hyprland priority conflicts!
                ColumnLayout {
                    id: customExplorerSection
                    visible: root.customExplorerOpen
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.colors.colLayer0Border
                        opacity: 0.25
                    }

                    // Quick Folder Selection Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: Translation.tr("Browse:")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            font.weight: Font.Medium
                        }

                        // Shorekeeper Downloaded Pack Tab
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            readonly property string shorekeeperPath: Directories.downloads + "/shorekeeper_47394874a2_VSTHEMES-ORG/Cursors"
                            readonly property bool active: root.customExplorerFolder === shorekeeperPath
                            colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            padding: 6
                            onClicked: root.customExplorerFolder = shorekeeperPath
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "auto_awesome"
                                    iconSize: 16
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: "Shorekeeper"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Columbina Downloaded Pack Tab
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            readonly property string columbinaPath: Directories.downloads + "/shorekeeper_47394874a2_VSTHEMES-ORG/columbina-genshin_c4cdb91178_VSTHEMES-ORG/Windows"
                            readonly property bool active: root.customExplorerFolder === columbinaPath
                            colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            padding: 6
                            onClicked: root.customExplorerFolder = columbinaPath
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "stars"
                                    iconSize: 16
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: "Columbina"
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Downloads Folder Tab
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            readonly property bool active: root.customExplorerFolder === Directories.downloads
                            colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            padding: 6
                            onClicked: root.customExplorerFolder = Directories.downloads
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "download"
                                    iconSize: 16
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: Translation.tr("Downloads")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Installed Icons Tab
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            readonly property bool active: root.customExplorerFolder === (Directories.home + "/.icons")
                            colBackground: active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            padding: 6
                            onClicked: root.customExplorerFolder = Directories.home + "/.icons"
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "category"
                                    iconSize: 16
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: Translation.tr("Installed")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: parent.parent.active ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // External File Manager launch (safely dismisses Settings so Dolphin gets 100% priority)
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            padding: 6
                            onClicked: {
                                GlobalStates.settingsOpen = false
                                Quickshell.execDetached(["dolphin", FileUtils.trimFileProtocol(root.customExplorerFolder)])
                            }
                            contentItem: RowLayout {
                                spacing: 4
                                MaterialSymbol {
                                    text: "open_in_new"
                                    iconSize: 16
                                    color: Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: Translation.tr("Open Dolphin")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }

                    // Direct path entry field
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: pathInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                MaterialSymbol {
                                    text: "search"
                                    iconSize: 18
                                    color: Appearance.colors.colSubtext
                                }

                                TextInput {
                                    id: pathInput
                                    Layout.fillWidth: true
                                    text: FileUtils.trimFileProtocol(root.customExplorerFolder)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSecondaryContainer
                                    clip: true
                                    onAccepted: {
                                        root.customExplorerFolder = text.trim()
                                    }
                                }
                            }
                        }

                        RippleButton {
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimaryContainer
                            colBackgroundHover: Appearance.colors.colPrimary
                            padding: 8
                            onClicked: {
                                const clean = FileUtils.trimFileProtocol(pathInput.text.trim())
                                if (clean !== "") {
                                    // If pointing directly to a file, apply it immediately
                                    if (/\.(png|svg|xcursor|cur|jpg|jpeg|webp)$/i.test(clean)) {
                                        SystemTheming.setCustomCursorFile(root.selectedActionKey, clean)
                                    } else {
                                        root.customExplorerFolder = clean
                                    }
                                }
                            }
                            contentItem: StyledText {
                                text: Translation.tr("Apply")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }

                    // Quick Install Pack Action Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RippleButton {
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimaryContainer
                            colBackgroundHover: Appearance.colors.colPrimary
                            padding: 8
                            onClicked: {
                                const folder = FileUtils.trimFileProtocol(root.customExplorerFolder)
                                Quickshell.execDetached([
                                    "bash", "-c",
                                    `python3 "${SystemTheming.scriptDir}/cursor_manager.py" import-pack "${folder}" && qs -c ballade ipc call systemTheming rescanThemes 2>/dev/null || true`
                                ])
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                MaterialSymbol {
                                    text: "install_desktop"
                                    iconSize: 18
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                                StyledText {
                                    text: Translation.tr("Install this folder as a System Cursor Theme")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Embedded Folder Model & Image Thumbnail Flow
                    FolderListModel {
                        id: customFolderModel
                        folder: {
                            const p = root.customExplorerFolder
                            if (!p || p.trim() === "") return ""
                            const trimmed = p.trim()
                            return trimmed.startsWith("file://") ? trimmed : ("file://" + trimmed)
                        }
                        showDirs: false
                        nameFilters: ["*.ani", "*.cur", "*.xcursor", "*.png", "*.svg"]
                    }

                    // Thumbnail Flow
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(76, customFolderModel.count === 0 ? 50 : explorerFlow.implicitHeight)

                        // Empty State
                        StyledText {
                            visible: customFolderModel.count === 0
                            anchors.centerIn: parent
                            text: Translation.tr("No images or cursors found in this folder. Drop an image here or change path.")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        Flow {
                            id: explorerFlow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 8

                            Repeater {
                                model: customFolderModel
                                delegate: RippleButton {
                                    id: thumbItem
                                    required property string fileName
                                    required property string filePath

                                    readonly property bool isCurrent: FileUtils.trimFileProtocol(thumbItem.filePath.toString()) === FileUtils.trimFileProtocol(root.selectedActionOverride)

                                    width: 76
                                    implicitHeight: 78
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: thumbItem.isCurrent
                                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.45)
                                        : Appearance.colors.colLayer2
                                    colBackgroundHover: thumbItem.isCurrent
                                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.65)
                                        : Appearance.colors.colLayer2Hover

                                    onClicked: {
                                        const clean = FileUtils.trimFileProtocol(thumbItem.filePath.toString())
                                        SystemTheming.setCustomCursorFile(root.selectedActionKey, clean)
                                    }

                                    contentItem: Item {
                                        anchors.fill: parent

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            spacing: 2

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                Image {
                                                    id: thumbImg
                                                    anchors.centerIn: parent
                                                    width: 38
                                                    height: 38
                                                    fillMode: Image.PreserveAspectFit
                                                    source: thumbItem.filePath
                                                    smooth: true
                                                    mipmap: true
                                                    cache: false
                                                }

                                                MaterialSymbol {
                                                    anchors.centerIn: parent
                                                    visible: thumbImg.status !== Image.Ready
                                                    text: "mouse"
                                                    iconSize: 22
                                                    color: thumbItem.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                                }

                                                MaterialSymbol {
                                                    visible: thumbItem.isCurrent
                                                    anchors { top: parent.top; right: parent.right }
                                                    text: "check_circle"
                                                    iconSize: 14
                                                    color: Appearance.colors.colPrimary
                                                }
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: thumbItem.fileName
                                                font.pixelSize: 10
                                                horizontalAlignment: Text.AlignHCenter
                                                color: thumbItem.isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                                elide: Text.ElideMiddle
                                            }
                                        }

                                        Rectangle {
                                            visible: thumbItem.isCurrent
                                            anchors {
                                                bottom: parent.bottom
                                                bottomMargin: 2
                                                horizontalCenter: parent.horizontalCenter
                                            }
                                            width: 20
                                            height: 2.5
                                            radius: 1.25
                                            color: Appearance.colors.colPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 4. System Themes & Icons (GTK & Icon Themes) ───────────────────────────
    ContentSubsection {
        title: Translation.tr("System Themes & Icons")

        GroupedList {
            ConfigComboBox {
                buttonIcon: "shapes"
                text: Translation.tr("Icon theme")
                description: Translation.tr("System-wide icon pack for desktop apps and file managers")
                model: {
                    let themes = SystemTheming.iconThemes.slice()
                    if (SystemTheming.currentIconTheme && !themes.includes(SystemTheming.currentIconTheme)) {
                        themes.push(SystemTheming.currentIconTheme)
                    }
                    themes.sort()
                    return themes.map(t => ({ displayName: t, value: t }))
                }
                currentValue: SystemTheming.currentIconTheme
                onSelected: newValue => {
                    SystemTheming.applyIconTheme(newValue)
                }
            }

            ConfigComboBox {
                buttonIcon: "palette"
                text: Translation.tr("GTK application theme")
                description: Translation.tr("Widget style for GTK applications")
                model: {
                    let themes = SystemTheming.gtkThemes.slice()
                    if (SystemTheming.currentGtkTheme && !themes.includes(SystemTheming.currentGtkTheme)) {
                        themes.push(SystemTheming.currentGtkTheme)
                    }
                    themes.sort()
                    return themes.map(t => ({ displayName: t, value: t }))
                }
                currentValue: SystemTheming.currentGtkTheme
                onSelected: newValue => {
                    SystemTheming.applyGtkTheme(newValue)
                }
            }
        }
    }
}
