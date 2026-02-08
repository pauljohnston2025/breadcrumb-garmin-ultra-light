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

    function rerender() as Void {}
}

(:settingsView,:menu2)
function getZoomAtPaceModeString(mode as Number) as ResourceId or String {
    switch (mode) {
        case ZOOM_AT_PACE_MODE_PACE:
            return Rez.Strings.zoomAtPaceModePace;
        case ZOOM_AT_PACE_MODE_STOPPED:
            return Rez.Strings.zoomAtPaceModeStopped;
        case ZOOM_AT_PACE_MODE_NEVER_ZOOM:
            return Rez.Strings.zoomAtPaceModeNever;
        case ZOOM_AT_PACE_MODE_ALWAYS_ZOOM:
            return Rez.Strings.zoomAtPaceModeAlways;
        case ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK:
            return Rez.Strings.zoomAtPaceModeRoutesWithoutTrack;
        default:
            return "";
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
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceMode,
            getZoomAtPaceModeString(settings.zoomAtPaceMode)
        );
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
        safeSetSubLabel(
            me,
            :settingsGeneralRecalculateIntervalS,
            settings.recalculateIntervalS.toString()
        );

        safeSetSubLabel(
            me,
            :settingsGeneralCenterUserOffsetY,
            settings.centerUserOffsetY.format("%.2f")
        );
        safeSetToggle(me, :settingsGeneralDisplayLatLong, settings.displayLatLong);
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
        safeSetSubLabel(
            me,
            :settingsTrackUseTrackAsHeadingSpeedMPS,
            settings.useTrackAsHeadingSpeedMPS.format("%.2f") + "m/s"
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

        if (itemId == :settingsMainGeneral) {
            var view = new $.SettingsGeneral();
            WatchUi.pushView(view, new $.SettingsGeneralDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainTrack) {
            var view = new $.SettingsTrack();
            WatchUi.pushView(view, new $.SettingsTrackDelegate(view), WatchUi.SLIDE_IMMEDIATE);
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

    // compiler complains it cannot find the global ones
    // even $.method(:...) does not seem to work
    public function getZoomAtPaceModeStringL(value as Number) as ResourceId or String {
        return getZoomAtPaceModeString(value);
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
                new EnumMenu(
                    Rez.Strings.zoomAtPaceModeTitle,
                    method(:getZoomAtPaceModeStringL),
                    settings.zoomAtPaceMode,
                    ZOOM_AT_PACE_MODE_MAX
                ),
                new $.EnumDelegate(settings.method(:setZoomAtPaceMode), view),
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

        if (itemId == :settingsGeneralRecalculateIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setRecalculateIntervalS),
                    settings.recalculateIntervalS,
                    view
                )
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
class EnumMenu extends WatchUi.Menu2 {
    function initialize(
        title as String or ResourceId,
        callback as (Method(value as Number) as ResourceId or String),
        current as Number,
        max as Number
    ) {
        Menu2.initialize({ :title => title });
        for (var i = 0; i < max; i++) {
            var label = callback.invoke(i);
            if (label.equals("")) {
                continue;
            }
            var isSelected = i == current;
            addItem(new MenuItem(label, isSelected ? "Selected" : "", i, {}));
        }
    }
}

(:settingsView,:menu2)
class EnumDelegate extends WatchUi.Menu2InputDelegate {
    private var callback as (Method(value as Number) as Void);
    private var parent as Renderable;

    function initialize(callback as (Method(value as Number) as Void), parent as Renderable) {
        Menu2InputDelegate.initialize();
        self.callback = callback;
        self.parent = parent;
    }

    function onSelect(item as MenuItem) as Void {
        callback.invoke(item.getId() as Number);
        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
