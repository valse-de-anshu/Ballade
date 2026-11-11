import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property int currentWorkspaceId: monitor?.activeWorkspace?.id ?? HyprlandData.activeWorkspace?.id ?? 1

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property string activeWindowAddress: activeWindow?.HyprlandToplevel?.address ? `0x${activeWindow.HyprlandToplevel.address}` : ""
    readonly property var activeClient: HyprlandData.windowByAddress[activeWindowAddress]
    readonly property bool activeWindowOnThisWorkspace: Boolean(activeClient && activeClient.workspace && activeClient.workspace.id === currentWorkspaceId)

    readonly property bool focusingThisMonitor: Boolean(!HyprlandData.activeWorkspace?.monitor || HyprlandData.activeWorkspace.monitor === monitor?.name)
    readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(currentWorkspaceId)

    implicitWidth: colLayout.implicitWidth

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: {
                if (root.focusingThisMonitor && root.activeWindowOnThisWorkspace && root.activeClient) {
                    return root.activeClient.class || root.activeWindow?.appId || Translation.tr("Desktop");
                }
                if (root.biggestWindow) {
                    return root.biggestWindow.class || Translation.tr("Desktop");
                }
                return Translation.tr("Desktop");
            }
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: {
                if (root.focusingThisMonitor && root.activeWindowOnThisWorkspace && root.activeClient) {
                    return root.activeClient.title || root.activeWindow?.title || `${Translation.tr("Workspace")} ${root.currentWorkspaceId}`;
                }
                if (root.biggestWindow) {
                    return root.biggestWindow.title || `${Translation.tr("Workspace")} ${root.currentWorkspaceId}`;
                }
                return `${Translation.tr("Workspace")} ${root.currentWorkspaceId}`;
            }
        }
    }
}
