using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time.Gregorian as Date;

class DexcomFaceWatchView extends WatchUi.WatchFace {
    private var screenWidth;
    private var screenHeight;
    private var heart;
    private var showSeconds = false;
    private var isLowPowerMode = false;
    private var isHidden = false;
    private var heartHeight = 0;
    private var heartWidth = 0;


    function initialize() {
        WatchFace.initialize();
    }

    function onSettingsChanged() {
        showSeconds = Application.Properties.getValue("showSeconds");
    }

    // Load your resources here
    function onLayout(dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();

        var heartResource = WatchUi.loadResource(Rez.Drawables.Heart);
        heartWidth = heartResource.getWidth();
        heartHeight = heartResource.getHeight();
        var angle_deg = 195; // 8:30 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var heartX = screenWidth / 2 + radius * Math.cos(angle_rad);
        var heartY = screenHeight / 2 - radius * Math.sin(angle_rad); // Note the '-' because of the coordinate system

        heart = new WatchUi.AnimationLayer(heartResource, {
            :locX => heartX,
            :locY => heartY,
        });
        addLayer(heart);
    }

    private function drawHeartRateText(dc) {
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

        var heartResource = heart.getResource();

        dc.setColor(
            (heartRate != null && heartRate > 120) ? Graphics.COLOR_DK_RED : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT
        );
        var angle_deg = 195; // 8:30 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 2 - 20; // 20 units away from the edge

        var heartX = screenWidth / 2 + radius * Math.cos(angle_rad);
        var heartY = screenHeight / 2 - radius * Math.sin(angle_rad); 
        var x = heartX + heartWidth + 15;
        var y = heartY + 10;
        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            (heartRate == 0 || heartRate == null) ? "95" : heartRate.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER // Changed to center justify
        );
    }

    function pumpHeart() {
        heart.play(null);
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
        drawBattery(dc);
        drawBluetoothStatus(dc);

        // Draw optional animations
        if (!isLowPowerMode && !isHidden) {
            pumpHeart();
            if (System.getClockTime().sec % 15 == 0) {
            }
        }
    }

    function onPartialUpdate(dc) {
        drawSecondsText(dc, true);
    }

    private function drawHoursMinutes(dc) {
        var clockTime = System.getClockTime();
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

        var x = screenWidth / 2; // Centered horizontally
        var y = screenHeight / 2; // Centered vertically

        // Draw hours
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x - 2,
            y,
            Graphics.FONT_SMALL,
            hoursString,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw the colon (optional)
        dc.drawText(
            x,
            y,
            Graphics.FONT_SMALL,
            ":",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw minutes
        dc.drawText(
            x + 2,
            y,
            Graphics.FONT_SMALL,
            minutesString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw AM/PM (optional)
        dc.drawText(
            x + 18,  // Adjusted for visual placement
            y,
            Graphics.FONT_SMALL,
            am_pm,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }


    private function drawSecondsText(dc, isPartialUpdate) {
        if (!showSeconds || isHidden) {
            return;
        }

        var clockTime = System.getClockTime();
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
            30,
            Graphics.FONT_SMALL,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }


    private function drawBattery(dc) {
        var battery = System.getSystemStats().battery;
        var batteryText = battery.format("%d") + "\u0025";

        var height = 12;
        var width = 18;

        // Coordinates for 2PM
        var angle_deg = 60; // 2 PM on the clock in degrees
        var angle_rad = angle_deg * (Math.PI / 180);
        var radius = screenWidth / 4;

        var x = screenWidth / 2 + radius * Math.cos(angle_rad);
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
        var text_y = y + height / 2; // Align the text vertically centered to the battery rectangle
        dc.drawText(
            text_x,
            text_y,
            Graphics.FONT_XTINY,
            batteryText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Left justify and vertically center
        );
    }
    private function drawBluetoothStatus(dc) {
        var deviceSettings = System.getDeviceSettings();
        var bluetoothState = deviceSettings.connectionInfo[:bluetooth].state;
    
        // Check if connected
        var isConnected = (bluetoothState == 2); // Or use the appropriate enum if available
        
        var statusText = isConnected ? "Connected" : "Disconnected \uF294"; // '\uF294' could be a Bluetooth symbol in some font libraries
        
        // Choose your x, y position for drawing
        var x = 150; // Example: 10 units from the left edge
        var y = 100; // Example: 10 units from the top edge

        // Set text color based on connection status
        dc.setColor(
            isConnected ? Graphics.COLOR_GREEN : Graphics.COLOR_RED,
            Graphics.COLOR_TRANSPARENT
        );

        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            statusText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
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

}
