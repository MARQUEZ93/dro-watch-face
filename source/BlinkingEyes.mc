using Toybox.Timer;

class BlinkingEyes {
    private var dc;
    private var blinkCount = 0;
    private var blinkingTimer;

    function initialize(_dc) {
        dc = _dc;
        blinkCount = 0;
    }

    function blink() {
    }

    function stop() {
        blinkCount = 0;
        if (blinkingTimer) {
          blinkingTimer.stop();
        }
    }
}
