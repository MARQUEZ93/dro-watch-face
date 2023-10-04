using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Time.Gregorian as Date;
using Toybox.Time as Time;

module DataProvider {
    function getHeartRate() {
        var heartRate = 0;
        var info = Activity.getActivityInfo();
        if (info != null) {
            heartRate = info.currentHeartRate;
        } else {
            var latestHeartRateSample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (latestHeartRateSample != null) {
                heartRate = latestHeartRateSample.heartRate;
            }
        }
        return heartRate;
    }

    function getSteps() {
        var info = ActivityMonitor.getInfo();
        var steps = 0;
        if (info != null && info.steps != null) {
            steps = info.steps;
        }
        return steps;
    }

    function getBatteryLevel() {
        return System.getSystemStats().battery;
    }

    function getBluetoothStatus() {
        var deviceSettings = System.getDeviceSettings();
        return deviceSettings.connectionInfo[:bluetooth].state;
    }

    function getCurrentTime() {
        return System.getClockTime();
    }

    function getCurrentDate() {
        return Date.info(Time.now(), Time.FORMAT_MEDIUM);
    }

    function getTemperature() {
        // You'll have to implement this with your specific logic
        // For now, returning a dummy value
        return 20;
    }
}
