pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    property var clock: SystemClock {
        id: clock
        precision: {
            if (Config.options.time.secondPrecision || GlobalStates.screenLocked)
                return SystemClock.Seconds;
            return SystemClock.Minutes;
        }
    }
    property string time: Qt.locale().toString(clock.date, Config.options?.time.format ?? "hh:mm")
    readonly property bool is12Hour: {
        const fmt = (Config.options?.time?.format ?? "").toLowerCase();
        return fmt.includes("ap") || fmt.includes("a") || (fmt.includes("h") && !fmt.includes("hh"));
    }
    readonly property string ampm: Qt.locale().toString(clock.date, (Config.options?.time?.format ?? "").includes("ap") ? "ap" : "AP")
    readonly property string hoursStr: {
        if (is12Hour) {
            const h = clock.date.getHours() % 12 || 12;
            return String(h).padStart(2, "0");
        }
        return Qt.locale().toString(clock.date, "hh").padStart(2, "0");
    }
    readonly property string minutesStr: Qt.locale().toString(clock.date, "mm").padStart(2, "0")
    readonly property string digitH0: hoursStr.charAt(0) || "0"
    readonly property string digitH1: hoursStr.charAt(1) || "0"
    readonly property string digitM0: minutesStr.charAt(0) || "0"
    readonly property string digitM1: minutesStr.charAt(1) || "0"
    property string shortDate: Qt.locale().toString(clock.date, Config.options?.time.shortDateFormat ?? "dd/MM")
    property string date: Qt.locale().toString(clock.date, Config.options?.time.dateWithYearFormat ?? "dd/MM/yyyy")
    property string longDate: Qt.locale().toString(clock.date, Config.options?.time.dateFormat ?? "dddd, dd/MM")
    property string collapsedCalendarFormat: Qt.locale().toString(clock.date, "dddd, MMMM dd")
    property string uptime: "0h, 0m"

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload();
            const textUptime = fileUptime.text();
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0);

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400);
            const hours = Math.floor((uptimeSeconds % 86400) / 3600);
            const minutes = Math.floor((uptimeSeconds % 3600) / 60);

            // Build the formatted uptime string
            let formatted = "";
            if (days > 0)
                formatted += `${days}d`;
            if (hours > 0)
                formatted += `${formatted ? ", " : ""}${hours}h`;
            if (minutes > 0 || !formatted)
                formatted += `${formatted ? ", " : ""}${minutes}m`;
            uptime = formatted;
            interval = Config.options?.resources?.updateInterval ?? 3000;
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }
}
