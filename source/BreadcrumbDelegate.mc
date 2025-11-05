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
        var halfHitboxSize = hitboxSize / 2.0f;

        if (settings.uiMode == UI_MODE_NONE) {
            return false;
        }

        // perhaps put this into new class to handle touch events, and have a
        // renderer for that ui would allow us to switch out ui and handle touched
        // differently also will alow setting the scren height
        if (inHitbox(x, y, renderer.modeSelectX, renderer.modeSelectY, halfHitboxSize)) {
            // top right
            settings.nextMode();
            return true;
        }

        //  else if (
        //     y > renderer.mapEnabledY - halfHitboxSize &&
        //     y < renderer.mapEnabledY + halfHitboxSize &&
        //     x > renderer.mapEnabledX - halfHitboxSize &&
        //     x < renderer.mapEnabledX + halfHitboxSize
        // ) {
        //     // botom right
        //     // map enable/disable now handled above
        //     // if (settings.mode == MODE_NORMAL) {
        //     //     settings.toggleMapEnabled();
        //     //     return true;
        //     // }

        //     return false;
        // }
        // todo update these to use inHitbox ?
        else if (x < hitboxSize) {
            // left of screen
            settings.nextZoomAtPaceMode();
            return true;
        }

        return false;
    }
}
