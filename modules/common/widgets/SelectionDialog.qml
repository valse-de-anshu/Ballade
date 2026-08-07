import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
    id: root
    property real dialogPadding: 15
    property real dialogMargin: 30
    property string titleText: "Selection Dialog"
    property list<string> items: []
    property var defaultChoice
    property string selectedValue: root.defaultChoice !== undefined ? root.defaultChoice.toString() : ""
    property string searchText: ""

    property var pinnedList: {
        try {
            return Config.options.language.translator.pinnedLanguages || ["auto", "english", "spanish", "french", "german", "hindi", "japanese"]
        } catch(e) {
            return ["auto", "english", "spanish", "french", "german", "hindi", "japanese"]
        }
    }

    signal canceled()
    signal selected(var result)

    function isPinned(itemStr) {
        if (!itemStr) return false
        let lower = itemStr.toString().trim().toLowerCase()
        for (let p of root.pinnedList) {
            if (p.toString().trim().toLowerCase() === lower) return true
        }
        return false
    }

    function togglePin(itemStr) {
        if (!itemStr) return
        let lower = itemStr.toString().trim().toLowerCase()
        let list = []
        for (let p of root.pinnedList) list.push(p.toString())
        let idx = list.findIndex(p => p.toString().trim().toLowerCase() === lower)
        if (idx >= 0) {
            list.splice(idx, 1)
        } else {
            list.unshift(itemStr.toString())
        }
        root.pinnedList = list
        try {
            Config.options.language.translator.pinnedLanguages = list
        } catch(e) {}
    }

    readonly property var displayItems: {
        let query = root.searchText.trim().toLowerCase()
        let all = root.items || []
        let pinned = []
        let unpinned = []

        for (let i = 0; i < all.length; i++) {
            let str = all[i] ? all[i].toString() : ""
            if (!str) continue
            if (query && !str.toLowerCase().includes(query)) continue
            if (root.isPinned(str)) {
                pinned.push(str)
            } else {
                unpinned.push(str)
            }
        }
        return pinned.concat(unpinned)
    }

    Rectangle { // Scrim
        id: scrimOverlay
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colScrim
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
        }
    }

    Rectangle { // The dialog
        id: dialog
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal
        anchors.fill: parent
        anchors.margins: dialogMargin
        clip: true

        ColumnLayout {
            id: dialogColumnLayout
            anchors.fill: parent
            spacing: 10

            // Header
            RowLayout {
                Layout.topMargin: root.dialogPadding
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
                Layout.fillWidth: true

                StyledText {
                    id: dialogTitle
                    Layout.fillWidth: true
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.bold: true
                    text: root.titleText
                }
            }

            // Search Bar
            ConfigTextArea {
                id: searchBar
                Layout.fillWidth: true
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
                buttonIcon: "search"
                placeholderText: Translation.tr("Search language...")
                value: root.searchText
                confirmButtonVisible: root.searchText.length > 0
                confirmButtonIcon: "close"
                onValueChanged: root.searchText = value
                onConfirmClicked: {
                    root.searchText = ""
                    value = ""
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
            }

            // List of languages (Pinned on top, unpinned below)
            StyledListView {
                id: choiceListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4

                model: ScriptModel {
                    id: choiceModel
                    values: root.displayItems
                }

                delegate: Rectangle {
                    id: itemRow
                    required property var modelData
                    required property int index

                    width: choiceListView.width - root.dialogPadding * 2
                    implicitHeight: 38
                    anchors.horizontalCenter: choiceListView.horizontalCenter
                    radius: Appearance.rounding.small

                    readonly property bool isSelected: root.selectedValue === modelData.toString()
                    readonly property bool itemPinned: root.isPinned(modelData)

                    color: isSelected
                        ? Appearance.colors.colPrimaryContainer
                        : (rowMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        // Selection indicator / icon
                        MaterialSymbol {
                            text: itemRow.isSelected ? "radio_button_checked" : "radio_button_unchecked"
                            iconSize: Appearance.font.pixelSize.normal
                            color: itemRow.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }

                        // Language text label
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.toString()
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.bold: itemRow.itemPinned || itemRow.isSelected
                            color: itemRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        // Pin button icon
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 14
                            color: pinMouseArea.containsMouse ? Appearance.colors.colLayer3 : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "push_pin"
                                iconSize: 16
                                color: itemRow.itemPinned ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                opacity: itemRow.itemPinned ? 1.0 : (rowMouseArea.containsMouse ? 0.6 : 0.25)
                            }

                            MouseArea {
                                id: pinMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePin(modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouseArea
                        anchors.fill: parent
                        anchors.rightMargin: 36 // Don't steal click from pin button
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedValue = modelData.toString()
                        }
                    }
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
            }

            // Dialog Buttons
            RowLayout {
                id: dialogButtonsRowLayout
                Layout.bottomMargin: root.dialogPadding
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
                Layout.alignment: Qt.AlignRight

                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: root.canceled()
                }
                DialogButton {
                    buttonText: Translation.tr("OK")
                    onClicked: root.selected(root.selectedValue)
                }
            }
        }
    }
}
