import Toybox.Position;
import Toybox.System;
import Toybox.Lang;
import Toybox.StringUtil;
import Toybox.Activity;
import Toybox.Math;
import Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;

const RESTART_STABILITY_POINT_COUNT = 10; // number of points in a row that need to be within RESTART_STABILITY_DISTANCE_M to be considered a valid course
//note: RESTART_STABILITY_POINT_COUNT should be set based on DELAY_COMPUTE_COUNT
// if DELAY_COMPUTE_COUNT = 5 seconds, 10 points give us startup checking for 50 seconds, enough time to get a lock
// max distance allowed to move to be considered a stable point (distance from previous point)
// this needs to be relatively high, since the compute interval could be set quite large, or the user could be  on a motor transport (car, bike, jetski)
// eg. at 80kmph with a 5 second compute interval (that may not run for 3 attempts, 15 seconds)
// 80000/60/60*15 = 333.333
const STABILITY_MAX_DISTANCE_M = 400;
// note: onActivityInfo is called once per second but delayed by DELAY_COMPUTE_COUNT make sure STABILITY_MAX_DISTANCE_M takes that into account
// ie human averge running speed is 3m/s if DELAY_COMPUTE_COUNT is set to 5 STABILITY_MAX_DISTANCE_M should be set to at least 15
const DELAY_COMPUTE_COUNT = 5;
// start as minimum area, and is set to the correct size as points are added
// we want a 'empty' track to not sway the calculation of what to render
// note: we cannot do a const, as it assigns the array or point by reference
function BOUNDING_BOX_DEFAULT() as [Float, Float, Float, Float] {
    return [FLOAT_MAX, FLOAT_MAX, FLOAT_MIN, FLOAT_MIN];
}
function BOUNDING_BOX_CENTER_DEFAULT() as RectangularPoint {
    return new RectangularPoint(0.0f, 0.0f);
}

class BreadcrumbTrack {
    // the data stored on this class is scaled (coordinates are prescaled since scale changes are rare - but renders occur a lot)
    // scaled coordinates will be marked with // SCALED - anything that uses them needs to take scale into account
    // gets updated when track data is loaded, set to first point on track
    // also gets updated whenever we calculate off track
    // there is one oddity with storing lastClosePoint, if the user gets closer to another section of the track we will keep
    // telling them to go back to where they left the track. Acceptable, since the user should do their entire planned route.
    // If they rejoin the track at another point we pick up that they are on track correctly.
    // Multi routes also makes this issue slightly more annoying, in a rare case where a user has left one route, and done another route,
    // when we get close to the first route (if we are still off track) it will snap to the last point they left the route, rather than the start.
    // such a small edge case, that I only found in a random test setup, the performance benefits of caching the lastClosePoint
    // outweigh the chances users will run into this edge case. To solve it we have to process the whole route every time,
    // though we already do this in a multi route setup, we might parse off track alerts for all the other routes then get to the one we are on.
    // single route use case is more common though, so we will optimise for that. in multi route we could store 'last route we were on'
    var coordinates as PointArray = new PointArray(0); // SCALED
    var seenStartupPoints as Number = 0;
    var possibleBadPointsAdded as Number = 0;
    var inRestartMode as Boolean = true;
    var minDistanceMScaled as Float = 5f; // SCALED
    var maxDistanceMScaled as Float = STABILITY_MAX_DISTANCE_M.toFloat(); // SCALED

    var boundingBox as [Float, Float, Float, Float] = BOUNDING_BOX_DEFAULT(); // SCALED -- since the points are used to generate it on failure
    var boundingBoxCenter as RectangularPoint = BOUNDING_BOX_CENTER_DEFAULT(); // SCALED -- since the points are used to generate it on failure
    var distanceTotal as Float = 0f; // SCALED -- since the points are used to generate it on failure
    var _neverStarted as Boolean;

    function initialize(initalPointCount as Number) {
        _neverStarted = true;
        coordinates = new PointArray(initalPointCount);
    }

    function rescale(scaleFactor as Float) as Void {
        boundingBox[0] = boundingBox[0] * scaleFactor;
        boundingBox[1] = boundingBox[1] * scaleFactor;
        boundingBox[2] = boundingBox[2] * scaleFactor;
        boundingBox[3] = boundingBox[3] * scaleFactor;
        distanceTotal = distanceTotal * scaleFactor;
        boundingBoxCenter.rescaleInPlace(scaleFactor);
        coordinates.rescale(scaleFactor);
        // directions.rescale(scaleFactor); no need to rescale they are just an angle and index into coordinates
        minDistanceMScaled = minDistanceMScaled * scaleFactor;
        maxDistanceMScaled = maxDistanceMScaled * scaleFactor;
    }

