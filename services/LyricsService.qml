pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    property var lyricsLines: []
    property int activeIndex: -1
    property string status: "loading"  // "loading" | "ok" | "not_found" | "no_info" | "error"
    property var slots: ["", "", "", "", "", "", ""]

    // Track what we last searched so retries know what to re-run
    property string _lastTitle:    ""
    property string _lastArtist:   ""
    property string _lastDuration: ""
    property string _lastUrl:      ""

    readonly property int before: 3
    readonly property int after:  3
    readonly property int total:  7

    function buildSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            let lineIdx = idx - root.before + i
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length)
                result.push(root.lyricsLines[lineIdx].text || "♪")
            else
                result.push("")
        }
        return result
    }

    // ── Sync timer: updates activeIndex every 300ms while playing ─────────────
    Timer {
        id: syncTimer
        interval: 300
        repeat: true
        running: root.status === "ok" && root.lyricsLines.length > 0
        onTriggered: {
            const pos = root.activePlayer?.position ?? 0
            let idx = -1
            for (let i = 0; i < root.lyricsLines.length; i++) {
                if (root.lyricsLines[i].time <= pos) idx = i
                else break
            }
            if (idx !== root.activeIndex) {
                root.activeIndex = idx
                root.slots = root.buildSlots(idx)
            }
        }
    }

    // ── Auto-retry: if not_found, retry once after 8s (network may have been slow)
    Timer {
        id: retryTimer
        interval: 8000
        repeat: false
        running: false
        onTriggered: {
            if (root.status === "not_found" || root.status === "error") {
                root._runFetch(root._lastTitle, root._lastArtist,
                               root._lastDuration, root._lastUrl)
            }
        }
    }

    // ── Process that runs lyrics.py ───────────────────────────────────────────
    Process {
        id: lyricsProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                if (trimmed === "not_found") {
                    root.status = "not_found"
                    retryTimer.restart()   // auto-retry once
                    return
                }
                if (trimmed === "no_info") { root.status = "no_info"; return }

                const parts = trimmed.split("§")
                if (parts.length < 3) return
                if (parts[parts.length - 1].trim() !== "ok") return

                let lines = []
                for (let i = 0; i < parts.length - 1; i += 2) {
                    const t = parseFloat(parts[i])
                    const txt = parts[i + 1] || ""
                    if (!isNaN(t)) lines.push({ time: t, text: txt })
                }

                if (lines.length === 0) {
                    root.status = "not_found"
                    retryTimer.restart()
                    return
                }

                retryTimer.stop()
                root.lyricsLines = lines
                root.activeIndex = -1
                root.slots = root.buildSlots(-1)
                root.status = "ok"
            }
        }
    }

    // ── Internal: kick off the python process ─────────────────────────────────
    function _runFetch(title, artist, duration, url) {
        lyricsProc.running = false
        lyricsProc.command = [
            "python3",
            `${Directories.scriptPath}/lyrics/lyrics.py`,
            title, artist, duration, url
        ]
        lyricsProc.running = true
    }

    // ── Public: restart for a new track ──────────────────────────────────────
    function restartLyrics() {
        retryTimer.stop()
        lyricsProc.running = false
        root.lyricsLines = []
        root.activeIndex = -1
        root.slots = ["", "", "", "", "", "", ""]
        root.status = "loading"

        const title    = root.activePlayer?.trackTitle  ?? ""
        const artist   = root.activePlayer?.trackArtist ?? ""
        const duration = String(Math.floor(root.activePlayer?.length ?? 0))
        const url      = root.activePlayer?.trackUrl    ?? ""

        if (!title) { root.status = "no_info"; return }

        // Save so retries can re-use them
        root._lastTitle    = title
        root._lastArtist   = artist
        root._lastDuration = duration
        root._lastUrl      = url

        root._runFetch(title, artist, duration, url)
    }

    // ── Public: manual reload from UI (force bypass cache would need --no-cache flag)
    function reloadLyrics() {
        root.restartLyrics()
    }

    // ── React to track changes ────────────────────────────────────────────────
    Connections {
        target: root.activePlayer
        function onTrackTitleChanged() { root.restartLyrics() }
    }

    Component.onCompleted: root.restartLyrics()
}