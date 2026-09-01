import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int currentIndex: 0
    property bool expanded: false
    property color colToggled: Appearance.colors.colSecondaryContainer
    default property alias _contentData: tabBarColumn.data  
    implicitHeight: tabBarColumn.implicitHeight
    implicitWidth: tabBarColumn.implicitWidth
    Layout.topMargin: 25

    function getActiveButton() {
        let count = 0;
        for (let i = 0; i < tabBarColumn.children.length; ++i) {
            let child = tabBarColumn.children[i];
            if (child && child.baseSize !== undefined) {
                if (count === root.currentIndex) return child;
                count++;
            }
        }
        return null;
    }

    Rectangle {
        id: highlightPill
        property var activeBtn: root.getActiveButton()
        property real itemHeight: activeBtn?.baseSize ?? 56
        property real baseHighlightHeight: activeBtn?.baseHighlightHeight ?? 32

        anchors {
            top: tabBarColumn.top
            left: tabBarColumn.left
            topMargin: itemHeight * root.currentIndex + (root.expanded ? 0 : ((itemHeight - baseHighlightHeight) / 2))
        }
        radius: Appearance.rounding.full
        color: root.colToggled
        implicitHeight: root.expanded ? itemHeight : baseHighlightHeight
        implicitWidth: root.expanded ? (activeBtn?.visualWidth ?? 140) : (activeBtn?.baseSize ?? 56)

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: Appearance.animationCurves.expressiveFastSpatialDuration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.animationCurves.expressiveFastSpatialDuration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
    }

    ColumnLayout {
        id: tabBarColumn
        anchors.fill: parent
        spacing: 0
    }
}
