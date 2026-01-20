import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Application;

typedef Renderable as interface {
    function rerender() as Void;
};

(:settingsView,:menu2)
class SettingsStringPicker extends MyTextPickerDelegate {
    private var callback as (Method(value as String) as Void);
    public var parent as Renderable;
    function initialize(
        callback as (Method(value as String) as Void),
        parent as Renderable,
        picker as TextPickerView
    ) {
        MyTextPickerDelegate.initialize(me.method(:onTextEntered), picker);
        self.callback = callback;
        self.parent = parent;
    }

    function onTextEntered(text as Lang.String) as Lang.Boolean {
        logT("onTextEntered: " + text);

        callback.invoke(text);
        parent.rerender();

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onCancel() as Boolean {
        logT("canceled");
        return true;
    }
}

(:settingsView,:menu2)
function startPicker(
    picker as SettingsFloatPicker or SettingsColourPicker or SettingsNumberPicker
) as Void {
    WatchUi.pushView(
        new $.NumberPickerView(picker),
        new $.NumberPickerDelegate(picker),
        WatchUi.SLIDE_IMMEDIATE
    );
}

(:settingsView,:menu2)
function safeSetSubLabel(
    menu as WatchUi.Menu2,
    id as Object,
    value as String or ResourceId
) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setSubLabel(value);
}

(:settingsView,:menu2)
function safeSetLabel(menu as WatchUi.Menu2, id as Object, value as String or ResourceId) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setLabel(value);
}

(:settingsView,:menu2)
function safeSetToggle(menu as WatchUi.Menu2, id as Object, value as Boolean) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    if (item instanceof WatchUi.ToggleMenuItem) {
        item.setEnabled(value);
    }
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/379406/vertically-center-icon-in-iconmenuitem-using-menu2#pifragment-1298=4
const iconMenuWidthPercent = 0.6;

(:settingsView,:menu2)
class ColourIcon extends WatchUi.Drawable {
    var colour as Number;

    function initialize(colour as Number) {
        Drawable.initialize({});
        self.colour = colour;
    }

    function draw(dc as Graphics.Dc) {
        var iconWidthHeight;

        // Calculate Width Height of Icon based on drawing area
        if (dc.getHeight() > dc.getWidth()) {
            iconWidthHeight = iconMenuWidthPercent * dc.getHeight();
        } else {
            iconWidthHeight = iconMenuWidthPercent * dc.getWidth();
        }

        dc.setColor(colour, colour);
        dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2, iconWidthHeight / 2f);
    }
}

(:settingsView,:menu2)
function safeSetIcon(menu as WatchUi.Menu2, id as Object, value as WatchUi.Drawable) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    // support was added for icons on menuitems in API Level 3.4.0 but IconMenuItem had it from API 3.0.0
    // MenuItem and IconMenuItem, they both support icons
    if (item has :setIcon) {
        item.setIcon(value);
    }
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/304179/programmatically-set-the-state-of-togglemenuitem
(:settingsView,:menu2)
class SettingsMain extends Rez.Menus.SettingsMain {
    function initialize() {
        Rez.Menus.SettingsMain.initialize();
        rerender();
    }

    function rerender() as Void {
    }
}

(:settingsView,:menu2)
function getDataTypeString(type as Number) as ResourceId {
    switch (type) {
        case DATA_TYPE_NONE:
            return Rez.Strings.dataTypeNone;
        case DATA_TYPE_SCALE:
            return Rez.Strings.dataTypeScale;
        case DATA_TYPE_ALTITUDE:
            return Rez.Strings.dataTypeAltitude;
        case DATA_TYPE_AVERAGE_HEART_RATE:
            return Rez.Strings.dataTypeAvgHR;
        case DATA_TYPE_AVERAGE_SPEED:
            return Rez.Strings.dataTypeAvgSpeed;
        case DATA_TYPE_CURRENT_HEART_RATE:
            return Rez.Strings.dataTypeCurHR;
        case DATA_TYPE_CURRENT_SPEED:
            return Rez.Strings.dataTypeCurSpeed;
        case DATA_TYPE_ELAPSED_DISTANCE:
            return Rez.Strings.dataTypeDistance;
        case DATA_TYPE_ELAPSED_TIME:
            return Rez.Strings.dataTypeTime;
        case DATA_TYPE_TOTAL_ASCENT:
            return Rez.Strings.dataTypeAscent;
        case DATA_TYPE_TOTAL_DESCENT:
            return Rez.Strings.dataTypeDescent;
        case DATA_TYPE_AVERAGE_PACE:
            return Rez.Strings.dataTypeAvgPace;
        case DATA_TYPE_CURRENT_PACE:
            return Rez.Strings.dataTypeCurPace;
        default:
            return Rez.Strings.dataTypeNone;
    }
}

