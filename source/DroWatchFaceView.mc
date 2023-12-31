using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time.Gregorian as Date;

// Import the DataProvider class
using DataProvider;

class DroFaceWatchView extends WatchUi.WatchFace {
    private var screenWidth;
    private var screenHeight;
    private var heartWidth = 0;
    private var stepsImage;
    private var connectedImage;
    private var disconnectedImage;

    private var heartImage;
    private var sunnyImage;
    private var rainyImage;
    private var snowyImage;
    private var cloudyImage;
    private var thunderImage;

    function initialize() {
        WatchFace.initialize();
        stepsImage = Application.loadResource(Rez.Drawables.steps);
        disconnectedImage = Application.loadResource(Rez.Drawables.disconnected);
        connectedImage = Application.loadResource(Rez.Drawables.connected);
        sunnyImage = Application.loadResource(Rez.Drawables.sunny);
        rainyImage = Application.loadResource(Rez.Drawables.rainy);
        snowyImage = Application.loadResource(Rez.Drawables.snowy);
        cloudyImage = Application.loadResource(Rez.Drawables.cloudy);
        thunderImage = Application.loadResource(Rez.Drawables.thunder);
        heartImage = Application.loadResource(Rez.Drawables.heart);
    }

    // Update the view
    function onUpdate(dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw the UI
        drawRing(dc);
        drawHoursMinutes(dc);
        drawDate(dc);
        drawHeartRateText(dc);
        drawBatteryBluetooth(dc);
        drawSteps(dc);
        drawTemperature(dc);
        drawWeather(dc);
    }

