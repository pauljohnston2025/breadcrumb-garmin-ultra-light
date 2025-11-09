import Toybox.ActivityRecording;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Background;
import Toybox.System;
using Toybox.Time;

var globalExceptionCounter as Number = 0;
var sourceMustBeNativeColorFormatCounter as Number = 0;

(:background)
enum /* Protocol */ {
    // PROTOCOL_ROUTE_DATA = 0, - removed in favour of PROTOCOL_ROUTE_DATA2, users must update companion app
    // PROTOCOL_MAP_TILE = 1, - removed watch has pulled tiles from phone rather than phone pushing for a while
    /*PROTOCOL_REQUEST_LOCATION_LOAD = 2,*/
    /*PROTOCOL_RETURN_TO_USER = 3,*/
    PROTOCOL_REQUEST_SETTINGS = 4,
    PROTOCOL_SAVE_SETTINGS = 5,
    /* PROTOCOL_COMPANION_APP_TILE_SERVER_CHANGED = 6, // generally because a new url has been selected on the companion app  */
    /* PROTOCOL_ROUTE_DATA2 = 7, // an optimised form of PROTOCOL_ROUTE_DATA, so we do not trip the watchdog */
    /* PROTOCOL_CACHE_CURRENT_AREA = 8, */
    PROTOCOL_ROUTE_DATA_UL = 9
}

(:background)
enum /* ProtocolSend */ {
    PROTOCOL_SEND_OPEN_APP = 0,
    PROTOCOL_SEND_SETTINGS = 1,
}

(:background)
class SettingsSent extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }
    function onComplete() {
        logB("Settings sent");
        Background.exit(null);
    }

    function onError() {
        logB("Settings send failed");
        Background.exit(null);
    }
}

var _breadcrumbContext as BreadcrumbContext? = null;
var _view as BreadcrumbDataFieldView? = null; // set in getInitialView so we do not get Circular dependency detected during initialization between '$' and '$.BreadcrumbDataFieldView'.

// to get devices and their memory limits
// cd <homedir>/AppData/Roaming/Garmin/ConnectIQ/Devices/
// cat ./**/compiler.json | grep -E '"type": "datafield"|displayName' -B 1
// we currently need 128.5Kb of memory
// for supported image formats of devices
// cat ./**/compiler.json | grep -E 'imageFormats|displayName' -A 5
// looks like if it does not have a key for "imageFormats" the device only supports native formats and "Source must be native color format" if trying to use anything else.
(:background)
class BreadcrumbDataFieldApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() as Void {
        logT("onSettingsChanged");
        try {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.settings.onSettingsChanged();
            }
        } catch (e) {
            logE("failed onSettingsChange: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(messages as Application.PersistableType) as Void {
        setupGlobals();
        if (messages == null || !(messages instanceof Array)) {
            return;
        }

        for (var i = 0; i < messages.size(); ++i) {
            onPhone(messages[i]);
        }
    }

    function getServiceDelegate() as [ServiceDelegate] {
        return [new BreadcrumbServiceDelegate()];
    }

    // onStop() is called when your application is exiting

    function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        logT("Get initial view");
        setupGlobals();

        if (Background has :registerForPhoneAppMessageEvent) {
            Background.registerForPhoneAppMessageEvent();
        } else {
            // poll it every 5 minutes, this is not really ideal our phone app timeouts will have to wait for 5 minutes on older devices
            var FIVE_MINUTES = new Time.Duration(5 * 60);
            var eventTime = Time.now().add(FIVE_MINUTES);
            Background.registerForTemporalEvent(eventTime);
            logT("registerForTemporalEvent");
        }
        // to open settings to test the simulator has it in an obvious place
        // Settings -> Trigger App Settings (right down the bottom - almost off the screen)
        // then to go back you need to Settings -> Time Out App Settings
        return [$._view as BreadcrumbDataFieldView];
    }

    (:typecheck(disableBackgroundCheck))
    function setupGlobals() as Void {
        if ($._breadcrumbContext != null) {
            return;
        }

        $._breadcrumbContext = new BreadcrumbContext();
        ($._breadcrumbContext as BreadcrumbContext).setup();
        $._view = new BreadcrumbDataFieldView($._breadcrumbContext as BreadcrumbContext);
    }

    (:settingsView,:menu2,:typecheck(disableBackgroundCheck))
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        setupGlobals();
        var settings = new $.SettingsMain();
        return [settings, new $.SettingsMainDelegate(settings)];
    }
}