(:settingsView,:menu2)
class SettingsZoomAtPace extends Rez.Menus.SettingsZoomAtPace {
    function initialize() {
        Rez.Menus.SettingsZoomAtPace.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var modeString = "";
        switch (settings.zoomAtPaceMode) {
            case ZOOM_AT_PACE_MODE_PACE:
                modeString = Rez.Strings.zoomAtPaceModePace;
                break;
            case ZOOM_AT_PACE_MODE_STOPPED:
                modeString = Rez.Strings.zoomAtPaceModeStopped;
                break;
            case ZOOM_AT_PACE_MODE_NEVER_ZOOM:
                modeString = Rez.Strings.zoomAtPaceModeNever;
                break;
            case ZOOM_AT_PACE_MODE_ALWAYS_ZOOM:
                modeString = Rez.Strings.zoomAtPaceModeAlways;
                break;
            case ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK:
                modeString = Rez.Strings.zoomAtPaceModeRoutesWithoutTrack;
                break;
        }
        safeSetSubLabel(me, :settingsZoomAtPaceMode, modeString);
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceUserMeters,
            settings.metersAroundUser.toString() + "m"
        );
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceMPS,
            settings.zoomAtPaceSpeedMPS.format("%.2f") + "m/s"
        );
    }
}

(:settingsView,:menu2)
class SettingsGeneral extends Rez.Menus.SettingsGeneral {
    function initialize() {
        Rez.Menus.SettingsGeneral.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var modeString = "";
        switch (settings.mode) {
            case MODE_NORMAL:
                modeString = Rez.Strings.trackRouteMode;
                break;
            case MODE_ELEVATION:
                modeString = Rez.Strings.elevationMode;
                break;
            case MODE_MAP_MOVE:
                modeString = Rez.Strings.mapMove;
                break;
            case MODE_DEBUG:
                modeString = Rez.Strings.debug;
                break;
        }
        safeSetSubLabel(me, :settingsGeneralMode, modeString);
        var uiModeString = "";
        switch (settings.uiMode) {
            case UI_MODE_SHOW_ALL:
                uiModeString = Rez.Strings.uiModeShowAll;
                break;
            case UI_MODE_HIDDEN:
                uiModeString = Rez.Strings.uiModeHidden;
                break;
            case UI_MODE_NONE:
                uiModeString = Rez.Strings.uiModeNone;
                break;
        }
        safeSetSubLabel(me, :settingsGeneralModeUiMode, uiModeString);
        var elevationModeString = "";
        switch (settings.elevationMode) {
            case ELEVATION_MODE_STACKED:
                elevationModeString = Rez.Strings.elevationModeStacked;
                break;
            case ELEVATION_MODE_ORDERED_ROUTES:
                elevationModeString = Rez.Strings.elevationModeOrderedRoutes;
                break;
        }
        safeSetSubLabel(me, :settingsGeneralModeElevationMode, elevationModeString);
        safeSetSubLabel(
            me,
            :settingsGeneralRecalculateIntervalS,
            settings.recalculateIntervalS.toString()
        );
        var renderModeString = "";
        switch (settings.renderMode) {
            case RENDER_MODE_UNBUFFERED_ROTATING:
                renderModeString = Rez.Strings.renderModeUnbufferedRotating;
                break;
            case RENDER_MODE_UNBUFFERED_NO_ROTATION:
                renderModeString = Rez.Strings.renderModeNoBufferedNoRotating;
                break;
        }
        safeSetSubLabel(me, :settingsGeneralRenderMode, renderModeString);
        safeSetSubLabel(
            me,
            :settingsGeneralCenterUserOffsetY,
            settings.centerUserOffsetY.format("%.2f")
        );
        safeSetToggle(me, :settingsGeneralDisplayLatLong, settings.displayLatLong);
        safeSetSubLabel(
            me,
            :settingsGeneralMapMoveScreenSize,
            settings.mapMoveScreenSize.format("%.2f")
        );
    }
}

(:settingsView,:menu2)
class SettingsTrack extends Rez.Menus.SettingsTrack {
    function initialize() {
        Rez.Menus.SettingsTrack.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(me, :settingsTrackMaxTrackPoints, settings.maxTrackPoints.toString());
        safeSetSubLabel(
            me,
            :settingsTrackMinTrackPointDistanceM,
            settings.minTrackPointDistanceM.toString()
        );
        var trackPointReductionMethodString = "";
        switch (settings.trackPointReductionMethod) {
            case TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE:
                trackPointReductionMethodString = Rez.Strings.trackPointReductionMethodDownsample;
                break;
            case TRACK_POINT_REDUCTION_METHOD_REUMANN_WITKAM:
                trackPointReductionMethodString =
                    Rez.Strings.trackPointReductionMethodReumannWitkam;
                break;
        }
        safeSetSubLabel(
            me,
            :settingTrackTrackPointReductionMethod,
            trackPointReductionMethodString
        );
        safeSetSubLabel(
            me,
            :settingsTrackUseTrackAsHeadingSpeedMPS,
            settings.useTrackAsHeadingSpeedMPS.format("%.2f") + "m/s"
        );
    }
}

