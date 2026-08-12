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
    function isPinned(entry) {
        if (!entry || !Persistent.ready) return false;
        const clean = StringUtils.cleanCliphistEntry(entry);
        return (Persistent.states.pinnedClipboard || []).some(p => StringUtils.cleanCliphistEntry(p) === clean);
    }

    function togglePin(entry) {
        if (!entry || !Persistent.ready) return;
        const clean = StringUtils.cleanCliphistEntry(entry);
        let list = [...(Persistent.states.pinnedClipboard || [])];
        const idx = list.findIndex(p => StringUtils.cleanCliphistEntry(p) === clean);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            list.push(entry);
        }
        Persistent.states.pinnedClipboard = list;
        root.refresh();
    }

    function sortEntries(rawList) {
        if (!rawList) return [];
        const pinned = rawList.filter(e => root.isPinned(e));
        const unpinned = rawList.filter(e => !root.isPinned(e));
        return [...pinned, ...unpinned];
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
        return sortEntries(rawResults);
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
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
        if (isPinned(entry)) {
            togglePin(entry);
        }
        Quickshell.execDetached([
            "bash", "-c",
            `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} delete`
        ]);
        delayedUpdateTimer.restart();
    }

    function wipe() {
        // Only wipe UNPINNED entries so pinned entries remain safe!
        const unpinned = entries.filter(e => !isPinned(e));
        if (unpinned.length === 0) return;

        const deleteCmds = unpinned.map(e => `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(e)}' | ${root.cliphistBinary} delete`);
        Quickshell.execDetached(["bash", "-c", deleteCmds.join(" && ")]);
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

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
