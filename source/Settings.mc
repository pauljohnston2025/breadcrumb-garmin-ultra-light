import Toybox.Application;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Application;
import Toybox.Communications;
import Toybox.WatchUi;
import Toybox.PersistedContent;

enum /* TrackStyle */ {
    TRACK_STYLE_LINE = 0, // Standard continuous line
    TRACK_STYLE_DASHED = 1, // Interpolated dashes
    TRACK_STYLE_POINTS = 2, // Dots only at actual data points
    TRACK_STYLE_POINTS_INTERPOLATED = 3, // Dots spaced evenly along the path
    TRACK_STYLE_BOXES = 4, // Squares outline only at actual data points
    TRACK_STYLE_BOXES_INTERPOLATED = 5, // Squares outline spaced evenly along the path
    TRACK_STYLE_FILLED_SQUARE = 6, // Squares only at actual data points
    TRACK_STYLE_FILLED_SQUARE_INTERPOLATED = 7, // Squares spaced evenly along the path
    TRACK_STYLE_POINTS_OUTLINE = 8, // Dots only at actual data points, just the circle outline
    TRACK_STYLE_POINTS_OUTLINE_INTERPOLATED = 9, // Dots spaced evenly along the path, just the circle outline
    TRACK_STYLE_CHECKERBOARD = 10,
    TRACK_STYLE_HAZARD = 11,
    TRACK_STYLE_DOT_MATRIX = 12,
    TRACK_STYLE_POLKA_DOT = 13,
    TRACK_STYLE_DIAMOND = 14,

    TRACK_STYLE_MAX,
}

enum /*TrackPointReductionMethod*/ {
    TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE = 0,
    TRACK_POINT_REDUCTION_METHOD_REUMANN_WITKAM = 1,

    TRACK_POINT_REDUCTION_METHOD_MAX,
}

enum /*DataType*/ {
    DATA_TYPE_NONE,
    DATA_TYPE_SCALE,
    DATA_TYPE_ALTITUDE,
    DATA_TYPE_AVERAGE_HEART_RATE,
    DATA_TYPE_AVERAGE_SPEED,
    DATA_TYPE_CURRENT_HEART_RATE,
    DATA_TYPE_CURRENT_SPEED,
    DATA_TYPE_ELAPSED_DISTANCE,
    DATA_TYPE_ELAPSED_TIME,
    DATA_TYPE_TOTAL_ASCENT,
    DATA_TYPE_TOTAL_DESCENT,
    DATA_TYPE_AVERAGE_PACE,
    DATA_TYPE_CURRENT_PACE,

    // other metrics that might be good
    // most of these are inbuilt garmin ones (so could easily be added to a second data screen)
    // Ill add them if users ask, but currently only have requests for pace https://github.com/pauljohnston2025/breadcrumb-garmin/issues/8
    // anything to do with laps I will need to store timestamps when onTimerLap() is called, and probably store all the activity info? or maybe just store distance/and timestamp?
    // time of day - wall clock
    // last lap time
    // current lap time

    DATA_TYPE_MAX,
}

enum /*Mode*/ {
    MODE_NORMAL = 0,
    MODE_ELEVATION = 1,
    MODE_MAP_MOVE = 2,
    MODE_DEBUG = 3,
    MODE_MAP_MOVE_ZOOM = 4, // mostly for app (and button presses), but also allows larger touch zones
    MODE_MAP_MOVE_UP_DOWN = 5, // mostly for app (and button presses), but also allows larger touch zones
    MODE_MAP_MOVE_LEFT_RIGHT = 6, // mostly for app (and button presses), but also allows larger touch zones

    MODE_MAX,
}

enum /*ElevationMode*/ {
    ELEVATION_MODE_STACKED,
    ELEVATION_MODE_ORDERED_ROUTES,
    ELEVATION_MODE_MAX,
}

enum /*ZoomMode*/ {
    ZOOM_AT_PACE_MODE_PACE,
    ZOOM_AT_PACE_MODE_STOPPED,
    ZOOM_AT_PACE_MODE_NEVER_ZOOM,
    ZOOM_AT_PACE_MODE_ALWAYS_ZOOM,
    ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK,
    ZOOM_AT_PACE_MODE_MAX,
}

enum /*UiMode*/ {
    UI_MODE_SHOW_ALL, // show a heap of ui elements on screen always
    UI_MODE_HIDDEN, // ui still active, but is hidden
    UI_MODE_NONE, // no accessible ui (touch events disabled)
    UI_MODE_MAX,
}

enum /*RenderMode*/ {
    /*RENDER_MODE_BUFFERED_ROTATING = 0,*/
    RENDER_MODE_UNBUFFERED_ROTATING = 1,
    /* RENDER_MODE_BUFFERED_NO_ROTATION = 2,*/
    RENDER_MODE_UNBUFFERED_NO_ROTATION = 3,
    RENDER_MODE_MAX,
}

enum /*RenderMode*/ {
    ALERT_TYPE_TOAST,
    ALERT_TYPE_ALERT,
    ALERT_TYPE_IMAGE,
    ALERT_TYPE_MAX,
}

(:background)
function settingsAsDict() as Dictionary<String, PropertyValueType> {
    var routes = Application.Storage.getValue("routes"); // routes are saved to storage, does this even work on real devices? save/delete are documented to only work on 3.2.0
    if (routes == null) {
        // its storage, not properties, so it can be null
        routes = [];
    }

    return (
        ({
            "turnAlertTimeS" => Application.Properties.getValue("turnAlertTimeS"),
            "minTurnAlertDistanceM" => Application.Properties.getValue("minTurnAlertDistanceM"),
            "maxTrackPoints" => Application.Properties.getValue("maxTrackPoints"),
            "showDirectionPointTextUnderIndex" => Application.Properties.getValue(
                "showDirectionPointTextUnderIndex"
            ),
            "centerUserOffsetY" => Application.Properties.getValue("centerUserOffsetY"),
            "mapMoveScreenSize" => Application.Properties.getValue("mapMoveScreenSize"),
            "recalculateIntervalS" => Application.Properties.getValue("recalculateIntervalS"),
            "mode" => Application.Properties.getValue("mode"),
            "drawLineToClosestPoint" => Application.Properties.getValue("drawLineToClosestPoint"),
            "showPoints" => Application.Properties.getValue("showPoints"),
            "drawLineToClosestTrack" => Application.Properties.getValue("drawLineToClosestTrack"),
            "includeDebugPageInOnScreenUi" => Application.Properties.getValue(
                "includeDebugPageInOnScreenUi"
            ),
            "drawHitBoxes" => Application.Properties.getValue("drawHitBoxes"),
            "showDirectionPoints" => Application.Properties.getValue("showDirectionPoints"),
            "displayLatLong" => Application.Properties.getValue("displayLatLong"),
            "trackColour" => Application.Properties.getValue("trackColour"),
            "defaultRouteColour" => Application.Properties.getValue("defaultRouteColour"),
            "elevationColour" => Application.Properties.getValue("elevationColour"),
            "userColour" => Application.Properties.getValue("userColour"),
            "metersAroundUser" => Application.Properties.getValue("metersAroundUser"),
            "zoomAtPaceMode" => Application.Properties.getValue("zoomAtPaceMode"),
            "zoomAtPaceSpeedMPS" => Application.Properties.getValue("zoomAtPaceSpeedMPS"),
            "uiMode" => Application.Properties.getValue("uiMode"),
            "elevationMode" => Application.Properties.getValue("elevationMode"),
            "alertType" => Application.Properties.getValue("alertType"),
            "renderMode" => Application.Properties.getValue("renderMode"),
            "fixedLatitude" => Application.Properties.getValue("fixedLatitude"),
            "fixedLongitude" => Application.Properties.getValue("fixedLongitude"),
            "routes" => routes,
            "routesEnabled" => Application.Properties.getValue("routesEnabled"),
            "displayRouteNames" => Application.Properties.getValue("displayRouteNames"),
            "enableOffTrackAlerts" => Application.Properties.getValue("enableOffTrackAlerts"),
            "offTrackWrongDirection" => Application.Properties.getValue("offTrackWrongDirection"),
            "drawCheverons" => Application.Properties.getValue("drawCheverons"),
            "offTrackAlertsDistanceM" => Application.Properties.getValue("offTrackAlertsDistanceM"),
            "offTrackAlertsMaxReportIntervalS" => Application.Properties.getValue(
                "offTrackAlertsMaxReportIntervalS"
            ),
            "offTrackCheckIntervalS" => Application.Properties.getValue("offTrackCheckIntervalS"),
            "normalModeColour" => Application.Properties.getValue("normalModeColour"),
            "routeMax" => Application.Properties.getValue("routeMax"),
            "uiColour" => Application.Properties.getValue("uiColour"),
            "debugColour" => Application.Properties.getValue("debugColour"),
            "resetDefaults" => Application.Properties.getValue("resetDefaults"),
        }) as Dictionary<String, PropertyValueType>
    );
}