(:settingsView,:menu2)
class SettingsDataField extends Rez.Menus.SettingsDataField {
    function initialize() {
        Rez.Menus.SettingsDataField.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(me, :settingsDataFieldTopDataType, getDataTypeString(settings.topDataType));
        safeSetSubLabel(
            me,
            :settingsDataFieldTextSize,
            getFontSizeString(settings.dataFieldTextSize)
        );
        safeSetSubLabel(
            me,
            :settingsDataFieldBottomDataType,
            getDataTypeString(settings.bottomDataType)
        );
    }
}

(:settingsView,:menu2)
class SettingsAlerts extends Rez.Menus.SettingsAlerts {
    function initialize() {
        Rez.Menus.SettingsAlerts.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        alertsCommon(me, settings);
        safeSetSubLabel(
            me,
            :settingsAlertsOffTrackAlertsMaxReportIntervalS,
            settings.offTrackAlertsMaxReportIntervalS.toString()
        );
    }
}

(:settingsView,:menu2)
function alertsCommon(menu as WatchUi.Menu2, settings as Settings) as Void {
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackDistanceM,
        settings.offTrackAlertsDistanceM.toString()
    );
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackCheckIntervalS,
        settings.offTrackCheckIntervalS.toString()
    );
    safeSetToggle(menu, :settingsAlertsDrawLineToClosestPoint, settings.drawLineToClosestPoint);
    safeSetToggle(menu, :settingsAlertsDrawCheverons, settings.drawCheverons);
    safeSetToggle(menu, :settingsAlertsOffTrackWrongDirection, settings.offTrackWrongDirection);
    safeSetToggle(menu, :settingsAlertsEnabled, settings.enableOffTrackAlerts);
    safeSetSubLabel(menu, :settingsAlertsTurnAlertTimeS, settings.turnAlertTimeS.toString());
    safeSetSubLabel(
        menu,
        :settingsAlertsMinTurnAlertDistanceM,
        settings.minTurnAlertDistanceM.toString()
    );
    var alertTypeString = "";
    switch (settings.alertType) {
        case ALERT_TYPE_TOAST:
            alertTypeString = Rez.Strings.alertTypeToast;
            break;
        case ALERT_TYPE_ALERT:
            alertTypeString = Rez.Strings.alertTypeAlert;
            break;
        case ALERT_TYPE_IMAGE:
            alertTypeString = Rez.Strings.alertTypeImage;
            break;
    }
    safeSetSubLabel(menu, :settingsAlertsAlertType, alertTypeString);
}

(:settingsView,:menu2)
class SettingsAlertsDisabled extends Rez.Menus.SettingsAlertsDisabled {
    function initialize() {
        Rez.Menus.SettingsAlertsDisabled.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        alertsCommon(me, settings);
    }
}

(:settingsView,:menu2)
class SettingsColours extends Rez.Menus.SettingsColours {
    function initialize() {
        Rez.Menus.SettingsColours.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetIcon(me, :settingsColoursTrackColour, new ColourIcon(settings.trackColour));
        safeSetIcon(
            me,
            :settingsColoursDefaultRouteColour,
            new ColourIcon(settings.defaultRouteColour)
        );
        safeSetIcon(me, :settingsColoursUserColour, new ColourIcon(settings.userColour));
        safeSetIcon(me, :settingsColoursElevationColour, new ColourIcon(settings.elevationColour));
        safeSetIcon(
            me,
            :settingsColoursNormalModeColour,
            new ColourIcon(settings.normalModeColour)
        );
        safeSetIcon(me, :settingsColoursUiColour, new ColourIcon(settings.uiColour));
        safeSetIcon(me, :settingsColoursDebugColour, new ColourIcon(settings.debugColour));
    }
}

(:settingsView,:menu2)
class SettingsDebug extends Rez.Menus.SettingsDebug {
    function initialize() {
        Rez.Menus.SettingsDebug.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetToggle(me, :settingsDebugShowPoints, settings.showPoints);
        safeSetToggle(me, :settingsDebugDrawLineToClosestTrack, settings.drawLineToClosestTrack);
        safeSetToggle(
            me,
            :settingsDebugIncludeDebugPageInOnScreenUi,
            settings.includeDebugPageInOnScreenUi
        );
        safeSetToggle(me, :settingsDebugDrawHitBoxes, settings.drawHitBoxes);
        safeSetToggle(me, :settingsDebugShowDirectionPoints, settings.showDirectionPoints);
        safeSetSubLabel(
            me,
            :settingsDebugShowDirectionPointTextUnderIndex,
            settings.showDirectionPointTextUnderIndex.toString()
        );
    }
}

(:settingsView,:menu2)
class SettingsRoute extends Rez.Menus.SettingsRoute {
    var settings as Settings;
    var routeId as Number;
    var parent as SettingsRoutes;
    function initialize(settings as Settings, routeId as Number, parent as SettingsRoutes) {
        Rez.Menus.SettingsRoute.initialize();
        self.settings = settings;
        self.routeId = routeId;
        self.parent = parent;
        rerender();
    }

