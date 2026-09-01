import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "notes"
    hoverEnabled: true

    implicitWidth: 276
    implicitHeight: 252

    property string mode: "list" // "list" | "edit"
    property var pendingNoteId: null
    onModeChanged: GlobalStates.desktopWidgetKeyboardFocus = (mode === "edit")

    function toggleFlip() { flipAnim.start() }

    function openNewNote() {
        root.pendingNoteId = null
        editTextArea.text = ""
        if (editFlickable) editFlickable.contentY = 0
        toggleFlip()
        Qt.callLater(() => editTextArea.forceActiveFocus())
    }

    function openNote(note) {
        root.pendingNoteId = note.id
        editTextArea.text = note.content
        if (editFlickable) editFlickable.contentY = 0
        toggleFlip()
        Qt.callLater(() => editTextArea.forceActiveFocus())
    }

    function saveAndBack() {
        let text = editTextArea.text
        if (text.length > 0) {
            if (root.pendingNoteId) {
                Notes.updateNote(root.pendingNoteId, text)
            } else {
                Notes.addNote(text)
            }
        }
        toggleFlip()
    }

    Item {
        id: cardWrapper
        anchors.fill: parent

        transform: Scale {
            id: flipScale
            origin.x: cardWrapper.width  / 2
            origin.y: cardWrapper.height / 2
            xScale: 1
        }

        SequentialAnimation {
            id: flipAnim
            NumberAnimation {
                target: flipScale; property: "xScale"
                to: 0; duration: 150; easing.type: Easing.InQuad
            }
            ScriptAction {
                script: root.mode = (root.mode === "list" ? "edit" : "list")
            }
            NumberAnimation {
                target: flipScale; property: "xScale"
                to: 1; duration: 150; easing.type: Easing.OutQuad
            }
        }

        StyledDropShadow { target: contentRect }

        Rectangle {
            id: contentRect
            anchors.fill: parent
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding?.verylarge ?? 30

            // List
            ColumnLayout {
                id: listPage
                anchors { fill: parent; margins: 12 }
                spacing: 10
                visible: root.mode === "list"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.topMargin: -4
                        Layout.leftMargin: 8
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimaryContainer
                        text: "Notes"
                    }
                    Item { Layout.fillWidth: true }

                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: "add"
                        onClicked: root.openNewNote()
                    }
                }

                StyledListView {
                    id: notesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: Notes.list

                    delegate: SwipeDelegate {
                        id: noteCard
                        required property var modelData
                        required property int index

                        width: notesListView.width
                        implicitHeight: 55
                        padding: 0
                        background: null
                        clip: true

                        property color bg: {
                            const cyclePos = index % 3
                            if (cyclePos === 0) return Appearance.colors.colPrimary
                            if (cyclePos === 1) return Appearance.colors.colSecondary
                            return Appearance.colors.colTertiary
                        }
                        property color fg: {
                            const cyclePos = index % 3
                            if (cyclePos === 0) return Appearance.colors.colOnPrimary
                            if (cyclePos === 1) return Appearance.colors.colOnSecondary
                            return Appearance.colors.colOnTertiary
                        }

                        onClicked: root.openNote(noteCard.modelData)

                        contentItem: Rectangle {
                            radius: Appearance.rounding.normal
                            color: noteCard.bg
                            width: parent.width - Math.abs(noteCard.swipe.position) * 6

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 6
                                spacing: 4

                                StyledText {
                                    Layout.fillWidth: true
                                    color: noteCard.fg
                                    text: noteCard.modelData.content
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                RippleButton {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colError
                                    colRipple: Appearance.colors.colOnError
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        iconSize: 18
                                        text: "delete"
                                        color: noteCard.fg
                                    }
                                    downAction: () => {
                                        Notes.deleteNote(noteCard.modelData.id)
                                    }
                                }
                            }
                        }

                        swipe.right: Rectangle {
                            width: 64
                            anchors.right: parent.right
                            height: parent.height
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colError

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnError
                            }

                            SwipeDelegate.onClicked: Notes.deleteNote(noteCard.modelData.id)
                        }
                    }
                }
            }

            // Edit
            ColumnLayout {
                id: editPage
                anchors { fill: parent; margins: 12 }
                spacing: 10
                visible: root.mode === "edit"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        radius: Appearance.rounding.full
                        color: "transparent"
                        implicitWidth: 28; implicitHeight: 28
                        MaterialSymbol {
                            anchors.centerIn: parent
                            iconSize: Appearance.font.pixelSize.normal
                            text: "arrow_back"
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFlip()
                        }
                    }
                    Item { Layout.fillWidth: true }

                    // Markdown Preview / Edit Mode Switcher
                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: root.isMarkdownPreview ? "edit" : "visibility"
                        onClicked: {
                            root.isMarkdownPreview = !root.isMarkdownPreview
                            if (!root.isMarkdownPreview) {
                                Qt.callLater(() => editTextArea.forceActiveFocus())
                            }
                        }
                    }

                    ToolbarPairedFab {
                        visible: root.pendingNoteId !== null
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: "delete"
                        onClicked: {
                            if (root.pendingNoteId) {
                                Notes.deleteNote(root.pendingNoteId)
                            }
                            root.toggleFlip()
                        }
                    }

                    ToolbarPairedFab {
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        baseSize: 38
                        iconText: "save"
                        onClicked: root.saveAndBack()
                    }
                }

                Rectangle {
                    id: editBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    clip: true

                    Flickable {
                        id: editFlickable
                        anchors.fill: parent
                        anchors.margins: 10
                        contentWidth: width
                        contentHeight: Math.max(height, root.isMarkdownPreview ? previewMarkdownText.implicitHeight + 40 : editTextArea.implicitHeight + 40)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        MouseArea {
                            anchors.fill: parent
                            visible: !root.isMarkdownPreview
                            onClicked: {
                                editTextArea.forceActiveFocus()
                                editTextArea.cursorPosition = editTextArea.text.length
                            }
                        }

                        // Raw Markdown Editor
                        TextArea {
                            id: editTextArea
                            visible: !root.isMarkdownPreview
                            width: editFlickable.width
                            wrapMode: TextArea.Wrap
                            placeholderText: "Type note with markdown formatting (# heading, - list, **bold**, `code`)..."
                            color: Appearance.colors.colOnLayer0
                            background: null
                            selectByMouse: true
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        // Rich Markdown Rendered Preview
                        StyledText {
                            id: previewMarkdownText
                            visible: root.isMarkdownPreview
                            width: editFlickable.width
                            textFormat: Text.MarkdownText
                            text: editTextArea.text.trim() ? editTextArea.text : "*No markdown content*"
                            wrapMode: Text.Wrap
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: Appearance.font.pixelSize.small
                            onLinkActivated: (link) => Qt.openUrlExternally(link)
                        }
                    }
                }
            }
        }
    }
}