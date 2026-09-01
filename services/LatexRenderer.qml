pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell

/**
 * Renders LaTeX snippets with MicroTeX.
 * For every request:
 *   1. Hash it
 *   2. Check if the hash is already processed
 *   3. If not, render it with MicroTeX and mark as processed
 */
Singleton {
    id: root
    
    readonly property var renderPadding: 4 // This is to prevent cutoff in the rendered images

    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    property string microtexBinaryDir: "/opt/MicroTeX"
    property string microtexBinaryName: "LaTeX"
    property string latexOutputPath: Directories.latexOutput

    signal renderFinished(string hash, string imagePath)

    function getRenderedPath(hash) {
        return renderedImagePaths[hash] || ""
    }

    function isReady(hash) {
        return !!(renderedImagePaths && renderedImagePaths[hash])
    }

    /**
    * Requests rendering of a LaTeX expression.
    * Returns the [hash, isNew]
    */
    function requestRender(expression) {
        if (!expression || typeof expression !== "string" || !expression.trim()) return ["", false]
        const cleanExpr = expression.trim()
        const hash = Qt.md5(cleanExpr)
        const imagePath = `${latexOutputPath}/${hash}.svg`
        
        // 1. If already rendered and ready, notify and return
        if (root.isReady(hash)) {
            renderFinished(hash, imagePath)
            return [hash, false]
        }
        
        // 2. If already in flight, don't spawn duplicate processes
        if (processedHashes.includes(hash)) {
            return [hash, false]
        }

        root.processedHashes.push(hash)
        root.processedExpressions[hash] = cleanExpr

        // 3. Render with MicroTeX
        const processQml = `
            import Quickshell.Io
            Process {
                id: microtexProcess${hash}
                running: true
                command: [ "bash", "-c", 
                    "cd ${root.microtexBinaryDir} && ./${root.microtexBinaryName} -headless '-input=${StringUtils.shellSingleQuoteEscape(StringUtils.escapeBackslashes(cleanExpr))}' "
                    + "'-output=${imagePath}' " 
                    + "'-textsize=${Appearance.font.pixelSize.normal}' "
                    + "'-padding=${renderPadding}' "
                    + "'-foreground=${Appearance.colors.colOnLayer1}' "
                    + "-maxwidth=0.85 "
                ]
                onExited: (exitCode, exitStatus) => {
                    let updated = Object.assign({}, root.renderedImagePaths)
                    updated["${hash}"] = "${imagePath}"
                    root.renderedImagePaths = updated
                    root.renderFinished("${hash}", "${imagePath}")
                    microtexProcess${hash}.destroy()
                }
            }
        `
        Qt.createQmlObject(processQml, root, `MicroTeXProcess_${hash}`)
        return [hash, true]
    }
}