    function rerender() as Void {
        var name = settings.routeName(routeId);
        setTitle(name);
        safeSetSubLabel(me, :settingsRouteName, name);
        safeSetToggle(me, :settingsRouteEnabled, settings.routeEnabled(routeId));
        safeSetIcon(me, :settingsRouteColour, new ColourIcon(settings.routeColour(routeId)));
        safeSetToggle(me, :settingsRouteReversed, settings.routeReversed(routeId));
        parent.rerender();
    }

    function setName(value as String) as Void {
        settings.setRouteName(routeId, value);
    }

    function setEnabled(value as Boolean) as Void {
        settings.setRouteEnabled(routeId, value);
    }

    function setReversed(value as Boolean) as Void {
        settings.setRouteReversed(routeId, value);
    }

    function routeEnabled() as Boolean {
        return settings.routeEnabled(routeId);
    }

    function routeReversed() as Boolean {
        return settings.routeReversed(routeId);
    }

    function routeColour() as Number {
        return settings.routeColour(routeId);
    }

    function setColour(value as Number) as Void {
        settings.setRouteColour(routeId, value);
    }
}

(:settingsView,:menu2)
class SettingsRoutes extends WatchUi.Menu2 {
    var settings as Settings;
    function initialize(settings as Settings) {
        WatchUi.Menu2.initialize({
            :title => Rez.Strings.routesTitle,
        });
        me.settings = settings;
        setup();
        rerender();
    }

    function setup() as Void {
        addItem(
            new ToggleMenuItem(
                Rez.Strings.routesEnabled,
                "", // sublabel
                :settingsRoutesEnabled,
                settings.routesEnabled,
                {}
            )
        );
        if (!settings.routesEnabled) {
            return;
        }

        addItem(
            new ToggleMenuItem(
                Rez.Strings.displayRouteNamesTitle,
                "", // sublabel
                :settingsDisplayRouteNames,
                settings.displayRouteNames,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.routeMax,
                settings.routeMax().toString(),
                :settingsDisplayRouteMax,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.clearRoutes,
                "", // sublabel
                :settingsRoutesClearAll,
                {}
            )
        );

        for (var i = 0; i < settings.routeMax(); ++i) {
            var routeIndex = settings.getRouteIndexById(i);
            if (routeIndex == null) {
                // do not show routes that are not in the settings array
                // but still show disabled routes that are in the array
                continue;
            }
            var routeName = settings.routeName(i);
            var enabledStr = settings.routeEnabled(i) ? "Enabled" : "Disabled";
            var reversedStr = settings.routeReversed(i) ? "Reversed" : "Forward";
            addItem(
                // do not be tempted to switch this to a menuitem (IconMenuItem is supported since API 3.0.0, MenuItem only supports icons from API 3.4.0)
                new IconMenuItem(
                    routeName.equals("") ? "<unlabeled>" : routeName,
                    enabledStr + " " + reversedStr,
                    i,
                    new ColourIcon(settings.routeColour(i)),
                    {
                        // only get left or right, no center :(
                        :alignment => MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT,
                    }
                )
            );
        }
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsRoutesEnabled, settings.routesEnabled);
        safeSetToggle(me, :settingsDisplayRouteNames, settings.displayRouteNames);
        safeSetSubLabel(me, :settingsDisplayRouteMax, settings.routeMax().toString());
        for (var i = 0; i < settings.routeMax(); ++i) {
            var routeName = settings.routeName(i);
            safeSetLabel(me, i, routeName.equals("") ? "<unlabeled>" : routeName);
            safeSetIcon(me, i, new ColourIcon(settings.routeColour(i)));
            safeSetSubLabel(me, i, settings.routeEnabled(i) ? "Enabled" : "Disabled");
        }
    }
}

(:settingsView,:menu2)
class SettingsMainDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMain;
    function initialize(view as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsMainGeneral) {
            var view = new $.SettingsGeneral();
            WatchUi.pushView(view, new $.SettingsGeneralDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainTrack) {
            var view = new $.SettingsTrack();
            WatchUi.pushView(view, new $.SettingsTrackDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainDataField) {
            var view = new $.SettingsDataField();
            WatchUi.pushView(view, new $.SettingsDataFieldDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainZoomAtPace) {
            var view = new $.SettingsZoomAtPace();
            WatchUi.pushView(view, new $.SettingsZoomAtPaceDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainRoutes) {
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainAlerts) {
            if (settings.offTrackWrongDirection || settings.enableOffTrackAlerts) {
                var view = new SettingsAlerts();
                WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
            var disabledView = new SettingsAlertsDisabled();
            WatchUi.pushView(
                disabledView,
                new $.SettingsAlertsDisabledDelegate(disabledView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainColours) {
            var view = new SettingsColours();
            WatchUi.pushView(view, new $.SettingsColoursDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainDebug) {
            var view = new SettingsDebug();
            WatchUi.pushView(view, new $.SettingsDebugDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainClearStorage) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearStorage) as String
            );
            WatchUi.pushView(dialog, new ClearStorageDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainReturnToUser) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.returnToUserTitle) as String
            );
            WatchUi.pushView(dialog, new ReturnToUserDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainResetDefaults) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.resetDefaults) as String
            );
            WatchUi.pushView(dialog, new ResetSettingsDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView,:menu2)
class ResetSettingsDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.settings.resetDefaults();
            }
        }

        return true; // we always handle it
    }
}