    // Load your resources here
    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    private function drawHeartRateText(dc) {
        heartWidth = heartImage.getWidth();
        var angle_deg = 195; // 8:30 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var heartX = screenWidth / 2 + radius * Math.cos(angle_rad) + 10;
        var heartY = screenHeight / 2 - radius * Math.sin(angle_rad) + 10; // Note the '-' because of the coordinate system

        var heartRate = DataProvider.getHeartRate();

        dc.setColor(
            (heartRate != null && heartRate > 120) ? Graphics.COLOR_DK_RED : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        var x = heartX + heartWidth + 23;
        var y = heartY + 20;
        var heartTextOffset = -5;
        if (heartRate != null && heartRate >= 100) {
            heartTextOffset = 0;
        }
        dc.drawBitmap(
            heartX,
            heartY + 10,
            heartImage 
        );
        dc.drawText(
            x + heartTextOffset,
            y,
            Graphics.FONT_TINY,
            (heartRate == 0 || heartRate == null) ? "N/A" : heartRate.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER // Changed to center justify
        );
    }

    private function drawSteps(dc) {
        var steps = DataProvider.getSteps();
        var stepsOffset = 0;
        if (steps != null && steps > 10000.0){
            stepsOffset = -5;
        }
        var stepsInK = steps / 1000.0;
        var formattedSteps = stepsInK.format("%.1f") + "K";

        dc.setColor(
            steps > 10000 ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        var angle_deg = 345; // 2:45 PM, symmetrical to 195 degrees for heart
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) - 65;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 30;

        var imgWidth = stepsImage.getWidth();
        var imgHeight = stepsImage.getHeight();
        // Draw the steps image to the left of the text
        dc.drawBitmap(
            x - imgWidth + stepsOffset, 
            y - imgHeight / 2,
            stepsImage
        );

        dc.drawText(
            x + 25,
            y,
            Graphics.FONT_TINY,
            formattedSteps,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawTemperature(dc) {
        var tempOffset = 0;
        var temperature = DataProvider.getTemperature();
        if (temperature != null && temperature >= 100) {
            tempOffset = 5;
        }
        var tempString = (temperature == null) ? "N/A" : temperature.format("%d");
        var degreeSymbol = (temperature == null) ? "" : "°";

        // Position at 10:30 on the clock
        var angle_deg = 155; // 10:30 in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) + 43;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 10; // Note the '-' because of the coordinate system

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (temperature == null){
            // Draw the temperature number
            dc.drawText(
                x + 5,
                y - 5,
                Graphics.FONT_TINY,
                tempString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
        // Draw the degree symbol, with a manual offset
        if (temperature != null) {
            dc.drawText(
                x,
                y - 5,
                Graphics.FONT_TINY,
                tempString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            var xOffsetDegree = 12;
            var yOffsetDegree = -5;
            dc.drawText(
                x + xOffsetDegree + tempOffset,
                y + yOffsetDegree,
                Graphics.FONT_TINY,
                degreeSymbol,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    private function drawWeather(dc) {
        var weatherCondition = DataProvider.getForecast();

        if (weatherCondition == null) {
            weatherCondition = 0;
        }

        var weatherImage;

        // Assume weatherCondition is a number based on Garmin's API
        switch(weatherCondition) {
            // Clear conditions
            case 0:  // CONDITION_CLEAR
            case 22: // CONDITION_PARTLY_CLEAR
            case 23: // CONDITION_MOSTLY_CLEAR
            case 40: // CONDITION_FAIR
                weatherImage = sunnyImage;
                break;

            // Cloudy conditions
            case 1:  // CONDITION_PARTLY_CLOUDY
            case 2:  // CONDITION_MOSTLY_CLOUDY
            case 20: // CONDITION_CLOUDY
            case 52: // CONDITION_THIN_CLOUDS
                weatherImage = cloudyImage;
                break;

            // Rainy conditions
            case 3:  // CONDITION_RAIN
            case 14: // CONDITION_LIGHT_RAIN
            case 15: // CONDITION_HEAVY_RAIN
            case 25: // CONDITION_SHOWERS
            case 26: // CONDITION_HEAVY_SHOWERS
            case 27: // CONDITION_CHANCE_OF_SHOWERS
            case 45: // CONDITION_CLOUDY_CHANCE_OF_RAIN
                weatherImage = rainyImage;
                break;

            // Snowy conditions
            case 4:  // CONDITION_SNOW
            case 16: // CONDITION_LIGHT_SNOW
            case 17: // CONDITION_HEAVY_SNOW
            case 43: // CONDITION_CHANCE_OF_SNOW
            case 46: // CONDITION_CLOUDY_CHANCE_OF_SNOW
            case 48: // CONDITION_FLURRIES
                weatherImage = snowyImage;
                break;

            // Thunderstorm conditions
            case 6:  // CONDITION_THUNDERSTORMS
            case 12: // CONDITION_SCATTERED_THUNDERSTORMS
            case 28: // CONDITION_CHANCE_OF_THUNDERSTORMS
                weatherImage = thunderImage;
                break;

            // Unhandled cases
            default:
                weatherImage = sunnyImage;
                break;
        }

        var imgHeight = weatherImage.getHeight();

        var angle_deg = 155;
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad); // Adjusted x-coordinate
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 10;

        dc.drawBitmap(
            x,  // Changed from fixed 100 to calculated x
            y - imgHeight / 2 - 5,  // Adjusted y to vertically center the image
            weatherImage
        );
    }

    private function drawHoursMinutes(dc) {
        var clockTime = DataProvider.getCurrentTime();
        var hours = clockTime.hour;
        var am_pm = "AM";

        // Convert to 12-hour format
        if (hours >= 12) {
            am_pm = "PM";
        }
        if (hours > 12) {
            hours -= 12;
        }
        if (hours == 0) {
            hours = 12;
        }

        var hoursString = hours.format("%d");
        var minutesString = clockTime.min.format("%02d");
        var colonString = ":";

        var x = screenWidth / 2; // Centered horizontally
        var y = screenHeight / 2 + 5; // Centered vertically

        var fullTimeString = hoursString + colonString + minutesString + " " + am_pm;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        
        // Draw full time string (hours + colon + minutes + AM/PM) centered
        dc.drawText(
            x,
            y,
            Graphics.FONT_LARGE,
            fullTimeString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawDate(dc) {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day]);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            45,
            Graphics.FONT_SMALL,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }


    private function drawBatteryBluetooth(dc) {
        var battery = DataProvider.getBatteryLevel();
        var add100EdgeCase = 8;
        if (battery == 100) {
            add100EdgeCase = -4;
        }
        var batteryText = battery.format("%d") + "\u0025";

        var bluetoothState = DataProvider.getBluetoothStatus();
        // Check if connected
        var isConnected = (bluetoothState == 2); // Or use the appropriate enum if available
        var bluetoothImg = isConnected ? connectedImage : disconnectedImage; 

        var height = 12;
        var width = 24;

        // Coordinates for 2PM
        var angle_deg = 60; // 2 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 4;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) - 36 + add100EdgeCase;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 10; // Note the '-' because of the coordinate system

        dc.setPenWidth(2);
        dc.setColor(
            battery <= 20 ? Graphics.COLOR_DK_RED : Graphics.COLOR_GREEN,
            Graphics.COLOR_TRANSPARENT
        );
        // Draw the outer rect
        dc.drawRoundedRectangle(
            x,
            y,
            width,
            height,
            2
        );
        // Draw the small + on the right
        dc.drawLine(
            x + width + 1,
            y + 3,
            x + width + 1,
            y + height - 3
        );
        // Fill the rect based on current battery
        dc.fillRectangle(
            x + 1,
            y,
            (width - 2) * battery / 100,
            height
        );

        // Adjust text position
        var text_x = x + width + 5; // Shift text 5 units to the right of the battery rectangle
        var text_y = y + height / 2 - 2; // Align the text vertically centered to the battery rectangle
        dc.drawText(
            text_x,
            text_y,
            Graphics.FONT_TINY,
            batteryText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Left justify and vertically center
        );
        // Draw the bluetooth to the right of the text
        dc.drawBitmap(
            x + 83 - add100EdgeCase, 
            y + height / 2 - 13,
            bluetoothImg
        );
    }

    private function drawRing(dc) {
        var centerX = screenWidth / 2;
        var centerY = screenHeight / 2;
        var radius = screenWidth / 2 - 5; // 5 pixels from the edge
        var startAngle = 0;
        var endAngle = 360;
        var attr = Graphics.ARC_COUNTER_CLOCKWISE;

        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6); // Adjust the thickness of the ring
        dc.drawArc(centerX, centerY, radius, attr, startAngle, endAngle);
    }

     function onHide() as Void {}
     function onExitSleep() as Void {}
     function onEnterSleep() as Void {}
     function onPartialUpdate(dc) {}
     function onShow() as Void {}
     function onSettingsChanged() as Void {}
}
