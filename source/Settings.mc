import Toybox.Application;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Application;
import Toybox.Communications;
import Toybox.WatchUi;
import Toybox.PersistedContent;

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

(:background)
function settingsAsDict() as Dictionary<String, PropertyValueType> {
    return (
        ({
            "maxTrackPoints" => Application.Properties.getValue("maxTrackPoints"),
            "centerUserOffsetY" => Application.Properties.getValue("centerUserOffsetY"),
            "recalculateIntervalS" => Application.Properties.getValue("recalculateIntervalS"),
            "drawLineToClosestPoint" => Application.Properties.getValue("drawLineToClosestPoint"),
            "showPoints" => Application.Properties.getValue("showPoints"),
            "displayLatLong" => Application.Properties.getValue("displayLatLong"),
            "metersAroundUser" => Application.Properties.getValue("metersAroundUser"),
            "zoomAtPaceMode" => Application.Properties.getValue("zoomAtPaceMode"),
            "zoomAtPaceSpeedMPS" => Application.Properties.getValue("zoomAtPaceSpeedMPS"),
            "uiMode" => Application.Properties.getValue("uiMode"),
            "alertType" => Application.Properties.getValue("alertType"),
            "routesEnabled" => Application.Properties.getValue("routesEnabled"),
            "enableOffTrackAlerts" => Application.Properties.getValue("enableOffTrackAlerts"),
            "offTrackWrongDirection" => Application.Properties.getValue("offTrackWrongDirection"),
            "offTrackAlertsDistanceM" => Application.Properties.getValue("offTrackAlertsDistanceM"),
            "offTrackAlertsMaxReportIntervalS" => Application.Properties.getValue(
                "offTrackAlertsMaxReportIntervalS"
            ),
            "offTrackCheckIntervalS" => Application.Properties.getValue("offTrackCheckIntervalS"),
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
    // Renders around the users position
    var metersAroundUser as Number = 500; // keep this fairly high by default, too small and the map tiles start to go blurry
    var centerUserOffsetY as Float = 0.5f; // fraction of the screen to move the user down the page 0.5 - user appears in center, 0.75 - user appears 3/4 down the screen. Useful to see more of the route in front of the user.
    var zoomAtPaceMode as Number = ZOOM_AT_PACE_MODE_PACE;
    var zoomAtPaceSpeedMPS as Float = 1.0; // meters per second
    var uiMode as Number = UI_MODE_SHOW_ALL;
    
    var routesEnabled as Boolean = true;
    
    // note this only works if a single track is enabled (multiple tracks would always error)
    var enableOffTrackAlerts as Boolean = true;
    var offTrackAlertsDistanceM as Number = 20;
    var offTrackAlertsMaxReportIntervalS as Number = 60;
    var offTrackCheckIntervalS as Number = 15;
    var offTrackWrongDirection as Boolean = false;

    var drawLineToClosestPoint as Boolean = true;
    var displayLatLong as Boolean = true;

    // how many seconds should we wait before even considering the next point
    // changes in speed/angle/zoom are not effected by this number. Though maybe they should be?
    var recalculateIntervalS as Number = 5;
    var maxTrackPoints as Number = 100;

    // these settings can only be modified externally, but we cache them for faster/easier lookup
    // https://www.youtube.com/watch?v=LasrD6SZkZk&ab_channel=JaylaB
    var distanceImperialUnits as Boolean =
        System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;

    (:settingsView,:menu2)
    function setUiMode(_uiMode as Number) as Void {
        uiMode = _uiMode;
        setValue("uiMode", uiMode);
    }

    function setValue(key as String, value as PropertyValueType) as Void {
        Application.Properties.setValue(key, value);
        setValueSideEffect();
    }

    function setValueSideEffect() as Void {
        updateCachedValues();
        updateViewSettings();
    }

    function setZoomAtPaceMode(_zoomAtPaceMode as Number) as Void {
        zoomAtPaceMode = _zoomAtPaceMode;
        setValue("zoomAtPaceMode", zoomAtPaceMode);
    }

    (:settingsView,:menu2)
    function setZoomAtPaceSpeedMPS(mps as Float) as Void {
        zoomAtPaceSpeedMPS = mps;
        setValue("zoomAtPaceSpeedMPS", zoomAtPaceSpeedMPS);
    }

    (:settingsView,:menu2)
    function setMetersAroundUser(value as Number) as Void {
        metersAroundUser = value;
        setValue("metersAroundUser", metersAroundUser);
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

    function maxTrackPointsChanged() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.track.coordinates.restrictPointsToMaxMemory(maxTrackPoints);
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
    function setDisplayLatLong(value as Boolean) as Void {
        displayLatLong = value;
        setValue("displayLatLong", displayLatLong);
    }
    
    function setRoutesEnabled(_routesEnabled as Boolean) as Void {
        routesEnabled = _routesEnabled;
        setValue("routesEnabled", routesEnabled);
    }

    (:settingsView,:menu2)
    function toggleDrawLineToClosestPoint() as Void {
        drawLineToClosestPoint = !drawLineToClosestPoint;
        setValue("drawLineToClosestPoint", drawLineToClosestPoint);
    }
    (:settingsView,:menu2)
    function toggleDisplayLatLong() as Void {
        displayLatLong = !displayLatLong;
        setValue("displayLatLong", displayLatLong);
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
    function toggleRoutesEnabled() as Void {
        routesEnabled = !routesEnabled;
        setValue("routesEnabled", routesEnabled);
    }

    function nextZoomAtPaceMode() as Void {
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

    function updateCachedValues() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        _breadcrumbContextLocal.cachedValues.recalculateAll();
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

    function resetDefaults() as Void {
        logT("Resetting settings to default values");
        // clear the flag first thing in case of crash we do not want to try clearing over and over
        setValue("resetDefaults", false);

        // note: this pulls the defaults from whatever we have at the top of the file these may differ from the defaults in properties.xml
        var defaultSettings = new Settings();
        maxTrackPoints = defaultSettings.maxTrackPoints;
        centerUserOffsetY = defaultSettings.centerUserOffsetY;
        drawLineToClosestPoint = defaultSettings.drawLineToClosestPoint;
        displayLatLong = defaultSettings.displayLatLong;
        metersAroundUser = defaultSettings.metersAroundUser;
        zoomAtPaceMode = defaultSettings.zoomAtPaceMode;
        zoomAtPaceSpeedMPS = defaultSettings.zoomAtPaceSpeedMPS;
        uiMode = defaultSettings.uiMode;
        routesEnabled = defaultSettings.routesEnabled;
        enableOffTrackAlerts = defaultSettings.enableOffTrackAlerts;
        offTrackWrongDirection = defaultSettings.offTrackWrongDirection;
        offTrackAlertsDistanceM = defaultSettings.offTrackAlertsDistanceM;
        offTrackAlertsMaxReportIntervalS = defaultSettings.offTrackAlertsMaxReportIntervalS;
        offTrackCheckIntervalS = defaultSettings.offTrackCheckIntervalS;

        // raw write the settings to disk
        var dict = asDict();
        saveSettings(dict);

        // purge storage, all routes and caches
        Application.Storage.clearValues();
        updateCachedValues();
        updateViewSettings();
    }

    function asDict() as Dictionary<String, PropertyValueType> {
        // all these return values should be identical to the storage value
        // eg. nulls are exposed as 0
        // colours are strings

        return (
            ({
                "maxTrackPoints" => maxTrackPoints,
                "centerUserOffsetY" => centerUserOffsetY,
                "recalculateIntervalS" => recalculateIntervalS,
                "drawLineToClosestPoint" => drawLineToClosestPoint,
                "displayLatLong" => displayLatLong,
                "metersAroundUser" => metersAroundUser,
                "zoomAtPaceMode" => zoomAtPaceMode,
                "zoomAtPaceSpeedMPS" => zoomAtPaceSpeedMPS,
                "uiMode" => uiMode,
                "routesEnabled" => routesEnabled,
                "enableOffTrackAlerts" => enableOffTrackAlerts,
                "offTrackWrongDirection" => offTrackWrongDirection,
                "offTrackAlertsDistanceM" => offTrackAlertsDistanceM,
                "offTrackAlertsMaxReportIntervalS" => offTrackAlertsMaxReportIntervalS,
                "offTrackCheckIntervalS" => offTrackCheckIntervalS,
                "resetDefaults" => false,
            }) as Dictionary<String, PropertyValueType>
        );
    }

    function saveSettings(settings as Dictionary<String, PropertyValueType>) as Void {
        // should we sanitize this as its untrusted? makes it significantly more annoying to do
        var keys = settings.keys();
        for (var i = 0; i < keys.size(); ++i) {
            var key = keys[i] as Application.PropertyKeyType;
            var value = settings[key];
            // for now just blindly trust the users
            // we do reload which sanitizes, but they could break garmins settings page with unexpected types
            try {
                Application.Properties.setValue(key, value as PropertyValueType);
            } catch (e) {
                logE("failed property save: " + e.getErrorMessage() + " " + key + ":" + value);
                ++$.globalExceptionCounter;
            }
        }
    }

    function setup() as Void {
        // assert the map choice when we load the settings, as it may have been changed when the app was not running and onSettingsChanged might not be called
        loadSettings();
    }

    function loadSettingsPart1() as Void {
        maxTrackPoints = parseNumber("maxTrackPoints", maxTrackPoints);
        centerUserOffsetY = parseFloat("centerUserOffsetY", centerUserOffsetY);
        recalculateIntervalS = parseNumber("recalculateIntervalS", recalculateIntervalS);
        recalculateIntervalS = recalculateIntervalS <= 0 ? 1 : recalculateIntervalS;
        drawLineToClosestPoint = parseBool("drawLineToClosestPoint", drawLineToClosestPoint);
        displayLatLong = parseBool("displayLatLong", displayLatLong);
        enableOffTrackAlerts = parseBool("enableOffTrackAlerts", enableOffTrackAlerts);
        offTrackWrongDirection = parseBool("offTrackWrongDirection", offTrackWrongDirection);
        routesEnabled = parseBool("routesEnabled", routesEnabled);
    }

    function loadSettingsPart2() as Void {
        metersAroundUser = parseNumber("metersAroundUser", metersAroundUser);
        zoomAtPaceMode = parseNumber("zoomAtPaceMode", zoomAtPaceMode);
        zoomAtPaceSpeedMPS = parseFloat("zoomAtPaceSpeedMPS", zoomAtPaceSpeedMPS);
        uiMode = parseNumber("uiMode", uiMode);

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
            resetDefaults(); // pulls from our defaults
        }

        var resetDefaults = Application.Properties.getValue("resetDefaults") as Boolean;
        if (resetDefaults) {
            resetDefaults();
            return;
        }

        logT("loadSettings: Loading all settings");
        loadSettingsPart1();
        loadSettingsPart2();

        // testing coordinates (piper-comanche-wreck)
        // // cachedValues.setScale(0.39); // zoomed out a bit
        // cachedValues.setScale(1.96); // really close
    }

    function onSettingsChanged() as Void {
        logT("onSettingsChanged: Setting Changed, loading");
        var oldMaxTrackPoints = maxTrackPoints;
        loadSettings();

        if (oldMaxTrackPoints != maxTrackPoints) {
            maxTrackPointsChanged();
        }

        setValueSideEffect();
    }
}