(:settingsView,:menu2)
class ReturnToUserDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.cachedValues.returnToUser();
            }
        }

        return true; // we always handle it
    }
}

(:settingsView,:menu2)
class ClearStorageDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            Application.Storage.clearValues(); // purge the storage, but we have to clean up all our classes that load from storage too
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.clearRoutes(); // also clear the routes to mimic storage being removed
            }
        }

        return true; // we always handle it
    }
}

(:settingsView,:menu2)
class DeleteRouteDelegate extends WatchUi.ConfirmationDelegate {
    var routeId as Number;
    var settings as Settings;
    function initialize(_routeId as Number, _settings as Settings) {
        WatchUi.ConfirmationDelegate.initialize();
        routeId = _routeId;
        settings = _settings;
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal != null) {
                _breadcrumbContextLocal.clearRoute(routeId);
            }

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop route view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView,:menu2)
class SettingsModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsGeneral;
    function initialize(parent as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsModeTrackRoute) {
            settings.setMode(MODE_NORMAL);
        } else if (itemId == :settingsModeElevation) {
            settings.setMode(MODE_ELEVATION);
        } else if (itemId == :settingsModeMapMove) {
            settings.setMode(MODE_MAP_MOVE);
        } else if (itemId == :settingsModeMapDebug) {
            settings.setMode(MODE_DEBUG);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsUiModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsGeneral;
    function initialize(parent as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsUiModeShowall) {
            settings.setUiMode(UI_MODE_SHOW_ALL);
        } else if (itemId == :settingsUiModeHidden) {
            settings.setUiMode(UI_MODE_HIDDEN);
        } else if (itemId == :settingsUiModeNone) {
            settings.setUiMode(UI_MODE_NONE);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsElevationModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsGeneral;
    function initialize(parent as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsElevationModeStacked) {
            settings.setElevationMode(ELEVATION_MODE_STACKED);
        } else if (itemId == :settingsElevationModeOrderedRoutes) {
            settings.setElevationMode(ELEVATION_MODE_ORDERED_ROUTES);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsAlertTypeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsAlerts or SettingsAlertsDisabled;
    function initialize(parent as SettingsAlerts or SettingsAlertsDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsAlertTypeToast) {
            settings.setAlertType(ALERT_TYPE_TOAST);
        } else if (itemId == :settingsAlertTypeAlert) {
            settings.setAlertType(ALERT_TYPE_ALERT);
        } else if (itemId == :settingsAlertTypeImage) {
            settings.setAlertType(ALERT_TYPE_IMAGE);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsRenderModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsGeneral;
    function initialize(parent as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsRenderModeUnbufferedRotating) {
            settings.setRenderMode(RENDER_MODE_UNBUFFERED_ROTATING);
        } else if (itemId == :settingsRenderModeNoBufferedNoRotating) {
            settings.setRenderMode(RENDER_MODE_UNBUFFERED_NO_ROTATION);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsZoomAtPaceDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsZoomAtPace;
    function initialize(view as SettingsZoomAtPace) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsZoomAtPaceMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsZoomAtPaceMode(),
                new $.SettingsZoomAtPaceModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsZoomAtPaceUserMeters) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMetersAroundUser),
                    settings.metersAroundUser,
                    view
                )
            );
        } else if (itemId == :settingsZoomAtPaceMPS) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setZoomAtPaceSpeedMPS),
                    settings.zoomAtPaceSpeedMPS,
                    view
                )
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsGeneralDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsGeneral;
    function initialize(view as SettingsGeneral) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsGeneralMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMode(),
                new $.SettingsModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralModeUiMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsUiMode(),
                new $.SettingsUiModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralModeElevationMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsElevationMode(),
                new $.SettingsElevationModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralRecalculateIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setRecalculateIntervalS),
                    settings.recalculateIntervalS,
                    view
                )
            );
        } else if (itemId == :settingsGeneralRenderMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsRenderMode(),
                new $.SettingsRenderModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsGeneralCenterUserOffsetY) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setCenterUserOffsetY),
                    settings.centerUserOffsetY,
                    view
                )
            );
        } else if (itemId == :settingsGeneralDisplayLatLong) {
            settings.toggleDisplayLatLong();
            view.rerender();
        } else if (itemId == :settingsGeneralMapMoveScreenSize) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setMapMoveScreenSize),
                    settings.mapMoveScreenSize,
                    view
                )
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsTrackDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsTrack;
    function initialize(view as SettingsTrack) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsTrackMaxTrackPoints) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxTrackPoints),
                    settings.maxTrackPoints,
                    view
                )
            );
        } else if (itemId == :settingsTrackMinTrackPointDistanceM) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMinTrackPointDistanceM),
                    settings.minTrackPointDistanceM,
                    view
                )
            );
        } else if (itemId == :settingTrackTrackPointReductionMethod) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsTrackPointReductionMethod(),
                new $.SettingsTrackPointReductionMethodDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsTrackUseTrackAsHeadingSpeedMPS) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setUseTrackAsHeadingSpeedMPS),
                    settings.useTrackAsHeadingSpeedMPS,
                    view
                )
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsDataFieldDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDataField;
    function initialize(view as SettingsDataField) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsDataFieldTopDataType) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsDataFieldType(),
                new $.SettingsDataFieldTypeDelegate(view, settings.method(:setTopDataType)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsDataFieldBottomDataType) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsDataFieldType(),
                new $.SettingsDataFieldTypeDelegate(view, settings.method(:setBottomDataType)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsDataFieldTextSize) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsFontSize(),
                new $.SettingsFontSizeDelegate(view, settings.method(:setDataFieldTextSize)),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsRoutesDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoutes;
    var settings as Settings;
    function initialize(view as SettingsRoutes, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }

    function setRouteMax(value as Number) as Void {
        settings.setRouteMax(value);
        // reload our ui, so any route changes are cleared
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // remove the number picker view
        reloadView();
        WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the number picker to remove
    }

    function reloadView() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var view = new $.SettingsRoutes(settings);
        WatchUi.pushView(
            view,
            new $.SettingsRoutesDelegate(view, settings),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRoutesEnabled) {
            settings.toggleRoutesEnabled();
            reloadView();
        } else if (itemId == :settingsDisplayRouteNames) {
            settings.toggleDisplayRouteNames();
            view.rerender();
        } else if (itemId == :settingsDisplayRouteMax) {
            startPicker(new SettingsNumberPicker(method(:setRouteMax), settings.routeMax(), view));
        } else if (itemId == :settingsRoutesClearAll) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearRoutes1) as String
            );
            WatchUi.pushView(dialog, new ClearRoutesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }

        // itemId should now be the route storageIndex = routeId
        if (itemId instanceof Number) {
            var thisView = new $.SettingsRoute(settings, itemId, view);
            WatchUi.pushView(
                thisView,
                new $.SettingsRouteDelegate(thisView, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsRouteDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoute;
    var settings as Settings;
    function initialize(view as SettingsRoute, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRouteName) {
            var pickerView = new TextPickerView(
                "Route Name",
                "",
                0,
                256,
                settings.routeName(view.routeId)
            );
            var picker = new SettingsStringPicker(view.method(:setName), view, pickerView);
            WatchUi.pushView(pickerView, picker, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsRouteEnabled) {
            if (view.routeEnabled()) {
                view.setEnabled(false);
            } else {
                view.setEnabled(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteReversed) {
            if (view.routeReversed()) {
                view.setReversed(false);
            } else {
                view.setReversed(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteColour) {
            startPicker(
                new SettingsColourPicker(view.method(:setColour), view.routeColour(), view)
            );
        } else if (itemId == :settingsRouteDelete) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.routeDelete) as String
            );
            WatchUi.pushView(
                dialog,
                new DeleteRouteDelegate(view.routeId, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsZoomAtPaceModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsZoomAtPace;
    function initialize(parent as SettingsZoomAtPace) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsZoomAtPaceModePace) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_PACE);
        } else if (itemId == :settingsZoomAtPaceModeStopped) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_STOPPED);
        } else if (itemId == :settingsZoomAtPaceModeNever) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_NEVER_ZOOM);
        } else if (itemId == :settingsZoomAtPaceModeAlways) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_ALWAYS_ZOOM);
        } else if (itemId == :settingsZoomAtPaceModeRoutesWithoutTrack) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