// we are getting dangerously close to the app settings limit
// was getting "Unable to serialize app data" in the sim, but after a restart worked fine
// see
// https://forums.garmin.com/developer/connect-iq/f/discussion/409127/unable-to-serialize-app-data---watch-app?pifragment-1298=1#pifragment-1298=1
// is seems like this only happened when:
// * I tried to run on instinct 3 (that only has 128kb of memory)
// * Crashed with OOM
// * Then tried running on the venu2s which has enough memory it fails with "Unable to serialize app data"
// * Reset sim app data and remove apps
// * Works fine
class Settings {
    var mode as Number = MODE_NORMAL;
    var modeDisplayOrder as Array<Number> = [0, 1, 2];
    var elevationMode as Number = ELEVATION_MODE_STACKED;

    var trackColour as Number = Graphics.COLOR_GREEN;
    var trackColour2 as Number = Graphics.COLOR_TRANSPARENT;
    const DEFAULT_ROUTE_COLOUR_2 = Graphics.COLOR_TRANSPARENT;
    const DEFAULT_ROUTE_STYLE = TRACK_STYLE_LINE;
    const DEFAULT_ROUTE_WIDTH = 4;
    var defaultRouteColour as Number = Graphics.COLOR_BLUE;
    var elevationColour as Number = Graphics.COLOR_ORANGE;
    var userColour as Number = Graphics.COLOR_ORANGE;

    // Renders around the users position
    var metersAroundUser as Number = 500; // keep this fairly high by default, too small and the map tiles start to go blurry
    var centerUserOffsetY as Float = 0.5f; // fraction of the screen to move the user down the page 0.5 - user appears in center, 0.75 - user appears 3/4 down the screen. Useful to see more of the route in front of the user.
    var mapMoveScreenSize as Float = 0.3f; // how far to move the map when the user presses on screen buttons, a fraction of the screen size.
    var zoomAtPaceMode as Number = ZOOM_AT_PACE_MODE_PACE;
    var zoomAtPaceSpeedMPS as Float = 1.0; // meters per second
    var useTrackAsHeadingSpeedMPS as Float = 1000f; // meters per second
    var topDataType as Number = DATA_TYPE_NONE;
    var bottomDataType as Number = DATA_TYPE_SCALE;
    var dataFieldTextSize as Number = Graphics.FONT_XTINY;
    var minTrackPointDistanceM as Number = 5; // minimum distance between 2 track points
    var trackPointReductionMethod as Number = TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE;
    var uiMode as Number = UI_MODE_SHOW_ALL;
    var fixedLatitude as Float? = null;
    var fixedLongitude as Float? = null;

    // see keys below in routes = getArraySchema(...)
    // see oddity with route name and route loading new in context.newRoute
    var routes as Array<Dictionary> = [];
    var routesEnabled as Boolean = true;
    var displayRouteNames as Boolean = true;
    var normalModeColour as Number = Graphics.COLOR_BLUE;
    var uiColour as Number = Graphics.COLOR_DK_GRAY;
    var debugColour as Number = 0xfeffffff; // white, but colour_white results in FFFFFFFF (-1) when we parse it and that is fully transparent
    // I did get up to 4 large routes working with off track alerts, but any more than that and watchdog catches us out, 3 is a safer limit.
    // currently we still load disabled routes into memory, so its also not great having this large and a heap of disabled routes
    private var _routeMax as Number = 3;

    // note this only works if a single track is enabled (multiple tracks would always error)
    var enableOffTrackAlerts as Boolean = true;
    var offTrackAlertsDistanceM as Number = 20;
    var offTrackAlertsMaxReportIntervalS as Number = 60;
    var offTrackCheckIntervalS as Number = 15;
    var alertType as Number = ALERT_TYPE_TOAST;
    var offTrackWrongDirection as Boolean = false;
    var drawCheverons as Boolean = false;

    var drawLineToClosestPoint as Boolean = true;
    var displayLatLong as Boolean = true;

    // scratchpad used for rotations, but it also means we have a large bitmap stored around
    // I will also use that bitmap for re-renders though, and just do rotations every render rather than re-drawing all the tracks/tiles again
    var renderMode as Number = RENDER_MODE_UNBUFFERED_ROTATING;
    // how many seconds should we wait before even considering the next point
    // changes in speed/angle/zoom are not effected by this number. Though maybe they should be?
    var recalculateIntervalS as Number = 5;
    var turnAlertTimeS as Number = -1; // -1 disables the check
    var minTurnAlertDistanceM as Number = -1; // -1 disables the check
    var maxTrackPoints as Number = 400;
    var trackStyle as Number = TRACK_STYLE_LINE;
    var trackWidth as Number = 4;

    // bunch of debug settings
    var drawLineToClosestTrack as Boolean = false;
    var drawHitBoxes as Boolean = false;
    var showDirectionPoints as Boolean = false;
    var showDirectionPointTextUnderIndex as Number = 0;

    // these settings can only be modified externally, but we cache them for faster/easier lookup
    // https://www.youtube.com/watch?v=LasrD6SZkZk&ab_channel=JaylaB
    var distanceImperialUnits as Boolean =
        System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
    var elevationImperialUnits as Boolean =
        System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE;
    var trackTexture as Graphics.BitmapTexture or Number = -1; // -1 is to say use colour instead
    var routeTextures as Array<Graphics.BitmapTexture or Number> = []; // -1 is to say use colour instead

    (:lowMemory)
    function routeMax() as Number {
        return 1; // can only get 1 route (second route crashed on storage save), we also still need space for the track
    }

    (:highMemory)
    function routeMax() as Number {
        return _routeMax;
    }

    function setMode(_mode as Number) as Void {
        mode = _mode;
        // directly set mode, its only for what is displayed, which takes effect ont he next onUpdate
        // we do not want to call view.onSettingsChanged because it clears timestamps when going to the debug page.
        // The setValue method on this class calls the view changed method, so do not call it.
        Application.Properties.setValue("mode", mode);
    }

    (:settingsView,:menu2)
    function setElevationMode(value as Number) as Void {
        elevationMode = value;
        setValue("elevationMode", elevationMode);
    }

    (:settingsView,:menu2)
    function setUiMode(_uiMode as Number) as Void {
        uiMode = _uiMode;
        setValue("uiMode", uiMode);
    }

    (:settingsView,:menu2)
    function setAlertType(_alertType as Number) as Void {
        alertType = _alertType;
        setValue("alertType", alertType);
    }

    (:settingsView,:menu2)
    function setRenderMode(_renderMode as Number) as Void {
        renderMode = _renderMode;
        setValue("renderMode", renderMode);
        updateCachedValues();
        updateViewSettings();
    }

    function setFixedPositionRaw(lat as Float, long as Float) as Void {
        // hack method so that cached values can update the settings without reloading itself
        // its guaranteed to only be when moving around, and will never go to null
        fixedLatitude = lat;
        fixedLongitude = long;
        Application.Properties.setValue("fixedLatitude", lat);
        Application.Properties.setValue("fixedLongitude", long);
    }

    function setFixedPosition(lat as Float?, long as Float?) as Void {
        // logT("moving to: " + lat + " " + long);
        // be very careful about putting null into properties, it breaks everything
        if (lat == null || !(lat instanceof Float)) {
            lat = 0f;
        }
        if (long == null || !(long instanceof Float)) {
            long = 0f;
        }
        fixedLatitude = lat;
        fixedLongitude = long;
        setValue("fixedLatitude", lat);
        setValue("fixedLongitude", long);

        var latIsBasicallyNull = fixedLatitude == null || fixedLatitude == 0;
        var longIsBasicallyNull = fixedLongitude == null || fixedLongitude == 0;
        if (latIsBasicallyNull || longIsBasicallyNull) {
            fixedLatitude = null;
            fixedLongitude = null;
            updateCachedValues();
            return;
        }

        // we should have a lat and a long at this point
        // updateCachedValues(); already called by the above sets
        // var latlong = RectangularPoint.xyToLatLon(fixedPosition.x, fixedPosition.y);
        // logT("round trip conversion result: " + latlong);
    }

