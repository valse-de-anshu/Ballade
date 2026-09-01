import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    property var responseData
    property var tagInputField

    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath

    width: ListView.view?.width ?? parent?.width ?? 0
    height: implicitHeight
    implicitHeight: columnLayout.implicitHeight + root.responsePadding * 2

    property real availableWidth: Math.max(100, (ListView.view ? ListView.view.width : (parent ? parent.width : 400)))
    property real rowTooShortThreshold: 190
    property real imageSpacing: 5
    property real responsePadding: 5

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: columnLayout
        
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: responsePadding
        spacing: root.imageSpacing

        RowLayout { // Header
            Rectangle { // Provider name
                id: providerNameWrapper
                color: Appearance.colors.colSecondaryContainer
                radius: Appearance.rounding.small
                implicitWidth: providerName.implicitWidth + 10 * 2
                implicitHeight: Math.max(providerName.implicitHeight + 5 * 2, 30)
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerName
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.m3colors.m3onSecondaryContainer
                    text: Booru.providers[root.responseData.provider].name
                }
            }
            Item { Layout.fillWidth: true }
            Item { // Page number
                visible: root.responseData.page != "" && root.responseData.page > 0
                implicitWidth: Math.max(pageNumber.implicitWidth + 10 * 2, 30)
                implicitHeight: pageNumber.implicitHeight + 5 * 2
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: pageNumber
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer2
                    // text: `Page ${root.responseData.page}`
                    text: Translation.tr("Page %1").arg(root.responseData.page)
                }
            }
        }

        StyledFlickable { // Tag strip
            id: tagsFlickable
            visible: root.responseData.tags.length > 0
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            implicitHeight: tagRowLayout.implicitHeight
            contentWidth: tagRowLayout.implicitWidth

            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: tagsFlickable.width
                    height: tagsFlickable.height
                    radius: Appearance.rounding.small
                }
            }

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            RowLayout {
                id: tagRowLayout
                Layout.alignment: Qt.AlignBottom

                Repeater {
                    id: tagRepeater
                    model: root.responseData.tags

                    ApiCommandButton {
                        Layout.fillWidth: false
                        buttonText: modelData
                        onClicked: {
                            if(root.tagInputField.text.length !== 0) root.tagInputField.text += " "
                            root.tagInputField.text += modelData
                        }
                    }
                }
                
            }
        }

        StyledText { // Message
            id: messageText
            Layout.fillWidth: true
            visible: root.responseData.message.length > 0
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: root.responseData.message
            wrapMode: Text.WordWrap
            Layout.margins: responsePadding
            textFormat: Text.MarkdownText
            onLinkActivated: (link) => {
                Qt.openUrlExternally(link)
                GlobalStates.sidebarLeftOpen = false
            }
            PointingHandLinkHover {}
        }

        Repeater {
            model: ScriptModel {
                values: {
                    // Greedily add images to a row as long as rowHeight >= rowTooShortThreshold
                    let i = 0;
                    let rows = [];
                    const responseList = root.responseData.images;
                    const minRowHeight = rowTooShortThreshold;
                    const availableImageWidth = availableWidth - root.imageSpacing - (responsePadding * 2);

                    while (i < responseList.length) {
                        let row = {
                            height: 0,
                            images: [],
                        };
                        let j = i;
                        let combinedAspect = 0;
                        let rowHeight = 0;

                        // Try to add as many images as possible without going below minRowHeight
                        while (j < responseList.length) {
                            combinedAspect += responseList[j].aspect_ratio;
                            // Subtract imageSpacing for each gap between images in the row
                            let imagesInRow = j - i + 1;
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);
                            let rowAvailableWidth = availableImageWidth - totalSpacing;
                            rowHeight = rowAvailableWidth / combinedAspect;
                            if (rowHeight < minRowHeight) {
                                combinedAspect -= responseList[j].aspect_ratio;
                                imagesInRow -= 1;
                                totalSpacing = root.imageSpacing * (imagesInRow - 1);
                                rowAvailableWidth = availableImageWidth - totalSpacing;
                                rowHeight = rowAvailableWidth / combinedAspect;
                                break;
                            }
                            j++;
                        }

                        // If we couldn't add any image (shouldn't happen), add at least one
                        if (j === i) {
                            row.images.push(responseList[i]);
                            row.height = availableImageWidth / responseList[i].aspect_ratio;
                            rows.push(row);
                            i++;
                        } else {
                            for (let k = i; k < j; k++) {
                                row.images.push(responseList[k]);
                            }
                            // Recalculate spacing for the final row
                            let imagesInRow = j - i;
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);
                            let rowAvailableWidth = availableImageWidth - totalSpacing;
                            row.height = rowAvailableWidth / combinedAspect;
                            rows.push(row);
                            i = j;
                        }
                    }
                    return rows;
                }
            }
            delegate: RowLayout {
                id: imageRow
                required property var modelData
                property var rowHeight: modelData.height
                spacing: root.imageSpacing

                Repeater {
                    model: modelData.images
                    delegate: BooruImage {
                        required property var modelData
                        imageData: modelData
                        rowHeight: imageRow.rowHeight
                        imageRadius: imageRow.modelData.images.length == 1 ? 50 : Appearance.rounding.normal
                        // Download manually to reduce redundant requests or make sure downloading works
                        manualDownload: ["danbooru", "waifu.im", "t.alcy.cc", "konachan"].includes(root.responseData.provider)
                        previewDownloadPath: root.previewDownloadPath
                        downloadPath: root.downloadPath
                        nsfwPath: root.nsfwPath
                    }
                }
            }
        }
    }
}