    function handleRouteV2(
        routeData as Array<Float>,
        cachedValues as CachedValues
    ) as Boolean {
        // trust the app completely
        coordinates._internalArrayBuffer = routeData;
        coordinates._size = routeData.size();
        // we could optimise this further if the app provides us with binding box, center
        // but it makes it really hard to add any more cached data to the route, that the companion app then has to send
        // by making these rectangular coordinates, we skip a huge amount of math converting them from lat/long
        updatePointDataFromAllPoints();
        var wrote = writeToDisk(ROUTE_KEY); // write to disk before we scale, all routes on disk are unscaled
        var currentScale = cachedValues.currentScale;
        if (currentScale != 0f) {
            rescale(currentScale);
        }
        cachedValues.recalculateAll();
        return wrote;
    }

    // writeToDisk should always be in raw meters coordinates // UNSCALED
    function writeToDisk(key as String) as Boolean {
        try {
            Storage.setValue(key + "bb", boundingBox);
            Storage.setValue(key + "bbc", [
                boundingBoxCenter.x,
                boundingBoxCenter.y,
            ]);
            Storage.setValue(
                key + "coords",
                coordinates._internalArrayBuffer as Array<PropertyValueType>
            );
            Storage.setValue(key + "coordsSize", coordinates._size);
            Storage.setValue(key + "distanceTotal", distanceTotal);
        } catch (e) {
            // it will still be in memory, just not persisted, this is bad as the user will think it worked, so return false to indicate error
            logE("failed route save: " + e.getErrorMessage());
            ++$.globalExceptionCounter;
            return false;
        }
        return true;
    }

    static function clearRoute(key as String) as Void {
        // removing any key should cause it to fail to load next time, but would look weird when debugging, so remove all keys
        Storage.deleteValue(key + "bb");
        Storage.deleteValue(key + "bbc");
        Storage.deleteValue(key + "coords");
        Storage.deleteValue(key + "coordsSize");
        Storage.deleteValue(key + "distanceTotal");
    }

    static function readFromDisk(key as String) as BreadcrumbTrack? {
        try {
            var bb = Storage.getValue(key + "bb");
            if (bb == null) {
                return null;
            }
            var bbc = Storage.getValue(key + "bbc");
            if (bbc == null || !(bbc instanceof Array) || bbc.size() != 2) {
                return null;
            }
            var coords = Storage.getValue(key + "coords");
            if (coords == null) {
                return null;
            }

            var coordsSize = Storage.getValue(key + "coordsSize");
            if (coordsSize == null) {
                return null;
            }

            var distanceTotal = Storage.getValue(key + "distanceTotal");
            if (distanceTotal == null) {
                return null;
            }

            var track = new BreadcrumbTrack(0);
            track.boundingBox = bb as [Float, Float, Float, Float];
            if (track.boundingBox.size() != 4) {
                return null;
            }
            track.boundingBoxCenter = new RectangularPoint(
                bbc[0] as Float,
                bbc[1] as Float
            );
            track.coordinates._internalArrayBuffer = coords as Array<Float>;
            track.coordinates._size = coordsSize as Number;
            track.distanceTotal = distanceTotal as Float;
            if (track.coordinates.size() % ARRAY_POINT_SIZE != 0) {
                return null;
            }
            return track;
        } catch (e) {
            return null;
        }
    }

    function lastPoint() as RectangularPoint? {
        return coordinates.lastPoint();
    }

    function firstPoint() as RectangularPoint? {
        return coordinates.firstPoint();
    }

    // new point should be in scale already
    function addPointRaw(newPoint as RectangularPoint, distance as Float) as Boolean {
        distanceTotal += distance;
        coordinates.add(newPoint);
        updateBoundingBox(newPoint);
        // todo have a local ref to settings
        var _breadcrumbContextLocal = $._breadcrumbContext;
        if (_breadcrumbContextLocal != null) {
            if (
                coordinates.restrictPoints(
                    _breadcrumbContextLocal.settings.maxTrackPoints,
                    _breadcrumbContextLocal.settings.trackPointReductionMethod,
                    _breadcrumbContextLocal.cachedValues.currentScale
                )
            ) {
                // a resize occurred, calculate important data again
                updatePointDataFromAllPoints();
                // opt to remove more points then less, to ensure we get the bad point, or 1 of the good points instead
                possibleBadPointsAdded = Math.ceil(possibleBadPointsAdded / 2.0f).toNumber();
                return true;
            }
        }

        return false;
    }

    function updatePointDataFromAllPoints() as Void {
        boundingBox = BOUNDING_BOX_DEFAULT();
        boundingBoxCenter = BOUNDING_BOX_CENTER_DEFAULT();
        distanceTotal = 0f;
        var pointSize = coordinates.pointSize();
        var prevPoint = coordinates.firstPoint();
        if (prevPoint == null) {
            return;
        }
        updateBoundingBox(prevPoint);
        for (var i = 1; i < pointSize; ++i) {
            var point = coordinates.getPoint(i);
            // should never be null, but check to be safe
            if (point == null) {
                break;
            }

            updateBoundingBox(point);
            distanceTotal += prevPoint.distanceTo(point);
            prevPoint = point;
        }
    }

