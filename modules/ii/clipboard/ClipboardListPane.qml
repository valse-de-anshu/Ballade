pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property string searchQuery: ""
    property var filteredList: []
    property int selectedIndex: 0
    property bool isListFocused: true

    signal requestFocusEditor()
    signal requestCopyAndClose(string entry)
    signal requestPasteAndClose(string entry)
    signal requestClose()
    signal showNotification(string text)

    function focusSearch() {
        searchField.forceActiveFocus();
    }

    function focusList() {
        searchField.forceActiveFocus();
    }

    function selectPrevious() {
        if (root.filteredList.length === 0) return;
        if (root.selectedIndex > 0) {
            root.selectedIndex--;
            listView.currentIndex = root.selectedIndex;
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function selectNext() {
        if (root.filteredList.length === 0) return;
        if (root.selectedIndex < root.filteredList.length - 1) {
            root.selectedIndex++;
            listView.currentIndex = root.selectedIndex;
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function deleteCurrent() {
        if (root.filteredList.length === 0 || root.selectedIndex < 0) return;
        const entry = root.filteredList[root.selectedIndex];
        if (!entry) return;

        if (Cliphist.isPinned(entry)) {
            root.showNotification(Translation.tr("Pinned item is protected"));
            return;
        }

        const currIndex = root.selectedIndex;
        Cliphist.deleteEntry(entry);

        Qt.callLater(() => {
            const newLen = root.filteredList.length;
            if (newLen > 0) {
                root.selectedIndex = Math.min(currIndex, newLen - 1);
                listView.currentIndex = root.selectedIndex;
                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            } else {
                root.selectedIndex = -1;
                listView.currentIndex = -1;
            }
            searchField.forceActiveFocus();
        });
    }

    onFilteredListChanged: {
        if (root.filteredList.length === 0) {
            root.selectedIndex = -1;
        } else if (root.selectedIndex >= root.filteredList.length) {
            root.selectedIndex = Math.max(0, root.filteredList.length - 1);
        } else if (root.selectedIndex < 0) {
            root.selectedIndex = 0;
        }
        Qt.callLater(() => {
            if (root.selectedIndex >= 0 && root.selectedIndex < root.filteredList.length) {
                listView.currentIndex = root.selectedIndex;
                listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            }
        });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Material Impulse Search Bar with Action Buttons (Wipe, Google Lens, Song Recognition)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.fillHeight: false
            spacing: 6

            // Clipboard Icon in Material Gem Shape
            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: Appearance.font.pixelSize.huge
                shape: MaterialShape.Shape.Gem
                text: "content_paste_search"
            }

            // Search Text Field
            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                placeholderText: Translation.tr("Search clipboard...")

                text: root.searchQuery
                onTextChanged: root.searchQuery = text

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        root.selectNext();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.selectPrevious();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageDown) {
                        for (let i = 0; i < 5; i++) root.selectNext();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageUp) {
                        for (let i = 0; i < 5; i++) root.selectPrevious();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        if (searchField.text.length === 0 || searchField.cursorPosition === searchField.text.length || (event.modifiers & (Qt.AltModifier | Qt.ControlModifier))) {
                            root.requestFocusEditor();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Tab) {
                        root.requestFocusEditor();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete) {
                        if (searchField.text.length === 0) {
                            root.deleteCurrent();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.filteredList.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredList.length) {
                            if (event.modifiers === Qt.ShiftModifier) {
                                root.requestPasteAndClose(root.filteredList[root.selectedIndex]);
                            } else {
                                root.requestCopyAndClose(root.filteredList[root.selectedIndex]);
                            }
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        if (searchField.text.length > 0) {
                            searchField.text = "";
                        } else {
                            root.requestClose();
                        }
                        event.accepted = true;
                    }
                }
            }

            // Clear Clipboard Button (Instant wipe, no confirmation popup/icon)
            IconToolbarButton {
                id: clearClipboardButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    Cliphist.wipe();
                }
                text: "delete_sweep"
                colText: hovered ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant

                StyledToolTip {
                    y: parent.height + 6
                    text: Translation.tr("Clear all clipboard history")
                }
            }

            // Google Lens / Region Search Button
            IconToolbarButton {
                id: lensButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    GlobalStates.clipboardOpen = false;
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
                }
                text: "image_search"

                StyledToolTip {
                    y: parent.height + 6
                    text: Translation.tr("Google Lens / Circle to Search")
                }
            }

            // Song Recognition Button (With rotating animated MaterialShape)
            IconToolbarButton {
                id: songRecButton
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                toggled: SongRec.running
                onClicked: SongRec.toggleRunning()
                text: "music_cast"

                StyledToolTip {
                    y: parent.height + 6
                    text: Translation.tr("Recognize music")
                }

                colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                background: MaterialShape {
                    RotationAnimation on rotation {
                        running: songRecButton.toggled
                        duration: 12000
                        easing.type: Easing.Linear
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                    }
                    shape: {
                        if (songRecButton.down) {
                            return songRecButton.toggled ? MaterialShape.Shape.Circle : MaterialShape.Shape.Square
                        } else {
                            return songRecButton.toggled ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Circle
                        }
                    }
                    color: {
                        if (songRecButton.toggled) {
                            return songRecButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                        } else {
                            return songRecButton.hovered ? Appearance.colors.colSurfaceContainerHigh : ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh)
                        }
                    }
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }

        // Subtle Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOutlineVariant
        }

        // List View of Clipboard Cards
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: root.filteredList
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 120
            focusPolicy: Qt.NoFocus

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < count) {
                    listView.positionViewAtIndex(currentIndex, ListView.Contain);
                }
            }

            ScrollBar.vertical: StyledScrollBar {}

            delegate: ClipboardItemDelegate {
                id: delegateItem
                required property string modelData
                required property int index

                width: listView.width
                entry: modelData
                itemIndex: index
                isSelected: index === root.selectedIndex
                isListFocused: root.isListFocused

                onItemClicked: {
                    root.selectedIndex = index;
                    searchField.forceActiveFocus();
                }

                onPinToggled: {
                    Cliphist.togglePin(modelData);
                }

                onDeleteRequested: {
                    if (Cliphist.isPinned(modelData)) {
                        root.showNotification(Translation.tr("Pinned items cannot be deleted"));
                        return;
                    }
                    root.selectedIndex = index;
                    root.deleteCurrent();
                }

                onCopyRequested: {
                    root.requestCopyAndClose(modelData);
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                    root.selectNext();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    root.selectPrevious();
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    for (let i = 0; i < 5; i++) root.selectNext();
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    for (let i = 0; i < 5; i++) root.selectPrevious();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                    root.requestFocusEditor();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete) {
                    root.deleteCurrent();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.filteredList.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredList.length) {
                        if (event.modifiers === Qt.ShiftModifier) {
                            root.requestPasteAndClose(root.filteredList[root.selectedIndex]);
                        } else {
                            root.requestCopyAndClose(root.filteredList[root.selectedIndex]);
                        }
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.requestClose();
                    event.accepted = true;
                } else if (event.text && event.text.length > 0 && !event.modifiers && event.text.charCodeAt(0) >= 0x20) {
                    searchField.forceActiveFocus();
                    searchField.text += event.text;
                    event.accepted = true;
                }
            }

            Item {
                anchors.fill: parent
                visible: root.filteredList.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 32
                        text: "content_paste_off"
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No clipboard entries")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
