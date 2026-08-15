import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            shown: Config.options.bar.resources.alwaysShowRam
            
            property string rawTextOverride: `${ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)} / ${ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)}`
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: Config.options.bar.resources.alwaysShowSwap && percentage > 0
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
            
            property string rawTextOverride: `${ResourceUsage.kbToGbString(ResourceUsage.swapUsed)} / ${ResourceUsage.kbToGbString(ResourceUsage.swapTotal)}`
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            
            property string rawTextOverride: `${Math.round(ResourceUsage.cpuUsage * 100).toString()}%`
        }

        Resource {
            iconName: "device_thermostat"
            percentage: (ResourceUsage.cpuTemp > 0) ? (ResourceUsage.cpuTemp / 100) : 0
            shown: Config.options.bar.resources.alwaysShowCpuTemp && ResourceUsage.cpuTemp > 0
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 85
            
            property string rawTextOverride: `${Math.round(ResourceUsage.cpuTemp)}°C`
        }

        Resource {
            iconName: "hard_drive"
            percentage: ResourceUsage.diskUsedPercentage || 0.0
            shown: Config.options.bar.resources.alwaysShowDisk
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.diskWarningThreshold || 90
            
            property string rawTextOverride: `${ResourceUsage.kbToGbString(ResourceUsage.diskUsed)} / ${ResourceUsage.kbToGbString(ResourceUsage.diskTotal)}`
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
