pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple Pomodoro time manager.
 */
Singleton {
    id: root

    property int focusTime: Config.options.time.pomodoro.focus
    property int breakTime: Config.options.time.pomodoro.breakTime
    property int longBreakTime: Config.options.time.pomodoro.longBreak
    property int cyclesBeforeLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak

    property bool pomodoroRunning: Persistent.states.timer.pomodoro.running
    property bool pomodoroBreak: Persistent.states.timer.pomodoro.isBreak
    property bool pomodoroLongBreak: Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak);
    property int pomodoroLapDuration: pomodoroLongBreak ? longBreakTime : pomodoroBreak ? breakTime : focusTime // This is a binding that's to be kept
    property int pomodoroSecondsLeft: pomodoroLapDuration // Reasonable init value, to be changed
    property int pomodoroCycle: Persistent.states.timer.pomodoro.cycle

    property bool stopwatchRunning: Persistent.states.timer.stopwatch.running
    property int stopwatchTime: 0
    property int stopwatchStart: Persistent.states.timer.stopwatch.start
    property var stopwatchLaps: Persistent.states.timer.stopwatch.laps

    // General
    Component.onCompleted: {
        if (!stopwatchRunning)
            stopwatchReset();
        if (!Persistent.states.timer.pomodoro.running || !Persistent.states.timer.pomodoro.start || Persistent.states.timer.pomodoro.start <= 0) {
            Persistent.states.timer.pomodoro.running = false;
        } else {
            let elapsed = getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start;
            if (elapsed >= pomodoroLapDuration) {
                resetPomodoro();
            } else {
                refreshPomodoro();
            }
        }
    }

    function getCurrentTimeInSeconds() {  // Pomodoro uses Seconds
        return Math.floor(Date.now() / 1000);
    }

    function getCurrentTimeIn10ms() {  // Stopwatch uses 10ms
        return Math.floor(Date.now() / 10);
    }

    // Pomodoro
    function refreshPomodoro() {
        if (!Persistent.states.timer.pomodoro.running) return;

        let nowSec = getCurrentTimeInSeconds();
        let elapsed = nowSec - Persistent.states.timer.pomodoro.start;

        // Work <-> break ?
        if (elapsed >= pomodoroLapDuration) {
            // Reset counts
            Persistent.states.timer.pomodoro.isBreak = !Persistent.states.timer.pomodoro.isBreak;
            Persistent.states.timer.pomodoro.start = nowSec;

            // Send notification
            let notificationMessage;
            let summaryTitle = "Pomodoro";
            if (Persistent.states.timer.pomodoro.isBreak && (pomodoroCycle + 1 == cyclesBeforeLongBreak)) {
                notificationMessage = Translation.tr(`Long break: %1 minutes`).arg(Math.floor(longBreakTime / 60));
                summaryTitle = "Pomodoro Long Break";
            } else if (Persistent.states.timer.pomodoro.isBreak) {
                notificationMessage = Translation.tr(`Break: %1 minutes`).arg(Math.floor(breakTime / 60));
                summaryTitle = "Pomodoro Break Time";
            } else {
                notificationMessage = Translation.tr(`Focus: %1 minutes`).arg(Math.floor(focusTime / 60));
                summaryTitle = "Pomodoro Focus Time";
            }

            Quickshell.execDetached(["notify-send", summaryTitle, notificationMessage, "-a", "Pomodoro"]);
            if (Config.options.sounds.pomodoro ?? true) {
                let isBreakStart = Persistent.states.timer.pomodoro.isBreak;
                root.playPomodoroAudio(isBreakStart ? "break" : "focus");
            }

            if (!pomodoroBreak) {
                Persistent.states.timer.pomodoro.cycle = (Persistent.states.timer.pomodoro.cycle + 1) % root.cyclesBeforeLongBreak;
            }
            elapsed = 0;
        }

        pomodoroSecondsLeft = Math.max(0, pomodoroLapDuration - elapsed);
    }

    function playPomodoroAudio(soundType = "break") {
        let customPath = Config.options.sounds.pomodoroSoundPath || Config.options.sounds.alarmSoundPath || ""
        let vol = Math.max(0, Math.min(100, Config.options.sounds.pomodoroVolume ?? Config.options.sounds.alarmVolume ?? 80))
        let fallback = soundType === "focus" 
            ? "/usr/share/sounds/freedesktop/stereo/bell.oga" 
            : "/usr/share/sounds/freedesktop/stereo/complete.oga"

        Quickshell.execDetached([
            "bash",
            Directories.scriptPath + "/play-audio.sh",
            "--file", customPath,
            "--volume", vol.toString(),
            "--fallback", fallback,
            "--category", "pomodoro"
        ]);
    }

    Timer {
        id: pomodoroTimer
        interval: 200
        running: root.pomodoroRunning
        repeat: true
        onTriggered: refreshPomodoro()
    }

    function togglePomodoro() {
        let willRun = !Persistent.states.timer.pomodoro.running;
        Persistent.states.timer.pomodoro.running = willRun;
        if (willRun) {
            // Start/Resume
            let remaining = (pomodoroSecondsLeft > 0 && pomodoroSecondsLeft <= pomodoroLapDuration) ? pomodoroSecondsLeft : pomodoroLapDuration;
            Persistent.states.timer.pomodoro.start = getCurrentTimeInSeconds() - (pomodoroLapDuration - remaining);
            refreshPomodoro();
        } else {
            let elapsed = getCurrentTimeInSeconds() - Persistent.states.timer.pomodoro.start;
            pomodoroSecondsLeft = Math.max(0, pomodoroLapDuration - elapsed);
        }
    }

    function resetPomodoro() {
        Persistent.states.timer.pomodoro.running = false;
        Persistent.states.timer.pomodoro.isBreak = false;
        Persistent.states.timer.pomodoro.start = 0;
        Persistent.states.timer.pomodoro.cycle = 0;
        pomodoroSecondsLeft = root.focusTime;
    }

    // Stopwatch
    function refreshStopwatch() {  // Stopwatch stores time in 10ms
        stopwatchTime = getCurrentTimeIn10ms() - stopwatchStart;
    }

    Timer {
        id: stopwatchTimer
        interval: 10
        running: root.stopwatchRunning
        repeat: true
        onTriggered: refreshStopwatch()
    }

    function toggleStopwatch() {
        if (root.stopwatchRunning)
            stopwatchPause();
        else
            stopwatchResume();
    }

    function stopwatchPause() {
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchResume() {
        if (stopwatchTime === 0) Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = true;
        Persistent.states.timer.stopwatch.start = getCurrentTimeIn10ms() - stopwatchTime;
    }

    function stopwatchReset() {
        stopwatchTime = 0;
        Persistent.states.timer.stopwatch.laps = [];
        Persistent.states.timer.stopwatch.running = false;
    }

    function stopwatchRecordLap() {
        Persistent.states.timer.stopwatch.laps.push(stopwatchTime);
    }
}
