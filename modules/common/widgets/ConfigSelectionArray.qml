import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    property string text: ""
    property string icon: ""
    property var options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null
    property bool stacked: false

    signal selected(var newValue)

    spacing: root.stacked ? 8 : 0
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    // Standard inline row layout (when not stacked)
    RowLayout {
        id: inlineRow
        visible: !root.stacked
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 10
            visible: root.text !== ""
            OptionalMaterialSymbol {
                icon: root.icon
                opacity: root.enabled ? 1 : 0.4
            }
            StyledText {
                id: labelWidget
                Layout.fillWidth: true
                text: root.text
                color: Appearance.colors.colOnSecondaryContainer
                opacity: root.enabled ? 1 : 0.4
            }
        }

        Item {
            Layout.fillWidth: true
            visible: root.text !== ""
        }

        Flow {
            id: buttonsFlow
            visible: !root.stacked
            Layout.fillWidth: !root.text
            Layout.alignment: Qt.AlignRight
            spacing: 2

            Repeater {
                model: root.stacked ? null : root.options
                delegate: SelectionGroupButton {
                    id: paletteButton
                    required property var modelData
                    required property int index
                    onYChanged: {
                        if (index === 0) {
                            paletteButton.leftmost = true
                        } else {
                            var prev = buttonsFlow.children[index - 1]
                            var thisIsOnNewLine = prev && prev.y !== paletteButton.y
                            paletteButton.leftmost = thisIsOnNewLine
                            prev.rightmost = thisIsOnNewLine
                        }
                    }
                    leftmost: index === 0
                    rightmost: index === (root.options ? root.options.length - 1 : 0)
                    buttonIcon: modelData.icon || ""
                    buttonText: modelData.displayName
                    toggled: root.currentValue == modelData.value
                    onClicked: {
                        root.selected(modelData.value);
                    }
                }
            }
        }
    }

    // Stacked title row
    RowLayout {
        id: stackedTitleRow
        visible: root.stacked && root.text !== ""
        Layout.fillWidth: true
        spacing: 10

        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
    }

    // Stacked buttons row
    Flow {
        id: buttonsFlowStacked
        visible: root.stacked
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 2

        Repeater {
            model: root.stacked ? root.options : null
            delegate: SelectionGroupButton {
                id: paletteButtonStacked
                required property var modelData
                required property int index
                onYChanged: {
                    if (index === 0) {
                        paletteButtonStacked.leftmost = true
                    } else {
                        var prev = buttonsFlowStacked.children[index - 1]
                        var thisIsOnNewLine = prev && prev.y !== paletteButtonStacked.y
                        paletteButtonStacked.leftmost = thisIsOnNewLine
                        prev.rightmost = thisIsOnNewLine
                    }
                }
                leftmost: index === 0
                rightmost: index === (root.options ? root.options.length - 1 : 0)
                buttonIcon: modelData.icon || ""
                buttonText: modelData.displayName
                toggled: root.currentValue == modelData.value
                onClicked: {
                    root.selected(modelData.value);
                }
            }
        }
    }
}