function onPhone(data as Application.PersistableType) as Void {
    try {
        if (data == null || !(data instanceof Array) || data.size() < 1) {
            logE("Bad message: " + data);
            mustUpdate();
            return;
        }

        var type = data[0] as Number;
        var rawData = data.slice(1, null);

        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            logE("Breadcrumb context was null: " + data);
            return;
        }

        if (type == PROTOCOL_ROUTE_DATA_UL) {
            logT("Parsing route data 2");
            // protocol:
            //  [x, y]...  // latitude <float> and longitude <float> in rectangular coordinates - pre calculated by the app
            if (rawData.size() < 1) {
                logT("Failed to parse route ul data, bad length: " + rawData.size());
                mustUpdate();
                return;
            }

            var routeData = rawData[0] as Array<Float>; // special UL payload that only has x/y coordinates
            if (routeData.size() % ARRAY_POINT_SIZE == 0) {
                var route = _breadcrumbContextLocal.newRoute();
                var routeWrote = route.handleRouteV2(
                    routeData,
                    _breadcrumbContextLocal.cachedValues
                );
                logT("Parsing route data ul complete, wrote to storage: " + routeWrote);
                if (!routeWrote) {
                    _breadcrumbContextLocal.clearRoute();
                }
                return;
            }

            logE(
                "Failed to parse route ul data, bad length: " +
                    rawData.size() +
                    " remainder: " +
                    (rawData.size() % 3)
            );
            mustUpdate();
            return;
        } else if (type == PROTOCOL_SAVE_SETTINGS) {
            logT("got save settings req: " + rawData);
            if (rawData.size() < 1) {
                logE("Failed to parse save settings request, bad length: " + rawData.size());
                return;
            }
            _breadcrumbContextLocal.settings.saveSettings(
                rawData[0] as Dictionary<String, PropertyValueType>
            );
            _breadcrumbContextLocal.settings.onSettingsChanged(); // reload anything that has changed
            return;
        }

        logE("Unknown message type: " + type);
        mustUpdate();
    } catch (e) {
        logE("failed onPhone: " + e.getErrorMessage());
        mustUpdate();
        ++$.globalExceptionCounter;
    }
}

(:background)
class BreadcrumbServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        logB("onTemporalEvent");
        // only called from old devices that can not directly listen for phone app messages
        // this seems to only work on some devices (tested on ven2s), and those devices generally already support onPhoneAppMessage directly from Background.registerForPhoneAppMessageEvent
        // testing on the old 2.4 device (edge_1000) threw an error about registerForPhoneAppMessages symbol not found
        // Im guessing it was only supported in datafields (or maybe background processes) after a certain point
        if (Communications has :registerForPhoneAppMessages) {
            logB("registering for phone messages in onTemporalEvent");
            Communications.registerForPhoneAppMessages(method(:onPhoneAppMessage));
        }

        Background.exit(null);
    }

    private function addWithLimit(oldData as Array, data as Array) as Void {
        oldData.add(data);
        if (oldData.size() > 3) {
            oldData.remove(oldData[0] as Object);
        }
    }

    // returns true if handled false if the data should be added to the background data buffer to be handled on the main process
    // if its handled we will call the background exit function at some point, the caller should not call it
    private function handlePhoneMessage(data as Array?) as Boolean {
        try {
            if (data == null || !(data instanceof Array) || data.size() < 1) {
                logB("Bad message: " + data);
                Background.exit(null);
                return true;
            }

            var type = data[0] as Number;
            /* var rawData = data.slice(1, null); */

            if (type == PROTOCOL_REQUEST_SETTINGS) {
                logB("got send settings req: ");
                Communications.transmit(
                    [PROTOCOL_SEND_SETTINGS, settingsAsDict()],
                    {},
                    new SettingsSent()
                );
                return true;
            }
        } catch (e) {
            logB("Error background: " + e.getErrorMessage());
            return false;
        }
        return false;
    }

    function onPhoneAppMessage(msg as Communications.PhoneAppMessage) as Void {
        logB("Background Service: Received phone message.");
        var data = msg.data as Array?;

        if (handlePhoneMessage(data)) {
            logB("Background Service: handled message.");
            return;
        }

        var oldData = Background.getBackgroundData();
        if (!(oldData instanceof Array)) {
            oldData = [] as Array;
        }

        addWithLimit(oldData as Array, data as Array);
        try {
            Background.exit(oldData as Application.PropertyValueType);
        } catch (e instanceof Background.ExitDataSizeLimitException) {
            var newData = [data];
            Background.exit(newData as Application.PropertyValueType); // just exit with the last message
        }
    }

    function getApp() as BreadcrumbDataFieldApp {
        return Application.getApp() as BreadcrumbDataFieldApp;
    }
}
