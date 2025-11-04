import Toybox.Activity;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

const NO_SMOKING_RADIUS = 10.0f;
const DESIRED_SCALE_PIXEL_WIDTH as Float = 100.0f;
const DESIRED_ELEV_SCALE_PIXEL_WIDTH as Float = 50.0f;
// note sure why this has anything to do with DESIRED_SCALE_PIXEL_WIDTH, should just be whatever tile layer 0 equates to for the screen size
const MIN_SCALE as Float = DESIRED_SCALE_PIXEL_WIDTH / 1000000000.0f;

const ARROW_SIZE = 20.0f;
const ARROW_PEN_WIDTH = 2;
const ARROW_WALL_OFFSET = 6.0f;

class BreadcrumbRenderer {
    // todo put into ui class
    var _clearRouteProgress as Number = 0;
    var settings as Settings;
    var _cachedValues as CachedValues;

    // units in mm (float/int)
    const SCALE_KEYS as Array<Number> = [
        1000, 5000, 10000, 20000, 30000, 40000, 50000, 100000, 250000, 500000, 1000000, 2000000,
        3000000, 4000000, 5000000, 10000000, 20000000, 30000000, 40000000, 50000000, 100000000,
        500000000, 1000000000, 2000000000,
    ];
    const SCALE_VALUES as Array<String> = [
        "1m",
        "5m",
        "10m",
        "20m",
        "30m",
        "40m",
        "50m",
        "100m",
        "250m",
        "500m",
        "1km",
        "2km",
        "3km",
        "4km",
        "5km",
        "10km",
        "20km",
        "30km",
        "40km",
        "50km",
        "100km",
        "500km",
        "1000km",
        "2000km",
    ];

    // key is in mm
    const SCALE_KEYS_IMPERIAL as Array<Number> = [
        1524, 3048, 7620, 15240, 30480, 76200, 152400, 304800, 804672, 1609344, 3218688, 8046720,
        16093440, 32186880, 80467200, 160934400, 804672000, 1609344000,
    ];
    const SCALE_VALUES_IMPERIAL as Array<String> = [
        "5ft",
        "10ft",
        "25ft",
        "50ft",
        "100ft",
        "250ft",
        "500ft",
        "1000ft",
        "0.5mi",
        "1mi",
        "2mi",
        "5mi",
        "10mi",
        "20mi",
        "50mi",
        "100mi",
        "500mi",
        "1000mi",
    ];

    // elevation scales are in mm
    const ELEVATION_SCALE_KEYS as Array<Number> = [
        1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 5000, 10000, 20000, 30000, 40000, 50000, 100000,
        250000, 500000,
    ];
    const ELEVATION_SCALE_VALUES as Array<String> = [
        "1mm",
        "2mm",
        "5mm",
        "1cm",
        "2.5cm",
        "5cm",
        "10cm",
        "25cm",
        "50cm",
        "1m",
        "5m",
        "10m",
        "20m",
        "30m",
        "40m",
        "50m",
        "100m",
        "250m",
        "500m",
    ];

    // key is in mm
    const ELEVATION_SCALE_KEYS_IMPERIAL as Array<Number> = [
        25, 51, 127, 254, 305, 1524, 3048, 6096, 15240, 30480, 76200, 152400, 304800,
    ];
    const ELEVATION_SCALE_VALUES_IMPERIAL as Array<String> = [
        "1in",
        "2in",
        "5in",
        "10in",
        "1ft",
        "5ft",
        "10ft",
        "20ft",
        "50ft",
        "100ft",
        "250ft",
        "500ft",
        "1000ft",
    ];

    // benchmark same track loaded (just render track no activity running) using
    // average time over 1min of benchmark
    // (just route means we always have a heap of points, and a small track does not bring the average down)
    // 13307us or 17718us - renderTrack manual code (rotateCos, rotateSin)
    // 15681us or 17338us or 11996us - renderTrack manual code (rotateCos, rotateSin)  - use local variables might be faster lookup?
    // 11162us or 18114us - rotateCos, rotateSin and hard code 180 as xhalf/yhalf
    // 22297us - renderTrack Graphics.AffineTransform

    function initialize(settings as Settings, cachedValues as CachedValues) {
        self.settings = settings;
        _cachedValues = cachedValues;

        if (
            SCALE_KEYS.size() != SCALE_VALUES.size() ||
            SCALE_KEYS_IMPERIAL.size() != SCALE_VALUES_IMPERIAL.size() ||
            ELEVATION_SCALE_KEYS.size() != ELEVATION_SCALE_VALUES.size() ||
            ELEVATION_SCALE_KEYS_IMPERIAL.size() != ELEVATION_SCALE_VALUES_IMPERIAL.size()
        ) {
            throw new Exception();
        }
    }

    function getScaleSizeGeneric(
        scale as Float,
        desiredWidth as Float,
        scaleKeys as Array<Number>,
        scaleValues as Array<String>
    ) as [Float, Number, String] {
        // get the closest without going over
        // The keys array is already sorted, so we get the first element as the default
        var foundDistanceKey = scaleKeys[0];
        var foundName = scaleValues[0];
        var foundPixelWidth = 0f;

        for (var i = 0; i < scaleKeys.size(); ++i) {
            var distanceKey = scaleKeys[i];
            var testPixelWidth = (distanceKey.toFloat() / 1000) * scale;
            if (testPixelWidth > desiredWidth) {
                break;
            }

            foundPixelWidth = testPixelWidth;
            foundDistanceKey = distanceKey;
            foundName = scaleValues[i];
        }

        return [foundPixelWidth, foundDistanceKey, foundName];
    }

