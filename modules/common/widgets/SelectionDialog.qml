import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
    id: root
    property real dialogPadding: 12
    property real dialogMargin: 12
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
        border.width: 1
        border.color: Appearance.colors.colLayer3 || "#30FFFFFF"
        anchors.fill: parent
        anchors.margins: dialogMargin
        clip: true

        ColumnLayout {
            id: dialogColumnLayout
            anchors.fill: parent
            spacing: 8

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
            Rectangle {
                id: searchContainer
                Layout.fillWidth: true
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
                implicitHeight: 36
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    MaterialSymbol {
                        text: "search"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        clip: true
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: root.searchText
                        onTextChanged: root.searchText = text

                        StyledText {
                            anchors.fill: parent
                            visible: !searchInput.text && !searchInput.activeFocus
                            text: Translation.tr("Search language...")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }

                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        visible: root.searchText.length > 0
                        color: clearMouse.containsMouse ? Appearance.colors.colLayer3 : "transparent"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 13
                            color: Appearance.colors.colSubtext
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.searchText = ""
                                searchInput.text = ""
                            }
                        }
                    }
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                opacity: 0.5
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
                spacing: 3

                model: ScriptModel {
                    id: choiceModel
                    values: root.displayItems
                }

                delegate: Rectangle {
                    id: itemRow
                    required property var modelData
                    required property int index

                    x: root.dialogPadding
                    width: choiceListView.width - root.dialogPadding * 2
                    implicitHeight: 36
                    radius: Appearance.rounding.small

                    readonly property bool isSelected: root.selectedValue === modelData.toString()
                    readonly property bool itemPinned: root.isPinned(modelData)

                    color: isSelected
                        ? Appearance.colors.colPrimaryContainer
                        : (rowMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
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
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.bold: itemRow.itemPinned || itemRow.isSelected
                            color: itemRow.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        // Pin button icon
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 13
                            color: pinMouseArea.containsMouse ? Appearance.colors.colLayer3 : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "push_pin"
                                iconSize: 15
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
                        anchors.rightMargin: 34 // Don't steal click from pin button
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedValue = modelData.toString()
                        }
                        onDoubleClicked: {
                            root.selectedValue = modelData.toString()
                            root.selected(root.selectedValue)
                        }
                    }
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                opacity: 0.5
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
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

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
