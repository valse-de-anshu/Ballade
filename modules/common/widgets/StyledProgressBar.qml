pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls


/**
 * Material 3 progress bar. See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
    id: root
    property real valueBarWidth: 120
    property real valueBarHeight: 6
    property real valueBarGap: 6
    property color highlightColor: Appearance?.colors.colPrimary ?? "#685496"
    property color trackColor: Appearance?.m3colors.m3secondaryContainer ?? "#F1D3F9"
    property bool wavy: false
    property bool animateWave: false
    
    Behavior on value {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    
    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Item {
        id: contentItem
        anchors.fill: parent

        Loader {
            anchors.left: parent.left
            width: contentItem.width * root.visualPosition
            height: parent.height
            active: !root.wavy
            sourceComponent: Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.highlightColor
            }
        }

        Loader {
            anchors.left: parent.left
            width: contentItem.width * root.visualPosition
            height: parent.height
            active: root.wavy
            sourceComponent: Canvas {
                id: pbCanvas
                property real currentPhase: 0

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width <= 2) return;

                    var centerY = height / 2;
                    var amplitude = 2.8;
                    var wavelength = 28.0;

                    ctx.strokeStyle = root.highlightColor;
                    ctx.lineWidth = 3.2;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();

                    ctx.moveTo(0, centerY);
                    for (var px = 0; px <= width; px += 1.5) {
                        var taper = 1.0;
                        var distFromEnd = width - px;
                        if (distFromEnd < 12) {
                            taper = Math.max(0, distFromEnd / 12.0);
                        }
                        var py = centerY + amplitude * taper * Math.sin((px / wavelength) * 2 * Math.PI + currentPhase);
                        ctx.lineTo(px, py);
                    }
                    ctx.stroke();
                }

                Connections {
                    target: root
                    function onVisualPositionChanged() { pbCanvas.requestPaint() }
                }

                Timer {
                    interval: 40
                    repeat: true
                    running: root.animateWave && pbCanvas.visible && width > 4
                    onTriggered: {
                        pbCanvas.currentPhase += 0.045;
                        if (pbCanvas.currentPhase > 6.28) pbCanvas.currentPhase -= 6.28;
                        pbCanvas.requestPaint();
                    }
                }
            }
        }
        
        Rectangle { // Right remaining part fill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, (1 - root.visualPosition) * parent.width)
            height: root.wavy ? 3.5 : parent.height
            radius: height / 2
            color: root.trackColor
        }
        
        // Circular head
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, contentItem.width * root.visualPosition - (width / 2))
            width: 12
            height: 12
            radius: height / 2
            color: root.highlightColor
            border.width: 0
        }
    }
}