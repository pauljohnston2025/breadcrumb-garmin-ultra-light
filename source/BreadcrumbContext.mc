import Toybox.Position;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Application;

class BreadcrumbContext {
    var settings as Settings;
    var cachedValues as CachedValues;
    var breadcrumbRenderer as BreadcrumbRenderer;
    var route as BreadcrumbTrack? = null;
    var track as BreadcrumbTrack;

    // Set the label of the data field here.
    function initialize() {
        settings = new Settings();
        cachedValues = new CachedValues(settings);

        track = new BreadcrumbTrack(settings.maxTrackPoints);
        breadcrumbRenderer = new BreadcrumbRenderer(settings, cachedValues);
    }

    function setup() as Void {
        settings.setup(); // we want to make sure everything is done later
        cachedValues.setup();
        me.route = BreadcrumbTrack.readFromDisk(ROUTE_KEY);

        // we pulled in some new route data, make sure we recalculate the bounding box etc.
        cachedValues.recalculateAll();
    }

    function newRoute() as BreadcrumbTrack {
        // we could maybe just not load the route if they are not enabled?
        // but they are pushing a new route from the app for this to happen
        // so forcing the new route to be enabled
        settings.setRoutesEnabled(true);
        me.route = new BreadcrumbTrack(0);
        return me.route;
    }
    
    function clearRoute() as Void {
        me.route = null;
        BreadcrumbTrack.clearRoute(ROUTE_KEY);
    }
}
