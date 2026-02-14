import Toybox.Application;
import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Activity;

// https://developer.garmin.com/connect-iq/reference-guides/monkey-c-reference/
// Monkey C is a message-passed language. When a function is called, the virtual machine searches a hierarchy at runtime in the following order to find the function:
// Instance members of the class
// Members of the superclass
// Static members of the class
// Members of the parent module, and the parent modules up to the global namespace
// Members of the superclass’s parent module up to the global namespace
class CachedValues {
    private var _settings as Settings;

    // cache some important maths to make everything faster
    // things set to -1 are updated on the first layout/calculate call

    // updated whenever we change zoom level (speed changes, zoom at pace mode etc.)
    var centerPosition as RectangularPoint = new RectangularPoint(0f, 0f); // scaled to pixels
    var currentScale as Float = 0.0; // pixels per meter so <pixel count> / _currentScale = meters  or  meters * _currentScale = pixels

    // updated whenever we get new activity data with a new heading
    var rotateCos as Float = Math.cos(0f).toFloat() as Float;
    var rotateSin as Float = Math.sin(0f).toFloat() as Float;
    private var _lastStableHeading as Float = 0.0f;
    var currentSpeed as Float = -1f;
    var currentlyZoomingAroundUser as Boolean = false;
    var headingPoint1 as RectangularPoint = new RectangularPoint(0f, 0f);
    var headingPoint2 as RectangularPoint = new RectangularPoint(0f, 0f);

    // updated whenever onlayout changes (audit usages, these should not need to be floats, but sometimes are used to do float math)
    // default to full screen guess
    var xHalfPhysical as Float = System.getDeviceSettings().screenWidth as Number / 2f;
    var yHalfPhysical as Float = System.getDeviceSettings().screenHeight as Number / 2f;

    var rotateAroundScreenXOffsetFactoredIn as Float = xHalfPhysical;
    var rotateAroundScreenYOffsetFactoredIn as Float = yHalfPhysical;

    function initialize(settings as Settings) {
        self._settings = settings;
    }

    function setup() as Void {
        recalculateAll();
    }

    function calcOuterBoundingBoxFromTrackAndRoute(
        route as BreadcrumbTrack?,
        trackBoundingBox as [Float, Float, Float, Float]?
    ) as [Float, Float, Float, Float] {
        var scaleDivisor = currentScale;
        if (currentScale == 0f) {
            scaleDivisor = 1; // use raw coordinates
        }

        // we need to make a new object, otherwise we will modify the one thats passed in
        var outerBoundingBox = BOUNDING_BOX_DEFAULT();
        if (trackBoundingBox != null) {
            outerBoundingBox[0] = trackBoundingBox[0] / scaleDivisor;
            outerBoundingBox[1] = trackBoundingBox[1] / scaleDivisor;
            outerBoundingBox[2] = trackBoundingBox[2] / scaleDivisor;
            outerBoundingBox[3] = trackBoundingBox[3] / scaleDivisor;
        }

        if (route != null && _settings.routesEnabled) {
            // tmp vars so we can inline the function and remove it
            var outerBoundingBox0Tmp = outerBoundingBox[0] as Float;
            var outerBoundingBox1Tmp = outerBoundingBox[1] as Float;
            var outerBoundingBox2Tmp = outerBoundingBox[2] as Float;
            var outerBoundingBox3Tmp = outerBoundingBox[3] as Float;

            var routeBoundingBox0Tmp = route.boundingBox[0] as Float;
            var routeBoundingBox1Tmp = route.boundingBox[1] as Float;
            var routeBoundingBox2Tmp = route.boundingBox[2] as Float;
            var routeBoundingBox3Tmp = route.boundingBox[3] as Float;

            outerBoundingBox0Tmp = minF(routeBoundingBox0Tmp / scaleDivisor, outerBoundingBox0Tmp);
            outerBoundingBox1Tmp = minF(routeBoundingBox1Tmp / scaleDivisor, outerBoundingBox1Tmp);
            outerBoundingBox2Tmp = maxF(routeBoundingBox2Tmp / scaleDivisor, outerBoundingBox2Tmp);
            outerBoundingBox3Tmp = maxF(routeBoundingBox3Tmp / scaleDivisor, outerBoundingBox3Tmp);

            outerBoundingBox[0] = outerBoundingBox0Tmp;
            outerBoundingBox[1] = outerBoundingBox1Tmp;
            outerBoundingBox[2] = outerBoundingBox2Tmp;
            outerBoundingBox[3] = outerBoundingBox3Tmp;
        }

        return outerBoundingBox;
    }

    /** returns true if a rescale occurred */
    function updateScaleCenter() as Boolean {
        var newScale = getNewScaleAndUpdateCenter();
        var rescaleOccurred = handleNewScale(newScale);
        return rescaleOccurred;
    }

