//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        ScreenTime.load()

        if (Config.options.sounds.enableStartupSound ?? true) {
            let startPath = Config.options.sounds.startupSoundPath || "";
            if (startPath.length > 0) {
                let vol = Math.max(0, Math.min(100, Config.options.sounds.systemSoundVolume ?? 70));
                let volNorm = (vol / 100).toFixed(2);
                let paVol = Math.round(65536 * (vol / 100));
                let cmd = `p="${startPath}"; if [ -d "$p" ]; then file=$(find "$p" -maxdepth 1 -type f \\( -name "*.flac" -o -name "*.wav" -o -name "*.mp3" -o -name "*.ogg" \\) 2>/dev/null | shuf -n 1); else file="$p"; fi; if [ -n "$file" ] && [ -f "$file" ]; then pw-play --volume ${volNorm} --media-role=event "$file" 2>/dev/null || paplay --volume=${paVol} --media-role=event "$file" 2>/dev/null || mpv --no-video --volume=${vol} "$file" 2>/dev/null || canberra-gtk-play --file="$file" 2>/dev/null; fi`;
                Quickshell.execDetached(["bash", "-c", cmd]);
            }
        }
    }


    // Panel families
    property list<string> families: ["ii"]
    function cyclePanelFamily() {
        Config.options.panelFamily = "ii"
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            // Keep locked to ii
            Config.options.panelFamily = "ii"
        }
    }
}

