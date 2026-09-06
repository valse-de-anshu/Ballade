import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image backed by the Freedesktop thumbnail cache.
 * Handles:
 *   - First-time generation via ensure_wallpaper_thumbnails.py
 *   - Rename / delete / conflict: re-generates when source file changes identity
 *   - Stale cache: cache:false + forced source bust on regeneration
 *
 * IMPORTANT: sourcePath must be a plain absolute path WITHOUT file:// prefix.
 * The MD5 computation must match pathlib.Path(path).as_uri() in Python exactly.
 * encodeURIComponent in JS encodes all chars Python's as_uri() does (spaces→%20 etc).
 * Do NOT use Qt.resolvedUrl() here — it already percent-encodes the path,
 * and then encodeURIComponent would double-encode (space → %20 → %2520).
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: "x-large"
    property string thumbnailPath: {
        if (!sourcePath || sourcePath.length === 0) return "";
        // Ensure we have a clean absolute path (no file:// prefix)
        const clean = FileUtils.trimFileProtocol(sourcePath);
        if (!clean || clean.length === 0) return "";
        // Build Freedesktop-spec URI: encode each path segment individually
        // This matches: pathlib.Path(path).resolve().as_uri() in Python
        const encoded = clean.split("/").map(part => encodeURIComponent(part)).join("/");
        const uri = "file://" + encoded;
        const md5Hash = Qt.md5(uri);
        const cacheDir = FileUtils.trimFileProtocol(Directories.genericCache);
        return `${cacheDir}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }

    // Version-bust string: bumped when thumbnail is freshly regenerated
    property string _versionBust: ""
    source: thumbnailPath
        ? ("file://" + thumbnailPath + (_versionBust ? "?v=" + _versionBust : ""))
        : ""

    cache: false
    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function _runGeneration() {
        if (!root.generateThumbnail) return;
        if (!root.sourcePath || root.sourcePath.length === 0) return;
        thumbnailGeneration.running = false;
        thumbnailGeneration.running = true;
    }

    Component.onCompleted: _runGeneration()

    onSourcePathChanged: {
        root._versionBust = "";
        _runGeneration();
    }

    Process {
        id: thumbnailGeneration
        command: [
            "python3",
            `${Directories.scriptPath}/thumbnails/ensure_wallpaper_thumbnails.py`,
            "--single",
            FileUtils.trimFileProtocol(root.sourcePath),
            "--size",
            root.thumbnailSizeName
        ]
        onExited: (exitCode, exitStatus) => {
            if (!root.thumbnailPath) return;
            if (exitCode === 1) {
                // Thumbnail was freshly regenerated (new file, rename, conflict, etc.)
                root._versionBust = Date.now().toString();
            } else if (exitCode === 0 && root.status !== Image.Ready) {
                // Already fresh but image not loaded yet — force a load
                const s = "file://" + root.thumbnailPath;
                root.source = "";
                root.source = s;
            }
        }
    }

    // Retry on load error (thumbnail written by concurrent process, disk flush delay)
    Timer {
        id: retryTimer
        interval: 800
        repeat: false
        onTriggered: _runGeneration()
    }
    onStatusChanged: {
        if (status === Image.Error) retryTimer.start();
    }
}
