pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))
    function getEntryId(entry) {
        if (!entry) return "";
        const m = String(entry).match(/^(\d+)\t/);
        return m ? m[1] : "";
    }

    property int pinRevision: 0
    property var pinnedList: []
    property var pinnedMap: ({})
    property string pinnedFilePath: FileUtils.trimFileProtocol(`${Directories.state}/user/pinned_clipboard.json`)

    function rebuildPinnedMap() {
        const set = {};
        for (let i = 0; i < root.pinnedList.length; i++) {
            const item = String(root.pinnedList[i]);
            set[item] = true;
            const id = getEntryId(item);
            if (id) set[id] = true;
            const clean = item.replace(/^\d+\t/, "").trim();
            if (clean) set[clean] = true;
        }
        root.pinnedMap = set;
        root.pinRevision++;
    }

    function isPinned(entry) {
        if (!entry) return false;
        const eStr = String(entry);
        if (root.pinnedMap[eStr]) return true;
        const id = getEntryId(eStr);
        if (id && root.pinnedMap[id]) return true;
        const clean = eStr.replace(/^\d+\t/, "").trim();
        if (clean && root.pinnedMap[clean]) return true;
        return false;
    }

    function togglePin(entry) {
        if (!entry) return;
        const eStr = String(entry);
        const id = getEntryId(eStr);
        const clean = eStr.replace(/^\d+\t/, "").trim();
        let foundIdx = -1;
        for (let i = 0; i < root.pinnedList.length; i++) {
            const item = String(root.pinnedList[i]);
            const storedId = getEntryId(item);
            const storedClean = item.replace(/^\d+\t/, "").trim();
            if ((storedId !== "" && id !== "" && storedId === id) || (storedClean !== "" && clean !== "" && storedClean === clean) || item === eStr) {
                foundIdx = i;
                break;
            }
        }
        const updated = [...root.pinnedList];
        if (foundIdx >= 0) {
            updated.splice(foundIdx, 1);
        } else {
            updated.push(eStr);
        }
        root.pinnedList = updated;
        root.rebuildPinnedMap();

        if (Persistent.ready && Persistent.states) {
            Persistent.states.pinnedClipboard = updated;
        }
        pinnedFileView.setText(JSON.stringify(updated));
    }

    function sortEntries(rawList) {
        if (!rawList || rawList.length === 0) return [];
        const pinned = [];
        const unpinned = [];
        for (let i = 0; i < rawList.length; i++) {
            const e = rawList[i];
            if (root.isPinned(e)) {
                pinned.push(e);
            } else {
                unpinned.push(e);
            }
        }
        return pinned.concat(unpinned);
    }

    function fuzzyQuery(search: string): var {
        let rawResults = [];
        if (search.trim() === "") {
            rawResults = entries;
        } else if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score);
            rawResults = results.map(item => item.entry);
        } else {
            rawResults = Fuzzy.go(search, preparedEntries, {
                all: true,
                key: "name"
            }).map(r => r.obj.entry);
        }
        return rawResults;
    }

    function entryIsImage(entry) {
        if (!entry) return false;
        return /^\d+\t\[\[\s*binary data/i.test(String(entry));
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy`]);
        }
    }

    function paste(entry) {
        if (root.cliphistBinary.includes("cliphist")) // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && wl-paste`]);
        else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy; ${root.pressPasteCommand}`]);
        }
    }

    function copyText(text) {
        if (text === undefined || text === null) return;
        Quickshell.clipboardText = text;
        Quickshell.execDetached(["bash", "-c", `printf '%s' '${StringUtils.shellSingleQuoteEscape(text)}' | wl-copy`]);
        delayedUpdateTimer.restart();
    }

    function pasteText(text) {
        if (text === undefined || text === null) return;
        Quickshell.clipboardText = text;
        Quickshell.execDetached(["bash", "-c", `printf '%s' '${StringUtils.shellSingleQuoteEscape(text)}' | wl-copy; sleep ${root.pasteDelay}; ${root.pressPasteCommand}`]);
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`)
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    function deleteEntry(entry) {
        if (!entry) return;
        // Pinned items are fully protected — cannot be deleted
        if (isPinned(entry)) return;

        // 1. Immediately update in-memory entries so UI updates with 0ms latency and no index mismatch
        const updated = [];
        for (let i = 0; i < root.entries.length; i++) {
            if (root.entries[i] !== entry) {
                updated.push(root.entries[i]);
            }
        }
        root.entries = updated;

        // 2. Persistently delete in cliphist DB in background
        Quickshell.execDetached([
            "bash", "-c",
            `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} delete`
        ]);
    }

    function wipe() {
        const pinnedList = entries.filter(e => isPinned(e));
        // Immediately update in-memory entries to only pinned items
        root.entries = pinnedList;

        if (pinnedList.length === 0) {
            // No pinned entries — just wipe everything
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} wipe`]);
        } else {
            // Decode pinned entries to temp files FIRST (before wipe destroys the DB),
            // then wipe, then wl-copy each saved file so cliphist re-indexes them.
            const tmpBase = `/tmp/qs-cliphist-pin-$$`;
            const saveCmds = pinnedList.map((e, i) =>
                `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(e)}' | ${root.cliphistBinary} decode > '${tmpBase}-${i}'`
            );
            // Re-copy in reverse so the first pinned item ends up newest (top of list)
            const restoreCmds = pinnedList.map((e, i) =>
                `wl-copy < '${tmpBase}-${i}' && sleep 0.08`
            ).reverse();
            const fullCmd = [
                ...saveCmds,
                `${root.cliphistBinary} wipe`,
                `sleep 0.2`,
                ...restoreCmds,
                `rm -f '${tmpBase}-'*`
            ].join(" && ");
            Quickshell.execDetached(["bash", "-c", fullCmd]);
        }
        delayedUpdateTimer.restart();
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart()
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus)
            }
        }
    }

    FileView {
        id: pinnedFileView
        path: Qt.resolvedUrl(root.pinnedFilePath)
        onLoaded: {
            try {
                const data = JSON.parse(pinnedFileView.text());
                if (Array.isArray(data) && data.length > 0) {
                    root.pinnedList = data;
                    root.rebuildPinnedMap();
                } else if (Persistent.ready && Persistent.states && Persistent.states.pinnedClipboard && Persistent.states.pinnedClipboard.length > 0) {
                    root.pinnedList = [...Persistent.states.pinnedClipboard];
                    root.rebuildPinnedMap();
                    pinnedFileView.setText(JSON.stringify(root.pinnedList));
                }
            } catch (e) {
                console.error("[Cliphist] Error loading pinned clipboard:", e);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                if (Persistent.ready && Persistent.states && Persistent.states.pinnedClipboard && Persistent.states.pinnedClipboard.length > 0) {
                    root.pinnedList = [...Persistent.states.pinnedClipboard];
                } else {
                    root.pinnedList = [];
                }
                root.rebuildPinnedMap();
                pinnedFileView.setText(JSON.stringify(root.pinnedList));
            }
        }
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.ready && root.pinnedList.length === 0 && Persistent.states && Persistent.states.pinnedClipboard && Persistent.states.pinnedClipboard.length > 0) {
                root.pinnedList = [...Persistent.states.pinnedClipboard];
                root.rebuildPinnedMap();
            }
        }
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
