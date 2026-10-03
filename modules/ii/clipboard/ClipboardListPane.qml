import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
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
        listView.forceActiveFocus();
    }

    function selectPrevious() {
        if (root.filteredList.length === 0) return;
        if (root.selectedIndex > 0) {
            root.selectedIndex--;
        } else {
            root.selectedIndex = root.filteredList.length - 1;
        }
        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function selectNext() {
        if (root.filteredList.length === 0) return;
        if (root.selectedIndex < root.filteredList.length - 1) {
            root.selectedIndex++;
        } else {
            root.selectedIndex = 0;
        }
        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function deleteCurrent() {
        if (root.filteredList.length === 0) return;
        const entry = root.filteredList[root.selectedIndex];
        if (!entry) return;

        if (Cliphist.isPinned(entry)) {
            root.showNotification("Pinned item is protected");
            return;
        }

        Cliphist.deleteEntry(entry);
    }

    onFilteredListChanged: {
        if (root.filteredList.length === 0) {
            root.selectedIndex = -1;
        } else if (root.selectedIndex >= root.filteredList.length) {
            root.selectedIndex = Math.max(0, root.filteredList.length - 1);
        } else if (root.selectedIndex < 0) {
            root.selectedIndex = 0;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Original style Search Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal
            border.width: searchField.activeFocus ? 1.5 : 0
            border.color: Appearance.colors.colPrimary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                MaterialSymbol {
                    font.pixelSize: 18
                    text: "content_paste"
                    color: searchField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search clipboard..."
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.main
                    font.pixelSize: 13
                    background: null
                    renderType: Text.NativeRendering
                    selectByMouse: true
                    selectedTextColor: Appearance.colors.colOnPrimaryContainer
                    selectionColor: Appearance.colors.colPrimaryContainer

                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.focusList();
                            root.selectNext();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.focusList();
                            root.selectPrevious();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.filteredList.length > 0 && root.selectedIndex >= 0) {
                                root.requestCopyAndClose(root.filteredList[root.selectedIndex]);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            root.requestFocusEditor();
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

                // Clear text button
                RippleButton {
                    visible: searchField.text.length > 0
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    onClicked: {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 14
                        text: "close"
                        color: Appearance.colors.colSubtext
                    }
                }

                // Wipe unpinned button
                RippleButton {
                    id: wipeBtn
                    property bool confirmState: false
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    colBackground: confirmState 
                        ? ColorUtils.transparentize(Appearance.m3colors.m3error || "#ff5555", 0.3) 
                        : "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    onClicked: {
                        if (!confirmState) {
                            confirmState = true;
                            wipeTimer.restart();
                        } else {
                            Cliphist.wipe();
                            confirmState = false;
                            root.showNotification("Cleared unpinned items");
                        }
                    }

                    Timer {
                        id: wipeTimer
                        interval: 3000
                        onTriggered: wipeBtn.confirmState = false
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        text: wipeBtn.confirmState ? "warning" : "delete_sweep"
                        color: wipeBtn.confirmState ? (Appearance.m3colors.m3error || "#ff5555") : Appearance.colors.colSubtext
                    }

                    StyledToolTip {
                        text: wipeBtn.confirmState ? "Click to confirm wipe" : "Clear unpinned items"
                    }
                }
            }
        }

        // List View
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.filteredList
            currentIndex: root.selectedIndex
            focus: root.isListFocused
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: StyledScrollBar {}

            delegate: ClipboardItemDelegate {
                required property string modelData
                required property int index

                width: listView.width
                entry: modelData
                itemIndex: index
                isSelected: index === root.selectedIndex
                isListFocused: root.isListFocused

                onItemClicked: {
                    root.selectedIndex = index;
                    root.focusList();
                }

                onPinToggled: {
                    Cliphist.togglePin(modelData);
                }

                onDeleteRequested: {
                    if (Cliphist.isPinned(modelData)) {
                        root.showNotification("Pinned items cannot be deleted");
                        return;
                    }
                    Cliphist.deleteEntry(modelData);
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
                } else if (event.key === Qt.Key_Right) {
                    root.requestFocusEditor();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete) {
                    root.deleteCurrent();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.filteredList.length > 0 && root.selectedIndex >= 0) {
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
                } else if (event.text && event.text.length > 0 && !event.modifiers) {
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
                    spacing: 6

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 28
                        text: "content_paste_off"
                        color: Appearance.colors.colSubtext
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No clipboard entries"
                        font.family: Appearance.font.family.main
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
