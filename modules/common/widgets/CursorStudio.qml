pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    readonly property string selectedActionEffectiveTheme: selectedActionIsOverridden
        ? selectedActionOverride
        : (SystemTheming.currentCursorTheme || "Gloomi_x")

    readonly property int totalOverridesCount: {
        const o = Config.options.appearance?.cursor?.overrides
        return o ? Object.keys(o).filter(k => o[k] && o[k] !== "Default").length : 0
    }

    // ── 1. Master Base Theme & Size Card ──────────────────────────────────────
    GroupedList {
        Layout.fillWidth: true

        ConfigComboBox {
            buttonIcon: "mouse"
            text: Translation.tr("Base cursor theme")
            description: Translation.tr("Active cursor pack used as default for all pointer states")
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

        ConfigSpinBox {
            id: cursorSizeSpin
            icon: "zoom_in"
            text: Translation.tr("Cursor size")
            value: SystemTheming.currentCursorSize
            from: 16; to: 64; stepSize: 2
            onValueChanged: {
                if (value === SystemTheming.currentCursorSize) return
                cursorSizeApplyTimer.restart()
            }
            Timer {
                id: cursorSizeApplyTimer
                interval: 400
                repeat: false
                onTriggered: SystemTheming.applyCursorTheme(SystemTheming.currentCursorTheme, cursorSizeSpin.value)
            }
        }
    }

    // ── 2. Action Grid Header ─────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Cursor Action Studio")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSecondaryContainer
                }

                Rectangle {
                    radius: 10
                    color: root.totalOverridesCount > 0
                        ? Appearance.colors.colPrimary
                        : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.12)
                    implicitHeight: 20
                    implicitWidth: overrideBadgeText.implicitWidth + 12

                    StyledText {
                        id: overrideBadgeText
                        anchors.centerIn: parent
                        text: root.totalOverridesCount > 0
                            ? `${root.totalOverridesCount} ${Translation.tr("Custom")}`
                            : Translation.tr("All Default")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: root.totalOverridesCount > 0
                            ? Appearance.colors.colOnPrimary
                            : Appearance.colors.colSubtext
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Click any action tile to inspect and customize its cursor shape from any installed theme.")
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

    // ── 3. Cursor Action Tiles Grid ───────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        radius: Appearance.rounding.normal
        color: ColorUtils.applyAlpha(Appearance.colors.colLayer1Base, 0.50)
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        implicitHeight: gridFlow.implicitHeight + 20

        Flow {
            id: gridFlow
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10
            }
            spacing: 8

            Repeater {
                model: SystemTheming.cursorActions
                delegate: RippleButton {
                    id: tileButton
                    required property var modelData
                    required property int index

                    width: Math.floor((gridFlow.width - (gridFlow.spacing * 5)) / 6)
                    implicitHeight: 94

                    readonly property string tileKey: modelData.key
                    readonly property string tileOverride: Config.options.appearance?.cursor?.overrides?.[tileKey] || ""
                    readonly property bool isOverridden: tileOverride !== "" && tileOverride !== "Default"
                    readonly property string activeTheme: isOverridden ? tileOverride : (SystemTheming.currentCursorTheme || "Gloomi_x")
                    readonly property string previewPath: SystemTheming.getCursorPreview(activeTheme, tileKey)
                    readonly property bool isSelected: root.selectedActionIndex === index

                    buttonRadius: 14
                    colBackground: isSelected
                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                        : isOverridden
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.08)
                            : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected
                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25)
                        : Appearance.colors.colLayer1Hover

                    border: true
                    borderWidth: isSelected ? 2 : 1
                    colBorder: isSelected
                        ? Appearance.colors.colPrimary
                        : isOverridden
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.45)
                            : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.10)

                    onClicked: {
                        root.selectedActionIndex = index
                    }

                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        // Preview box with optional custom indicator
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.centerIn: parent
                                width: 42
                                height: 42
                                radius: 10
                                color: tileButton.isSelected
                                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25)
                                    : Appearance.colors.colLayer2

                                Image {
                                    id: tileCursorImg
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    fillMode: Image.PreserveAspectFit
                                    source: tileButton.previewPath
                                    smooth: false
                                    scale: tileButton.hovered ? 1.15 : 1.0

                                    Behavior on scale {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                    }
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: tileCursorImg.status !== Image.Ready
                                    text: tileButton.modelData.icon || "mouse"
                                    iconSize: 22
                                    color: tileButton.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }
                            }

                            // Accent badge for custom overrides
                            Rectangle {
                                visible: tileButton.isOverridden
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    topMargin: -2
                                    rightMargin: -2
                                }
                                width: 8
                                height: 8
                                radius: 4
                                color: Appearance.colors.colPrimary
                                border.width: 1
                                border.color: Appearance.colors.colLayer1Base
                            }
                        }

                        // Action label
                        StyledText {
                            Layout.fillWidth: true
                            text: tileButton.modelData.shortLabel || tileButton.modelData.label
                            font.pixelSize: 11
                            font.weight: tileButton.isSelected ? Font.Bold : Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            color: tileButton.isSelected
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // ── 4. Selected Cursor Action Inspector ───────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        implicitHeight: inspectorCol.implicitHeight + 24

        ColumnLayout {
            id: inspectorCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 12

            // Top inspector row: Preview + Title/Desc + Reset button
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    Layout.alignment: Qt.AlignVCenter
                    radius: 12
                    color: root.selectedActionIsOverridden
                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.20)
                        : Appearance.colors.colLayer2
                    border.width: 1.5
                    border.color: root.selectedActionIsOverridden
                        ? Appearance.colors.colPrimary
                        : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.15)

                    Image {
                        id: inspectLargeImg
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        fillMode: Image.PreserveAspectFit
                        source: SystemTheming.getCursorPreview(root.selectedActionEffectiveTheme, root.selectedActionKey)
                        smooth: false
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: inspectLargeImg.status !== Image.Ready
                        text: root.currentAction ? root.currentAction.icon : "mouse"
                        iconSize: 28
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    RowLayout {
                        spacing: 8
                        StyledText {
                            text: root.currentAction ? root.currentAction.label : ""
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }

                        Rectangle {
                            radius: 6
                            color: root.selectedActionIsOverridden
                                ? Appearance.colors.colPrimary
                                : ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.12)
                            implicitHeight: 20
                            implicitWidth: activePillText.implicitWidth + 10

                            StyledText {
                                id: activePillText
                                anchors.centerIn: parent
                                text: root.selectedActionIsOverridden
                                    ? `Custom: ${root.selectedActionOverride}`
                                    : `Default: ${SystemTheming.currentCursorTheme || "Gloomi_x"}`
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.DemiBold
                                color: root.selectedActionIsOverridden
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.currentAction ? root.currentAction.desc : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                RippleButton {
                    visible: root.selectedActionIsOverridden
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    padding: 8
                    onClicked: {
                        SystemTheming.resetCursorOverride(root.selectedActionKey)
                    }

                    contentItem: RowLayout {
                        spacing: 6
                        MaterialSymbol {
                            text: "undo"
                            iconSize: 18
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: Translation.tr("Reset to Default")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
                opacity: 0.5
            }

            // Theme picker chips row
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: Translation.tr("Assign cursor from theme:")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                }

                Flow {
                    id: themeChipsFlow
                    Layout.fillWidth: true
                    spacing: 8

                    // 1. "Default (Inherited)" chip
                    RippleButton {
                        readonly property bool isCurrent: !root.selectedActionIsOverridden
                        buttonRadius: Appearance.rounding.full
                        implicitHeight: 38
                        padding: 10
                        colBackground: isCurrent
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer2
                        colBackgroundHover: isCurrent
                            ? Appearance.colors.colPrimaryHover
                            : Appearance.colors.colLayer2Hover

                        onClicked: {
                            SystemTheming.resetCursorOverride(root.selectedActionKey)
                        }

                        contentItem: RowLayout {
                            spacing: 6
                            MaterialSymbol {
                                text: isCurrent ? "check" : "restart_alt"
                                iconSize: 18
                                color: isCurrent ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: Translation.tr("Default (Inherited)")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: isCurrent ? Font.Bold : Font.Normal
                                color: isCurrent ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    // 2. Individual theme chips with mini preview
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
                            required property string modelData
                            readonly property bool isCurrent: root.selectedActionOverride === modelData
                            readonly property string chipPreview: SystemTheming.getCursorPreview(modelData, root.selectedActionKey)

                            buttonRadius: Appearance.rounding.full
                            implicitHeight: 38
                            padding: 8
                            colBackground: isCurrent
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer2
                            colBackgroundHover: isCurrent
                                ? Appearance.colors.colPrimaryHover
                                : Appearance.colors.colLayer2Hover

                            onClicked: {
                                if (modelData === SystemTheming.currentCursorTheme) {
                                    SystemTheming.resetCursorOverride(root.selectedActionKey)
                                } else {
                                    SystemTheming.setCursorOverride(root.selectedActionKey, modelData)
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 8

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 6
                                    color: isCurrent
                                        ? ColorUtils.applyAlpha(Appearance.colors.colOnPrimary, 0.20)
                                        : ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.50)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        fillMode: Image.PreserveAspectFit
                                        source: chipPreview
                                        smooth: false
                                    }
                                }

                                StyledText {
                                    text: modelData
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: isCurrent ? Font.Bold : Font.Normal
                                    color: isCurrent ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }

                                MaterialSymbol {
                                    visible: isCurrent
                                    text: "check"
                                    iconSize: 16
                                    color: Appearance.colors.colOnPrimary
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 5. System Themes & Icons (GTK & Icon Themes) ───────────────────────────
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
