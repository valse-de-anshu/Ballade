pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Hyprland
 */
Singleton {
    id: root
    
    signal reloaded()

    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/hyprconfigurator.py")
    readonly property string shellOverridesPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/main.lua`)

    function set(key: string, value: var) {
        Quickshell.execDetached(["bash", "-c",
            `python3 '${root.configuratorScriptPath}' --file '${root.shellOverridesPath}' --set "${key}" "${value}" && hyprctl reload`
        ])
    }
    
    function setMany(entries: var) {
        let args = ""
        for (let key in entries) {
            args += `--set "${key}" "${entries[key]}" `
        }
        Quickshell.execDetached(["bash", "-c",
            `python3 '${root.configuratorScriptPath}' --file '${root.shellOverridesPath}' ${args} && hyprctl reload`
        ])
    }
    
    function reset(key: string) {
        Quickshell.execDetached(["bash", "-c",
            `python3 '${root.configuratorScriptPath}' --file '${root.shellOverridesPath}' --reset "${key}" && hyprctl reload`
        ])
    }
    
    function resetMany(keys: list<string>) {
        let args = ""
        for (let i = 0; i < keys.length; i++) {
            args += `--reset "${keys[i]}" `
        }
        Quickshell.execDetached(["bash", "-c",
            `python3 '${root.configuratorScriptPath}' --file '${root.shellOverridesPath}' ${args} && hyprctl reload`
        ])
    }

    readonly property string borderActiveKey: "general:col.active_border"
    readonly property string borderInactiveKey: "general:col.inactive_border"

    function toHyprColor(color, opacity) {
        if (opacity === undefined) opacity = 1.0
        const c = Qt.color(color)
        const hex = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0")
        return `rgba(${hex(c.r)}${hex(c.g)}${hex(c.b)}${hex(opacity)})`
    }

    // Custom window border colors & gradients
    function borderColorEntries() {
        const opts = Config.options?.hyprland?.general?.borderColor
        if (WM.compositor !== "hyprland" || !Config.ready || !opts?.enable) return ({})
        let entries = ({})

        // Active border
        const activeC1 = root.toHyprColor(
            Appearance.getColorFromName(opts.activeRole ?? "layer0Border"), opts.activeOpacity ?? 0.47)
        if (opts.activeGradient && opts.activeRoleSecondary) {
            const activeC2 = root.toHyprColor(
                Appearance.getColorFromName(opts.activeRoleSecondary), opts.activeOpacity ?? 0.47)
            const angle = opts.activeAngle ?? 45
            entries[root.borderActiveKey] = `${activeC1} ${activeC2} ${angle}deg`
        } else {
            entries[root.borderActiveKey] = activeC1
        }

        // Inactive border
        const inactiveC1 = root.toHyprColor(
            Appearance.getColorFromName(opts.inactiveRole ?? "layer0Border"), opts.inactiveOpacity ?? 0.2)
        if (opts.inactiveGradient && opts.inactiveRoleSecondary) {
            const inactiveC2 = root.toHyprColor(
                Appearance.getColorFromName(opts.inactiveRoleSecondary), opts.inactiveOpacity ?? 0.2)
            const angle = opts.inactiveAngle ?? 45
            entries[root.borderInactiveKey] = `${inactiveC1} ${inactiveC2} ${angle}deg`
        } else {
            entries[root.borderInactiveKey] = inactiveC1
        }

        return entries
    }

    function applyBorderColors() {
        const entries = root.borderColorEntries()
        if (Object.keys(entries).length > 0) root.setMany(entries)
    }

    function resetBorderColors() {
        if (WM.compositor !== "hyprland") return
        root.resetMany([root.borderActiveKey, root.borderInactiveKey])
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) root.applyBorderColors()
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded()
            }
        }
    }
}