    function setFixedPositionWithoutUpdate(lat as Float?, long as Float?) as Void {
        // logT("moving to: " + lat + " " + long);
        // be very careful about putting null into properties, it breaks everything
        if (lat == null || !(lat instanceof Float)) {
            lat = 0f;
        }
        if (long == null || !(long instanceof Float)) {
            long = 0f;
        }
        fixedLatitude = lat;
        fixedLongitude = long;
        Application.Properties.setValue("fixedLatitude", lat);
        Application.Properties.setValue("fixedLongitude", long);

        var latIsBasicallyNull = fixedLatitude == null || fixedLatitude == 0;
        var longIsBasicallyNull = fixedLongitude == null || fixedLongitude == 0;
        if (latIsBasicallyNull || longIsBasicallyNull) {
            fixedLatitude = null;
            fixedLongitude = null;
            updateCachedValues();
            return;
        }

        // we should have a lat and a long at this point
        // updateCachedValues(); already called by the above sets
        // var latlong = RectangularPoint.xyToLatLon(fixedPosition.x, fixedPosition.y);
        // logT("round trip conversion result: " + latlong);
    }

    function setValue(key as String, value as PropertyValueType) as Void {
        Application.Properties.setValue(key, value);
        setValueSideEffect();
    }

    function setValueSideEffect() as Void {
        updateCachedValues();
        updateViewSettings();
        updateRouteSettings();
    }

    function setZoomAtPaceMode(_zoomAtPaceMode as Number) as Void {
        zoomAtPaceMode = _zoomAtPaceMode;
        setValue("zoomAtPaceMode", zoomAtPaceMode);
    }

    function setZoomAtPaceSpeedMPS(mps as Float) as Void {
        zoomAtPaceSpeedMPS = mps;
        setValue("zoomAtPaceSpeedMPS", zoomAtPaceSpeedMPS);
    }

    (:settingsView,:menu2)
    function setUseTrackAsHeadingSpeedMPS(mps as Float) as Void {
        useTrackAsHeadingSpeedMPS = mps;
        setValue("useTrackAsHeadingSpeedMPS", useTrackAsHeadingSpeedMPS);
    }

    (:settingsView,:menu2)
    function setMetersAroundUser(value as Number) as Void {
        metersAroundUser = value;
        setValue("metersAroundUser", metersAroundUser);
    }

    (:settingsView,:menu2)
    function setTopDataType(value as Number) as Void {
        topDataType = value;
        setValue("topDataType", topDataType);
    }

    (:settingsView,:menu2)
    function setBottomDataType(value as Number) as Void {
        bottomDataType = value;
        setValue("bottomDataType", bottomDataType);
    }

    (:settingsView,:menu2)
    function setMinTrackPointDistanceM(value as Number) as Void {
        minTrackPointDistanceM = value;
        setValue("minTrackPointDistanceM", minTrackPointDistanceM);
        setMinTrackPointDistanceMSideEffect();
    }

