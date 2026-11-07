pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
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

    // Native file dialog for selecting a custom mouse icon / image from disk
    FileDialog {
        id: customCursorDialog
        title: Translation.tr("Select Custom Mouse Icon from Disk")
        nameFilters: [
            Translation.tr("Cursor & Image files (*.png *.svg *.xcursor *.cur *.jpg *.jpeg *.webp)"),
            Translation.tr("All files (*)")
        ]
        onAccepted: {
            const raw = selectedFile.toString().replace(/^file:\/\//, "")
            SystemTheming.setCustomCursorFile(root.selectedActionKey, raw)
        }
    }

    // ── 1. Master Base Theme & Size Card (GroupedList with smooth slider) ──────
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

        ConfigSlider {
            buttonIcon: "zoom_in"
            text: Translation.tr("Cursor size")
            from: 16
            to: 64
            stepSize: 4
            usePercentTooltip: false
            value: SystemTheming.currentCursorSize
            onMoved: {
                SystemTheming.setCursorSize(Math.round(value))
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
                            text: Translation.tr("Click any cursor to select it, then choose an icon below:")
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

                // Grid of 17 symmetrical active cursor tiles (clean, flat, no harsh borders)
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
                            implicitHeight: 82

                            readonly property string tileKey: modelData.key
                            readonly property string tileOverride: Config.options.appearance?.cursor?.overrides?.[tileKey] || ""
                            readonly property bool isOverridden: tileOverride !== "" && tileOverride !== "Default"
                            readonly property string activeTheme: isOverridden ? tileOverride : (SystemTheming.currentCursorTheme || "Gloomi_x")
                            readonly property string previewPath: SystemTheming.getCursorPreview(activeTheme, tileKey)
                            readonly property bool isSelected: root.selectedActionIndex === index

                            buttonRadius: Appearance.rounding.small
                            colBackground: isSelected
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colLayer1
                            colBackgroundHover: isSelected
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colLayer1Hover

                            onClicked: {
                                root.selectedActionIndex = index
                            }

                            contentItem: ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

                                // Symmetrical centered icon
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Image {
                                        id: tileImg
                                        anchors.centerIn: parent
                                        width: 38
                                        height: 38
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
                                        iconSize: 24
                                        color: tileBtn.isSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
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
                                        width: 6
                                        height: 6
                                        radius: 3
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
                                        ? Appearance.colors.colOnSecondaryContainer
                                        : Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // Clean separator
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
                            text: Translation.tr("Click any icon below to apply it immediately:")
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

                // Visual Icon Cards Flow (clean, soft selection, no harsh borders)
                Flow {
                    id: visualIconsFlow
                    Layout.fillWidth: true
                    spacing: 8

                    // 1. "Default (Inherited)" Visual Tile
                    RippleButton {
                        id: defaultCard
                        width: 82
                        implicitHeight: 84
                        readonly property bool isCurrent: !root.selectedActionIsOverridden
                        readonly property string iconSrc: SystemTheming.getCursorPreview(SystemTheming.currentCursorTheme, root.selectedActionKey)

                        buttonRadius: Appearance.rounding.small
                        colBackground: defaultCard.isCurrent
                            ? Appearance.colors.colSecondaryContainer
                            : Appearance.colors.colLayer2
                        colBackgroundHover: defaultCard.isCurrent
                            ? Appearance.colors.colSecondaryContainerHover
                            : Appearance.colors.colLayer2Hover

                        onClicked: {
                            SystemTheming.resetCursorOverride(root.selectedActionKey)
                        }

                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

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
                                    text: "check"
                                    iconSize: 14
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Default")
                                font.pixelSize: 11
                                font.weight: defaultCard.isCurrent ? Font.Bold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                color: defaultCard.isCurrent ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // 2. Installed Theme Visual Tiles
                    Repeater {
                        model: {
                            let themes = SystemTheming.cursorThemes.slice()
                            if (SystemTheming.currentCursorTheme && !themes.includes(SystemTheming.currentCursorTheme)) {
                                themes.push(SystemTheming.currentCursorTheme)
                            }
                            themes.sort()
                            return themes
                        }
                        delegate: RippleButton {
                            id: themeCard
                            required property string modelData

                            width: 82
                            implicitHeight: 84

                            readonly property bool isCurrent: root.selectedActionOverride === modelData
                            readonly property string iconSrc: SystemTheming.getCursorPreview(modelData, root.selectedActionKey)

                            buttonRadius: Appearance.rounding.small
                            colBackground: themeCard.isCurrent
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colLayer2
                            colBackgroundHover: themeCard.isCurrent
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colLayer2Hover

                            onClicked: {
                                if (modelData === SystemTheming.currentCursorTheme) {
                                    SystemTheming.resetCursorOverride(root.selectedActionKey)
                                } else {
                                    SystemTheming.setCursorOverride(root.selectedActionKey, modelData)
                                }
                            }

                            contentItem: ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

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
                                        text: "check"
                                        iconSize: 14
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: themeCard.modelData
                                    font.pixelSize: 11
                                    font.weight: themeCard.isCurrent ? Font.Bold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    color: themeCard.isCurrent ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // 3. Custom File Visual Tile (visible when a custom disk file is active)
                    RippleButton {
                        id: customFileCard
                        visible: root.selectedActionIsCustomFile
                        width: 82
                        implicitHeight: 84

                        readonly property string iconSrc: SystemTheming.getCursorPreview("custom", root.selectedActionKey)

                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover

                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

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
                                    text: "check"
                                    iconSize: 14
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.customFileName
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                color: Appearance.colors.colOnSecondaryContainer
                                elide: Text.ElideMiddle
                            }
                        }
                    }

                    // 4. "+ Add Custom Icon from Disk" Button
                    RippleButton {
                        id: addFromDiskCard
                        width: 82
                        implicitHeight: 84

                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover

                        onClicked: {
                            customCursorDialog.open()
                        }

                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "add_photo_alternate"
                                    iconSize: 28
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("From Disk...")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                color: Appearance.colors.colPrimary
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3. System Themes & Icons (GTK & Icon Themes) ───────────────────────────
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
