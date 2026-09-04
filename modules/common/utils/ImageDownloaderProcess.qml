import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    
    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    function processSourceUrl() {
        return StringUtils.shellSingleQuoteEscape(sourceUrl);
    }

    function curlUserAgentArg() {
        if (!downloadUserAgent || sourceUrl.includes("waifu.im")) {
            return "";
        }
        return ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(downloadUserAgent)}'`;
    }

    function curlRefererArg() {
        if (sourceUrl && (sourceUrl.includes("pixiv") || sourceUrl.includes("pximg"))) {
            return " -H 'Referer: https://www.pixiv.net/'";
        }
        return "";
    }

    running: true
    command: ["bash", "-c", 
        `TARGET='${processFilePath()}'; if [ -s "$TARGET" ]; then file "$TARGET"; exit 0; fi; mkdir -p "$(dirname "$TARGET")"; LOCK="$TARGET.lock"; TMP="$TARGET.part"; exec 200>"$LOCK"; if flock -n 200; then if [ ! -s "$TARGET" ]; then curl -sSL --connect-timeout 8 --max-time 90 '${processSourceUrl()}'${curlUserAgentArg()}${curlRefererArg()} -o "$TMP"; if [ -s "$TMP" ]; then mv -f "$TMP" "$TARGET"; else rm -f "$TMP"; fi; fi; flock -u 200; rm -f "$LOCK"; else flock 200; flock -u 200; fi; [ -s "$TARGET" ] && file "$TARGET"`
    ]
    stdout: StdioCollector {
        id: imageSizeOutputCollector
        onStreamFinished: {
            const output = imageSizeOutputCollector.text.trim();
            const match = output.match(/(\d+)\s*x\s*(\d+)/);

            if (match) {
                const width = Number(match[1]);
                const height = Number(match[2]);
                root.done(root.filePath, width, height);
            }
        }
    }
}