    function renderCurrentScale(dc as Dc) as Void {
        var scaleKeys = settings.distanceImperialUnits ? SCALE_KEYS_IMPERIAL : SCALE_KEYS;
        var scaleValues = settings.distanceImperialUnits ? SCALE_VALUES_IMPERIAL : SCALE_VALUES;
        var scaleData = getScaleSizeGeneric(
            _cachedValues.currentScale,
            DESIRED_SCALE_PIXEL_WIDTH,
            scaleKeys as Array<Number>,
            scaleValues as Array<String>
        );
        var pixelWidth = scaleData[0];
        var foundName = scaleData[2];

        if (pixelWidth == 0f) {
            return;
        }

        var y = _cachedValues.physicalScreenHeight - 25;
        dc.setColor(settings.normalModeColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(
            _cachedValues.xHalfPhysical - pixelWidth / 2.0f,
            y,
            _cachedValues.xHalfPhysical + pixelWidth / 2.0f,
            y
        );
        dc.drawText(
            _cachedValues.xHalfPhysical,
            y - 30,
            Graphics.FONT_XTINY,
            foundName,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    (:noUnbufferedRotations)
    function renderLineFromLastPointToRoute(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {}

    // points should already be scaled
    (:unbufferedRotations)
    function renderLineFromLastPointToRoute(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var lastPointUnrotatedX = lastPoint.x - centerPosition.x;
        var lastPointUnrotatedY = lastPoint.y - centerPosition.y;
        var lastPointRotatedX =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * lastPointUnrotatedX -
            rotateSin * lastPointUnrotatedY;
        var lastPointRotatedY =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * lastPointUnrotatedX + rotateCos * lastPointUnrotatedY);

        var offTrackPointUnrotatedX = offTrackPoint.x - centerPosition.x;
        var offTrackPointUnrotatedY = offTrackPoint.y - centerPosition.y;
        var offTrackPointRotatedX =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * offTrackPointUnrotatedX -
            rotateSin * offTrackPointUnrotatedY;
        var offTrackPointRotatedY =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * offTrackPointUnrotatedX + rotateCos * offTrackPointUnrotatedY);

        dc.setPenWidth(4);
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.drawLine(
            lastPointRotatedX,
            lastPointRotatedY,
            offTrackPointRotatedX,
            offTrackPointRotatedY
        );
    }

    function renderLineFromLastPointToRouteUnrotated(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var lastPointUnrotatedX =
            rotateAroundScreenXOffsetFactoredIn + (lastPoint.x - centerPosition.x);
        var lastPointUnrotatedY =
            rotateAroundScreenYOffsetFactoredIn - (lastPoint.y - centerPosition.y);

        var offTrackPointUnrotatedX =
            rotateAroundScreenXOffsetFactoredIn + (offTrackPoint.x - centerPosition.x);
        var offTrackPointUnrotatedY =
            rotateAroundScreenYOffsetFactoredIn - (offTrackPoint.y - centerPosition.y);

        dc.setPenWidth(4);
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.drawLine(
            lastPointUnrotatedX,
            lastPointUnrotatedY,
            offTrackPointUnrotatedX,
            offTrackPointUnrotatedY
        );
    }

    // last location should already be scaled
    function renderUser(dc as Dc, usersLastLocation as RectangularPoint) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var userPosUnrotatedX = usersLastLocation.x - centerPosition.x;
        var userPosUnrotatedY = usersLastLocation.y - centerPosition.y;

        var userPosRotatedX = rotateAroundScreenXOffsetFactoredIn + userPosUnrotatedX;
        var userPosRotatedY = rotateAroundScreenYOffsetFactoredIn - userPosUnrotatedY;
        if (settings.renderMode == RENDER_MODE_UNBUFFERED_ROTATING) {
            userPosRotatedX =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * userPosUnrotatedX -
                rotateSin * userPosUnrotatedY;
            userPosRotatedY =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * userPosUnrotatedX + rotateCos * userPosUnrotatedY);
        }

        var triangleSizeY = 10;
        var triangleSizeX = 4;
        var triangleTopX = userPosRotatedX;
        var triangleTopY = userPosRotatedY - triangleSizeY;

        var triangleLeftX = triangleTopX - triangleSizeX;
        var triangleLeftY = userPosRotatedY + triangleSizeY;

        var triangleRightX = triangleTopX + triangleSizeX;
        var triangleRightY = triangleLeftY;

        var triangleCenterX = userPosRotatedX;
        var triangleCenterY = userPosRotatedY;

        if (settings.renderMode != RENDER_MODE_UNBUFFERED_ROTATING) {
            // todo: load user arrow from bitmap and draw rotated instead
            // we normally rotate the track, but we now need to rotate the user
            var triangleTopXRot =
                triangleCenterX +
                rotateCos * (triangleTopX - triangleCenterX) -
                rotateSin * (triangleTopY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleTopY =
                triangleCenterY +
                (rotateSin * (triangleTopX - triangleCenterX) +
                    rotateCos * (triangleTopY - triangleCenterY));
            triangleTopX = triangleTopXRot;

            var triangleLeftXRot =
                triangleCenterX +
                rotateCos * (triangleLeftX - triangleCenterX) -
                rotateSin * (triangleLeftY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleLeftY =
                triangleCenterY +
                (rotateSin * (triangleLeftX - triangleCenterX) +
                    rotateCos * (triangleLeftY - triangleCenterY));
            triangleLeftX = triangleLeftXRot;

            var triangleRightXRot =
                triangleCenterX +
                rotateCos * (triangleRightX - triangleCenterX) -
                rotateSin * (triangleRightY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleRightY =
                triangleCenterY +
                (rotateSin * (triangleRightX - triangleCenterX) +
                    rotateCos * (triangleRightY - triangleCenterY));
            triangleRightX = triangleRightXRot;
        }

        dc.setColor(settings.userColour, Graphics.COLOR_BLACK);
        dc.setPenWidth(6);
        dc.drawLine(triangleTopX, triangleTopY, triangleRightX, triangleRightY);
        dc.drawLine(triangleRightX, triangleRightY, triangleLeftX, triangleLeftY);
        dc.drawLine(triangleLeftX, triangleLeftY, triangleTopX, triangleTopY);
    }

    function renderTrackUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        // note: size is using the overload of points array (the reduced pointarray size)
        // but we draw from the raw points
        if (size >= ARRAY_POINT_SIZE * 2) {
            var firstXScaledAtCenter = coordinatesRaw[0] - centerPosition.x;
            var firstYScaledAtCenter = coordinatesRaw[1] - centerPosition.y;
            var firstX = rotateAroundScreenXOffsetFactoredIn + firstXScaledAtCenter;
            var firstY = rotateAroundScreenYOffsetFactoredIn - firstYScaledAtCenter;
            var lastX = firstX;
            var lastY = firstY;

            for (var i = ARRAY_POINT_SIZE; i < size; i += ARRAY_POINT_SIZE) {
                var nextX =
                    rotateAroundScreenXOffsetFactoredIn + (coordinatesRaw[i] - centerPosition.x);
                var nextY =
                    rotateAroundScreenYOffsetFactoredIn -
                    (coordinatesRaw[i + 1] - centerPosition.y);

                dc.drawLine(lastX, lastY, nextX, nextY);

                lastX = nextX;
                lastY = nextY;
            }

            renderStartAndEnd(dc, firstX, firstY, lastX, lastY, drawEndMarker);
        }
    }

    const CHEVRON_SPREAD_RADIANS = 0.75;
    const CHEVRON_ARM_LENGTH = 15;
    const CHEVRON_POINTS = 6; // the last point is not counted, as we only use it to get the line angle, number of cheverons = CHEVRON_POINTS - 1

    function drawCheveron(
        dc as Dc,
        lastX as Float,
        lastY as Float,
        nextX as Float,
        nextY as Float
    ) as Void {
        var dx = nextX - lastX;
        var dy = nextY - lastY;

        var segmentAngle = Math.atan2(dy, dx);

        // Calculate angles for the two arms (pointing backward from the tip)
        // Base direction for arms is opposite to segment direction
        var baseArmAngle = segmentAngle + Math.PI;

        var angleArm1 = baseArmAngle - CHEVRON_SPREAD_RADIANS;
        var angleArm2 = baseArmAngle + CHEVRON_SPREAD_RADIANS;

        // Calculate endpoints of the chevron arms
        var arm1EndX = lastX + CHEVRON_ARM_LENGTH * Math.cos(angleArm1);
        var arm1EndY = lastY + CHEVRON_ARM_LENGTH * Math.sin(angleArm1);

        var arm2EndX = lastX + CHEVRON_ARM_LENGTH * Math.cos(angleArm2);
        var arm2EndY = lastY + CHEVRON_ARM_LENGTH * Math.sin(angleArm2);

        // Draw the chevron
        dc.drawLine(lastX, lastY, arm1EndX, arm1EndY);
        dc.drawLine(lastX, lastY, arm2EndX, arm2EndY);
    }

    (:noUnbufferedRotations)
    function renderTrackCheverons(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
    }
        
    (:unbufferedRotations)
    function renderTrackCheverons(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var lastClosePointIndex = breadcrumb.lastClosePointIndex;
        if (lastClosePointIndex == null) {
            // we have never seen the track, cheverons only extend out from the users last point on the track
            // this means off track alerts must be enabled too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to scroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        var nextClosePointIndexRaw = lastClosePointIndex * ARRAY_POINT_SIZE + ARRAY_POINT_SIZE;
        if (nextClosePointIndexRaw < size - ARRAY_POINT_SIZE) {
            var firstXScaledAtCenter = coordinatesRaw[nextClosePointIndexRaw] - centerPosition.x;
            var firstYScaledAtCenter =
                coordinatesRaw[nextClosePointIndexRaw + 1] - centerPosition.y;
            var firstXRotated =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * firstXScaledAtCenter -
                rotateSin * firstYScaledAtCenter;
            var firstYRotated =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * firstXScaledAtCenter + rotateCos * firstYScaledAtCenter);
            var lastXRotated = firstXRotated;
            var lastYRotated = firstYRotated;

            for (
                var i = nextClosePointIndexRaw + ARRAY_POINT_SIZE;
                i < size && i <= nextClosePointIndexRaw + CHEVRON_POINTS * ARRAY_POINT_SIZE;
                i += ARRAY_POINT_SIZE
            ) {
                var nextX = coordinatesRaw[i];
                var nextY = coordinatesRaw[i + 1];

                var nextXScaledAtCenter = nextX - centerPosition.x;
                var nextYScaledAtCenter = nextY - centerPosition.y;

                var nextXRotated =
                    rotateAroundScreenXOffsetFactoredIn +
                    rotateCos * nextXScaledAtCenter -
                    rotateSin * nextYScaledAtCenter;
                var nextYRotated =
                    rotateAroundScreenYOffsetFactoredIn -
                    (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

                drawCheveron(dc, lastXRotated, lastYRotated, nextXRotated, nextYRotated);

                lastXRotated = nextXRotated;
                lastYRotated = nextYRotated;
            }
        }
    }

    // function name is to keep consistency with other methods, the chverons themselves will be rotated
    function renderTrackCheveronsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var lastClosePointIndex = breadcrumb.lastClosePointIndex;
        if (lastClosePointIndex == null) {
            // we have never seen the track, cheverons only extend out from the users last point on the track
            // this means off track alerts must be enabled too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        var nextClosePointIndexRaw = lastClosePointIndex * ARRAY_POINT_SIZE + ARRAY_POINT_SIZE;
        if (nextClosePointIndexRaw < size - ARRAY_POINT_SIZE) {
            var lastX =
                rotateAroundScreenXOffsetFactoredIn +
                coordinatesRaw[nextClosePointIndexRaw] -
                centerPosition.x;
            var lastY =
                rotateAroundScreenYOffsetFactoredIn -
                coordinatesRaw[nextClosePointIndexRaw + 1] -
                centerPosition.y;

            for (
                var i = nextClosePointIndexRaw + ARRAY_POINT_SIZE;
                i < size && i <= nextClosePointIndexRaw + CHEVRON_POINTS * ARRAY_POINT_SIZE;
                i += ARRAY_POINT_SIZE
            ) {
                var nextX =
                    rotateAroundScreenXOffsetFactoredIn + (coordinatesRaw[i] - centerPosition.x);
                var nextY =
                    rotateAroundScreenYOffsetFactoredIn -
                    (coordinatesRaw[i + 1] - centerPosition.y);

                drawCheveron(dc, lastX, lastY, nextX, nextY);

                lastX = nextX;
                lastY = nextY;
            }
        }
    }

    (:noUnbufferedRotations)
    function renderTrackName(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {}

    (:unbufferedRotations)
    function renderTrackName(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster

        var xScaledAtCenter = breadcrumb.boundingBoxCenter.x - centerPosition.x;
        var yScaledAtCenter = breadcrumb.boundingBoxCenter.y - centerPosition.y;

        var x =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * xScaledAtCenter -
            rotateSin * yScaledAtCenter;
        var y =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * xScaledAtCenter + rotateCos * yScaledAtCenter);
        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            settings.routeName(breadcrumb.storageIndex),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function renderTrackNameUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var xScaledAtCenter = breadcrumb.boundingBoxCenter.x - centerPosition.x;
        var yScaledAtCenter = breadcrumb.boundingBoxCenter.y - centerPosition.y;

        var x = rotateAroundScreenXOffsetFactoredIn + xScaledAtCenter;
        var y = rotateAroundScreenYOffsetFactoredIn - yScaledAtCenter;

        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            settings.routeName(breadcrumb.storageIndex),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    (:noUnbufferedRotations)
    function renderTrack(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(
            xHalfPhysical,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            "RENDER MODE\nNOT SUPPORTED",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    (:unbufferedRotations)
    function renderTrack(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        // note: size is using the overload of points array (the reduced pointarray size)
        // but we draw from the raw points
        if (size >= ARRAY_POINT_SIZE * 2) {
            var firstXScaledAtCenter = coordinatesRaw[0] - centerPosition.x;
            var firstYScaledAtCenter = coordinatesRaw[1] - centerPosition.y;
            var firstXRotated =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * firstXScaledAtCenter -
                rotateSin * firstYScaledAtCenter;
            var firstYRotated =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * firstXScaledAtCenter + rotateCos * firstYScaledAtCenter);
            var lastXRotated = firstXRotated;
            var lastYRotated = firstYRotated;

            for (var i = ARRAY_POINT_SIZE; i < size; i += ARRAY_POINT_SIZE) {
                var nextX = coordinatesRaw[i];
                var nextY = coordinatesRaw[i + 1];

                var nextXScaledAtCenter = nextX - centerPosition.x;
                var nextYScaledAtCenter = nextY - centerPosition.y;

                var nextXRotated =
                    rotateAroundScreenXOffsetFactoredIn +
                    rotateCos * nextXScaledAtCenter -
                    rotateSin * nextYScaledAtCenter;
                var nextYRotated =
                    rotateAroundScreenYOffsetFactoredIn -
                    (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

                dc.drawLine(lastXRotated, lastYRotated, nextXRotated, nextYRotated);

                lastXRotated = nextXRotated;
                lastYRotated = nextYRotated;
            }

            renderStartAndEnd(
                dc,
                firstXRotated,
                firstYRotated,
                lastXRotated,
                lastYRotated,
                drawEndMarker
            );
        }
    }

    function renderStartAndEnd(
        dc as Dc,
        firstX as Float,
        firstY as Float,
        lastX as Float,
        lastY as Float,
        drawEndMarker as Boolean
    ) as Void {
        // todo let user configure these, or render icons instead
        // could add a start play button and a finnish flag (not Finland's flag, the checkered kind)
        var squareSize = 10;
        var squareHalf = squareSize / 2;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.fillRectangle(firstX - squareHalf, firstY - squareHalf, squareSize, squareSize);
        if (drawEndMarker) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            dc.fillRectangle(lastX - squareHalf, lastY - squareHalf, squareSize, squareSize);
        }
    }

    function renderYNUi(
        dc as Dc,
        text as ResourceId,
        leftText as String,
        rightText as String,
        leftColour as Number,
        rightColour as Number
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var padding = xHalfPhysical / 2.0f;
        var topText = yHalfPhysical / 2.0f;

        dc.setColor(leftColour, leftColour);
        dc.fillRectangle(0, 0, xHalfPhysical, physicalScreenHeight);
        dc.setColor(rightColour, rightColour);
        dc.fillRectangle(xHalfPhysical, 0, xHalfPhysical, physicalScreenHeight);

        var textArea = new WatchUi.TextArea({
            :text => text,
            :color => settings.uiColour,
            :font => [Graphics.FONT_XTINY],
            :justification => Graphics.TEXT_JUSTIFY_CENTER,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => topText,
            :width => physicalScreenWidth * 0.8f, // round devices cannot show text at top of screen
            :height => xHalfPhysical,
        });
        textArea.draw(dc);

        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            xHalfPhysical - padding,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            leftText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            xHalfPhysical + padding,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            rightText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function renderClearTrackUi(dc as Dc) as Boolean {
        switch (_clearRouteProgress) {
            case 0:
                break;
            case 1:
            case 3: {
                // press right to confirm, left cancels
                renderYNUi(
                    dc as Dc,
                    _clearRouteProgress == 1 ? Rez.Strings.clearRoutes1 : Rez.Strings.clearRoutes3,
                    "N",
                    "Y",
                    Graphics.COLOR_RED,
                    Graphics.COLOR_GREEN
                );
                return true;
            }
            case 2: {
                // press left to confirm, right cancels
                renderYNUi(
                    dc as Dc,
                    Rez.Strings.clearRoutes2,
                    "Y",
                    "N",
                    Graphics.COLOR_GREEN,
                    Graphics.COLOR_RED
                );
                return true;
            }
        }

        return false;
    }

    (:noDrawHitBoxes)
    function drawHitBoxes(
        dc as Dc,
        physicalScreenWidth as Float,
        physicalScreenHeight as Float
    ) as Void {
        unsupported(dc, "draw hit boxes");
    }

    (:drawHitBoxes)
    function drawHitBoxes(
        dc as Dc,
        physicalScreenWidth as Float,
        physicalScreenHeight as Float
    ) as Void {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(
            clearRouteX - halfHitboxSize,
            clearRouteY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            modeSelectX - halfHitboxSize,
            modeSelectY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            returnToUserX - halfHitboxSize,
            returnToUserY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            mapEnabledX - halfHitboxSize,
            mapEnabledY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );

        // top bottom left right
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, hitboxSize, physicalScreenWidth, hitboxSize);
        dc.drawLine(
            0,
            physicalScreenHeight - hitboxSize,
            physicalScreenWidth,
            physicalScreenHeight - hitboxSize
        );
        dc.drawLine(hitboxSize, 0, hitboxSize, physicalScreenHeight);
        dc.drawLine(
            physicalScreenWidth - hitboxSize,
            0,
            physicalScreenWidth - hitboxSize,
            physicalScreenHeight
        );
    }

    function renderUi(dc as Dc) as Void {
        var currentScale = _cachedValues.currentScale; // local lookup faster
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        if (settings.drawHitBoxes) {
            drawHitBoxes(dc, physicalScreenWidth, physicalScreenHeight);
        }

        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // current mode displayed
        var modeLetter = "T";
        switch (settings.mode) {
            case MODE_NORMAL:
                modeLetter = "T";
                break;
            case MODE_ELEVATION:
                modeLetter = "E";
                break;
            case MODE_MAP_MOVE:
                modeLetter = "M";
                break;
        }

        dc.drawText(
            modeSelectX,
            modeSelectY,
            Graphics.FONT_XTINY,
            modeLetter,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // clear routes
        dc.drawText(
            clearRouteX,
            clearRouteY,
            Graphics.FONT_XTINY,
            "C",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (settings.mode == MODE_ELEVATION) {
            return;
        }

        // make this a const
        var halfLineLength = 10;
        var lineFromEdge = 10;
        var scaleFromEdge = 75; // guestimate

        if (_cachedValues.fixedPosition != null || _cachedValues.scale != null) {
            // crosshair
            var centerX = returnToUserX;
            var centerY = returnToUserY;
            var halfSize = 25;

            // Draw the outer circle and lines
            dc.setPenWidth(2);

            // Vertical line
            dc.drawLine(centerX, centerY - halfSize, centerX, centerY + halfSize);
            // Horizontal line
            dc.drawLine(centerX - halfSize, centerY, centerX + halfSize, centerY);
            // Outer circle (r=35)
            dc.drawCircle(centerX, centerY, 18);

            // Draw the middle circle
            dc.setPenWidth(3);
            dc.drawCircle(centerX, centerY, 12);

            // Draw the inner, filled circle
            dc.fillCircle(centerX, centerY, 7);
        }

        if (settings.displayLatLong) {
            var fixedLatitude = settings.fixedLatitude;
            var fixedLongitude = settings.fixedLongitude;
            if (
                _cachedValues.fixedPosition != null &&
                fixedLatitude != null &&
                fixedLongitude != null
            ) {
                var txt = fixedLatitude.format("%.3f") + ", " + fixedLongitude.format("%.3f");
                dc.drawText(
                    xHalfPhysical,
                    physicalScreenHeight - scaleFromEdge,
                    Graphics.FONT_XTINY,
                    txt,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            } else if (currentScale != 0f) {
                var latLong = RectangularPoint.xyToLatLon(
                    centerPosition.x / currentScale,
                    centerPosition.y / currentScale
                );
                if (latLong != null) {
                    var txt = latLong[0].format("%.3f") + ", " + latLong[1].format("%.3f");
                    dc.drawText(
                        xHalfPhysical,
                        physicalScreenHeight - scaleFromEdge,
                        Graphics.FONT_XTINY,
                        txt,
                        Graphics.TEXT_JUSTIFY_CENTER
                    );
                }
            }
        }

        if (settings.mode == MODE_MAP_MOVE) {
            dc.setPenWidth(ARROW_PEN_WIDTH);
            var halfArrowSize = ARROW_SIZE / 2.0f;

            // --- Draw LEFT and RIGHT Arrows ---
            // Shared Y coordinates for the horizontal arrow chevrons
            var yTop = yHalfPhysical - halfArrowSize;
            var yBottom = yHalfPhysical + halfArrowSize;

            // Draw LEFT Arrow (<--) with offset
            var tipX = ARROW_WALL_OFFSET;
            var xChevronPoint = tipX + halfArrowSize;
            dc.drawLine(tipX, yHalfPhysical, xChevronPoint, yTop); // Upper chevron line
            dc.drawLine(tipX, yHalfPhysical, xChevronPoint, yBottom); // Lower chevron line
            dc.drawLine(tipX, yHalfPhysical, tipX + ARROW_SIZE, yHalfPhysical); // Shaft

            // Draw RIGHT Arrow (-->) with offset
            tipX = physicalScreenWidth - ARROW_WALL_OFFSET;
            xChevronPoint = tipX - halfArrowSize;
            dc.drawLine(tipX, yHalfPhysical, xChevronPoint, yTop); // Upper chevron line
            dc.drawLine(tipX, yHalfPhysical, xChevronPoint, yBottom); // Lower chevron line
            dc.drawLine(tipX, yHalfPhysical, tipX - ARROW_SIZE, yHalfPhysical); // Shaft

            // --- Draw UP and DOWN Arrows ---
            // Shared X coordinates for the vertical arrow chevrons
            var xLeft = xHalfPhysical - halfArrowSize;
            var xRight = xHalfPhysical + halfArrowSize;

            // Draw UP Arrow with offset
            var tipY = ARROW_WALL_OFFSET;
            var yChevronPoint = tipY + halfArrowSize;
            dc.drawLine(xHalfPhysical, tipY, xLeft, yChevronPoint); // Left chevron line
            dc.drawLine(xHalfPhysical, tipY, xRight, yChevronPoint); // Right chevron line
            dc.drawLine(xHalfPhysical, tipY, xHalfPhysical, tipY + ARROW_SIZE); // Shaft

            // Draw DOWN Arrow with offset
            tipY = physicalScreenHeight - ARROW_WALL_OFFSET;
            yChevronPoint = tipY - halfArrowSize;
            dc.drawLine(xHalfPhysical, tipY, xLeft, yChevronPoint); // Left chevron line
            dc.drawLine(xHalfPhysical, tipY, xRight, yChevronPoint); // Right chevron line
            dc.drawLine(xHalfPhysical, tipY, xHalfPhysical, tipY - ARROW_SIZE); // Shaft
            return;
        }

        // plus at the top of screen
        if (!_cachedValues.scaleCanInc) {
            // no smoking
            drawNoSmokingSign(dc, xHalfPhysical, NO_SMOKING_RADIUS);
        } else {
            dc.drawLine(
                xHalfPhysical - halfLineLength,
                lineFromEdge,
                xHalfPhysical + halfLineLength,
                lineFromEdge
            );
            dc.drawLine(
                xHalfPhysical,
                lineFromEdge - halfLineLength,
                xHalfPhysical,
                lineFromEdge + halfLineLength
            );
        }

        // minus at the bottom
        if (!_cachedValues.scaleCanDec) {
            // no smoking
            drawNoSmokingSign(dc, xHalfPhysical, physicalScreenHeight - NO_SMOKING_RADIUS);
        } else {
            dc.drawLine(
                xHalfPhysical - halfLineLength,
                physicalScreenHeight - lineFromEdge,
                xHalfPhysical + halfLineLength,
                physicalScreenHeight - lineFromEdge
            );
        }

        // M - default, moving is zoomed view, stopped if full view
        // S - stopped is zoomed view, moving is entire view
        var fvText = "M";
        // dirty hack, should pass the bool in another way
        // ui should be its own class, as should states
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_STOPPED) {
            // zoom view
            fvText = "S";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_NEVER_ZOOM) {
            // zoom view
            fvText = "N";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_ALWAYS_ZOOM) {
            // zoom view
            fvText = "A";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK) {
            // zoom view
            fvText = "R";
        }
        dc.drawText(
            halfHitboxSize,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            fvText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawNoSmokingSign(dc as Dc, x as Float, y as Float) as Void {
        var PEN_WIDTH = 2;
        dc.setPenWidth(PEN_WIDTH);

        // Draw the circle
        dc.drawCircle(x, y, NO_SMOKING_RADIUS);

        // TODO consider hard coding these once they are locked in

        // --- Draw the Diagonal Line ---
        // Calculate the endpoints so the line touches the *inner* edge of the circle's stroke.
        // The radius for the line's endpoints is the outer radius minus the full pen width.
        var lineEndpointRadius = NO_SMOKING_RADIUS - PEN_WIDTH;

        // For a 45-degree line, the x and y offsets from the center are equal.
        // Using Pythagorean theorem: offset^2 + offset^2 = radius^2
        // So, offset = radius / sqrt(2)
        var offset = lineEndpointRadius / Math.sqrt(2);

        // Calculate the start (top-left) and end (bottom-right) points of the line
        var startX = x - offset;
        var startY = y - offset;
        var endX = x + offset;
        var endY = y + offset;

        dc.drawLine(startX, startY, endX, endY);
    }

    function getScaleDecIncAmount(direction as Number) as Float {
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we never call this when its null
            return 0f;
        }

        var scaleKeys = settings.distanceImperialUnits ? SCALE_KEYS_IMPERIAL : SCALE_KEYS;
        var scaleValues = settings.distanceImperialUnits ? SCALE_VALUES_IMPERIAL : SCALE_VALUES;
        var scaleData = getScaleSizeGeneric(
            _cachedValues.currentScale,
            DESIRED_SCALE_PIXEL_WIDTH,
            scaleKeys as Array<Number>,
            scaleValues as Array<String>
        );
        var iInc = direction;
        var currentDistanceM = scaleData[1];

        for (var i = 0; i < scaleKeys.size(); ++i) {
            var distanceM = scaleKeys[i];
            if (currentDistanceM == distanceM) {
                var nextScaleIndex = i - iInc;
                if (nextScaleIndex >= scaleKeys.size()) {
                    nextScaleIndex = scaleKeys.size() - 1;
                }

                if (nextScaleIndex < 0) {
                    nextScaleIndex = 0;
                }

                // we want the result to be
                var nextDistanceM = scaleKeys[nextScaleIndex] / (1000f as Float);
                // -2 since we need some fudge factor to make sure we are very close to desired length, but not past it
                var desiredScale = (DESIRED_SCALE_PIXEL_WIDTH - 2) / nextDistanceM;
                var toInc = desiredScale - scale;
                return toInc;
            }
        }

        return direction * MIN_SCALE;
    }

    function incScale() as Void {
        if (settings.mode != MODE_NORMAL) {
            return;
        }

        if (_cachedValues.scale == null) {
            _cachedValues.setScale(_cachedValues.currentScale);
        }
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we just set it?
            return;
        }

        _cachedValues.setScale(scale + getScaleDecIncAmount(1));
        _cachedValues.scaleCanDec = true; // we can zoom out again
        _cachedValues.scaleCanInc = getScaleDecIncAmount(1) != 0f; // get the next inc amount so that it does not require one extra click
    }

    function decScale() as Void {
        if (settings.mode != MODE_NORMAL) {
            return;
        }

        if (_cachedValues.scale == null) {
            _cachedValues.setScale(_cachedValues.currentScale);
        }
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we just set it?
            return;
        }
        _cachedValues.setScale(scale + getScaleDecIncAmount(-1));
        _cachedValues.scaleCanInc = true; // we can zoom in again
        _cachedValues.scaleCanDec = getScaleDecIncAmount(-1) != 0f; // get the next dec amount so that it does not require one extra click

        // prevent negative values (dont think this ever gets hit, since we caluclate off of the predefined scales)
        if (scale <= 0f) {
            _cachedValues.setScale(MIN_SCALE);
            _cachedValues.scaleCanInc = true; // we can zoom in again
            _cachedValues.scaleCanDec = getScaleDecIncAmount(-1) != 0f; // get the next dec amount so that it does not require one extra click
        }
    }

    function handleClearRoute(x as Number, y as Number) as Boolean {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster

        if (
            settings.mode != MODE_NORMAL &&
            settings.mode != MODE_ELEVATION &&
            settings.mode != MODE_MAP_MOVE
        ) {
            return false; // debug and map move do not clear routes
        }

        if (exclusiveOpRunning(3)) {
            return false; // something else is running, do not handle touch events
        }

        switch (_clearRouteProgress) {
            case 0:
                // press top left to start clear route
                if (inHitbox(x, y, clearRouteX, clearRouteY, halfHitboxSize)) {
                    _clearRouteProgress = 1;
                    return true;
                }
                return false;
            case 1:
                // press right to confirm, left cancels
                if (x > xHalfPhysical) {
                    _clearRouteProgress = 2;
                    return true;
                }
                _clearRouteProgress = 0;
                return true;

            case 2:
                // press left to confirm, right cancels
                if (x < xHalfPhysical) {
                    _clearRouteProgress = 3;
                    return true;
                }
                _clearRouteProgress = 0;
                return true;
            case 3:
                // press right to confirm, left cancels
                if (x > xHalfPhysical) {
                    var _breadcrumbContextLocal = $._breadcrumbContext;
                    if (_breadcrumbContextLocal != null) {
                        _breadcrumbContextLocal.clearRoutes();
                    }
                }
                _clearRouteProgress = 0;
                return true;
        }

        return false;
    }

    function exclusiveOpRunning(current as Number) as Boolean {
        // _startCacheTilesProgress - 0
        // _enableMapProgress - 1
        // _disableMapProgress - 2
        // _clearRouteProgress - 3
        return _clearRouteProgress != 0 && current != 3;
    }

    function returnToUser() as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            return;
        }
        _cachedValues.returnToUser();
    }

    // todo move most of these into a ui class
    // and all the elevation ones into elevation class, or cached values if they are
    // things set to -1 are set by setScreenSize()
    var _xElevationStart as Float = -1f; // think this needs to depend on dpi?
    var _xElevationEnd as Float = -1f;
    var _yElevationHeight as Float = -1f;
    var _halfYElevationHeight as Float = -1f;
    var yElevationTop as Float = -1f;
    var yElevationBottom as Float = -1f;
    var clearRouteX as Float = -1f;
    var clearRouteY as Float = -1f;
    var modeSelectX as Float = -1f;
    var modeSelectY as Float = -1f;
    var returnToUserX as Float = -1f;
    var returnToUserY as Float = -1f;
    var mapEnabledX as Float = -1f;
    var mapEnabledY as Float = -1f;
    var hitboxSize as Float = 60f;
    var halfHitboxSize as Float = hitboxSize / 2.0f;

    function setElevationAndUiData(xElevationStart as Float) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster

        _xElevationStart = xElevationStart;
        _xElevationEnd = physicalScreenWidth - _xElevationStart;
        var xElevationFromCenter = xHalfPhysical - _xElevationStart;
        _yElevationHeight =
            Math.sqrt(
                xHalfPhysical * xHalfPhysical - xElevationFromCenter * xElevationFromCenter
            ).toFloat() *
                2 -
            40;
        _halfYElevationHeight = _yElevationHeight / 2.0f;
        yElevationTop = yHalfPhysical - _halfYElevationHeight;
        yElevationBottom = yHalfPhysical + _halfYElevationHeight;

        setCornerPositions();
    }

    (:round)
    function setCornerPositions() as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        var offsetSize = Math.sqrt(
            ((yHalfPhysical - halfHitboxSize) * (yHalfPhysical - halfHitboxSize)) / 2
        ).toFloat();

        // top left
        clearRouteX = xHalfPhysical - offsetSize;
        clearRouteY = yHalfPhysical - offsetSize;

        // top right
        modeSelectX = xHalfPhysical + offsetSize;
        modeSelectY = yHalfPhysical - offsetSize;

        // bottom left
        returnToUserX = xHalfPhysical - offsetSize;
        returnToUserY = yHalfPhysical + offsetSize;

        // bottom right
        mapEnabledX = xHalfPhysical + offsetSize;
        mapEnabledY = yHalfPhysical + offsetSize;
    }

    (:rectangle)
    function setCornerPositions() as Void {
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster

        // top left
        clearRouteX = halfHitboxSize;
        clearRouteY = halfHitboxSize;

        // top right
        modeSelectX = physicalScreenWidth - halfHitboxSize;
        modeSelectY = halfHitboxSize;

        // bottom left
        returnToUserX = halfHitboxSize;
        returnToUserY = physicalScreenHeight - halfHitboxSize;

        // bottom right
        mapEnabledX = physicalScreenWidth - halfHitboxSize;
        mapEnabledY = physicalScreenHeight - halfHitboxSize;
    }

    function renderElevationChart(
        dc as Dc,
        hScalePPM as Float,
        vScale as Float,
        startAt as Float,
        distancePixels as Float,
        elevationText as String
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster

        var hScaleKeys = settings.distanceImperialUnits ? SCALE_KEYS_IMPERIAL : SCALE_KEYS;
        var hScaleValues = settings.distanceImperialUnits ? SCALE_VALUES_IMPERIAL : SCALE_VALUES;
        var vScaleKeys = settings.elevationImperialUnits
            ? ELEVATION_SCALE_KEYS_IMPERIAL
            : ELEVATION_SCALE_KEYS;
        var vScaleValues = settings.elevationImperialUnits
            ? ELEVATION_SCALE_VALUES_IMPERIAL
            : ELEVATION_SCALE_VALUES;

        var hScaleData = getScaleSizeGeneric(
            hScalePPM,
            DESIRED_SCALE_PIXEL_WIDTH,
            hScaleKeys as Array<Number>,
            hScaleValues as Array<String>
        );
        var hPixelWidth = hScaleData[0];
        var vScaleData = getScaleSizeGeneric(
            vScale,
            DESIRED_ELEV_SCALE_PIXEL_WIDTH,
            vScaleKeys as Array<Number>,
            vScaleValues as Array<String>
        );
        var vPixelWidth = vScaleData[0];

        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // vertical and horizontal lines for extreems
        dc.drawLine(_xElevationStart, yElevationTop, _xElevationStart, yElevationBottom);
        dc.drawLine(_xElevationStart, yHalfPhysical, _xElevationEnd, yHalfPhysical);
        // border (does not look great)
        // dc.drawRectangle(_xElevationStart, yHalfPhysical - _halfYElevationHeight, screenWidth - _xElevationStart * 2, _yElevationHeight);

        // horizontal lines vertical scale
        if (vPixelWidth != 0) {
            // do not want infinite for loop
            for (var i = 0; i < _halfYElevationHeight; i += vPixelWidth) {
                var yTop = yHalfPhysical - i;
                var yBottom = yHalfPhysical + i;
                dc.drawLine(_xElevationStart, yTop, _xElevationEnd, yTop);
                dc.drawLine(_xElevationStart, yBottom, _xElevationEnd, yBottom);
            }
        }

        // vertical lines horizontal scale
        if (hPixelWidth != 0) {
            // do not want infinite for loop
            for (var i = _xElevationStart; i < _xElevationEnd; i += hPixelWidth) {
                dc.drawLine(i, yElevationTop, i, yElevationBottom);
            }
        }

        var mToFt = 3.28084f;
        var elevationUnit = "m";
        var startAtDisplay = startAt;
        if (settings.elevationImperialUnits) {
            elevationUnit = "ft";
            startAtDisplay = startAt * mToFt;
        }

        dc.drawText(
            0,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            startAtDisplay.format("%.0f"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        if (vScale != 0) {
            // prevent division by 0
            var topScaleM = startAt + _halfYElevationHeight / vScale;
            var topScaleDisplay = topScaleM;
            if (settings.elevationImperialUnits) {
                topScaleDisplay = topScaleM * mToFt;
            }
            var topText = topScaleDisplay.format("%.0f") + elevationUnit;
            var textDim = dc.getTextDimensions(topText, Graphics.FONT_XTINY);
            dc.drawText(
                _xElevationStart,
                yHalfPhysical - _halfYElevationHeight - textDim[1],
                Graphics.FONT_XTINY,
                topText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
            var bottomScaleM = startAt - _halfYElevationHeight / vScale;
            var bottomScaleDisplay = bottomScaleM;
            if (settings.elevationImperialUnits) {
                bottomScaleDisplay = bottomScaleM * mToFt;
            }
            dc.drawText(
                _xElevationStart,
                yHalfPhysical + _halfYElevationHeight,
                Graphics.FONT_XTINY,
                bottomScaleDisplay.format("%.0f") + elevationUnit,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }

        dc.setColor(settings.elevationColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);

        if (hPixelWidth != 0) {
            var hFoundName = hScaleData[2];
            var y = physicalScreenHeight - 20;
            dc.drawLine(
                xHalfPhysical - hPixelWidth / 2.0f,
                y,
                xHalfPhysical + hPixelWidth / 2.0f,
                y
            );
            dc.drawText(
                xHalfPhysical,
                y - 30,
                Graphics.FONT_XTINY,
                hFoundName,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        if (vPixelWidth != 0) {
            var vFoundName = vScaleData[2];
            var x = xHalfPhysical + DESIRED_SCALE_PIXEL_WIDTH / 2.0f;
            var y = physicalScreenHeight - 20 - 5 - vPixelWidth / 2.0f;
            dc.drawLine(x, y - vPixelWidth / 2.0f, x, y + vPixelWidth / 2.0f);
            dc.drawText(x + 5, y - 15, Graphics.FONT_XTINY, vFoundName, Graphics.TEXT_JUSTIFY_LEFT);
            // var vectorFont = Graphics.getVectorFont(
            //   {
            //     // font face from https://developer.garmin.com/connect-iq/reference-guides/devices-reference/
            //     :face=>["VeraSans"],
            //     :size=>16,
            //     // :font=>Graphics.FONT_XTINY,
            //     // :scale=>1.0f
            //   }
            // );
            // dc.drawAngledText(0, yHalfPhysical, vectorFont, vFoundName, Graphics.TEXT_JUSTIFY_LEFT, 90);
            // dc.drawRadialText(0, yHalfPhysical, vectorFont, vFoundName, Graphics.TEXT_JUSTIFY_LEFT, 90, 0, Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
            // drawAngledText and drawRadialText not available :(
        }

        var distanceM = _cachedValues.elapsedDistanceM;
        var distText;
        if (settings.elevationImperialUnits) {
            var distanceMi = distanceM * 0.000621371f;
            var distanceFt = distanceM * 3.28084f;
            distText =
                distanceMi >= 0.1
                    ? distanceMi.format("%.1f") + "mi"
                    : distanceFt.toNumber().toString() + "ft";
        } else {
            var distanceKM = distanceM / 1000f;
            distText =
                distanceKM > 1
                    ? distanceKM.format("%.1f") + "km"
                    : distanceM.toNumber().toString() + "m";
        }
        var text = "dist: " + distText + "\n" + "elev: " + elevationText;
        dc.drawText(xHalfPhysical, 20, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function getElevationScale(
        track as BreadcrumbTrack,
        routes as Array<BreadcrumbTrack>
    ) as [Float, Float, Float, Float] {
        var maxDistanceScaled = 0f;
        var minElevation = FLOAT_MAX;
        var maxElevation = FLOAT_MIN;
        if (track.coordinates.pointSize() > 2) {
            maxDistanceScaled = maxF(maxDistanceScaled, track.distanceTotal);
            minElevation = minF(minElevation, track.elevationMin);
            maxElevation = maxF(maxElevation, track.elevationMax);
        }

        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (!settings.routeEnabled(route.storageIndex)) {
                continue;
            }
            if (route.coordinates.pointSize() > 2) {
                maxDistanceScaled = maxF(maxDistanceScaled, route.distanceTotal);
                minElevation = minF(minElevation, route.elevationMin);
                maxElevation = maxF(maxElevation, route.elevationMax);
            }
        }

        // abs really only needed until we get the first point (then max should always be more than min)
        var elevationChange = abs(maxElevation - minElevation);
        var startAt = minElevation + elevationChange / 2;
        return getElevationScaleRaw(maxDistanceScaled, elevationChange, startAt);
    }

    function getElevationScaleOrderedRoutes(
        track as BreadcrumbTrack,
        routes as Array<BreadcrumbTrack>
    ) as [Float, Float, Float, Float] {
        var maxTrackDistanceScaled = 0f;
        var minElevation = FLOAT_MAX;
        var maxElevation = FLOAT_MIN;
        if (track.coordinates.pointSize() > 2) {
            maxTrackDistanceScaled = maxF(maxTrackDistanceScaled, track.distanceTotal);
            minElevation = minF(minElevation, track.elevationMin);
            maxElevation = maxF(maxElevation, track.elevationMax);
        }

        var allRouteDistanceScaled = 0f;
        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (!settings.routeEnabled(route.storageIndex)) {
                continue;
            }
            if (route.coordinates.pointSize() > 2) {
                allRouteDistanceScaled += route.distanceTotal;
                minElevation = minF(minElevation, route.elevationMin);
                maxElevation = maxF(maxElevation, route.elevationMax);
            }
        }

        // track renders ontop of the routes, so we need to get the max distance of the routes or the track
        var maxDistanceScaled = maxF(allRouteDistanceScaled, maxTrackDistanceScaled);

        // abs really only needed until we get the first point (then max should always be more than min)
        var elevationChange = abs(maxElevation - minElevation);
        var startAt = minElevation + elevationChange / 2;
        return getElevationScaleRaw(maxDistanceScaled, elevationChange, startAt);
    }

    function getElevationScaleRaw(
        distanceScaled as Float,
        elevationChange as Float,
        startAt as Float
    ) as [Float, Float, Float, Float] {
        var distanceM = distanceScaled;
        var distanceScale = _cachedValues.currentScale;
        if (distanceScale != 0f) {
            distanceM = distanceScaled / distanceScale;
        }

        // clip to a a square (since we cannot see the edges of the circle)
        var totalXDistance = _cachedValues.physicalScreenWidth - 2 * _xElevationStart;
        var totalYDistance = _yElevationHeight;

        if (distanceScaled == 0 && elevationChange == 0) {
            return [0f, 0f, startAt, 0f]; // do not divide by 0
        }

        if (distanceScaled == 0) {
            return [0f, totalYDistance / elevationChange, startAt, 0f]; // do not divide by 0
        }

        if (elevationChange == 0) {
            return [totalXDistance / distanceScaled, 0f, startAt, totalXDistance / distanceM]; // do not divide by 0
        }

        var hScalePPM = totalXDistance / distanceM; // pixels per meter
        var hScale = totalXDistance / distanceScaled; // pixels per pixel - make track renderring faster (single multiply)
        var vScale = totalYDistance / elevationChange;

        return [hScale, vScale, startAt, hScalePPM];
    }

    function renderTrackElevation(
        dc as Dc,
        xElevationStart as Float,
        track as BreadcrumbTrack,
        colour as Graphics.ColorType,
        hScale as Float,
        vScale as Float,
        startAt as Float
    ) as Float {
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        var sizeRaw = track.coordinates.size();
        if (sizeRaw < ARRAY_POINT_SIZE * 2) {
            return xElevationStart; // not enough points for iteration
        }

        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        var coordinatesRaw = track.coordinates._internalArrayBuffer;
        var prevPointX = coordinatesRaw[0];
        var prevPointY = coordinatesRaw[1];
        var prevPointAlt = coordinatesRaw[2];
        var prevChartX = xElevationStart;
        var prevChartY = yHalfPhysical + (startAt - prevPointAlt) * vScale;
        for (var i = ARRAY_POINT_SIZE; i < sizeRaw; i += ARRAY_POINT_SIZE) {
            var currPointX = coordinatesRaw[i];
            var currPointY = coordinatesRaw[i + 1];
            var currPointAlt = coordinatesRaw[i + 2];

            var xDistance = distance(prevPointX, prevPointY, currPointX, currPointY);
            var yDistance = prevPointAlt - currPointAlt;

            var currChartX = prevChartX + xDistance * hScale;
            var currChartY = prevChartY + yDistance * vScale;

            dc.drawLine(prevChartX, prevChartY, currChartX, currChartY);

            prevPointX = currPointX;
            prevPointY = currPointY;
            prevPointAlt = currPointAlt;
            prevChartX = currChartX;
            prevChartY = currChartY;
        }

        return prevChartX;
    }
}
