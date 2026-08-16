import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + 12
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        spacing: 6
        anchors.centerIn: parent

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            shown: Config.options.bar.resources.alwaysShowRam
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: ResourceUsage.swapUsedPercentage > 0 || Config.options.bar.resources.alwaysShowSwap
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || root.alwaysShowAllResources
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "device_thermostat"
            percentage: (ResourceUsage.cpuTemp > 0) ? (ResourceUsage.cpuTemp / 100) : 0
            shown: (Config.options.bar.resources.alwaysShowCpuTemp || root.alwaysShowAllResources) && ResourceUsage.cpuTemp > 0
            warningThreshold: 85
            rawTextOverride: `${Math.round(ResourceUsage.cpuTemp)}°C`
        }

        Resource {
            iconName: "hard_drive"
            percentage: ResourceUsage.diskUsedPercentage || 0.0
            shown: Config.options.bar.resources.alwaysShowDisk
            warningThreshold: Config.options.bar.resources.diskWarningThreshold || 90
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
