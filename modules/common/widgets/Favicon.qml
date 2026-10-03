import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell.Io
import Quickshell.Widgets

IconImage {
    id: root
    property string url
    property string displayText

    property real size: 32
    property string downloadUserAgent: (Config.options?.networking?.userAgent && Config.options.networking.userAgent.length > 0)
        ? Config.options.networking.userAgent
        : "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    property string faviconDownloadPath: Directories.favicons
    property string domainName: url ? (url.includes("vertexaisearch") ? displayText : (StringUtils.getDomain(url) ?? "")) : ""
    property string safeDomain: (domainName ?? "").replace(/[^a-zA-Z0-9.-]/g, "_")
    property string faviconUrl: `https://www.google.com/s2/favicons?domain=${domainName}&sz=32`
    property string fileName: `${safeDomain}.ico`
    property string faviconFilePath: `${faviconDownloadPath}/${fileName}`
    property string urlToLoad: ""

    Process {
        id: faviconDownloadProcess
        running: false
        command: ["bash", "-c", `mkdir -p '${root.faviconDownloadPath}' && [ -f '${root.faviconFilePath}' ] || curl -sL --connect-timeout 4 --max-time 8 '${root.faviconUrl}' -o '${root.faviconFilePath}' -H 'User-Agent: ${root.downloadUserAgent}'`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.safeDomain) {
                root.urlToLoad = "file://" + root.faviconFilePath;
            }
        }
    }

    function checkAndDownload() {
        if (!root.safeDomain || root.safeDomain.length === 0) {
            root.urlToLoad = "";
            return;
        }
        root.urlToLoad = "";
        if (!faviconDownloadProcess.running) {
            faviconDownloadProcess.running = true;
        }
    }

    onSafeDomainChanged: checkAndDownload()
    Component.onCompleted: checkAndDownload()

    MaterialSymbol {
        anchors.centerIn: parent
        iconSize: Math.max(12, root.size * 0.8)
        text: "language"
        color: Appearance.colors.colSubtext
        visible: root.status !== Image.Ready
    }

    source: root.urlToLoad
    implicitSize: root.size

    layer.enabled: root.status === Image.Ready
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.implicitSize
            height: root.implicitSize
            radius: Appearance.rounding.full
        }
    }
}