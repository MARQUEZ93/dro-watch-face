import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class DroWatchFaceApp extends Application.AppBase {
    private var view;
    private var stepsImage;

    function initialize() {
        AppBase.initialize();
    }

    function onSettingsChanged() {
        view.onSettingsChanged();
        WatchUi.requestUpdate();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        view = new DroFaceWatchView();
        onSettingsChanged();
        return [ view ] as Array<Views or InputDelegates>;
    }

}

function getApp() as DroWatchFaceApp {
    return Application.getApp() as DroWatchFaceApp;
}
