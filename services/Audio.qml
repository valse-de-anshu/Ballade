pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        if (Audio.sink?.audio) {
            Audio.sink.audio.muted = !Audio.sink.audio.muted
        }
    }

    function toggleMicMute() {
        if (Audio.source?.audio) {
            Audio.source.audio.muted = !Audio.source.audio.muted
        }
    }

    function incrementVolume(customStep) {
        if (!Audio.sink?.audio) return;
        const currentVolume = Audio.value;
        const step = (typeof customStep === "number") ? customStep : (currentVolume < 0.1 ? 0.01 : 0.05);
        Audio.sink.audio.volume = Math.min(1.0, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume(customStep) {
        if (!Audio.sink?.audio) return;
        const currentVolume = Audio.value;
        const step = (typeof customStep === "number") ? customStep : (currentVolume < 0.1 ? 0.01 : 0.05);
        Audio.sink.audio.volume = Math.max(0.0, Audio.sink.audio.volume - step);
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName, customPath) {
        let p = (customPath && customPath.trim().length > 0) ? customPath.trim() : "";
        if (p.startsWith("file://")) p = p.substring(7);

        let vol = Math.max(0, Math.min(100, Config.options.sounds.systemSoundVolume ?? 70));
        let volNorm = (vol / 100).toFixed(2);
        let paVol = Math.round(65536 * (vol / 100));

        if (p.length > 0) {
            let cmd = `pw-play --volume ${volNorm} --media-role=event "${p}" 2>/dev/null || paplay --volume=${paVol} --media-role=event "${p}" 2>/dev/null || mpv --no-video --volume=${vol} "${p}" 2>/dev/null || canberra-gtk-play --file="${p}" 2>/dev/null || ffplay -nodisp -autoexit -volume ${vol} "${p}" 2>/dev/null`;
            Quickshell.execDetached(["bash", "-c", cmd]);
            return;
        }

        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;
        let cmd = `pw-play --volume ${volNorm} --media-role=event "${ogaPath}" 2>/dev/null || paplay --volume=${paVol} --media-role=event "${ogaPath}" 2>/dev/null || pw-play --volume ${volNorm} --media-role=event "${oggPath}" 2>/dev/null || paplay --volume=${paVol} --media-role=event "${oggPath}" 2>/dev/null || canberra-gtk-play -i "${soundName}" 2>/dev/null`;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }
}