function checkAlertViewDisplay(
    oldView as SettingsAlerts or SettingsAlertsDisabled,
    settings as Settings
) as Void {
    if (
        oldView instanceof SettingsAlerts &&
        !settings.offTrackWrongDirection &&
        !settings.enableOffTrackAlerts
    ) {
        var view = new SettingsAlertsDisabled();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDisabledDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else if (
        oldView instanceof SettingsAlertsDisabled &&
        (settings.offTrackWrongDirection || settings.enableOffTrackAlerts)
    ) {
        var view = new SettingsAlerts();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else {
        oldView.rerender();
    }
}

(:settingsView,:menu2)
function onSelectAlertCommon(
    itemId as Object?,
    settings as Settings,
    view as SettingsAlerts or SettingsAlertsDisabled
) as Void {
    if (itemId == :settingsAlertsDrawLineToClosestPoint) {
        settings.toggleDrawLineToClosestPoint();
        view.rerender();
    } else if (itemId == :settingsAlertsEnabled) {
        settings.toggleEnableOffTrackAlerts();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsOffTrackWrongDirection) {
        settings.toggleOffTrackWrongDirection();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsDrawCheverons) {
        settings.toggleDrawCheverons();
        view.rerender();
    } else if (itemId == :settingsAlertsOffTrackDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackAlertsDistanceM),
                settings.offTrackAlertsDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsTurnAlertTimeS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setTurnAlertTimeS),
                settings.turnAlertTimeS,
                view
            )
        );
    } else if (itemId == :settingsAlertsMinTurnAlertDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setMinTurnAlertDistanceM),
                settings.minTurnAlertDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsOffTrackCheckIntervalS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackCheckIntervalS),
                settings.offTrackCheckIntervalS,
                view
            )
        );
    } else if (itemId == :settingsAlertsAlertType) {
        WatchUi.pushView(
            new $.Rez.Menus.SettingsAlertType(),
            new $.SettingsAlertTypeDelegate(view),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}

(:settingsView,:menu2)
class SettingsAlertsDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlerts;
    function initialize(view as SettingsAlerts) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();

        if (itemId == :settingsAlertsOffTrackAlertsMaxReportIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setOffTrackAlertsMaxReportIntervalS),
                    settings.offTrackAlertsMaxReportIntervalS,
                    view
                )
            );
            return;
        }

        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView,:menu2)
class SettingsAlertsDisabledDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlertsDisabled;
    function initialize(view as SettingsAlertsDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView,:menu2)
class DummyView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
}

(:settingsView,:menu2)
class ClearRoutesDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var _breadcrumbContextLocal = $._breadcrumbContext;
            if (_breadcrumbContextLocal == null) {
                breadcrumbContextWasNull();
                return true;
            }
            var settings = _breadcrumbContextLocal.settings;
            _breadcrumbContextLocal.clearRoutes();

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView,:menu2)
class SettingsColoursDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsColours;
    function initialize(view as SettingsColours) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsColoursTrackColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setTrackColour),
                    settings.trackColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursDefaultRouteColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setDefaultRouteColour),
                    settings.defaultRouteColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursElevationColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setElevationColour),
                    settings.elevationColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursUserColour) {
            startPicker(
                new SettingsColourPicker(settings.method(:setUserColour), settings.userColour, view)
            );
        } else if (itemId == :settingsColoursNormalModeColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setNormalModeColour),
                    settings.normalModeColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursUiColour) {
            startPicker(
                new SettingsColourPicker(settings.method(:setUiColour), settings.uiColour, view)
            );
        } else if (itemId == :settingsColoursDebugColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setDebugColour),
                    settings.debugColour,
                    view
                )
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsDebugDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDebug;
    function initialize(view as SettingsDebug) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var itemId = item.getId();
        if (itemId == :settingsDebugShowPoints) {
            settings.toggleShowPoints();
            view.rerender();
        } else if (itemId == :settingsDebugDrawLineToClosestTrack) {
            settings.toggleDrawLineToClosestTrack();
            view.rerender();
        } else if (itemId == :settingsDebugIncludeDebugPageInOnScreenUi) {
            settings.toggleIncludeDebugPageInOnScreenUi();
            view.rerender();
        } else if (itemId == :settingsDebugDrawHitBoxes) {
            settings.toggleDrawHitBoxes();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPoints) {
            settings.toggleShowDirectionPoints();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPointTextUnderIndex) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setShowDirectionPointTextUnderIndex),
                    settings.showDirectionPointTextUnderIndex,
                    view
                )
            );
        }
    }
}

(:settingsView,:menu2)
class SettingsDataFieldTypeDelegate extends WatchUi.Menu2InputDelegate {
    private var callback as (Method(value as Number) as Void);
    var parent as SettingsDataField;
    function initialize(
        parent as SettingsDataField,
        _callback as (Method(value as Number) as Void)
    ) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
        me.callback = _callback;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsDataTypeNone) {
            callback.invoke(DATA_TYPE_NONE);
        } else if (itemId == :settingsDataTypeScale) {
            callback.invoke(DATA_TYPE_SCALE);
        } else if (itemId == :settingsDataTypeAltitude) {
            callback.invoke(DATA_TYPE_ALTITUDE);
        } else if (itemId == :settingsDataTypeAvgHR) {
            callback.invoke(DATA_TYPE_AVERAGE_HEART_RATE);
        } else if (itemId == :settingsDataTypeAvgSpeed) {
            callback.invoke(DATA_TYPE_AVERAGE_SPEED);
        } else if (itemId == :settingsDataTypeCurHR) {
            callback.invoke(DATA_TYPE_CURRENT_HEART_RATE);
        } else if (itemId == :settingsDataTypeCurSpeed) {
            callback.invoke(DATA_TYPE_CURRENT_SPEED);
        } else if (itemId == :settingsDataTypeDistance) {
            callback.invoke(DATA_TYPE_ELAPSED_DISTANCE);
        } else if (itemId == :settingsDataTypeTime) {
            callback.invoke(DATA_TYPE_ELAPSED_TIME);
        } else if (itemId == :settingsDataTypeAscent) {
            callback.invoke(DATA_TYPE_TOTAL_ASCENT);
        } else if (itemId == :settingsDataTypeDescent) {
            callback.invoke(DATA_TYPE_TOTAL_DESCENT);
        } else if (itemId == :settingsDataTypeAvgPace) {
            callback.invoke(DATA_TYPE_AVERAGE_PACE);
        } else if (itemId == :settingsDataTypeCurPace) {
            callback.invoke(DATA_TYPE_CURRENT_PACE);
        }
        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
