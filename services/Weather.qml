pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: "--",
        sunrise: "--",
        sunset: "--",
        windDir: "N",
        wCode: "113",
        city: "--",
        region: "",
        country: "",
        lat: 0,
        lon: 0,
        description: "",
        wind: "--",
        precip: "--",
        visib: "--",
        press: "--",
        temp: "--°",
        tempFeelsLike: "--°",
        cr: "--",
        cloudcover: 0,
        lastRefresh: "--",
    })

    function refineData(data) {
        if (!data || !data.current) return;
        let temp = {};
        temp.uv = data?.current?.uvIndex || 0;
        temp.humidity = (data?.current?.humidity || 0) + "%";
        temp.sunrise = data?.astronomy?.sunrise || "--";
        temp.sunset = data?.astronomy?.sunset || "--";
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName ? (data.location.areaName[0]?.value || "City") : "City";
        temp.region = data?.location?.region ? (data.location.region[0]?.value || "") : "";
        temp.country = data?.location?.country ? (data.location.country[0]?.value || "") : "";
        temp.lat = parseFloat(data?.location?.latitude) || 0;
        temp.lon = parseFloat(data?.location?.longitude) || 0;
        temp.description = data?.current?.weatherDesc ? (data.current.weatherDesc[0]?.value || "") : "";
        temp.cloudcover = data?.current?.cloudcover || 0;
        if (root.useUSCS) {
            temp.wind = (data?.current?.windspeedMiles || 0) + " mph";
            temp.precip = (data?.current?.precipInches || 0) + " in";
            temp.visib = (data?.current?.visibilityMiles || 0) + " mi";
            temp.press = (data?.current?.pressureInches || 0) + " psi";
            temp.cr = (data?.current?.precipInches || 0) + " in";
            temp.temp = (data?.current?.temp_F || 0) + "°F";
            temp.tempFeelsLike = (data?.current?.FeelsLikeF || 0) + "°F";
        } else {
            temp.wind = (data?.current?.windspeedKmph || 0) + " km/h";
            temp.precip = (data?.current?.precipMM || 0) + " mm";
            temp.visib = (data?.current?.visibility || 0) + " km";
            temp.press = (data?.current?.pressure || 0) + " hPa";
            temp.cr = (data?.current?.precipMM || 0) + " mm";
            temp.temp = (data?.current?.temp_C || 0) + "°C";
            temp.tempFeelsLike = (data?.current?.FeelsLikeC || 0) + "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        let command = "curl -s wttr.in";

        if (root.city && root.city.trim().length > 0) {
            command += `/${formatCityName(root.city)}`;
        } else if (root.gpsActive && root.location.valid) {
            command += `/${root.location.lat},${root.location.long}`;
        }

        // format as json
        command += "?format=j1";
        command += " | ";
        // only take the current weather, location, astronomy data
        command += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    Component.onCompleted: {
        if (root.gpsActive) {
            console.info("[WeatherService] Starting the GPS service.");
            positionSource.start();
        } else {
            root.getData();
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                    // console.info(`[ data: ${JSON.stringify(parsedData)}`);
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.long = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
