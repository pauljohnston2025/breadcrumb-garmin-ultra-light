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
    var offTrackInfo as OffTrackInfo = new OffTrackInfo(true, null, false);
    var _breadcrumbContext as BreadcrumbContext;
    var settings as Settings;
    var _cachedValues as CachedValues;
    var lastOffTrackAlertNotified as Number = 0;
    var lastOffTrackAlertChecked as Number = 0;
    var _computeCounter as Number = 0;

    // Set the label of the data field here.
    function initialize(breadcrumbContext as BreadcrumbContext) {
        _breadcrumbContext = breadcrumbContext;
        DataField.initialize();
        settings = _breadcrumbContext.settings;
        _cachedValues = _breadcrumbContext.cachedValues;
    }

    function rescale(scaleFactor as Float) as Void {
        var pointWeLeftTrack = offTrackInfo.pointWeLeftTrack;
        if (pointWeLeftTrack != null) {
            pointWeLeftTrack.rescaleInPlace(scaleFactor);
        }
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
        var textDim = dc.getTextDimensions("1234", Graphics.FONT_XTINY);
        _breadcrumbContext.breadcrumbRenderer.setElevationAndUiData(textDim[0] * 1.0f);
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

    function showMyAlert(alert as String) as Void {
        try {
            if (Attention has :backlight) {
                // turn the screen on so we can see the alert, it does not respond to us gesturing to see the alert (think gesture controls are suppressed during vibration)
                Attention.backlight(true);
            }

            if (Attention has :vibrate) {
                var vibeData = [
                    new Attention.VibeProfile(100, 500),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(100, 500),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(100, 500),
                ];
                Attention.vibrate(vibeData);
            }

            WatchUi.showToast(alert, {});
        } catch (e) {
            logE("failed to show alert: " + e.getErrorMessage());
        }
    }

    function showMyTrackAlert(epoch as Number, alert as String) as Void {
        lastOffTrackAlertNotified = epoch; // if showAlert fails, we will still have vibrated and turned the screen on
        showMyAlert(alert);
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

        var settings = _breadcrumbContext.settings;
        var newPoint = _breadcrumbContext.track.pointFromActivityInfo(info);
        if (newPoint != null) {
            if (_cachedValues.currentScale != 0f) {
                newPoint.rescaleInPlace(_cachedValues.currentScale);
            }
            var trackAddRes = _breadcrumbContext.track.onActivityInfo(newPoint);
            var pointAdded = trackAddRes[0];
            var complexOperationHappened = trackAddRes[1];
            if (pointAdded && !complexOperationHappened) {
                // todo: PERF only update this if the new point added changed the bounding box
                // its pretty good atm though, only recalculates once every few seconds, and only
                // if a point is added
                _cachedValues.updateScaleCenter();
                var epoch = Time.now().value();
                if (epoch - settings.offTrackCheckIntervalS < lastOffTrackAlertChecked) {
                    return;
                }

                // Do not check again for this long, prevents the expensive off track calculation running constantly whilst we are on track.
                lastOffTrackAlertChecked = epoch;

                var lastPoint = _breadcrumbContext.track.lastPoint();
                if (lastPoint != null) {
                    if (
                        settings.enableOffTrackAlerts ||
                        settings.drawLineToClosestPoint ||
                        settings.offTrackWrongDirection ||
                        settings.drawCheverons
                    ) {
                        handleOffTrackAlerts(epoch, lastPoint);
                    }

                    if (settings.turnAlertTimeS >= 0 || settings.minTurnAlertDistanceM >= 0) {
                        handleDirections(lastPoint);
                    }
                }
            }
        }
    }

    // new point is already pre scaled
    function handleDirections(newPoint as RectangularPoint) as Void {
        var route = _breadcrumbContext.route;
        if (route != null) {
            var res = route.checkDirections(
                newPoint,
                settings.turnAlertTimeS,
                settings.minTurnAlertDistanceM,
                _cachedValues
            );

            if (res != null) {
                var direction = res[0];
                var distanceM = res[1];

                var dirText = direction >= 0 ? "Right" : "Left";
                var distanceText = "";

                if (settings.distanceImperialUnits) {
                    var distanceFt = distanceM * 3.28084;
                    distanceText = distanceFt.format("%.0f") + "ft";
                } else {
                    distanceText = distanceM.format("%.0f") + "m";
                }
                showMyAlert(dirText + " Turn In " + distanceText + " " + absN(direction) + "°");
            }
        }
    }

    // new point is already pre scaled
    function handleOffTrackAlerts(epoch as Number, newPoint as RectangularPoint) as Void {
        var atLeastOneEnabled = false;
        var route = _breadcrumbContext.route;
        if (route != null) {
            atLeastOneEnabled = true;
            var routeOffTrackInfo = route.checkOffTrack(
                newPoint,
                settings.offTrackAlertsDistanceM * _cachedValues.currentScale
            );

            if (routeOffTrackInfo.onTrack) {
                offTrackInfo = routeOffTrackInfo.clone(); // never store the point we got or rescales could occur twice on the same object
                if (settings.offTrackWrongDirection && offTrackInfo.wrongDirection) {
                    showMyTrackAlert(epoch, "WRONG DIRECTION");
                }

                return;
            }

            var pointWeLeftTrack = offTrackInfo.pointWeLeftTrack;
            var routePointWeLeftTrack = routeOffTrackInfo.pointWeLeftTrack;
            if (
                routePointWeLeftTrack != null &&
                (pointWeLeftTrack == null ||
                    pointWeLeftTrack.distanceTo(newPoint) >
                        routePointWeLeftTrack.distanceTo(newPoint))
            ) {
                offTrackInfo = routeOffTrackInfo.clone(); // never store the point we got or rescales could occur twice on the same object
            }
        }

        if (!atLeastOneEnabled) {
            // no routes are enabled - pretend we are ontrack
            offTrackInfo.onTrack = true;
            return;
        }

        offTrackInfo.onTrack = false; // use the last pointWeLeftTrack from when we were on track

        // do not trigger alerts often
        if (epoch - settings.offTrackAlertsMaxReportIntervalS < lastOffTrackAlertNotified) {
            return;
        }

        if (settings.enableOffTrackAlerts) {
            showMyTrackAlert(epoch, "OFF TRACK");
        }
    }

    function onSettingsChanged() as Void {
        // they could have turned off off track alerts, changed the distance of anything, so let it all recalculate
        // or modified routes
        lastOffTrackAlertNotified = 0;
        lastOffTrackAlertChecked = 0;
        offTrackInfo = new OffTrackInfo(true, null, false);
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
        if (renderer.renderClearTrackUi(dc)) {
            return;
        }

        // mode should be stored here, but is needed for rendering the ui
        // should structure this way better, but oh well (renderer per mode etc.)
        if (settings.mode == MODE_ELEVATION) {
            renderElevationStacked(dc);
            if (_breadcrumbContext.settings.uiMode == UI_MODE_SHOW_ALL) {
                renderer.renderUi(dc);
            }
            return;
        }

        if (settings.renderMode == RENDER_MODE_UNBUFFERED_ROTATING) {
            renderUnbufferedRotating(dc);
        } else {
            var track = _breadcrumbContext.track;
            rederUnrotated(dc, _breadcrumbContext.route, track);
        }

        // move based on the last scale we drew
        if (_breadcrumbContext.settings.uiMode == UI_MODE_SHOW_ALL) {
            renderer.renderUi(dc);
        }

        renderer.renderCurrentScale(dc);

        var lastPoint = _breadcrumbContext.track.lastPoint();
        if (lastPoint != null) {
            renderer.renderUser(dc, lastPoint);
        }
    }

    (:noUnbufferedRotations)
    function renderUnbufferedRotating(dc as Dc) as Void {}

    (:unbufferedRotations)
    function renderUnbufferedRotating(dc as Dc) as Void {
        var route = _breadcrumbContext.route;
        var track = _breadcrumbContext.track;

        var renderer = _breadcrumbContext.breadcrumbRenderer;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (route != null) {
            renderer.renderTrack(dc, route, Graphics.COLOR_BLUE, true);
            if (settings.drawCheverons) {
                renderer.renderTrackCheverons(dc, route, Graphics.COLOR_BLUE);
            }
        }
        renderer.renderTrack(dc, track, Graphics.COLOR_GREEN, false);
        renderOffTrackPoint(dc);
    }

    function rederUnrotated(dc as Dc, route as BreadcrumbTrack?, track as BreadcrumbTrack) as Void {
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (route != null) {
            renderer.renderTrackUnrotated(dc, route, Graphics.COLOR_BLUE, true);
            if (settings.drawCheverons) {
                renderer.renderTrackCheveronsUnrotated(dc, route, Graphics.COLOR_BLUE);
            }
        }
        renderer.renderTrackUnrotated(dc, track, Graphics.COLOR_GREEN, false);

        renderOffTrackPointUnrotated(dc);
    }

    (:noUnbufferedRotations)
    function renderOffTrackPoint(dc as Dc) as Void {}

    (:unbufferedRotations)
    function renderOffTrackPoint(dc as Dc) as Void {
        var lastPoint = _breadcrumbContext.track.lastPoint();
        var renderer = _breadcrumbContext.breadcrumbRenderer;
        var pointWeLeftTrack = offTrackInfo.pointWeLeftTrack;
        if (lastPoint != null) {
            // only ever not null if feature enabled
            if (
                !offTrackInfo.onTrack &&
                pointWeLeftTrack != null &&
                settings.drawLineToClosestPoint
            ) {
                // points need to be scaled and rotated :(
                renderer.renderLineFromLastPointToRoute(
                    dc,
                    lastPoint,
                    pointWeLeftTrack,
                    Graphics.COLOR_RED
                );
            }
        }
    }

    function renderOffTrackPointUnrotated(dc as Dc) as Void {
        var lastPoint = _breadcrumbContext.track.lastPoint();
        var renderer = _breadcrumbContext.breadcrumbRenderer;
        var pointWeLeftTrack = offTrackInfo.pointWeLeftTrack;
        if (lastPoint != null) {
            // only ever not null if feature enabled

            if (
                !offTrackInfo.onTrack &&
                pointWeLeftTrack != null &&
                settings.drawLineToClosestPoint
            ) {
                // points need to be scaled and rotated :(
                renderer.renderLineFromLastPointToRouteUnrotated(
                    dc,
                    lastPoint,
                    pointWeLeftTrack,
                    Graphics.COLOR_RED
                );
            }
        }
    }

    function renderElevationStacked(dc as Dc) as Void {
        var route = _breadcrumbContext.route;
        var track = _breadcrumbContext.track;
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        var elevationScale = renderer.getElevationScale(track, route);
        var hScale = elevationScale[0];
        var vScale = elevationScale[1];
        var startAt = elevationScale[2];
        var hScalePPM = elevationScale[3];

        var lastPoint = track.lastPoint();
        var elevationText = "";

        if (lastPoint == null) {
            elevationText = "";
        } else {
            if (settings.elevationImperialUnits) {
                var elevationFt = lastPoint.altitude * 3.28084;
                elevationText = elevationFt.format("%.0f") + "ft";
            } else {
                elevationText = lastPoint.altitude.format("%.0f") + "m";
            }
        }

        renderer.renderElevationChart(
            dc,
            hScalePPM,
            vScale,
            startAt,
            track.distanceTotal,
            elevationText
        );
        if (route != null) {
            renderer.renderTrackElevation(
                dc,
                renderer._xElevationStart,
                route,
                Graphics.COLOR_BLUE,
                hScale,
                vScale,
                startAt
            );
        }
        renderer.renderTrackElevation(
            dc,
            renderer._xElevationStart,
            track,
            Graphics.COLOR_GREEN,
            hScale,
            vScale,
            startAt
        );
    }
}
