import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Attention;
import Toybox.System;

// note to get this to work on the simulator need to modify simulator.json and
// add isTouchable this is already on edge devices with touch, but not the
// venu2s, even though I tested and it worked on the actual device
// AppData\Roaming\Garmin\ConnectIQ\Devices\venu2s\simulator.json
// "datafields": {
// 				"isTouchable": true,
//                 "datafields": [
// note: this only allows taps, cannot handle swipes/holds etc. (need to test on
// real device)
class BreadcrumbDataFieldView extends WatchUi.DataField {
    var _breadcrumbContext as BreadcrumbContext;
    var settings as Settings;
    var _cachedValues as CachedValues;
    var _computeCounter as Number = 0;

    // Set the label of the data field here.
    function initialize(breadcrumbContext as BreadcrumbContext) {
        _breadcrumbContext = breadcrumbContext;
        DataField.initialize();
        settings = _breadcrumbContext.settings;
        _cachedValues = _breadcrumbContext.cachedValues;
    }

    // see onUpdate explanation for when each is called
    function onLayout(dc as Dc) as Void {
        // logE("width: " + dc.getWidth());
        // logE("height: " + dc.getHeight());
        // logE("screen width: " + System.getDeviceSettings().screenWidth.toFloat());
        // logE("screen height: " + System.getDeviceSettings().screenHeight.toFloat());
        try {
            // call parent so screen can be setup correctly or the screen can be slightly offset left/right/up/down.
            // Usually on a physical devices I see an offset to the right and down (leaving a black bar on the left and top), the venu3s simulator shows this.
            // The venu3 simulator is offset left and down, instead of right and down.
            // Sometimes there is no offset though, very confusing.
            // see code at the top of onUpdate, even just calling clear() with a colour does not remove the black bar offsets.
            View.onLayout(dc);
            actualOnLayout(dc);
        } catch (e) {
            logE("failed onLayout: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
        }
    }

    function actualOnLayout(dc as Dc) as Void {
        // logD("onLayout");
        _cachedValues.setScreenSize(dc.getWidth(), dc.getHeight());
    }

    function onWorkoutStarted() as Void {
        _breadcrumbContext.track.onStart();
    }

    function onTimerStart() as Void {
        _breadcrumbContext.track.onStartResume();
    }

    function compute(info as Activity.Info) as Void {
        try {
            actualCompute(info);
        } catch (e) {
            logE("failed compute: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
        }
    }

    // see onUpdate explanation for when each is called
    function actualCompute(info as Activity.Info) as Void {
        _computeCounter++;

        // logD("compute");
        // temp hack for debugging in simulator (since it seems altitude does not work when playing activity data from gpx file)
        // var route = _breadcrumbContext.routes[0];
        // var nextPoint = route.coordinates.getPoint(_breadcrumbContext.track.coordinates.pointSize());
        // if (nextPoint != null)
        // {
        //     info.altitude = nextPoint.altitude;
        // }

        // make sure tile seed or anything else does not stop our computes completely
        var weReallyNeedACompute = _computeCounter > 3 * settings.recalculateIntervalS;
        if (!weReallyNeedACompute) {
            // store rotations and speed every time
            var rescaleOccurred = _cachedValues.onActivityInfo(info);
            if (rescaleOccurred) {
                // rescaling is an expensive operation, if we have multiple large routes rescale and then try and recalculate off track alerts (or anything else expensive)
                // we could hit watchdog errors. Best to not attempt anything else.
                logD("rescale occurred");
                return;
            }
        }

        // slow down the calls to onActivityInfo as its a heavy operation checking
        // the distance we don't really need data much faster than this anyway
        if (_computeCounter < settings.recalculateIntervalS) {
            return;
        }

        _computeCounter = 0;

        var newPoint = _breadcrumbContext.track.pointFromActivityInfo(info);
        if (newPoint != null) {
            if (_cachedValues.currentScale != 0f) {
                newPoint.rescaleInPlace(_cachedValues.currentScale);
            }
            var trackAddRes = _breadcrumbContext.track.onActivityInfo(newPoint);
            var pointAdded = trackAddRes[0];
            var complexOperationHappened = trackAddRes[1];
            if (pointAdded && !complexOperationHappened) {
                _cachedValues.updateScaleCenter();
            }
        }
    }

    // did some testing on real device
    // looks like when we are not on the data page onUpdate is not called, but compute is (as expected)
    // when we are on the data page and it is visible, onUpdate can be called many more times then compute (not just once a second)
    // in some other cases onUpdate is called interleaved with onCompute once a second each (think this might be when its the active screen but not currently renderring)
    // so we need to do all or heavy scaling code in compute, and make onUpdate just handle drawing, and possibly rotation (pre storing rotation could be slow/hard)
    function onUpdate(dc as Dc) as Void {
        // dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        // dc.clear();

        try {
            actualOnUpdate(dc);
        } catch (e) {
            logE("failed onUpdate: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
        }

        // template code for 'complex datafield' has this, but I just get a black screen if I do it (think it's only for when using layouts, but im directly drawing to dc)
        // Call parent's onUpdate(dc) to redraw the layout
        // View.onUpdate(dc);
    }

    function actualOnUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // logD("onUpdate");
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        renderUnbufferedRotating(dc);

        renderer.renderCurrentScale(dc);

        var lastPoint = _breadcrumbContext.track.lastPoint();
        if (lastPoint != null) {
            renderer.renderUser(dc, lastPoint);
        }
    }

    function renderUnbufferedRotating(dc as Dc) as Void {
        var route = _breadcrumbContext.route;
        var track = _breadcrumbContext.track;

        var renderer = _breadcrumbContext.breadcrumbRenderer;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (route != null && settings.routesEnabled) {
            renderer.renderTrack(dc, route, Graphics.COLOR_BLUE, true);
        }
        renderer.renderTrack(dc, track, Graphics.COLOR_GREEN, false);
    }
}
