import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property bool mediaEnabled: Config.options.sidebar.media.enable
    property var tabButtonList: [
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.mediaEnabled ? [{"icon": "music_note", "name": Translation.tr("Media")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    function setTab(idx) {
        if (idx >= 0 && idx < swipeView.count) {
            swipeView.currentIndex = idx
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: verticalTabBar.expanded ? -2 : 0

        VerticalTabBar {
            id: verticalTabBar
            visible: tabButtonList.length > 0
            Layout.fillWidth: true
            tabButtonList: root.tabButtonList
            currentIndex: swipeView.currentIndex
            onCurrentIndexChanged: swipeView.currentIndex = currentIndex
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            topLeftRadius: 0
            bottomLeftRadius: Appearance.rounding.normal
            topRightRadius: 0
            bottomRightRadius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10

                property var loadedTabs: ({})
                function isTabLoaded(idx) {
                    return loadedTabs[idx] === true;
                }
                function markTab(idx) {
                    if (loadedTabs[idx]) return;
                    let c = Object.assign({}, loadedTabs);
                    c[idx] = true;
                    loadedTabs = c;
                }
                onCurrentIndexChanged: markTab(currentIndex)
                Component.onCompleted: markTab(currentIndex)

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                Loader {
                    active: root.aiChatEnabled && swipeView.isTabLoaded(0)
                    visible: active
                    sourceComponent: Component { AiChat { scopeRoot: root.scopeRoot } }
                }
                Loader {
                    active: root.translatorEnabled && swipeView.isTabLoaded(1)
                    visible: active
                    sourceComponent: Component { Translator {} }
                }
                Loader {
                    active: root.mediaEnabled && swipeView.isTabLoaded(2)
                    visible: active
                    sourceComponent: Component { SidebarPlayerControl {} }
                }
                Loader {
                    active: (root.animeEnabled && !root.animeCloset) && swipeView.isTabLoaded(3)
                    visible: active
                    sourceComponent: Component { Anime {} }
                }
            }
        }
    }
}