    /** returns the new scale */
    function getNewScaleAndUpdateCenter() as Float {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return 0f;
        }

        if (currentlyZoomingAroundUser) {
            var renderDistanceM = _settings.metersAroundUser;
            var lastPoint = _breadcrumbContextLocal.track.coordinates.lastPoint();
            if (lastPoint != null) {
                centerPosition = lastPoint;
                return calcScaleForScreenMeters(renderDistanceM.toFloat());
            }
            // we are zooming around the user, but we do not have a last track point
            // resort to using bounding box
        }

        var boundingBox = calcOuterBoundingBoxFromTrackAndRoute(
            _breadcrumbContextLocal.route,
            // if no roues we will try and render the track instead
            _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK &&
                _breadcrumbContextLocal.route != null
                ? null
                : optionalTrackBoundingBox()
        );
        calcCenterPointForBoundingBox(boundingBox);
        var newScale = getNewScaleFromBoundingBox(boundingBox);
        // this is a special case that makes us zoom more when we are in the 'overview'
        // its also pretty bad when 'never' or 'routes' zoom at pace mode zooms in really small
        // so treating renderDistanceM as a min render distance (can still manually zoom in)
        // ie. with ZOOM_AT_PACE_MODE_PACE
        // - move a little bit (only 6m)
        // - stop moving so we are not currentlyZoomingAroundUser
        // - normally this should zoom out to show the entire map area, but if we have no routes it actually zooms in to a blurry map (since its a bounding box of 6m)

        // if we are not in a dynamic mode, we will do exactly what the user asks
        // if we are in a dynamic mode, cap the 'zoomed out' zoom level so it always shows more area, never less
        var scaleFromRenderDistance = calcScaleForScreenMeters(_settings.metersAroundUser.toFloat());
        if (scaleFromRenderDistance < newScale) {
            newScale = scaleFromRenderDistance;
        }

