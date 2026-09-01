pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    // These are needed on the parent loader
    property bool editing: false
    property bool renderMarkdown: true
    property bool enableMouseSelection: false
    property var segmentContent: ({})
    property var messageData: {}
    property bool done: true
    property bool forceDisableChunkSplitting: false

    property list<string> trackedLatexHashes: []
    property string shownText: ""
    property bool fadeChunkSplitting: !forceDisableChunkSplitting && !editing && !/\n\|/.test(shownText) && Config.options.sidebar.ai.textFadeIn

    Layout.fillWidth: true

    function updateShownText() {
        if (!root.segmentContent || typeof root.segmentContent !== "string") {
            root.shownText = ""
            return
        }

        if (root.editing || !root.renderMarkdown) {
            root.shownText = root.segmentContent
            return
        }

        // Parse math delimiters: $$...$$, $...$, \[...\], \(...\)
        let regex = /(\$\$([\s\S]+?)\$\$)|(\$([^\$\n\r]+?)\$)|(\\\[([\s\S]+?)\\\])|(\\\(([\s\S]+?)\\\))/g;
        let src = root.segmentContent
        let outText = ""
        let lastIdx = 0
        let match;

        while ((match = regex.exec(src)) !== null) {
            let fullToken = match[0]
            let innerFormula = match[2] || match[4] || match[6] || match[8] || ""
            let trimmedInner = innerFormula.trim()

            outText += src.slice(lastIdx, match.index)
            lastIdx = regex.lastIndex

            if (trimmedInner.length > 0) {
                let hash = Qt.md5(trimmedInner)
                if (LatexRenderer.isReady(hash)) {
                    let imgPath = LatexRenderer.getRenderedPath(hash)
                    outText += `![latex](${imgPath})`
                } else {
                    outText += fullToken
                    if (!root.trackedLatexHashes.includes(hash)) {
                        root.trackedLatexHashes.push(hash)
                    }
                    LatexRenderer.requestRender(trimmedInner)
                }
            } else {
                outText += fullToken
            }
        }

        outText += src.slice(lastIdx)
        root.shownText = outText
    }

    onSegmentContentChanged: updateShownText()
    onEditingChanged: updateShownText()
    onRenderMarkdownChanged: updateShownText()

    Connections {
        target: LatexRenderer
        function onRenderFinished(hash, imagePath) {
            if (root.trackedLatexHashes.includes(hash) || LatexRenderer.isReady(hash)) {
                root.updateShownText()
            }
        }
    }

    spacing: 0
    Repeater {
        id: textLinesRepeater
        property list<real> textLineOpacities: []
        model: ScriptModel {
            // Split by either double newlines or single newlines in a list
            values: root.fadeChunkSplitting ? root.shownText.split(/\n\n(?= {0,2})|\n(?= {0,2}[-\*])/g).filter(line => line.trim() !== "") : [root.shownText]
            onValuesChanged: {
                while (textLinesRepeater.textLineOpacities.length < values.length) {
                    textLinesRepeater.textLineOpacities.push(root.done ? 1 : 0);
                }
            }
        }
        delegate: TextArea {
            id: textArea
            required property int index
            required property string modelData

            // Fade in animation
            visible: opacity > 0
            opacity: fadeChunkSplitting ? (textLinesRepeater.textLineOpacities[index] ?? (root.done ? 1 : 0)) : 1
            Connections {
                target: textLinesRepeater.model
                function onValuesChanged() {
                    if (textLinesRepeater.model.values.length > textArea.index + 1) {
                        textLinesRepeater.textLineOpacities[textArea.index] = 1
                    }
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Layout.fillWidth: true
            readOnly: !editing
            selectByMouse: enableMouseSelection || editing
            renderType: Text.NativeRendering
            font.family: Appearance.font.family.reading
            font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
            selectionColor: Appearance.colors.colSecondaryContainer
            wrapMode: TextEdit.Wrap
            color: root.messageData?.thinking ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
            textFormat: renderMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
            text: modelData

            onTextChanged: {
                if (!root.editing) return
                segmentContent = text
            }

            onLinkActivated: (link) => {
                Qt.openUrlExternally(link)
                GlobalStates.sidebarLeftOpen = false
            }

            MouseArea { // Pointing hand for links
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // Only for hover
                hoverEnabled: true
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : 
                    (enableMouseSelection || editing) ? Qt.IBeamCursor : Qt.ArrowCursor
            }

            // Rectangle {
            //     anchors.fill: parent
            //     color: "#22786378"
            //     border.width: 1
            //     border.color: "#7E7E7E"
            // }
        }
    }
}