    function updateBoundingBox(point as RectangularPoint) as Void {
        // tmp vars so we can inline the function and remove it
        var boundingBox0Tmp = boundingBox[0] as Float;
        var boundingBox1Tmp = boundingBox[1] as Float;
        var boundingBox2Tmp = boundingBox[2] as Float;
        var boundingBox3Tmp = boundingBox[3] as Float;

        boundingBox0Tmp = minF(boundingBox0Tmp, point.x);
        boundingBox1Tmp = minF(boundingBox1Tmp, point.y);
        boundingBox2Tmp = maxF(boundingBox2Tmp, point.x);
        boundingBox3Tmp = maxF(boundingBox3Tmp, point.y);

        boundingBox[0] = boundingBox0Tmp;
        boundingBox[1] = boundingBox1Tmp;
        boundingBox[2] = boundingBox2Tmp;
        boundingBox[3] = boundingBox3Tmp;

        boundingBoxCenter = new RectangularPoint(
            boundingBox[0] + (boundingBox[2] - boundingBox[0]) / 2.0,
            boundingBox[1] + (boundingBox[3] - boundingBox[1]) / 2.0
        );
    }

    // call on first start
    function onStart() as Void {
        logD("onStart");
        // check from startup, and also clear the current coordinates,
        // anything we got before start is invalid
        coordinates.clear();
        // we also need to reset the bounding box, as its only ever expanded, never reduced
        boundingBox = BOUNDING_BOX_DEFAULT();
        boundingBoxCenter = BOUNDING_BOX_CENTER_DEFAULT();
        distanceTotal = 0f;
        _neverStarted = false;
        onStartResume();
    }

    // when an activity has been stopped, and we have moved and restarted
    function onStartResume() as Void {
        if (_neverStarted) {
            onStart();
        }
        logD("onStartResume");
        // check from startup
        seenStartupPoints = 0;
        possibleBadPointsAdded = 0;
        inRestartMode = true;
    }

    function handlePointAddStartup(newPoint as RectangularPoint) as [Boolean, Boolean] {
        // general plan of this function is
        // add data to both startup array and raw array (so we can start drawing points immediately, without the need for patching both arrays together)
        // on unstable points, remove points from both arrays
        // if the main coordinates array has been sliced in half through `restrictPoints()`
        // this may remove more points than needed, but is not a huge concern
        var lastStartupPoint = coordinates.lastPoint();
        if (lastStartupPoint == null) {
            // nothing to compare against, add the point to both arrays
            return [true, addPointRaw(newPoint, 0f)];
        }

        var stabilityCheckDistance = lastStartupPoint.distanceTo(newPoint);
        if (stabilityCheckDistance < minDistanceMScaled) {
            // point too close, no need to add, but its still a good point
            seenStartupPoints++;
            return [false, false];
        }

        // allow large distances when we have just started, we need to get the first point to work from after a resume
        if (stabilityCheckDistance > maxDistanceMScaled && possibleBadPointsAdded != 0) {
            // we are unstable, remove all our stability check points
            seenStartupPoints = 0;
            coordinates.removeLastCountPoints(possibleBadPointsAdded);
            possibleBadPointsAdded = 0;
            updatePointDataFromAllPoints();
            return [false, true];
        }

        // we are stable, see if we can break out of startup
        seenStartupPoints++;
        possibleBadPointsAdded++;
        if (seenStartupPoints == RESTART_STABILITY_POINT_COUNT) {
            inRestartMode = false;
        }

        // todo this could rescale underneath us, then we would remove the incorrect number of possibleBadPointsAdded if we get a bad point
        // have attempted to handle this on rescale, it will remove 1 extra point if it was an odd number before entering
        return [true, addPointRaw(newPoint, stabilityCheckDistance)];
    }

    function pointFromActivityInfo(activityInfo as Activity.Info) as RectangularPoint? {
        var loc = activityInfo.currentLocation;
        if (loc == null) {
            return null;
        }

        var asDeg = loc.toDegrees();
        var lat = asDeg[0].toFloat();
        var lon = asDeg[1].toFloat();

        return RectangularPoint.latLon2xy(lat, lon);
    }

    // returns [if a new point was added to the track, if a complex operation occurred]
    function onActivityInfo(newScaledPoint as RectangularPoint) as [Boolean, Boolean] {
        // todo only call this when a point is added (some points are skipped on smaller distances)
        // _breadcrumbContext.mapRenderer.loadMapTilesForPosition(newPoint, _breadcrumbContext.breadcrumbRenderer._currentScale);

        if (inRestartMode) {
            return handlePointAddStartup(newScaledPoint);
        }

        var lastPoint = lastPoint();
        if (lastPoint == null) {
            // startup mode should have set at least one point, revert to startup mode, something has gone wrong
            onStartResume();
            return [false, false];
        }

        var distance = lastPoint.distanceTo(newScaledPoint);
        if (distance < minDistanceMScaled) {
            // point too close, so we can skip it
            return [false, false];
        }

        if (distance > maxDistanceMScaled) {
            // it's too far away, and likely a glitch
            return [false, false];
        }

        return [true, addPointRaw(newScaledPoint, distance)];
    }
}
