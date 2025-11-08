import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

// see BreadcrumbDataFieldView if touch stops working
class BreadcrumbDataFieldDelegate extends WatchUi.InputDelegate {
    var _breadcrumbContext as BreadcrumbContext;

    function initialize(breadcrumbContext as BreadcrumbContext) {
        InputDelegate.initialize();
        _breadcrumbContext = breadcrumbContext;
    }

    // see BreadcrumbDataFieldView if touch stops working
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        // logT("got tap (x,y): (" + evt.getCoordinates()[0] + "," +
        //                evt.getCoordinates()[1] + ")");

        var coords = evt.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        var renderer = _breadcrumbContext.breadcrumbRenderer;
        var settings = _breadcrumbContext.settings;

        var hitboxSize = renderer.hitboxSize;

        if (settings.uiMode == UI_MODE_NONE) {
            return false;
        }

        if (x < hitboxSize) {
            // left of screen
            settings.nextZoomAtPaceMode();
            return true;
        }

        return false;
    }
}
