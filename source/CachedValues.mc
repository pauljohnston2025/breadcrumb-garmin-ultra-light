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
    var centerPosition as RectangularPoint = new RectangularPoint(0f, 0f, 0f); // scaled to pixels
    var currentScale as Float = 0.0; // pixels per meter so <pixel count> / _currentScale = meters  or  meters * _currentScale = pixels

    // updated whenever we get new activity data with a new heading
    var rotationRad as Float = 0.0f; // heading in radians
    var rotateCos as Float = Math.cos(rotationRad).toFloat() as Float;
    var rotateSin as Float = Math.sin(rotationRad).toFloat() as Float;
    var currentSpeed as Float = -1f;
    var elapsedDistanceM as Float = 0f;
    var currentlyZoomingAroundUser as Boolean = false;

    // updated whenever onlayout changes (audit usages, these should not need to be floats, but sometimes are used to do float math)
    // default to full screen guess
    var physicalScreenWidth as Float = System.getDeviceSettings().screenWidth.toFloat() as Float;
    var physicalScreenHeight as Float = System.getDeviceSettings().screenHeight.toFloat() as Float;
    var minPhysicalScreenDim as Float = -1f;
    var maxPhysicalScreenDim as Float = -1f;
    var xHalfPhysical as Float = physicalScreenWidth / 2f;
    var yHalfPhysical as Float = physicalScreenHeight / 2f;
    var virtualScreenWidth as Float = System.getDeviceSettings().screenWidth.toFloat() as Float;
    var virtualScreenHeight as Float = System.getDeviceSettings().screenHeight.toFloat() as Float;
    var minVirtualScreenDim as Float = -1f;
    var maxVirtualScreenDim as Float = -1f;
    var rotateAroundScreenXOffsetFactoredIn as Float = physicalScreenWidth / 2f;
    var rotateAroundScreenYOffsetFactoredIn as Float = physicalScreenHeight / 2f;
    var rotateAroundMinScreenDim as Float = -1f;

    function initialize(settings as Settings) {
        self._settings = settings;
        // initialised in constructor so they can be inlined
        minPhysicalScreenDim = minF(physicalScreenWidth, physicalScreenHeight);
        maxPhysicalScreenDim = maxF(physicalScreenWidth, physicalScreenHeight);
        minVirtualScreenDim = minF(virtualScreenWidth, virtualScreenHeight);
        maxVirtualScreenDim = maxF(virtualScreenWidth, virtualScreenHeight);
        rotateAroundMinScreenDim = minPhysicalScreenDim;
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

        if(route != null) {
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
            var boundingBox = calcOuterBoundingBoxFromTrackAndRoute(
                _breadcrumbContextLocal.route,
                null
            );
            calcCenterPointForBoundingBox(boundingBox);
            return calcScaleForScreenMeters(renderDistanceM.toFloat());
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
        return getNewScaleFromBoundingBox(boundingBox);
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
        if (activityInfo has :track) {
            var track = activityInfo.track;
            if (currentHeading == null && track != null) {
                currentHeading = track;
            }
        }

        if (currentHeading != null) {
            rotationRad = currentHeading;
            rotateCos = Math.cos(rotationRad).toFloat();
            rotateSin = Math.sin(rotationRad).toFloat();
        }
        var _currentSpeed = activityInfo.currentSpeed;
        if (_currentSpeed != null) {
            currentSpeed = _currentSpeed;
        }

        var _elapsedDistance = activityInfo.elapsedDistance;
        if (_elapsedDistance != null) {
            elapsedDistanceM = _elapsedDistance;
        }

        // we are either in 2 cases
        // if we are moving at some pace check the mode we are in to determine if we
        // zoom in or out
        // or we are not at speed, so invert logic (this allows us to zoom in when
        // stopped, and zoom out when running) mostly useful for cheking close route
        // whilst stopped but also allows quick zoom in before setting manual zoom
        // (rather than having to manually zoom in from the outer level) once zoomed
        // in we lock onto the user position anyway
        var weShouldZoomAroundUser =
            (_settings.zoomAtPaceMode != ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK) ||
            (currentSpeed > _settings.zoomAtPaceSpeedMPS &&
                _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_PACE) ||
            (currentSpeed <= _settings.zoomAtPaceSpeedMPS &&
                _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_STOPPED) ||
            _settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_ALWAYS_ZOOM;
        if (currentlyZoomingAroundUser != weShouldZoomAroundUser) {
            currentlyZoomingAroundUser = weShouldZoomAroundUser;
            updateUserRotationElements(_settings.centerUserOffsetY);
            var ret = updateScaleCenter();
            return ret;
        }

        return false;
    }

    function setScreenSize(width as Number, height as Number) as Void {
        physicalScreenWidth = width.toFloat();
        physicalScreenHeight = height.toFloat();
        minPhysicalScreenDim = minF(physicalScreenWidth, physicalScreenHeight);
        maxPhysicalScreenDim = maxF(physicalScreenWidth, physicalScreenHeight);
        xHalfPhysical = physicalScreenWidth / 2f;
        yHalfPhysical = physicalScreenHeight / 2f;

        updateVirtualScreenSize();
        updateScaleCenter();
    }

    function updateVirtualScreenSize() as Void {
        var centerUserOffsetY = _settings.centerUserOffsetY;

        virtualScreenWidth = physicalScreenWidth; // always the same, just using naming for consistency
        if (_settings.renderMode == RENDER_MODE_UNBUFFERED_ROTATING) {
            if (centerUserOffsetY >= 0.5) {
                virtualScreenHeight = physicalScreenHeight * centerUserOffsetY * 2;
            } else {
                virtualScreenHeight =
                    (physicalScreenHeight - physicalScreenHeight * centerUserOffsetY) * 2;
            }
        } else {
            virtualScreenHeight = physicalScreenHeight;
        }

        minVirtualScreenDim = minF(virtualScreenWidth, virtualScreenHeight);
        maxVirtualScreenDim = maxF(virtualScreenWidth, virtualScreenHeight);

        updateUserRotationElements(centerUserOffsetY);
    }

    function updateUserRotationElements(centerUserOffsetY as Float) as Void {
        if (currentlyZoomingAroundUser) {
            rotateAroundScreenXOffsetFactoredIn = virtualScreenWidth / 2f;
            rotateAroundScreenYOffsetFactoredIn = physicalScreenHeight * centerUserOffsetY;
            rotateAroundMinScreenDim = minVirtualScreenDim;
        } else {
            rotateAroundScreenXOffsetFactoredIn = xHalfPhysical;
            rotateAroundScreenYOffsetFactoredIn = yHalfPhysical;
            rotateAroundMinScreenDim = minPhysicalScreenDim;
        }
    }

    function calcScaleForScreenMeters(maxDistanceM as Float) as Float {
        // we want the whole map to be show on the screen, we have 360 pixels on the
        // venu 2s
        // but this would only work for squares, so 0.75 fudge factor for circle
        // watch face
        return (rotateAroundMinScreenDim / maxDistanceM) * 0.75;
    }

    /** returns the new scale */
    function getNewScaleFromBoundingBox(outerBoundingBox as [Float, Float, Float, Float]) as Float {
        var xDistanceM = outerBoundingBox[2] - outerBoundingBox[0];
        var yDistanceM = outerBoundingBox[3] - outerBoundingBox[1];

        var maxDistanceM = maxF(xDistanceM, yDistanceM);

        if (maxDistanceM == 0f) {
            // show 1m of space to avaoid division by 0
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

        if (abs(currentScale - newScale) < 0.000001) {
            // ignore any minor scale changes, esp if the scale is the same but float == does not work
            return false;
        }

        if (newScale == 0f) {
            return false; // don't allow silly scales
        }

        var scaleFactor = newScale;
        if (currentScale != null && currentScale != 0f) {
            // adjust by old scale
            scaleFactor = newScale / currentScale;
        }

        var route = _breadcrumbContextLocal.route;
        if(route != null) {
            route.rescale(scaleFactor); // rescale all routes, even if they are not enabled
        }
        _breadcrumbContextLocal.track.rescale(scaleFactor);
        var _viewLocal = $._view;
        if (_viewLocal != null) {
            _viewLocal.rescale(scaleFactor);
        }
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
            boundingBox[1] + (boundingBox[3] - boundingBox[1]) / 2.0,
            0.0f
        );

        if (currentScale != 0f) {
            centerPosition.rescaleInPlace(currentScale);
        }
    }
}
