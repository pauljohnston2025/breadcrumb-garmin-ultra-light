import Toybox.Activity;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

const NO_SMOKING_RADIUS = 10.0f;
const DESIRED_SCALE_PIXEL_WIDTH as Float = 100.0f;
// note sure why this has anything to do with DESIRED_SCALE_PIXEL_WIDTH, should just be whatever tile layer 0 equates to for the screen size
const MIN_SCALE as Float = DESIRED_SCALE_PIXEL_WIDTH / 1000000000.0f;

(:blackAndWhite)
const UI_COLOUR = Graphics.COLOR_WHITE;
(:fullColours)
const UI_COLOUR = Graphics.COLOR_DK_GRAY;
(:reducedColors)
const UI_COLOUR = Graphics.COLOR_DK_GRAY;

(:blackAndWhite)
const USER_AND_SCALE_COLOUR = Graphics.COLOR_WHITE;
(:fullColours)
const USER_AND_SCALE_COLOUR = Graphics.COLOR_ORANGE;
(:reducedColors)
const USER_AND_SCALE_COLOUR = Graphics.COLOR_ORANGE;

(:blackAndWhite)
const START_COLOUR = Graphics.COLOR_WHITE;
(:fullColours)
const START_COLOUR = Graphics.COLOR_GREEN;
(:reducedColors)
const START_COLOUR = Graphics.COLOR_GREEN;

(:blackAndWhite)
const END_COLOUR = Graphics.COLOR_WHITE;
(:fullColours)
const END_COLOUR = Graphics.COLOR_RED;
(:reducedColors)
const END_COLOUR = Graphics.COLOR_RED;

class BreadcrumbRenderer {
    // todo put into ui class
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
            SCALE_KEYS_IMPERIAL.size() != SCALE_VALUES_IMPERIAL.size()
        ) {
            throw new Exception();
        }
    }

    (:inline)
    function getScaleSize() as [Float, String] {
        var scaleKeys = settings.distanceImperialUnits ? SCALE_KEYS_IMPERIAL : SCALE_KEYS;
        var scaleValues = settings.distanceImperialUnits ? SCALE_VALUES_IMPERIAL : SCALE_VALUES;

        // get the closest without going over
        // The keys array is already sorted, so we get the first element as the default
        var foundName = scaleValues[0];
        var foundPixelWidth = 0f;

        for (var i = 0; i < scaleKeys.size(); ++i) {
            var distanceKey = scaleKeys[i];
            var testPixelWidth = (distanceKey.toFloat() / 1000) * _cachedValues.currentScale;
            if (testPixelWidth > DESIRED_SCALE_PIXEL_WIDTH) {
                break;
            }

            foundPixelWidth = testPixelWidth;
            foundName = scaleValues[i];
        }

        return [foundPixelWidth, foundName];
    }

    function renderCurrentScale(dc as Dc) as Void {
        var scaleData = getScaleSize();
        var pixelWidth = scaleData[0];
        var foundName = scaleData[1];

        if (pixelWidth == 0f) {
            return;
        }

        var y = dc.getHeight() - 25;
        dc.setColor(USER_AND_SCALE_COLOUR, Graphics.COLOR_TRANSPARENT);
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

    // last location should already be scaled
    function renderUser(dc as Dc, usersLastLocation as RectangularPoint) as Void {
        var cached = _cachedValues; // Single object lookup
        var centerPos = cached.centerPosition;

        // 1. Calculate the user's base position on screen
        var unRotX = usersLastLocation.x - centerPos.x;
        var unRotY = usersLastLocation.y - centerPos.y;

        var userX, userY;

        if (settings.renderMode == RENDER_MODE_UNBUFFERED_ROTATING) {
            var cos = cached.rotateCos;
            var sin = cached.rotateSin;
            userX = cached.rotateAroundScreenXOffsetFactoredIn + cos * unRotX - sin * unRotY;
            userY = cached.rotateAroundScreenYOffsetFactoredIn - (sin * unRotX + cos * unRotY);
        } else {
            userX = cached.rotateAroundScreenXOffsetFactoredIn + unRotX;
            userY = cached.rotateAroundScreenYOffsetFactoredIn - unRotY;
        }

        // 2. Define the Triangle (relative to userX, userY)
        // Constants for the shape
        var sX = 10; // triangleSizeX
        var sY = 16; // triangleSizeY

        var pTopX, pTopY, pLeftX, pLeftY, pRightX, pRightY;

        if (settings.renderMode != RENDER_MODE_UNBUFFERED_ROTATING) {
            var uCos = cached.rotateCosUser;
            var uSin = cached.rotateSinUser;

            // Simplified Rotation:
            // Top point is (0, -sY). Rotated: x = -sin*(-sY), y = cos*(-sY)
            pTopX = userX + uSin * sY;
            pTopY = userY - uCos * sY;

            // Left point is (-sX, sY). Rotated: x = cos*(-sX) - sin*(sY), y = sin*(-sX) + cos*(sY)
            pLeftX = userX - uCos * sX - uSin * sY;
            pLeftY = userY - uSin * sX + uCos * sY;

            // Right point is (sX, sY). Rotated: x = cos*(sX) - sin*(sY), y = sin*(sX) + cos*(sY)
            pRightX = userX + uCos * sX - uSin * sY;
            pRightY = userY + uSin * sX + uCos * sY;
        } else {
            // No user-rotation needed (likely because the whole screen is rotating)
            pTopX = userX;
            pTopY = userY - sY;
            pLeftX = userX - sX;
            pLeftY = userY + sY;
            pRightX = userX + sX;
            pRightY = userY + sY;
        }

        dc.setColor(USER_AND_SCALE_COLOUR, Graphics.COLOR_BLACK);
        dc.fillPolygon([
            [pTopX, pTopY],
            [pRightX, pRightY],
            [pLeftX, pLeftY],
        ]);
    }

    function renderTrack(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean,
        width as Number
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(width);

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
        }
    }
}
