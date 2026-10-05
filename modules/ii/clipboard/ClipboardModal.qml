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

Rectangle {
    id: root

    property int activeSection: 0 // 0 = List (Left), 1 = Editor (Right)
    property string searchQuery: ""
    property int selectedIndex: 0
    property string toastMessage: ""

    signal requestClose()

    implicitWidth: 890
    implicitHeight: 540

    color: Qt.rgba(
        Appearance.colors.colLayer0Base.r,
        Appearance.colors.colLayer0Base.g,
        Appearance.colors.colLayer0Base.b,
        0.28
    )
    radius: Appearance.rounding.windowRounding
    clip: true
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    property bool filterPinnedOnly: false

    readonly property var rawFiltered: {
        const _ = Cliphist.pinRevision;
        const _entries = Cliphist.entries;
        const _clip = Quickshell.clipboardText;
        const list = Cliphist.fuzzyQuery(root.searchQuery);
        if (root.filterPinnedOnly) {
            return list.filter(e => Cliphist.isPinned(e));
        }
        return list;
    }

    property string selectedEntryId: ""
    property string lastTopEntryId: ""

    onSelectedIndexChanged: {
        if (listPane && listPane.selectedIndex !== root.selectedIndex) {
            listPane.selectedIndex = root.selectedIndex;
        }
    }

    function findCopiedEntryIndex() {
        if (root.rawFiltered.length === 0) return -1;

        // If actively searching, default to top search result
        if (root.searchQuery.trim().length > 0) {
            return 0;
        }

        // 1. Match Quickshell.clipboardText if available (the exact fresh clipboard content)
        if (Quickshell.clipboardText && Quickshell.clipboardText.trim().length > 0) {
            const clipText = Quickshell.clipboardText.trim();
            for (let i = 0; i < root.rawFiltered.length; i++) {
                if (StringUtils.cleanCliphistEntry(root.rawFiltered[i]).trim() === clipText) {
                    return i;
                }
            }
        }

        // 2. Match newest entry from Cliphist.entries[0]
        if (Cliphist.entries && Cliphist.entries.length > 0) {
            const newestEntry = Cliphist.entries[0];
            const newestId = Cliphist.getEntryId(newestEntry);
            if (newestId !== "") {
                for (let i = 0; i < root.rawFiltered.length; i++) {
                    if (Cliphist.getEntryId(root.rawFiltered[i]) === newestId) {
                        return i;
                    }
                }
            }
            const newestClean = StringUtils.cleanCliphistEntry(newestEntry).trim();
            if (newestClean.length > 0) {
                for (let i = 0; i < root.rawFiltered.length; i++) {
                    if (StringUtils.cleanCliphistEntry(root.rawFiltered[i]).trim() === newestClean) {
                        return i;
                    }
                }
            }
        }

        // 3. Fallback: Always top entry (0)
        return 0;
    }

    function focusCopiedEntry() {
        const idx = findCopiedEntryIndex();
        const targetIdx = (idx >= 0 && idx < root.rawFiltered.length) ? idx : 0;
        root.selectedIndex = targetIdx;
        if (listPane) {
            listPane.selectedIndex = targetIdx;
        }
        if (root.rawFiltered.length > 0) {
            root.selectedEntryId = Cliphist.getEntryId(root.rawFiltered[targetIdx]);
        }
        if (targetIdx === 0) {
            listPane.resetToTop();
        } else {
            Qt.callLater(() => {
                listPane.scrollSelectedIntoView();
            });
        }
    }

    readonly property string selectedEntry: {
        if (root.rawFiltered.length === 0 || root.selectedIndex < 0 || root.selectedIndex >= root.rawFiltered.length) {
            return "";
        }
        return root.rawFiltered[root.selectedIndex];
    }

    onSelectedEntryChanged: {
        if (root.selectedEntry) {
            root.selectedEntryId = Cliphist.getEntryId(root.selectedEntry);
        }
    }

    onRawFilteredChanged: {
        if (root.rawFiltered.length === 0) {
            root.selectedIndex = -1;
            return;
        }

        // Check if top entry in cliphist changed (new item was copied)
        const currentTopId = (Cliphist.entries && Cliphist.entries.length > 0) ? Cliphist.getEntryId(Cliphist.entries[0]) : "";
        if (currentTopId !== "" && currentTopId !== root.lastTopEntryId) {
            root.lastTopEntryId = currentTopId;
            const newCopiedIdx = root.findCopiedEntryIndex();
            if (newCopiedIdx >= 0) {
                root.selectedIndex = newCopiedIdx;
                if (listPane) listPane.selectedIndex = newCopiedIdx;
                root.selectedEntryId = Cliphist.getEntryId(root.rawFiltered[newCopiedIdx]);
                if (newCopiedIdx === 0) {
                    listPane.resetToTop();
                } else {
                    Qt.callLater(() => {
                        listPane.scrollSelectedIntoView();
                    });
                }
                return;
            }
        }

        // If actively searching:
        if (root.searchQuery.trim().length > 0) {
            root.selectedIndex = 0;
            if (listPane) listPane.selectedIndex = 0;
            return;
        }

        // Otherwise preserve current selected entry if it still exists AND modal is open
        if (GlobalStates.clipboardOpen && root.selectedEntryId !== "") {
            for (let i = 0; i < root.rawFiltered.length; i++) {
                if (Cliphist.getEntryId(root.rawFiltered[i]) === root.selectedEntryId) {
                    if (root.selectedIndex !== i) {
                        root.selectedIndex = i;
                        if (listPane) listPane.selectedIndex = i;
                    }
                    return;
                }
            }
        }

        // Fallback to copied item
        const fallbackIdx = root.findCopiedEntryIndex();
        const targetFallback = (fallbackIdx >= 0 && fallbackIdx < root.rawFiltered.length) ? fallbackIdx : 0;
        root.selectedIndex = targetFallback;
        if (listPane) listPane.selectedIndex = targetFallback;
        root.selectedEntryId = Cliphist.getEntryId(root.rawFiltered[targetFallback]);
        if (targetFallback === 0) {
            listPane.resetToTop();
        }
    }

    // Always focus the search field and newly copied entry when the clipboard is opened
    Connections {
        target: GlobalStates
        function onClipboardOpenChanged() {
            if (GlobalStates.clipboardOpen) {
                root.searchQuery = "";
                root.filterPinnedOnly = false;
                root.lastTopEntryId = "";
                root.selectedEntryId = "";
                root.selectedIndex = 0;
                root.activeSection = 0;
                listPane.resetToTop();
                Cliphist.refresh();
                Qt.callLater(() => {
                    root.focusCopiedEntry();
                });
            } else {
                root.searchQuery = "";
                root.filterPinnedOnly = false;
                root.lastTopEntryId = "";
                root.selectedEntryId = "";
                root.selectedIndex = 0;
                root.activeSection = 0;
                listPane.resetToTop();
            }
        }
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            root.lastTopEntryId = "";
            Qt.callLater(() => {
                root.focusCopiedEntry();
            });
        }
    }

    Connections {
        target: Cliphist
        function onEntriesChanged() {
            if (Cliphist.entries.length === 0) return;
            const topId = Cliphist.getEntryId(Cliphist.entries[0]);
            if (topId !== "" && topId !== root.lastTopEntryId) {
                root.lastTopEntryId = topId;
                Qt.callLater(() => {
                    root.focusCopiedEntry();
                });
            }
        }
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab) {
            if (root.activeSection === 0) {
                root.activeSection = 1;
                editorPane.focusEditor();
            } else {
                root.activeSection = 0;
                listPane.focusSearch();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab) {
            if (root.activeSection === 1) {
                root.activeSection = 0;
                listPane.focusSearch();
            } else {
                root.activeSection = 1;
                editorPane.focusEditor();
            }
            event.accepted = true;
        }
    }

    // Split Layout
    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 0

        // Left Pane: Material Impulse Clipboard List
        ClipboardListPane {
            id: listPane
            Layout.preferredWidth: 410
            Layout.fillWidth: false
            Layout.fillHeight: true
            searchQuery: root.searchQuery
            filteredList: root.rawFiltered
            selectedIndex: root.selectedIndex
            isListFocused: root.activeSection === 0
            filterPinnedOnly: root.filterPinnedOnly

            onFilterPinnedOnlyChanged: root.filterPinnedOnly = filterPinnedOnly
            onSearchQueryChanged: root.searchQuery = searchQuery
            onSelectedIndexChanged: {
                if (root.selectedIndex !== selectedIndex) {
                    root.selectedIndex = selectedIndex;
                }
            }

            onRequestFocusEditor: {
                root.activeSection = 1;
                editorPane.focusEditor();
            }

            onRequestCopyAndClose: entry => {
                root.requestClose();
                Cliphist.copy(entry);
            }

            onRequestPasteAndClose: entry => {
                root.requestClose();
                Cliphist.paste(entry);
            }

            onRequestClose: root.requestClose()
            onShowNotification: msg => root.showToast(msg)
        }

        // Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: Appearance.colors.colOutlineVariant
        }

        // Right Pane: Preview & Live Editor
        ClipboardEditorPane {
            id: editorPane
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            clip: true
            currentEntry: root.selectedEntry
            isEditorFocused: root.activeSection === 1

            onRequestFocusList: {
                root.activeSection = 0;
                listPane.focusSearch();
            }

            onRequestClose: root.requestClose()
            onShowNotification: msg => root.showToast(msg)
        }
    }

    // Toast Banner
    Rectangle {
        id: toastBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        radius: Appearance.rounding.full
        color: Appearance.colors.colSecondaryContainer
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
        implicitHeight: 28
        implicitWidth: toastText.implicitWidth + 24
        visible: root.toastMessage.length > 0
        opacity: root.toastMessage.length > 0 ? 1 : 0
        z: 99

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        StyledText {
            id: toastText
            anchors.centerIn: parent
            text: root.toastMessage
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    Component.onCompleted: {
        root.lastTopEntryId = (Cliphist.entries && Cliphist.entries.length > 0) ? Cliphist.getEntryId(Cliphist.entries[0]) : "";
        root.focusCopiedEntry();
        listPane.focusSearch();
    }
}