        return newScale;
    }

    function optionalTrackBoundingBox() as [Float, Float, Float, Float]? {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return null;
        }

        return _breadcrumbContextLocal.track.coordinates.lastPoint() == null
            ? null
            : _breadcrumbContextLocal.track.boundingBox;
    }

    function calculateHeading(p1 as RectangularPoint, p2 as RectangularPoint) as Float {
        // atan2(dx, dy) for North-up orientation
        return Math.atan2(p2.x - p1.x, p2.y - p1.y).toFloat();
    }

    function handleHeadingPoint(newPoint as RectangularPoint) as Void {
        if (headingPoint2.distanceTo(newPoint) > 5) {
            headingPoint1 = headingPoint2;
            headingPoint2 = newPoint;
        }
    }

    /** returns true if a rescale occurred */
    function onActivityInfo(activityInfo as Activity.Info) as Boolean {
        // logT(
        //     "store heading, current speed etc. so we can know how to render the "
        //     + "map");
        // garmin might already do this for us? the docs say
        // track:
        // The current track in radians.
        // Track is the direction of travel in radians based on GPS movement. If supported by the device, this provides compass orientation when stopped.
        // currentHeading :
        // The true north referenced heading in radians.
        // This provides compass orientation if it is supported by the device.
        // based on some of the posts here, its better to use currentHeading if we want our compas to work whilst not moving, and track is only supported on some devices
        // https://forums.garmin.com/developer/connect-iq/f/discussion/258978/currentheading
        var currentHeading = activityInfo.currentHeading;
        var _currentSpeed = activityInfo.currentSpeed;
        if (_currentSpeed != null) {
            currentSpeed = _currentSpeed;
            if (currentSpeed >= _settings.useTrackAsHeadingSpeedMPS) {
                if (currentSpeed != 0.0f) {
                    var rawHeading = calculateHeading(headingPoint1, headingPoint2);

                    // 2. DYNAMIC ALPHA SMOOTHING
                    // Calculate how much we are turning
                    var diff = (rawHeading - _lastStableHeading).abs();
                    if (diff > Math.PI) {
                        diff = 2 * Math.PI - diff;
                    } // Handle wrap-around

                    var alpha;
                    if (diff > 0.52) {
                        // > 30 degrees: We are turning!
                        alpha = 0.9f; // Respond almost instantly
                    } else if (diff > 0.17) {
                        // > 10 degrees: Slight curve
                        alpha = 0.5f; // Balanced
                    } else {
                        alpha = 0.15f; // Moving straight: Heavy smoothing to kill jitter
                    }

                    // 3. VECTOR BLENDING (Prevents 360/0 degree glitches)
                    var newX =
                        (1.0 - alpha) * Math.cos(_lastStableHeading) + alpha * Math.cos(rawHeading);
                    var newY =
                        (1.0 - alpha) * Math.sin(_lastStableHeading) + alpha * Math.sin(rawHeading);

                    _lastStableHeading = Math.atan2(newY, newX).toFloat();
                    currentHeading = _lastStableHeading;
                } else {
                    currentHeading = _lastStableHeading;
                }
            }
        }

        if (currentHeading != null) {
            rotateCos = Math.cos(currentHeading).toFloat();
            rotateSin = Math.sin(currentHeading).toFloat();
        }

        // we are either in 2 cases
        // if we are moving at some pace check the mode we are in to determine if we
        // zoom in or out
        // or we are not at speed, so invert logic (this allows us to zoom in when
        // stopped, and zoom out when running) mostly useful for checking close route
        // whilst stopped but also allows quick zoom in before setting manual zoom
        // (rather than having to manually zoom in from the outer level) once zoomed
        // in we lock onto the user position anyway
        var weShouldZoomAroundUser =
            (currentSpeed > _settings.zoomAtPaceSpeedMPS &&
                _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_PACE) ||
            (currentSpeed <= _settings.zoomAtPaceSpeedMPS &&
                _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_STOPPED) ||
            _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_ALWAYS_ZOOM;
        if (currentlyZoomingAroundUser != weShouldZoomAroundUser) {
            currentlyZoomingAroundUser = weShouldZoomAroundUser;
            updateVirtualScreenSize();
            var ret = updateScaleCenter();
            return ret;
        }

        return false;
    }

    function setScreenSize(width as Number, height as Number) as Void {
        xHalfPhysical = width.toFloat()/2f;
        yHalfPhysical = height.toFloat() /2f;

        updateVirtualScreenSize();
        updateScaleCenter();
    }

    function updateVirtualScreenSize() as Void {
        rotateAroundScreenXOffsetFactoredIn = xHalfPhysical;
        if (currentlyZoomingAroundUser) {
            rotateAroundScreenYOffsetFactoredIn = yHalfPhysical * 2 * _settings.centerUserOffsetY;
        } else {
            rotateAroundScreenYOffsetFactoredIn = yHalfPhysical;
        }
    }

    function calcScaleForScreenMeters(maxDistanceM as Float) as Float {
        // we want the whole map to be show on the screen, we have 360 pixels on the
        // venu 2s
        // but this would only work for squares, so 0.75 (* 2 since we are using half measures) fudge factor for circle
        // watch face
        return (minF(xHalfPhysical, yHalfPhysical) * 1.5 / maxDistanceM) ;
    }

    /** returns the new scale */
    function getNewScaleFromBoundingBox(outerBoundingBox as [Float, Float, Float, Float]) as Float {
        var xDistanceM = outerBoundingBox[2] - outerBoundingBox[0];
        var yDistanceM = outerBoundingBox[3] - outerBoundingBox[1];

        var maxDistanceM = maxF(xDistanceM, yDistanceM);

        if (maxDistanceM == 0f) {
            // show 1m of space to avoid division by 0
            maxDistanceM = 1f;
        }

        return calcScaleForScreenMeters(maxDistanceM);
    }

    /** returns true if the scale changed */
    function handleNewScale(newScale as Float) as Boolean {
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal == null) {
            breadcrumbContextWasNull();
            return false;
        }

        if ((currentScale - newScale).abs() < 0.000001) {
            // ignore any minor scale changes, esp if the scale is the same but float == does not work
            return false;
        }

        if (newScale == 0f) {
            return false; // don't allow silly scales
        }

        var scaleFactor = newScale;
        logT("moving to scale: " + newScale);
        if (currentScale != null && currentScale != 0f) {
            // adjust by old scale
            scaleFactor = newScale / currentScale;
        }

        var route = _breadcrumbContextLocal.route;
        if (route != null) {
            route.rescale(scaleFactor); // rescale all routes, even if they are not enabled
        }
        _breadcrumbContextLocal.track.rescale(scaleFactor);
        centerPosition.rescaleInPlace(scaleFactor);

        currentScale = newScale;
        return true;
    }

    function recalculateAll() as Void {
        logT("recalculating all cached values from settings/routes change");
        updateVirtualScreenSize();
        updateScaleCenter();
    }

    function calcCenterPointForBoundingBox(boundingBox as [Float, Float, Float, Float]) as Void {
        centerPosition = new RectangularPoint(
            boundingBox[0] + (boundingBox[2] - boundingBox[0]) / 2.0,
            boundingBox[1] + (boundingBox[3] - boundingBox[1]) / 2.0
        );

        if (currentScale != 0f) {
            centerPosition.rescaleInPlace(currentScale);
        }
    }
}
