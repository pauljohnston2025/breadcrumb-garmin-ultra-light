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
function startPicker(picker as SettingsFloatPicker or SettingsNumberPicker) as Void {
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

// https://forums.garmin.com/developer/connect-iq/f/discussion/304179/programmatically-set-the-state-of-togglemenuitem
(:settingsView,:menu2)
class SettingsMain extends Rez.Menus.SettingsMain {
    function initialize() {
        Rez.Menus.SettingsMain.initialize();
        rerender();
    }

    function rerender() as Void {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return;
        }
        var settings = _breadcrumbContextLocal.settings;
        safeSetSubLabel(
            me,
            :settingsMainRecalculateIntervalS,
            settings.recalculateIntervalS.toString()
        );
        safeSetSubLabel(
            me,
            :settingsMainCenterUserOffsetY,
            settings.centerUserOffsetY.format("%.2f")
        );
        safeSetToggle(me, :settingsMainDisplayLatLong, settings.displayLatLong);
        safeSetSubLabel(me, :settingsMainMaxTrackPoints, settings.maxTrackPoints.toString());
        safeSetSubLabel(me, :settingsMainTopDataType, getDataTypeString(settings.topDataType));
        safeSetSubLabel(
            me,
            :settingsMainDataFieldTextSize,
            getFontSizeString(settings.dataFieldTextSize)
        );
        safeSetSubLabel(
            me,
            :settingsMainBottomDataType,
            getDataTypeString(settings.bottomDataType)
        );
        safeSetSubLabel(
            me,
            :settingsMainUseTrackAsHeadingSpeedMPS,
            settings.useTrackAsHeadingSpeedMPS.format("%.2f") + "m/s"
        );
        safeSetSubLabel(
            me,
            :settingsMainMapMoveScreenSize,
            settings.mapMoveScreenSize.format("%.2f")
        );
        safeSetSubLabel(
            me,
            :settingsMainMinTrackPointDistanceM,
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
            :settingsMainTrackPointReductionMethod,
            trackPointReductionMethodString
        );
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
            new MenuItem(
                Rez.Strings.clearRoutes,
                "", // sublabel
                :settingsRoutesClearAll,
                {}
            )
        );
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsRoutesEnabled, settings.routesEnabled);
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
        if (itemId == :settingsMainRecalculateIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setRecalculateIntervalS),
                    settings.recalculateIntervalS,
                    view
                )
            );
        } else if (itemId == :settingsMainCenterUserOffsetY) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setCenterUserOffsetY),
                    settings.centerUserOffsetY,
                    view
                )
            );
        } else if (itemId == :settingsMainDisplayLatLong) {
            settings.toggleDisplayLatLong();
            view.rerender();
        } else if (itemId == :settingsMainMaxTrackPoints) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxTrackPoints),
                    settings.maxTrackPoints,
                    view
                )
            );
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
        } else if (itemId == :settingsMainTopDataType) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsDataFieldType(),
                new $.SettingsDataFieldTypeDelegate(view, settings.method(:setTopDataType)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainBottomDataType) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsDataFieldType(),
                new $.SettingsDataFieldTypeDelegate(view, settings.method(:setBottomDataType)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainDataFieldTextSize) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsFontSize(),
                new $.SettingsFontSizeDelegate(view, settings.method(:setDataFieldTextSize)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainMinTrackPointDistanceM) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMinTrackPointDistanceM),
                    settings.minTrackPointDistanceM,
                    view
                )
            );
        } else if (itemId == :settingsMainTrackPointReductionMethod) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsTrackPointReductionMethod(),
                new $.SettingsTrackPointReductionMethodDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainUseTrackAsHeadingSpeedMPS) {
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
class SettingsRoutesDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoutes;
    var settings as Settings;
    function initialize(view as SettingsRoutes, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
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
        } else if (itemId == :settingsRoutesClearAll) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearRoutesConfirmation) as String
            );
            WatchUi.pushView(dialog, new ClearRoutesDelegate(), WatchUi.SLIDE_IMMEDIATE);
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
            _breadcrumbContextLocal.clearRoute();

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
class SettingsDataFieldTypeDelegate extends WatchUi.Menu2InputDelegate {
    private var callback as (Method(value as Number) as Void);
    var parent as SettingsMain;
    function initialize(parent as SettingsMain, _callback as (Method(value as Number) as Void)) {
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
    private var parent as SettingsMain;

    function initialize(parent as SettingsMain, _callback as (Method(value as Number) as Void)) {
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
    private var parent as SettingsMain;

    function initialize(parent as SettingsMain) {
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
