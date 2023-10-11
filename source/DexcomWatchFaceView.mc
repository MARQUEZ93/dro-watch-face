using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time.Gregorian as Date;

// Import the DataProvider class
using DataProvider;

class DexcomFaceWatchView extends WatchUi.WatchFace {
    private var screenWidth;
    private var screenHeight;
    private var heart;
    private var showSeconds = false;
    private var isLowPowerMode = false;
    private var isHidden = false;
    private var heartHeight = 0;
    private var heartWidth = 0;
    private var stepsImage;
    private var connectedImage;
    private var disconnectedImage;

    private var heartImage;
    private var sunnyImage;
    private var rainyImage;
    private var snowyImage;
    private var nightImage;
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
        nightImage = Application.loadResource(Rez.Drawables.night);
        cloudyImage = Application.loadResource(Rez.Drawables.cloudy);
        thunderImage = Application.loadResource(Rez.Drawables.thunder);
        heartImage = Application.loadResource(Rez.Drawables.heart);
    }

    function onSettingsChanged() {
        showSeconds = Application.Properties.getValue("showSeconds");
    }

    // Load your resources here
    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    private function drawHeartRateText(dc) {
        heartWidth = heartImage.getWidth();
        heartHeight = heartImage.getHeight();
        var angle_deg = 195; // 8:30 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var heartX = screenWidth / 2 + radius * Math.cos(angle_rad);
        var heartY = screenHeight / 2 - radius * Math.sin(angle_rad); // Note the '-' because of the coordinate system

        var heartRate = DataProvider.getHeartRate();

        dc.setColor(
            (heartRate != null && heartRate > 120) ? Graphics.COLOR_DK_RED : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        var x = heartX + heartWidth + 18;
        var y = heartY + 10;
         dc.drawBitmap(
            heartX,
            heartY,
            heartImage 
        );
        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            (heartRate == 0 || heartRate == null) ? "195" : heartRate.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER // Changed to center justify
        );
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        isHidden = false;
    }

    // Update the view
    function onUpdate(dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw the UI
        drawRing(dc);
        drawHoursMinutes(dc);
        // drawSecondsText(dc, false);
        drawDate(dc);
        drawHeartRateText(dc);
        drawBatteryBluetooth(dc);
        drawSteps(dc);
        drawTemperature(dc);
        drawWeather(dc);

    }

    function onPartialUpdate(dc) {
        drawSecondsText(dc, true);
    }

    private function drawSteps(dc) {
        var steps = DataProvider.getSteps();
        var stepsInK = steps / 1000.0;
        var formattedSteps = stepsInK.format("%.1f") + "K";

        dc.setColor(
            steps > 10000 ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );

        var angle_deg = 345; // 2:45 PM, symmetrical to 195 degrees for heart
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) - 40;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 10;

        var imgWidth = stepsImage.getWidth();
        var imgHeight = stepsImage.getHeight();
        // Draw the image to the left of the text
        dc.drawBitmap(
            x - imgWidth + 5, 
            y - imgHeight / 2,
            stepsImage
        );

        dc.drawText(
            x + 25,
            y,
            Graphics.FONT_XTINY,
            formattedSteps,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawTemperature(dc) {
        var temperature = DataProvider.getTemperature();
        var tempString = (temperature == null) ? "N/A" : temperature.format("%d");
        var degreeSymbol = (temperature == null) ? "" : "°";

        // Position at 10:30 on the clock
        var angle_deg = 155; // 10:30 in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) + 45;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad); // Note the '-' because of the coordinate system

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (temperature == null){
            // Draw the temperature number
            dc.drawText(
                x,
                y,
                Graphics.FONT_XTINY,
                tempString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Draw the degree symbol, with a manual offset
        if (temperature != null) {
            dc.drawText(
                x,
                y - 5,
                Graphics.FONT_SMALL,
                tempString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            var xOffsetDegree = 12;
            var yOffsetDegree = -5;
            dc.drawText(
                x + xOffsetDegree,
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
            return;
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

            // Night conditions (This is tricky since "Night" is a time rather than a weather condition)
            // For now, no mapping.

            // Unhandled cases
            default:
                weatherImage = sunnyImage;
                break;
        }

        var imgWidth = weatherImage.getWidth();
        var imgHeight = weatherImage.getHeight();

        var angle_deg = 155;
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad); // Adjusted x-coordinate
        var y = screenHeight / 2 - radius * Math.sin(angle_rad);

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
        var y = screenHeight / 2 - 10; // Centered vertically

        var fullTimeString = hoursString + colonString + minutesString + " " + am_pm;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        
        // Draw full time string (hours + colon + minutes + AM/PM) centered
        dc.drawText(
            x,
            y,
            Graphics.FONT_MEDIUM,
            fullTimeString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }


    private function drawSecondsText(dc, isPartialUpdate) {
        if (!showSeconds || isHidden) {
            return;
        }

        var clockTime = DataProvider.getCurrentTime();
        var minutes = clockTime.min.format("%02d");
        var seconds = clockTime.sec.format("%02d");

        var minutesWidth = 48; // dc.getTextWidthInPixels(minutes, minutesFont)
        var x = screenWidth / 2 + 2 + minutesWidth + 5; // Margin right 5px
        var y = screenHeight - 20 - 2; // Visual adjustment 2px

        if (isPartialUpdate) {
            dc.setClip(
                x,
                y + 5, // Adjust for text justification 5px
                18, // dc.getTextWidthInPixels(seconds, dateFont)
                15 // Fixed height 15px
            );
            // Use the background color to force repaint the clip
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.clear();
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }

        dc.drawText(
            x,
            y,
            Graphics.FONT_SMALL,
            seconds,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    private function drawDate(dc) {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day]);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            35,
            Graphics.FONT_SMALL,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }


    private function drawBatteryBluetooth(dc) {
        var battery = DataProvider.getBatteryLevel();
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

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) - 15;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad); // Note the '-' because of the coordinate system

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
            Graphics.FONT_XTINY,
            batteryText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Left justify and vertically center
        );
        // Draw the bluetooth to the right of the text
        dc.drawBitmap(
            x + 60, 
            y + height / 2 - 13,
            bluetoothImg
        );
    }
    private function drawBluetooth(dc) {
        var bluetoothState = DataProvider.getBluetoothStatus();
    
        // Check if connected
        var isConnected = (bluetoothState == 2); // Or use the appropriate enum if available
        
        // Choose your x, y position for drawing
        var angle_deg = 25; // 2:45 PM, symmetrical to 195 degrees for heart
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad) - 60;
        var y = screenHeight / 2 - radius * Math.sin(angle_rad) + 10;

        // Set text color based on connection status
        dc.setColor(
            isConnected ? Graphics.COLOR_BLUE : Graphics.COLOR_RED,
            Graphics.COLOR_TRANSPARENT
        );
        var bluetoothImg = isConnected ? connectedImage : disconnectedImage; 
        var imgWidth = bluetoothImg.getWidth();
        var imgHeight = bluetoothImg.getHeight();

        // Draw the image to the left of the text
        dc.drawBitmap(
            x + 20, 
            y - imgHeight / 2 + 8,
            bluetoothImg
        );
    }
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        isHidden = true;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isLowPowerMode = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isLowPowerMode = true;
        heart.stop();
    }

    private function drawRing(dc) {
        var centerX = screenWidth / 2;
        var centerY = screenHeight / 2;
        var radius = screenWidth / 2 - 5; // 5 pixels from the edge
        var startAngle = 0;
        var endAngle = 360;
        var attr = Graphics.ARC_COUNTER_CLOCKWISE;

        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4); // Adjust the thickness of the ring
        dc.drawArc(centerX, centerY, radius, attr, startAngle, endAngle);
    }

}
