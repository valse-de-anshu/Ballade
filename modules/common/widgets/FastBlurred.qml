import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property Item target: null
    property real blurRadius: 32
    property bool blurEnabled: true
    property bool transparentBorder: true

    FastBlur {
        anchors.fill: parent
        visible: root.blurEnabled && root.target !== null
        source: root.target
        radius: root.blurRadius
        transparentBorder: root.transparentBorder
    }
}