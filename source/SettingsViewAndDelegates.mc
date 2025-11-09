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
function startPicker(
    picker as SettingsFloatPicker or SettingsNumberPicker
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

