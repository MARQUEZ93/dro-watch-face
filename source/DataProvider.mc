using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Time.Gregorian as Date;
using Toybox.Time as Time;
using Toybox.Weather as Weather;
using Toybox.WatchUi;

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
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            var tempCelsius = conditions.temperature;
            var tempFahrenheit = (tempCelsius * 9/5) + 32;
            return tempFahrenheit;
        }
        return null; 
    }

    function getForecast() {
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            return conditions.condition;
        }
        return null; 
    }

    function isNightAndNoPrecipitation() {
        // Reusing the getCurrentTime() function to get the current time
        var currentTime = getCurrentTime();
        
        // Reusing the getForecast() function to get the weather forecast
        var forecast = getForecast();
        
        // Getting current weather conditions to retrieve sunset and sunrise times
        var conditions = Weather.getCurrentConditions();
        
        if (conditions != null && currentTime != null && forecast != null) {
            // Check for sunset and sunrise time
            var sunsetTime = conditions.sunsetTime;
            var sunriseTime = conditions.sunriseTime;
            
            // Determine if it's night
            var isNight = currentTime < sunriseTime || currentTime > sunsetTime;
            
            // Determine if there's no precipitation using the forecast
            var noPrecipitation = true;
            
            switch (forecast) {
                case 3:  // CONDITION_RAIN
                case 14: // CONDITION_LIGHT_RAIN
                case 15: // CONDITION_HEAVY_RAIN
                case 25: // CONDITION_SHOWERS
                case 26: // CONDITION_HEAVY_SHOWERS
                case 27: // CONDITION_CHANCE_OF_SHOWERS
                case 45: // CONDITION_CLOUDY_CHANCE_OF_RAIN
                    noPrecipitation = false;
                    break;
                default:
                    noPrecipitation = true;
            }
            
            return isNight && noPrecipitation;
        }
        
        return null; // Could not determine the conditions
    }
    // Function to check if any timer is on
    function isTimerOn() {
        var timers = WatchUi.getTimers(); // Hypothetical method, consult SDK
        foreach (var timer in timers) {
            if (timer.state == WatchUi.TimerState.RUNNING) { // Hypothetical enum, consult SDK
                return true;
            }
        }
        return false;
    }

    // Function to check if a stopwatch is on
    function isStopwatchOn() {
        var stopwatchState = WatchUi.getStopwatchState(); // Hypothetical method, consult SDK
        return (stopwatchState == WatchUi.StopwatchState.RUNNING); // Hypothetical enum, consult SDK
    }

    // Function to get the remaining time on the timer
    function getTimerTime() {
        var timers = WatchUi.getTimers(); // Hypothetical method, consult SDK
        foreach (var timer in timers) {
            if (timer.state == WatchUi.TimerState.RUNNING) { // Hypothetical enum, consult SDK
                return timer.remainingTime; // Hypothetical attribute, consult SDK
            }
        }
        return null;
    }

    // Function to get the elapsed time on the stopwatch
    function getStopwatchTime() {
        if (isStopwatchOn()) {
            var stopwatchTime = WatchUi.getStopwatchTime(); // Hypothetical method, consult SDK
            return stopwatchTime;
        }
        return null;
    }
}
