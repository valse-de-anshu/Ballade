import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var targetTextField
    property bool active: false
    property real volume: 0.0
    property real bounceY: 0.0
    property string baseText: ""

    implicitWidth: 34
    implicitHeight: 34

    signal transcribed(string text)

    Component.onDestruction: {
        root.stopRecording();
    }

    // Smooth Kimi bouncing ball animation
    SequentialAnimation {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "bounceY"
            from: 0
            to: -5
            duration: 850
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "bounceY"
            from: -5
            to: 0
            duration: 850
            easing.type: Easing.InOutQuad
        }
    }

    // Process for microphone capture and speech recognition
    Process {
        id: transcribeProc
        command: [
            "/home/valse-de-anshu/.config/quickshell/ballade/scripts/venv/bin/python3",
            "/home/valse-de-anshu/.config/quickshell/ballade/scripts/voice/transcribe.py"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (line.startsWith("VOLUME:")) {
                    let v = parseFloat(line.substring(7));
                    if (!isNaN(v)) root.volume = v;
                } else if (line.startsWith("PARTIAL:")) {
                    let partial = line.substring(8).trim();
                    if (partial.length > 0) {
                        let prefix = root.baseText;
                        if (prefix.length > 0 && !prefix.endsWith(" ")) prefix += " ";
                        root.targetTextField.text = prefix + partial;
                        root.targetTextField.cursorPosition = root.targetTextField.text.length;
                    }
                } else if (line.startsWith("FINAL:")) {
                    let text = line.substring(6).trim();
                    if (text.length > 0) {
                        let prefix = root.baseText;
                        if (prefix.length > 0 && !prefix.endsWith(" ")) prefix += " ";
                        let fullText = prefix + text;
                        root.targetTextField.text = fullText;
                        root.targetTextField.cursorPosition = root.targetTextField.text.length;
                        root.transcribed(fullText);
                    }
                    root.stopRecording();
                } else if (line.startsWith("STATUS:SILENCE_TIMEOUT")) {
                    root.stopRecording();
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.active = false;
            root.volume = 0.0;
        }
    }

    function toggleRecording() {
        if (root.active) {
            root.stopRecording();
        } else {
            root.startRecording();
        }
    }

    function startRecording() {
        root.baseText = root.targetTextField.text;
        root.active = true;
        root.volume = 0.0;
        transcribeProc.running = false;
        transcribeProc.running = true;
    }

    function stopRecording() {
        transcribeProc.running = false;
        root.active = false;
        root.volume = 0.0;
    }

    // Glowing Radial Light Aura (Radiating smooth blue light like Kimi ball)
    Rectangle {
        id: glowAura
        visible: root.active
        anchors.centerIn: parent
        width: 32 + root.volume * 18
        height: 32 + root.volume * 18
        radius: width / 2
        color: "#00b4d8"
        opacity: 0.35 + root.volume * 0.55
        transform: Translate { y: root.bounceY }

        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Outer Pulse Ring
    Rectangle {
        id: pulseRing
        visible: root.active
        anchors.centerIn: parent
        width: 28 + root.volume * 10
        height: 28 + root.volume * 10
        radius: width / 2
        color: "transparent"
        border.color: "#90e0ef"
        border.width: 2
        opacity: 0.6 + root.volume * 0.4
        transform: Translate { y: root.bounceY }

        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }
    }

    // Inner Kimi Circular Blue Ball Button
    GroupButton {
        id: micButton
        anchors.fill: parent
        buttonRadius: Appearance.rounding.full
        colBackground: root.active ? "#0077b6" : "transparent"
        colBackgroundHover: root.active ? "#023e8a" : Appearance.colors.colLayer2Hover
        transform: Translate { y: root.bounceY }

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            text: "mic"
            iconSize: 18
            color: root.active ? "#caf0f8" : Appearance.colors.colOnLayer1
        }

        onClicked: root.toggleRecording()
    }
}
