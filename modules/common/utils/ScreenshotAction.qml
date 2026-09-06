pragma ComponentBehavior: Bound
pragma Singleton
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        const cropBase = `magick ${StringUtils.shellSingleQuoteEscape(screenshotPath)} `
            + `-crop ${rw}x${rh}+${rx}+${ry} +repage`
        const cropToStdout = `${cropBase} -`
        const cropInPlace = `${cropBase} '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const cleanup = `rm '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        const annotationCommand = `${Config.options.regionSelector.annotation.useSatty ? "satty" : "swappy"} -f -`;
        switch (action) {
            case ScreenshotAction.Action.Copy:
                const targetDir = saveDir !== "" ? saveDir : `${Directories.pictures}/Screenshots`
                return [
                    "bash", "-c",
                    `mkdir -p '${StringUtils.shellSingleQuoteEscape(targetDir)}' && \
                    targetDir='${StringUtils.shellSingleQuoteEscape(targetDir)}' && \
                    targetDir="\${targetDir%/}" && \
                    saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && \
                    savePath="$targetDir/$saveFileName" && \
                    ${cropBase} "$savePath" && \
                    python3 '${Directories.scriptPath}/clipboard/copy-image-with-path.py' "$savePath" && \
                    ${cleanup}`
                ]
                break;
            case ScreenshotAction.Action.Edit:
                const editTargetDir = saveDir !== "" ? saveDir : `${Directories.pictures}/Screenshots`
                return [
                    "bash", "-c",
                    `mkdir -p '${StringUtils.shellSingleQuoteEscape(editTargetDir)}' && \
                    editTargetDir='${StringUtils.shellSingleQuoteEscape(editTargetDir)}' && \
                    editTargetDir="\${editTargetDir%/}" && \
                    saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && \
                    savePath="$editTargetDir/$saveFileName" && \
                    ${cropBase} "$savePath" && \
                    python3 '${Directories.snipAnnotateScriptPath}' --file "$savePath" && \
                    ${cleanup}`
                ]
                break;
            case ScreenshotAction.Action.Search:
                return ["bash", "-c", `${cropInPlace} && xdg-open "${root.imageSearchEngineBaseUrl}$(${uploadAndGetUrl(screenshotPath)})" && ${cleanup}`]
                break;
            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c", `${cropInPlace} && text=$(tesseract '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' stdout -l eng+hin 2>/dev/null) && if [ -n "$text" ]; then printf '%s' "$text" | wl-copy && notify-send -a "OCR" -i "edit-paste" "Text Copied to Clipboard" "$text"; else notify-send -a "OCR" -i "dialog-warning" "OCR" "No text recognized"; fi; ${cleanup}`]
                break;
            case ScreenshotAction.Action.Record:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}'`]
                break;
            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${slurpRegion}' --sound`]
                break;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}