    function setMinTrackPointDistanceMSideEffect() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }

        // only the track needs the setting, routes do not matter, they can stay at the default (5m) because they are limited by the companion app anyway
        _breadcrumbContextLocal.track.setMinDistanceM(
            minTrackPointDistanceM.toFloat(),
            _breadcrumbContextLocal.cachedValues.currentScale
        );
    }

    (:settingsView,:menu2)
    function setTrackPointReductionMethod(value as Number) as Void {
        trackPointReductionMethod = value;
        setValue("trackPointReductionMethod", trackPointReductionMethod);
    }

    (:settingsView,:menu2)
    function setDataFieldTextSize(value as Number) as Void {
        dataFieldTextSize = value;
        setValue("dataFieldTextSize", dataFieldTextSize);
    }

    (:settingsView,:menu2)
    function setFixedLatitude(value as Float) as Void {
        setFixedPosition(value, fixedLongitude);
    }

    (:settingsView,:menu2)
    function setFixedLongitude(value as Float) as Void {
        setFixedPosition(fixedLatitude, value);
    }

    (:settingsView,:menu2)
    function setTurnAlertTimeS(value as Number) as Void {
        turnAlertTimeS = value;
        setValue("turnAlertTimeS", turnAlertTimeS);
    }

    (:settingsView,:menu2)
    function setMinTurnAlertDistanceM(value as Number) as Void {
        minTurnAlertDistanceM = value;
        setValue("minTurnAlertDistanceM", minTurnAlertDistanceM);
    }

    (:settingsView,:menu2)
    function setModeDisplayOrder(value as String) as Void {
        // try and validate it before saving the setting
        modeDisplayOrder = parseCSVStringRaw(
            "modeDisplayOrder",
            value,
            modeDisplayOrder,
            method(:defaultNumberParser)
        );
        setValue("modeDisplayOrder", encodeCSV(modeDisplayOrder));
    }

    (:settingsView,:menu2)
    function setMaxTrackPoints(value as Number) as Void {
        var oldmaxTrackPoints = maxTrackPoints;
        maxTrackPoints = value;
        if (oldmaxTrackPoints != maxTrackPoints) {
            maxTrackPointsChanged();
        }
        setValue("maxTrackPoints", maxTrackPoints);
    }

    (:settingsView)
    function setTrackStyle(value as Number) as Void {
        trackStyle = value;
        setValue("trackStyle", trackStyle);
        recomputeTrackTexture();
    }

    (:settingsView)
    function setTrackWidth(value as Number) as Void {
        trackWidth = value;
        setValue("trackWidth", trackWidth);
        recomputeTrackTexture();
    }

    function maxTrackPointsChanged() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.track.coordinates.restrictPointsToMaxMemory(
            maxTrackPoints,
            _breadcrumbContextLocal.settings.trackPointReductionMethod,
            _breadcrumbContextLocal.cachedValues.currentScale
        );
    }

    (:settingsView,:menu2)
    function setShowDirectionPointTextUnderIndex(value as Number) as Void {
        showDirectionPointTextUnderIndex = value;
        setValue("showDirectionPointTextUnderIndex", showDirectionPointTextUnderIndex);
    }

    (:settingsView,:menu2)
    function setOffTrackAlertsDistanceM(value as Number) as Void {
        offTrackAlertsDistanceM = value;
        setValue("offTrackAlertsDistanceM", offTrackAlertsDistanceM);
        updateViewSettings();
    }

    (:settingsView,:menu2)
    function setOffTrackAlertsMaxReportIntervalS(value as Number) as Void {
        offTrackAlertsMaxReportIntervalS = value;
        setValue("offTrackAlertsMaxReportIntervalS", offTrackAlertsMaxReportIntervalS);
        updateViewSettings();
    }

    (:settingsView,:menu2)
    function setOffTrackCheckIntervalS(value as Number) as Void {
        offTrackCheckIntervalS = value;
        setValue("offTrackCheckIntervalS", offTrackCheckIntervalS);
        updateViewSettings();
    }

    (:settingsView,:menu2)
    function setRouteMax(value as Number) as Void {
        var oldRouteMax = _routeMax;
        _routeMax = value;
        if (oldRouteMax > _routeMax) {
            routeMaxReduced();
        }
        setValue("routeMax", _routeMax);
        updateCachedValues();
        updateViewSettings();
    }

    function routeMaxReduced() as Void {
        // remove the first oes or the last ones? we do not have an age, so just remove the last ones.
        var routesToRemove = [] as Array<Number>;
        for (var i = _routeMax; i < routes.size(); ++i) {
            var oldRouteEntry = routes[i];
            var oldRouteId = oldRouteEntry["routeId"] as Number;
            routesToRemove.add(oldRouteId);
        }
        for (var i = 0; i < routesToRemove.size(); ++i) {
            var routeId = routesToRemove[i];
            clearRouteFromContext(routeId);
            // do not use the clear route helper method, it will stack overflow
            var routeIndex = getRouteIndexById(routeId);
            if (routeIndex == null) {
                continue;
            }
            routes.remove(routes[routeIndex]);
        }

        saveRoutesNoSideEffect();
    }

    (:settingsView,:menu2)
    function setMapMoveScreenSize(value as Float) as Void {
        mapMoveScreenSize = value;
        setValue("mapMoveScreenSize", mapMoveScreenSize);
    }

    (:settingsView,:menu2)
    function setCenterUserOffsetY(value as Float) as Void {
        centerUserOffsetY = value;
        setValue("centerUserOffsetY", centerUserOffsetY);
    }

    (:settingsView,:menu2)
    function setRecalculateIntervalS(value as Number) as Void {
        recalculateIntervalS = value;
        recalculateIntervalS = recalculateIntervalS <= 0 ? 1 : recalculateIntervalS;
        setValue("recalculateIntervalS", recalculateIntervalS);
    }

    (:settingsView,:menu2)
    function setDrawLineToClosestPoint(value as Boolean) as Void {
        drawLineToClosestPoint = value;
        setValue("drawLineToClosestPoint", drawLineToClosestPoint);
        updateViewSettings();
    }

    (:settingsView,:menu2)
    function setDrawLineToClosestTrack(value as Boolean) as Void {
        drawLineToClosestTrack = value;
        setValue("drawLineToClosestTrack", drawLineToClosestTrack);
    }

    (:settingsView,:menu2)
    function setDrawHitBoxes(value as Boolean) as Void {
        drawHitBoxes = value;
        setValue("drawHitBoxes", drawHitBoxes);
    }

    (:settingsView,:menu2)
    function setShowDirectionPoints(value as Boolean) as Void {
        showDirectionPoints = value;
        setValue("showDirectionPoints", showDirectionPoints);
    }

    (:settingsView,:menu2)
    function setDisplayLatLong(value as Boolean) as Void {
        displayLatLong = value;
        setValue("displayLatLong", displayLatLong);
    }
    (:settingsView,:menu2)
    function setDisplayRouteNames(_displayRouteNames as Boolean) as Void {
        displayRouteNames = _displayRouteNames;
        setValue("displayRouteNames", displayRouteNames);
    }

    function setRoutesEnabled(_routesEnabled as Boolean) as Void {
        routesEnabled = _routesEnabled;
        setValue("routesEnabled", routesEnabled);
    }

    function routeColour(routeId as Number) as Number {
        return routeProp(routeId, "colour", defaultRouteColour) as Number;
    }

    function routeColour2(routeId as Number) as Number {
        return routeProp(routeId, "colour2", DEFAULT_ROUTE_COLOUR_2) as Number;
    }

    // see oddity with route name and route loading new in context.newRoute
    function routeName(routeId as Number) as String {
        return routeProp(routeId, "name", "") as String;
    }

    function routeProp(
        routeId as Number,
        key as String,
        defaultVal as Number or String or Boolean
    ) as Number or String or Boolean {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return defaultVal;
        }

        return routes[routeIndex][key] as Number or String or Boolean;
    }

    (:storage)
    function atLeast1RouteEnabled() as Boolean {
        if (!routesEnabled) {
            return false;
        }

        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (route["enabled"]) {
                return true;
            }
        }

        return false;
    }

    function routeEnabled(routeId as Number) as Boolean {
        if (!routesEnabled) {
            return false;
        }

        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return false;
        }
        return routes[routeIndex]["enabled"] as Boolean;
    }

    function routeReversed(routeId as Number) as Boolean {
        return routeProp(routeId, "reversed", false) as Boolean;
    }

    function routeStyle(routeId as Number) as Number {
        return routeProp(routeId, "style", DEFAULT_ROUTE_STYLE) as Number;
    }

    function routeTexture(routeId as Number) as Graphics.BitmapTexture or Number {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return -1;
        }
        padRouteTextures(routeIndex);
        return routeTextures[routeIndex];
    }

    function routeWidth(routeId as Number) as Number {
        return routeProp(routeId, "width", DEFAULT_ROUTE_WIDTH) as Number;
    }

    function ensureDefaultRoute(routeId as Number, name as String) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex != null) {
            routes[routeIndex] = defaultRoute(routeId, name);
            routeTextures[routeIndex] = -1;
            saveRoutes();
            return;
        }

        if (routes.size() >= _routeMax) {
            return;
        }

        routes.add(defaultRoute(routeId, name));
        routeTextures.add(-1);
        saveRoutes();
    }

    function simpleRouteProp(routeId as Number, key as String, value as Number or Boolean) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return;
        }

        routes[routeIndex][key] = value;
        saveRoutes();
        recomputeRouteTexture(routeIndex);
    }

    function setRouteColour(routeId as Number, value as Number) as Void {
        simpleRouteProp(routeId, "colour", value);
    }

    function setRouteColour2(routeId as Number, value as Number) as Void {
        simpleRouteProp(routeId, "colour2", value);
    }

    // see oddity with route name and route loading new in context.newRoute
    function setRouteName(routeId as Number, value as String) as Void {
        setRouteNameNoSideEffect(routeId, value);
        setValueSideEffect();
    }

    function setRouteNameNoSideEffect(routeId as Number, value as String) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return;
        }

        routes[routeIndex]["name"] = value;
        saveRoutesNoSideEffect();
    }

    function setRouteStyle(routeId as Number, value as Number) as Void {
        simpleRouteProp(routeId, "style", value);
    }

    function setRouteWidth(routeId as Number, value as Number) as Void {
        simpleRouteProp(routeId, "width", value);
    }

    function setRouteEnabled(routeId as Number, value as Boolean) as Void {
        simpleRouteProp(routeId, "enabled", value);
    }

    function setRouteReversed(routeId as Number, value as Boolean) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return;
        }

        var oldVal = routes[routeIndex]["reversed"];
        if (oldVal != value) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.reverseRouteId(routeId);
            }
        }
        routes[routeIndex]["reversed"] = value;
        saveRoutes();
        updateViewSettings();
    }

    function ensureRouteId(routeId as Number) as Void {
        ensureRouteIdNoSideEffect(routeId);
        setValueSideEffect();
    }

    function ensureRouteIdNoSideEffect(routeId as Number) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex != null) {
            return;
        }

        if (routes.size() >= _routeMax) {
            return;
        }

        routes.add(defaultRoute(routeId, ""));
        routeTextures.add(-1);
        saveRoutesNoSideEffect();
    }

    function defaultRoute(routeId as Number, name as String) as Dictionary {
        return {
            "routeId" => routeId,
            "name" => name,
            "enabled" => true,
            "colour" => defaultRouteColour,
            "colour2" => DEFAULT_ROUTE_COLOUR_2,
            "reversed" => false,
            "style" => DEFAULT_ROUTE_STYLE,
            "width" => DEFAULT_ROUTE_WIDTH,
        };
    }

    function getRouteIndexById(routeId as Number) as Number? {
        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (route["routeId"] == routeId) {
                return i;
            }
        }

        return null;
    }

    function clearRoutes() as Void {
        routes = [];
        routeTextures = [];
        saveRoutes();
    }

    function clearRoute(routeId as Number) as Void {
        var routeIndex = getRouteIndexById(routeId);
        if (routeIndex == null) {
            return;
        }
        routes.remove(routes[routeIndex]);
        routeTextures.remove(routeTextures[routeIndex]);
        saveRoutes();
    }

    function routesToSave() as Array<Dictionary<String, PropertyValueType> > {
        var toSave = [] as Array<Dictionary<String, PropertyValueType> >;
        for (var i = 0; i < routes.size(); ++i) {
            var entry = routes[i];
            var toAdd =
                ({
                    "routeId" => entry["routeId"] as Number,
                    "name" => entry["name"] as String,
                    "enabled" => entry["enabled"] as Boolean,
                    "colour" => (entry["colour"] as Number).format("%X"), // this is why we have to copy it :(
                    "colour2" => (entry["colour2"] as Number).format("%X"), // this is why we have to copy it :(
                    "reversed" => entry["reversed"] as Boolean,
                    "style" => entry["style"] as Number,
                    "width" => entry["width"] as Number,
                }) as Dictionary<String, PropertyValueType>;
            toSave.add(toAdd);
        }
        return toSave;
    }

    function saveRoutes() as Void {
        saveRoutesNoSideEffect();
        setValueSideEffect();
    }

    function saveRoutesNoSideEffect() as Void {
        var toSave = routesToSave();
        // note toSave is Array<Dictionary<String, PropertyValueType>>
        // but the compiler only allows "Array<PropertyValueType>" even though the array of dicts seems to work on sim and real watch
        safeSetStorage("routes", toSave as Array<PropertyValueType>);
    }

    (:settingsView,:menu2)
    function setTrackColour(value as Number) as Void {
        trackColour = value;
        setValue("trackColour", trackColour.format("%X"));
        recomputeTrackTexture();
    }

    (:settingsView)
    function setTrackColour2(value as Number) as Void {
        trackColour2 = value;
        setValue("trackColour2", trackColour2.format("%X"));
        recomputeTrackTexture();
    }

    function recomputeTrackTexture() as Void {
        trackTexture = getTexture(
            trackStyle,
            trackWidth,
            trackWidth / 2,
            trackColour,
            trackColour2
        );
    }

    function recomputeRouteTexture(routeIndex as Number) as Void {
        padRouteTextures(routeIndex);
        var route = routes[routeIndex];
        var currentWidth = route["width"] as Number;
        routeTextures[routeIndex] = getTexture(
            route["style"] as Number,
            currentWidth,
            currentWidth / 2,
            route["colour"] as Number,
            route["colour2"] as Number
        );
    }

    function padRouteTextures(routeIndex as Number) as Void {
        if (routeTextures.size() <= routeIndex) {
            // Calculate how many new slots we need
            var elementsToAdd = routeIndex + 1 - routeTextures.size();

            // Create the "padding" array filled with -1
            var padding = new [elementsToAdd] as Array<Graphics.BitmapTexture or Number>;
            for (var i = 0; i < elementsToAdd; i++) {
                padding[i] = -1;
            }

            routeTextures.addAll(padding);
        }
    }

    (:settingsView,:menu2)
    function setDefaultRouteColour(value as Number) as Void {
        defaultRouteColour = value;
        setValue("defaultRouteColour", defaultRouteColour.format("%X"));
    }

    (:settingsView,:menu2)
    function setUserColour(value as Number) as Void {
        userColour = value;
        setValue("userColour", userColour.format("%X"));
    }

    (:settingsView,:menu2)
    function setNormalModeColour(value as Number) as Void {
        normalModeColour = value;
        setValue("normalModeColour", normalModeColour.format("%X"));
    }

    (:settingsView,:menu2)
    function setDebugColour(value as Number) as Void {
        debugColour = value;
        setValue("debugColour", debugColour.format("%X"));
    }

    (:settingsView,:menu2)
    function setUiColour(value as Number) as Void {
        uiColour = value;
        setValue("uiColour", uiColour.format("%X"));
    }

    (:settingsView,:menu2)
    function setElevationColour(value as Number) as Void {
        elevationColour = value;
        setValue("elevationColour", elevationColour.format("%X"));
    }

    (:settingsView,:menu2)
    function toggleDrawLineToClosestPoint() as Void {
        drawLineToClosestPoint = !drawLineToClosestPoint;
        setValue("drawLineToClosestPoint", drawLineToClosestPoint);
    }
    (:settingsView,:menu2)
    function toggleDrawLineToClosestTrack() as Void {
        drawLineToClosestTrack = !drawLineToClosestTrack;
        setValue("drawLineToClosestTrack", drawLineToClosestTrack);
    }
    (:settingsView,:menu2)
    function toggleDrawHitBoxes() as Void {
        drawHitBoxes = !drawHitBoxes;
        setValue("drawHitBoxes", drawHitBoxes);
    }
    (:settingsView,:menu2)
    function toggleShowDirectionPoints() as Void {
        showDirectionPoints = !showDirectionPoints;
        setValue("showDirectionPoints", showDirectionPoints);
    }
    (:settingsView,:menu2)
    function toggleDisplayLatLong() as Void {
        displayLatLong = !displayLatLong;
        setValue("displayLatLong", displayLatLong);
    }
    (:settingsView,:menu2)
    function toggleDisplayRouteNames() as Void {
        displayRouteNames = !displayRouteNames;
        setValue("displayRouteNames", displayRouteNames);
    }
    (:settingsView,:menu2)
    function toggleEnableOffTrackAlerts() as Void {
        enableOffTrackAlerts = !enableOffTrackAlerts;
        setValue("enableOffTrackAlerts", enableOffTrackAlerts);
    }
    (:settingsView,:menu2)
    function toggleOffTrackWrongDirection() as Void {
        offTrackWrongDirection = !offTrackWrongDirection;
        setValue("offTrackWrongDirection", offTrackWrongDirection);
    }
    (:settingsView,:menu2)
    function toggleDrawCheverons() as Void {
        drawCheverons = !drawCheverons;
        setValue("drawCheverons", drawCheverons);
    }
    (:settingsView,:menu2)
    function toggleRoutesEnabled() as Void {
        routesEnabled = !routesEnabled;
        setValue("routesEnabled", routesEnabled);
    }

    function getNextMode() as Number {
        // does not handle dupes, but thats the user error if they do that
        if (modeDisplayOrder.size() < 1) {
            // they want to stay locked to the current mode thats picked
            return mode;
        }

        var curentModeIndex = modeDisplayOrder.indexOf(mode);
        if (curentModeIndex == -1 || curentModeIndex == modeDisplayOrder.size() - 1) {
            // not found, or we need to go back to the star of the array
            return modeDisplayOrder[0];
        }

        return modeDisplayOrder[curentModeIndex + 1];
    }

    function nextMode() as Void {
        // logT("mode cycled");
        mode = getNextMode();

        // try 5 times to get a good mode, if we can't bail out, better than an infinite while loop
        // helps if users do something like 1,2,3,40,5,6 it will ship over the bad '40' mode
        for (var i = 0; i < 5; ++i) {
            if (mode >= 0 && mode < MODE_MAX) {
                // not the best validation check, but modes are continuous for now
                // if we ever have gaps we will need to check for those too
                break;
            }
            mode = getNextMode();
        }
        setMode(mode);
    }

    function nextZoomAtPaceMode() as Void {
        if (mode != MODE_NORMAL) {
            return;
        }

        // could also do this? not sure what better for perf (probably the modulo 1 less instruction), below is more readable
        // zoomAtPaceMode = (zoomAtPaceMode + 1) % ZOOM_AT_PACE_MODE_MAX;
        zoomAtPaceMode++;
        if (zoomAtPaceMode >= ZOOM_AT_PACE_MODE_MAX) {
            zoomAtPaceMode = ZOOM_AT_PACE_MODE_PACE;
        }

        setZoomAtPaceMode(zoomAtPaceMode);
    }

    function updateViewSettings() as Void {
        var _viewLocal = $._view;
        if (_viewLocal != null) {
            _viewLocal.onSettingsChanged();
        }
    }

    function updateRouteSettings() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var contextRoutes = _breadcrumbContextLocal.routes;
        for (var i = 0; i < contextRoutes.size(); ++i) {
            var route = contextRoutes[i];
            // we do not care if its curently disabled, nuke the data anyway
            // if (!routeEnabled(route.storageIndex)) {
            //     continue;
            // }
            // todo only call this if setting sthat effect it changed, taking nuclear approach for now
            route.settingsChanged();
        }
    }

    function updateCachedValues() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.cachedValues.recalculateAll();
    }

    function clearContextRoutes() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.clearRoutes();
    }

    function clearRouteFromContext(routeId as Number) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.clearRouteId(routeId);
    }

    function purgeRoutesFromContext() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.purgeRoutes();
    }

    // some times these parserswere throwing when it was an empty strings seem to result in, or wrong type
    //
    // Error: Unhandled Exception
    // Exception: UnexpectedTypeException: Expected Number/Float/Long/Double/Char, given null/Number
    function parseColourTransparency(
        key as String,
        defaultValue as Number,
        allowTransparent as Boolean
    ) as Number {
        try {
            return parseColourRaw(
                key,
                Application.Properties.getValue(key),
                defaultValue,
                allowTransparent
            );
        } catch (e) {
            logE("Error parsing float: " + key);
        }
        return defaultValue;
    }

    function parseColour(key as String, defaultValue as Number) as Number {
        return parseColourTransparency(key, defaultValue, false);
    }

    static function parseColourRaw(
        key as String,
        colourString as PropertyValueType,
        defaultValue as Number,
        allowTransparent as Boolean
    ) as Number {
        try {
            if (colourString == null) {
                return defaultValue;
            }

            if (colourString instanceof String) {
                // want final string as AARRGGBB
                // colourString = padStart(colourString, 6, '0'); // fill in 24 bit colour with 0's
                // colourString = padStart(colourString, 8, 'F'); // pad alpha channel with FF
                // empty or invalid strings convert to null
                // anything with leading FF (when 8 characters supplied) needs to be a long, because its too big to fit in Number
                // if a user chooses FFFFFFFF (white) it is (-1) which is fully transparent, should choose FFFFFF (no alpha) or something close like FFFFFFFE
                // in any case we are currently ignoring alpha because we use setColor (text does not support alpha)
                var long = null;
                if (colourString has :toLongWithBase) {
                    long = colourString.toLongWithBase(16);
                } else {
                    // this could be a problem for older apis if the colour string is set with leading FF (or any high bit is set)
                    if (colourString.length() > 6) {
                        colourString =
                            colourString.substring(
                                colourString.length() - 6,
                                colourString.length()
                            ) as String;
                    }
                    long = colourString.toNumberWithBase(16);
                }
                if (long == null) {
                    return defaultValue;
                }
                // may have been a number from previous toNumberWithBase call
                long = long.toLong();

                // calling tonumber breaks - because its out of range, but we need to set the alpha bits
                var number = (long & 0xffffffffl).toNumber();
                if (number == 0xffffffff && !allowTransparent) {
                    // -1 is transparent and will not render
                    number = 0xfeffffff;
                }
                return number;
            }

            return parseNumberRaw(key, colourString, defaultValue);
        } catch (e) {
            logE("Error parsing colour: " + key + " " + colourString);
        }
        return defaultValue;
    }

    function parseNumber(key as String, defaultValue as Number) as Number {
        try {
            return parseNumberRaw(key, Application.Properties.getValue(key), defaultValue);
        } catch (e) {
            logE("Error parsing float: " + key);
        }
        return defaultValue;
    }

    static function parseNumberRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as Number
    ) as Number {
        try {
            if (value == null) {
                return defaultValue;
            }

            if (
                value instanceof String ||
                value instanceof Float ||
                value instanceof Number ||
                value instanceof Double
            ) {
                // empty or invalid strings convert to null
                var ret = value.toNumber();
                if (ret == null) {
                    return defaultValue;
                }

                return ret;
            }

            return defaultValue;
        } catch (e) {
            logE("Error parsing number: " + key + " " + value);
        }
        return defaultValue;
    }

    static function encodeCSV(value as Array<ReturnType>) as String {
        var result = "";
        var size = value.size();

        for (var i = 0; i < size; ++i) {
            // Convert element to string (works for both Number and String)
            result += value[i].toString();

            // Add a comma after every element except the last one
            if (i < size - 1) {
                result += ",";
            }
        }

        return result;
    }

    typedef ReturnType as Number /* or String*/;
    function parseCSVString(
        key as String,
        defaultValue as Array<ReturnType>,
        callback as (Method(key as String, value as PropertyValueType) as ReturnType)
    ) as Array<ReturnType> {
        try {
            return parseCSVStringRaw(
                key,
                Application.Properties.getValue(key),
                defaultValue,
                callback
            );
        } catch (e) {
            logE("Error parsing float: " + key);
        }
        return defaultValue;
    }

    function parseCSVStringRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as Array<ReturnType>,
        callback as (Method(key as String, value as PropertyValueType) as ReturnType)
    ) as Array<ReturnType> {
        try {
            if (value == null) {
                return defaultValue;
            }

            if (value instanceof String) {
                var string = value;
                var splitter = ",";
                var result = [] as Array<ReturnType>;
                var location = string.find(splitter) as Number?;

                while (location != null) {
                    result.add(callback.invoke(key, string.substring(0, location) as String));

                    // Truncate the string to look for the next splitter
                    string =
                        string.substring(location + splitter.length(), string.length()) as String;

                    location = string.find(splitter);
                }

                // Add the remaining part of the string if it's not empty
                if (string.length() > 0) {
                    result.add(callback.invoke(key, string));
                }

                return result;
            }

            return defaultValue;
        } catch (e) {
            logE("Error parsing string: " + key + " " + value);
        }
        return defaultValue;
    }

    function parseBool(key as String, defaultValue as Boolean) as Boolean {
        try {
            return parseBoolRaw(key, Application.Properties.getValue(key), defaultValue);
        } catch (e) {
            logE("Error parsing bool: " + key);
        }
        return defaultValue;
    }

    function parseBoolRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as Boolean
    ) as Boolean {
        try {
            if (value == null) {
                return false;
            }

            if (value instanceof String) {
                return (
                    value.equals("") ||
                    value.equals("false") ||
                    value.equals("False") ||
                    value.equals("FALSE") ||
                    value.equals("0")
                );
            }

            if (!(value instanceof Boolean)) {
                return false;
            }

            return value;
        } catch (e) {
            logE("Error parsing bool: " + key + " " + value);
        }
        return defaultValue;
    }

    function parseFloat(key as String, defaultValue as Float) as Float {
        try {
            return parseFloatRaw(key, Application.Properties.getValue(key), defaultValue);
        } catch (e) {
            logE("Error parsing float: " + key);
        }
        return defaultValue;
    }

    static function parseFloatRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as Float
    ) as Float {
        try {
            if (value == null) {
                return defaultValue;
            }

            if (
                value instanceof String ||
                value instanceof Float ||
                value instanceof Number ||
                value instanceof Double
            ) {
                // empty or invalid strings convert to null
                var ret = value.toFloat();
                if (ret == null) {
                    return defaultValue;
                }

                return ret;
            }

            return defaultValue;
        } catch (e) {
            logE("Error parsing float: " + key + " " + value);
        }
        return defaultValue;
    }

    function parseString(key as String, defaultValue as String) as String {
        try {
            return parseStringRaw(key, Application.Properties.getValue(key), defaultValue);
        } catch (e) {
            logE("Error parsing string: " + key);
        }
        return defaultValue;
    }

    function parseStringRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as String
    ) as String {
        try {
            if (value == null) {
                return defaultValue;
            }

            if (value instanceof String) {
                return value;
            }

            return defaultValue;
        } catch (e) {
            logE("Error parsing string: " + key + " " + value);
        }
        return defaultValue;
    }

    function parseOptionalFloat(key as String, defaultValue as Float?) as Float? {
        try {
            return parseOptionalFloatRaw(key, Application.Properties.getValue(key), defaultValue);
        } catch (e) {
            logE("Error parsing optional float: " + key);
        }
        return defaultValue;
    }

    function parseOptionalFloatRaw(
        key as String,
        value as PropertyValueType,
        defaultValue as Float?
    ) as Float? {
        try {
            if (value == null) {
                return null;
            }

            // as Float is a bit of a hack, it can be null, but we just want allow us to use our helper
            // (duck typing means at runtime the null passes through fine)
            return parseFloatRaw(key, value, defaultValue as Float);
        } catch (e) {
            logE("Error parsing optional float: " + key);
        }
        return defaultValue;
    }

    function getArraySchema(
        key as String,
        expectedKeys as Array<String>,
        parsers as Array<Method>,
        defaultValue as Array<Dictionary>
    ) as Array<Dictionary> {
        var value = null;
        try {
            value = Application.Storage.getValue(key);
            if (value == null) {
                return defaultValue;
            }

            if (!(value instanceof Array)) {
                return defaultValue;
            }

            // The dict we get is memory mapped, do not use it directly - need to create a copy so we can change the colour type from string to int
            // If we use it directly the storage value gets overwritten
            var result = [] as Array<Dictionary>;
            for (var i = 0; i < value.size(); ++i) {
                var entry = value[i];
                var entryOut = {};
                if (!(entry instanceof Dictionary)) {
                    return defaultValue;
                }

                for (var j = 0; j < expectedKeys.size(); ++j) {
                    var thisKey = expectedKeys[j];
                    var thisParser = parsers[j];
                    // back compat, if the keys are missing we need to default them
                    // old companion app will send route entries without the new keys
                    var keysValue = null;
                    if (entry.hasKey(thisKey)) {
                        keysValue = entry[thisKey];
                    }

                    entryOut[thisKey] = thisParser.invoke(key + "." + i + "." + thisKey, keysValue);
                }
                result.add(entryOut);
            }

            return result;
        } catch (e) {
            logE("Error parsing array: " + key + " " + value);
        }
        return defaultValue;
    }

    (:settingsView)
    function resetDefaultsFromMenu() as Void {
        // calling resetDefaults puts teh new values into our current state
        // we need to load
        // then we need to load them all back
        resetDefaultsInStorage();
        onSettingsChanged(); // reload anything that has changed
    }

    function resetDefaultsInStorage() as Void {
        logT("Resetting settings to default values");
        // resetDefaults flag is cleared by the asDict method
        var defaultSettings = new Settings();
        saveSettings(defaultSettings.asDict());
    }

    function asDict() as Dictionary<String, PropertyValueType> {
        // all these return values should be identical to the storage value
        // eg. nulls are exposed as 0
        // colours are strings

        return (
            ({
                "turnAlertTimeS" => turnAlertTimeS,
                "minTurnAlertDistanceM" => minTurnAlertDistanceM,
                "modeDisplayOrder" => encodeCSV(modeDisplayOrder),
                "maxTrackPoints" => maxTrackPoints,
                "trackStyle" => trackStyle,
                "trackWidth" => trackWidth,
                "showDirectionPointTextUnderIndex" => showDirectionPointTextUnderIndex,
                "centerUserOffsetY" => centerUserOffsetY,
                "mapMoveScreenSize" => mapMoveScreenSize,
                "recalculateIntervalS" => recalculateIntervalS,
                "mode" => mode,
                "drawLineToClosestPoint" => drawLineToClosestPoint,
                "drawLineToClosestTrack" => drawLineToClosestTrack,
                "drawHitBoxes" => drawHitBoxes,
                "showDirectionPoints" => showDirectionPoints,
                "displayLatLong" => displayLatLong,
                "trackColour" => trackColour.format("%X"),
                "trackColour2" => trackColour2.format("%X"),
                "defaultRouteColour" => defaultRouteColour.format("%X"),
                "elevationColour" => elevationColour.format("%X"),
                "userColour" => userColour.format("%X"),
                "metersAroundUser" => metersAroundUser,
                "zoomAtPaceMode" => zoomAtPaceMode,
                "zoomAtPaceSpeedMPS" => zoomAtPaceSpeedMPS,
                "useTrackAsHeadingSpeedMPS" => useTrackAsHeadingSpeedMPS,
                "topDataType" => topDataType,
                "bottomDataType" => bottomDataType,
                "minTrackPointDistanceM" => minTrackPointDistanceM,
                "trackPointReductionMethod" => trackPointReductionMethod,
                "dataFieldTextSize" => dataFieldTextSize,
                "uiMode" => uiMode,
                "elevationMode" => elevationMode,
                "alertType" => alertType,
                "renderMode" => renderMode,
                "fixedLatitude" => fixedLatitude == null ? 0f : fixedLatitude,
                "fixedLongitude" => fixedLongitude == null ? 0f : fixedLongitude,
                "routes" => routesToSave(),
                "routesEnabled" => routesEnabled,
                "displayRouteNames" => displayRouteNames,
                "enableOffTrackAlerts" => enableOffTrackAlerts,
                "offTrackWrongDirection" => offTrackWrongDirection,
                "drawCheverons" => drawCheverons,
                "offTrackAlertsDistanceM" => offTrackAlertsDistanceM,
                "offTrackAlertsMaxReportIntervalS" => offTrackAlertsMaxReportIntervalS,
                "offTrackCheckIntervalS" => offTrackCheckIntervalS,
                "normalModeColour" => normalModeColour.format("%X"),
                "routeMax" => _routeMax,
                "uiColour" => uiColour.format("%X"),
                "debugColour" => debugColour.format("%X"),
                "resetDefaults" => false,
            }) as Dictionary<String, PropertyValueType>
        );
    }

    function saveSettings(settings as Dictionary<String, PropertyValueType>) as Void {
        // should we sanitize this as its untrusted? makes it significantly more annoying to do
        var keys = settings.keys();
        for (var i = 0; i < keys.size(); ++i) {
            var key = keys[i] as String;
            var value = settings[key];
            // for now just blindly trust the users
            // we do reload which sanitizes, but they could break garmins settings page with unexpected types
            try {
                if (key.equals("routes")) {
                    Application.Storage.setValue(
                        key,
                        value as Dictionary<PropertyKeyType, PropertyValueType>
                    );
                } else {
                    Application.Properties.setValue(key, value as PropertyValueType);
                }
            } catch (e) {
                logE("failed property save: " + e.getErrorMessage() + " " + key + ":" + value);
                ++$.globalExceptionCounter;
            }
        }
    }

    function setup() as Void {
        // assert the map choice when we load the settings, as it may have been changed when the app was not running and onSettingsChanged might not be called
        loadSettings();
        setMinTrackPointDistanceMSideEffect();
        recomputeTrackTexture();
        for (var i = 0; i < routes.size(); ++i) {
            var routeId = routes[i]["routeId"] as Number;
            recomputeRouteTexture(i);
        }
    }

    function loadSettingsPart1() as Void {
        turnAlertTimeS = parseNumber("turnAlertTimeS", turnAlertTimeS);
        minTurnAlertDistanceM = parseNumber("minTurnAlertDistanceM", minTurnAlertDistanceM);
        maxTrackPoints = parseNumber("maxTrackPoints", maxTrackPoints);
        trackStyle = parseNumber("trackStyle", trackStyle);
        trackWidth = parseNumber("trackWidth", trackWidth);
        showDirectionPointTextUnderIndex = parseNumber(
            "showDirectionPointTextUnderIndex",
            showDirectionPointTextUnderIndex
        );
        centerUserOffsetY = parseFloat("centerUserOffsetY", centerUserOffsetY);
        mapMoveScreenSize = parseFloat("mapMoveScreenSize", mapMoveScreenSize);
        recalculateIntervalS = parseNumber("recalculateIntervalS", recalculateIntervalS);
        recalculateIntervalS = recalculateIntervalS <= 0 ? 1 : recalculateIntervalS;
        mode = parseNumber("mode", mode);
        modeDisplayOrder = parseCSVString(
            "modeDisplayOrder",
            modeDisplayOrder,
            method(:defaultNumberParser)
        );
        drawLineToClosestPoint = parseBool("drawLineToClosestPoint", drawLineToClosestPoint);
        drawLineToClosestTrack = parseBool("drawLineToClosestTrack", drawLineToClosestTrack);
        drawHitBoxes = parseBool("drawHitBoxes", drawHitBoxes);
        showDirectionPoints = parseBool("showDirectionPoints", showDirectionPoints);
        displayLatLong = parseBool("displayLatLong", displayLatLong);
        displayRouteNames = parseBool("displayRouteNames", displayRouteNames);
        enableOffTrackAlerts = parseBool("enableOffTrackAlerts", enableOffTrackAlerts);
        offTrackWrongDirection = parseBool("offTrackWrongDirection", offTrackWrongDirection);
        drawCheverons = parseBool("drawCheverons", drawCheverons);
        routesEnabled = parseBool("routesEnabled", routesEnabled);
        trackColour = parseColour("trackColour", trackColour);
        trackColour2 = parseColourTransparency("trackColour2", trackColour2, true);
        defaultRouteColour = parseColour("defaultRouteColour", defaultRouteColour);
        elevationColour = parseColour("elevationColour", elevationColour);
        userColour = parseColour("userColour", userColour);
        normalModeColour = parseColour("normalModeColour", normalModeColour);
    }

    function loadSettingsPart2() as Void {
        _routeMax = parseColour("routeMax", _routeMax);
        uiColour = parseColour("uiColour", uiColour);
        debugColour = parseColour("debugColour", debugColour);
        metersAroundUser = parseNumber("metersAroundUser", metersAroundUser);
        zoomAtPaceMode = parseNumber("zoomAtPaceMode", zoomAtPaceMode);
        zoomAtPaceSpeedMPS = parseFloat("zoomAtPaceSpeedMPS", zoomAtPaceSpeedMPS);
        useTrackAsHeadingSpeedMPS = parseFloat(
            "useTrackAsHeadingSpeedMPS",
            useTrackAsHeadingSpeedMPS
        );
        topDataType = parseNumber("topDataType", topDataType);
        bottomDataType = parseNumber("bottomDataType", bottomDataType);
        minTrackPointDistanceM = parseNumber("minTrackPointDistanceM", minTrackPointDistanceM);
        trackPointReductionMethod = parseNumber(
            "trackPointReductionMethod",
            trackPointReductionMethod
        );
        dataFieldTextSize = parseNumber("dataFieldTextSize", dataFieldTextSize);
        uiMode = parseNumber("uiMode", uiMode);
        elevationMode = parseNumber("elevationMode", elevationMode);
        alertType = parseNumber("alertType", alertType);
        renderMode = parseNumber("renderMode", renderMode);

        fixedLatitude = parseOptionalFloat("fixedLatitude", fixedLatitude);
        fixedLongitude = parseOptionalFloat("fixedLongitude", fixedLongitude);
        setFixedPositionWithoutUpdate(fixedLatitude, fixedLongitude);
        routes = getArraySchema(
            "routes",
            ["routeId", "name", "enabled", "colour", "colour2", "reversed", "style", "width"],
            [
                method(:defaultNumberParser),
                method(:emptyString),
                method(:defaultFalse),
                method(:defaultColourParser),
                method(:defaultColourParserTransparent),
                method(:defaultFalse),
                method(:defaultNumberParser),
                method(:defaultNumberParser4),
            ],
            routes
        );
        logT("parsed routes: " + routes);
        offTrackAlertsDistanceM = parseNumber("offTrackAlertsDistanceM", offTrackAlertsDistanceM);
        offTrackAlertsMaxReportIntervalS = parseNumber(
            "offTrackAlertsMaxReportIntervalS",
            offTrackAlertsMaxReportIntervalS
        );
        offTrackCheckIntervalS = parseNumber("offTrackCheckIntervalS", offTrackCheckIntervalS);
    }

    // Load the values initially from storage
    function loadSettings() as Void {
        // fix for a garmin bug where bool settings are not changable if they default to true
        // https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-boolean-properties-with-default-value-true-can-t-be-changed-in-simulator
        var haveDoneFirstLoadSetup = Application.Properties.getValue("haveDoneFirstLoadSetup");
        if (haveDoneFirstLoadSetup instanceof Boolean && !haveDoneFirstLoadSetup) {
            setValue("haveDoneFirstLoadSetup", true);
            resetDefaultsInStorage(); // puts the default values into storage
        }

        var resetDefaults = Application.Properties.getValue("resetDefaults") as Boolean;
        if (resetDefaults) {
            resetDefaultsInStorage(); // puts the default values into storage
            return;
        }

        var returnToUser = Application.Properties.getValue("returnToUser") as Boolean;
        if (returnToUser) {
            Application.Properties.setValue("returnToUser", false);
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.cachedValues.returnToUser();
            }
        }

        logT("loadSettings: Loading all settings");
        loadSettingsPart1();
        loadSettingsPart2();

        // testing coordinates (piper-comanche-wreck)
        // setFixedPosition(-27.297773, 152.753883);
        // // cachedValues.setScale(0.39); // zoomed out a bit
        // cachedValues.setScale(1.96); // really close
    }

    function emptyString(key as String, value as PropertyValueType) as String {
        return parseStringRaw(key, value, "");
    }

    function defaultNumberParser(key as String, value as PropertyValueType) as Number {
        return parseNumberRaw(key, value, 0);
    }

    function defaultNumberParser4(key as String, value as PropertyValueType) as Number {
        return parseNumberRaw(key, value, 4);
    }

    function defaultFalse(key as String, value as PropertyValueType) as Boolean {
        if (value instanceof Boolean) {
            return value;
        }

        return false;
    }

    function defaultColourParser(key as String, value as PropertyValueType) as Number {
        return parseColourRaw(key, value, Graphics.COLOR_RED, false);
    }

    function defaultColourParserTransparent(key as String, value as PropertyValueType) as Number {
        return parseColourRaw(key, value, Graphics.COLOR_TRANSPARENT, true);
    }

    function onSettingsChanged() as Void {
        logT("onSettingsChanged: Setting Changed, loading");
        var oldRoutes = routes;
        var oldRouteMax = _routeMax;
        var oldMaxTrackPoints = maxTrackPoints;
        var oldMinTrackPointDistanceM = minTrackPointDistanceM;
        var oldTrackStyle = trackStyle;
        var oldTrackWidth = trackWidth;
        var oldTrackColour = trackColour;
        var oldTrackColour2 = trackColour2;
        loadSettings();
        // route settins do not work because garmins setting spage cannot edit them
        // when any property is modified, so we have to explain to users not to touch the settings, but we cannot because it looks
        // like garmmins settings are not rendering desciptions anymore :(
        for (var i = 0; i < oldRoutes.size(); ++i) {
            var oldRouteEntry = oldRoutes[i];
            var oldRouteId = oldRouteEntry["routeId"] as Number;

            var routeIndex = getRouteIndexById(oldRouteId);
            if (routeIndex != null) {
                // we have the same route
                var currentRouteEntry = routes[routeIndex];
                if (oldRouteEntry["reversed"] != currentRouteEntry["reversed"]) {
                    var _breadcrumbContextLocal = $._breadcrumbContext;
                    if (_breadcrumbContextLocal != null) {
                        _breadcrumbContextLocal.reverseRouteId(oldRouteId);
                    }
                }

                var currentStyle = currentRouteEntry["style"] as Number;
                var currentWidth = currentRouteEntry["width"] as Number;
                var currentColour = currentRouteEntry["colour"] as Number;
                var currentColour2 = currentRouteEntry["colour2"] as Number;
                if (
                    oldRouteEntry["style"] != currentStyle ||
                    oldRouteEntry["width"] != currentWidth ||
                    oldRouteEntry["colour"] != currentColour ||
                    oldRouteEntry["colour2"] != currentColour2
                ) {
                    recomputeRouteTexture(routeIndex);
                }

                continue;
            }

            // clear the route
            clearRouteFromContext(oldRouteId);
        }

        if (oldRouteMax > _routeMax) {
            routeMaxReduced();
        }

        if (oldMaxTrackPoints != maxTrackPoints) {
            maxTrackPointsChanged();
        }

        if (oldMinTrackPointDistanceM != minTrackPointDistanceM) {
            setMinTrackPointDistanceMSideEffect();
        }

        if (
            oldTrackStyle != trackStyle ||
            oldTrackWidth != trackWidth ||
            oldTrackColour != trackColour ||
            oldTrackColour2 != trackColour2
        ) {
            recomputeTrackTexture();
        }

        setValueSideEffect();
    }
}