function getFontSizeString(font as Number) as ResourceId {
    switch (font) {
        case Graphics.FONT_XTINY:
            return Rez.Strings.fontXTiny;
        case Graphics.FONT_TINY:
            return Rez.Strings.fontTiny;
        case Graphics.FONT_SMALL:
            return Rez.Strings.fontSmall;
        case Graphics.FONT_MEDIUM:
            return Rez.Strings.fontMedium;
        case Graphics.FONT_LARGE:
            return Rez.Strings.fontLarge;
        // numbers cannot be used because we add letters too, and the numbers fonts only renders numbers
        // case Graphics.FONT_NUMBER_MILD: return Rez.Strings.fontNumMild;
        // case Graphics.FONT_NUMBER_MEDIUM: return Rez.Strings.fontNumMedium;
        // case Graphics.FONT_NUMBER_HOT: return Rez.Strings.fontNumHot;
        // case Graphics.FONT_NUMBER_THAI_HOT: return Rez.Strings.fontNumThaiHot;
        // <!-- System Fonts seem to be almost the same, so save the space for the strings and code-->
        // case Graphics.FONT_SYSTEM_XTINY: return Rez.Strings.fontSysXTiny;
        // case Graphics.FONT_SYSTEM_TINY: return Rez.Strings.fontSysTiny;
        // case Graphics.FONT_SYSTEM_SMALL: return Rez.Strings.fontSysSmall;
        // case Graphics.FONT_SYSTEM_MEDIUM: return Rez.Strings.fontSysMedium;
        // case Graphics.FONT_SYSTEM_LARGE: return Rez.Strings.fontSysLarge;
        default:
            return Rez.Strings.fontMedium;
    }
}

(:settingsView,:menu2)
class SettingsFontSizeDelegate extends WatchUi.Menu2InputDelegate {
    private var callback as (Method(value as Number) as Void);
    private var parent as SettingsDataField;

    function initialize(
        parent as SettingsDataField,
        _callback as (Method(value as Number) as Void)
    ) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
        me.callback = _callback;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();

        // Map the symbol ID back to the Graphics Font constant
        var fontValue = Graphics.FONT_MEDIUM; // Default

        if (itemId == :fontXTiny) {
            fontValue = Graphics.FONT_XTINY;
        } else if (itemId == :fontTiny) {
            fontValue = Graphics.FONT_TINY;
        } else if (itemId == :fontSmall) {
            fontValue = Graphics.FONT_SMALL;
        } else if (itemId == :fontMedium) {
            fontValue = Graphics.FONT_MEDIUM;
        } else if (itemId == :fontLarge) {
            fontValue = Graphics.FONT_LARGE;
        }
        /* else if (itemId == :fontNumMild) {
            fontValue = Graphics.FONT_NUMBER_MILD;
        } else if (itemId == :fontNumMedium) {
            fontValue = Graphics.FONT_NUMBER_MEDIUM;
        } else if (itemId == :fontNumHot) {
            fontValue = Graphics.FONT_NUMBER_HOT;
        } else if (itemId == :fontNumThaiHot) {
            fontValue = Graphics.FONT_NUMBER_THAI_HOT;
        } else if (itemId == :fontSysXTiny) {
            fontValue = Graphics.FONT_SYSTEM_XTINY;
        }
         else if (itemId == :fontSysTiny) {
            fontValue = Graphics.FONT_SYSTEM_TINY;
        } else if (itemId == :fontSysSmall) {
            fontValue = Graphics.FONT_SYSTEM_SMALL;
        } else if (itemId == :fontSysMedium) {
            fontValue = Graphics.FONT_SYSTEM_MEDIUM;
        } else if (itemId == :fontSysLarge) {
            fontValue = Graphics.FONT_SYSTEM_LARGE;
        }*/

        callback.invoke(fontValue);
        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
class SettingsTrackPointReductionMethodDelegate extends WatchUi.Menu2InputDelegate {
    private var parent as SettingsTrack;

    function initialize(parent as SettingsTrack) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();

        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        var value = TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE;

        if (itemId == :trackPointReductionMethodDownsample) {
            value = TRACK_POINT_REDUCTION_METHOD_DOWNSAMPLE;
        } else if (itemId == :trackPointReductionMethodReumannWitkam) {
            value = TRACK_POINT_REDUCTION_METHOD_REUMANN_WITKAM;
        }

        settings.setTrackPointReductionMethod(value);
        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
