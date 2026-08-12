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
        return (Persistent.states.pinnedClipboard || []).indexOf(clean) >= 0;
    }

    function togglePin(entry) {
        if (!entry || !Persistent.ready) return;
        const clean = StringUtils.cleanCliphistEntry(entry);
        let list = [...(Persistent.states.pinnedClipboard || [])];
        const idx = list.indexOf(clean);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            list.push(clean); // Store DISPLAY TEXT only (not raw entry with ID) for reboot persistence
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
        // Pinned items are fully protected — cannot be deleted
        if (isPinned(entry)) return;
        Quickshell.execDetached([
            "bash", "-c",
            `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} delete`
        ]);
        delayedUpdateTimer.restart();
    }

    function wipe() {
        const pinnedList = entries.filter(e => isPinned(e));
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

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