// As the number of settings and number of cached variables updated are increasing stack overflows are becoming more common
// I think the main issue is the setBlah methods are meant to be used for on app settings, so they all call into setValue()
// but we need to not do that when we are comming from the context of onSettingsChanged, since we manually call the updateCachedValues at the end of onSettingsChanged

// Error: Stack Overflow Error
// Details: 'Failed invoking <symbol>'
// Time: 2025-05-14T11:00:57Z
// Part-Number: 006-B3704-00
// Firmware-Version: '19.05'
// Language-Code: eng
// ConnectIQ-Version: 5.1.1
// Filename: BreadcrumbDataField
// Appname: BreadcrumbDataField
// Stack:
//   - pc: 0x10002541
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 875
//     Function: getRouteIndexById
//   - pc: 0x100024ef
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 813
//     Function: routeEnabled
//   - pc: 0x10008ec0
//     File: 'BreadcrumbDataField\source\CachedValues.mc'
//     Line: 114
//     Function: calcOuterBoundingBoxFromTrackAndRoutes
//   - pc: 0x1000833a
//     File: 'BreadcrumbDataField\source\CachedValues.mc'
//     Line: 170
//     Function: getNewScaleAndUpdateCenter
//   - pc: 0x100092f2
//     File: 'BreadcrumbDataField\source\CachedValues.mc'
//     Line: 128
//     Function: updateScaleCenterAndMap
//   - pc: 0x100093c8
//     File: 'BreadcrumbDataField\source\CachedValues.mc'
//     Line: 440
//     Function: recalculateAll
//   - pc: 0x100043d6
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 1169
//     Function: updateCachedValues
//   - pc: 0x10004359
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 417
//     Function: setValue
//   - pc: 0x10002a86
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 649
//     Function: setTileLayerMax
//   - pc: 0x10003948
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 541
//     Function: updateMapChoiceChange
//   - pc: 0x10003ff6
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 428
//     Function: setMapChoice
//   - pc: 0x10001e3e
//     File: 'BreadcrumbDataField\source\Settings.mc'
//     Line: 1817
//     Function: onSettingsChanged
//   - pc: 0x10006d39
//     File: 'BreadcrumbDataField\source\BreadcrumbDataFieldApp.mc'
//     Line: 253
//     Function: onPhone
