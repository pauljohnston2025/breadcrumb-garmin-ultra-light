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

const UI_COLOUR = Graphics.COLOR_DK_GRAY;

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

    function renderDataFields(dc as Dc) as Void {
        var edgeOffset = 25f;
        renderDataField(dc, settings.topDataType, edgeOffset, 1);
        renderDataField(
            dc,
            settings.bottomDataType,
            dc.getHeight() - edgeOffset,
            -1
        );
    }

    function renderDataField(dc as Dc, type as Number, y as Float, direction as Number) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);

        if (type == DATA_TYPE_NONE) {
            return;
        }

        if (type == DATA_TYPE_SCALE) {
            renderCurrentScale(dc, y, direction);
            return;
        }

        var info = Activity.getActivityInfo();
        if (info == null) {
            // all other metrics depend on info
            return;
        }

        var centeredTextOffset =
            (direction *
                dc.getTextDimensions("A", settings.dataFieldTextSize as Graphics.FontType)[1]) /
            2;
        y = y + centeredTextOffset;

        if (type == DATA_TYPE_ALTITUDE) {
            renderElevationMetric(dc, y, info.altitude);
        } else if (type == DATA_TYPE_AVERAGE_HEART_RATE) {
            renderHeartRateMetric(dc, y, info.averageHeartRate);
        } else if (type == DATA_TYPE_CURRENT_HEART_RATE) {
            renderHeartRateMetric(dc, y, info.currentHeartRate);
        } else if (type == DATA_TYPE_AVERAGE_SPEED) {
            renderSpeedMetric(dc, y, info.averageSpeed);
        } else if (type == DATA_TYPE_CURRENT_SPEED) {
            renderSpeedMetric(dc, y, info.currentSpeed);
        } else if (type == DATA_TYPE_ELAPSED_DISTANCE) {
            renderDistanceMetric(dc, y, info.elapsedDistance);
        } else if (type == DATA_TYPE_ELAPSED_TIME) {
            renderTimeMetric(dc, y, info.elapsedTime);
        } else if (type == DATA_TYPE_TOTAL_ASCENT) {
            renderElevationMetric(dc, y, info.totalAscent);
        } else if (type == DATA_TYPE_TOTAL_DESCENT) {
            renderElevationMetric(dc, y, info.totalDescent);
        } else if (type == DATA_TYPE_AVERAGE_PACE) {
            renderPaceMetric(dc, y, info.averageSpeed);
        } else if (type == DATA_TYPE_CURRENT_PACE) {
            renderPaceMetric(dc, y, info.currentSpeed);
        }
    }

    function renderTextMetric(dc as Dc, y as Float, val as String) as Void {
        dc.drawText(
            _cachedValues.xHalfPhysical,
            y,
            settings.dataFieldTextSize as Graphics.FontType,
            val,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function renderHeartRateMetric(dc as Dc, y as Float, hr as Number?) as Void {
        if (hr == null) {
            renderTextMetric(dc, y, "-");
            return;
        }
        // e.g. "145bpm"
        renderTextMetric(dc, y, hr.toString() + "bpm");
    }

    function renderTimeMetric(dc as Dc, y as Float, timeMs as Number?) as Void {
        if (timeMs == null) {
            renderTextMetric(dc, y, "--:--");
            return;
        }

        var secondsTotal = timeMs / 1000;
        var hours = secondsTotal / 3600;
        var minutes = (secondsTotal % 3600) / 60;
        var seconds = secondsTotal % 60;

        var timeStr;
        if (hours > 0) {
            timeStr = Lang.format("$1$:$2$:$3$", [
                hours,
                minutes.format("%02d"),
                seconds.format("%02d"),
            ]);
        } else {
            timeStr = Lang.format("$1$:$2$", [minutes, seconds.format("%02d")]);
        }
        renderTextMetric(dc, y, timeStr);
    }

    function renderSpeedMetric(dc as Dc, y as Float, speedMps as Float?) as Void {
        if (speedMps == null) {
            renderTextMetric(dc, y, "-.-");
            return;
        }

        var speedConverted = speedMps;
        var suffix = "k/h";

        if (settings.distanceImperialUnits) {
            speedConverted = speedMps * 2.23694f;
            suffix = "m/h";
        } else {
            speedConverted = speedMps * 3.6f;
        }

        // e.g. "12.5k/h"
        renderTextMetric(dc, y, speedConverted.format("%.1f") + suffix);
    }

    function renderPaceMetric(dc as Dc, y as Float, speedMps as Float?) as Void {
        if (speedMps == null || speedMps < 0.2f) {
            renderTextMetric(dc, y, "--:--");
            return;
        }

        var secondsPerUnit;
        var suffix = "/km";

        if (settings.distanceImperialUnits) {
            secondsPerUnit = 1609.34f / speedMps;
            suffix = "/mi";
        } else {
            secondsPerUnit = 1000.0f / speedMps;
        }

        var minutes = (secondsPerUnit / 60).toNumber();
        var seconds = secondsPerUnit.toNumber() % 60;

        if (minutes > 99) {
            renderTextMetric(dc, y, "--:--");
        } else {
            // e.g. "5:30/km"
            renderTextMetric(
                dc,
                y,
                Lang.format("$1$:$2$", [minutes, seconds.format("%02d")]) + suffix
            );
        }
    }

    function renderDistanceMetric(dc as Dc, y as Float, distMeters as Float?) as Void {
        if (distMeters == null) {
            renderTextMetric(dc, y, "-.--");
            return;
        }

        var distConverted;
        var suffix = "km";

        if (settings.distanceImperialUnits) {
            distConverted = distMeters / 1609.34f;
            suffix = "mi";
        } else {
            distConverted = distMeters / 1000.0f;
        }

        // e.g. "5.23km"
        renderTextMetric(dc, y, distConverted.format("%.2f") + suffix);
    }

    function renderElevationMetric(
        dc as Dc,
        y as Float,
        elevationMeters as Float or Number or Null
    ) as Void {
        if (elevationMeters == null) {
            renderTextMetric(dc, y, "-");
            return;
        }

        var elevationConverted = elevationMeters.toFloat();
        var suffix = "m";

        if (System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE) {
            elevationConverted = elevationMeters * 3.28084f;
            suffix = "ft";
        }

        // e.g. "1250ft"
        renderTextMetric(dc, y, elevationConverted.format("%.0f") + suffix);
    }

    function renderCurrentScale(dc as Dc, y as Float, direction as Number) as Void {
        var scaleData = getScaleSize();
        var pixelWidth = scaleData[0];
        var foundName = scaleData[1];

        if (pixelWidth == 0f) {
            return;
        }

        dc.setPenWidth(4);
        dc.drawLine(
            _cachedValues.xHalfPhysical - pixelWidth / 2.0f,
            y,
            _cachedValues.xHalfPhysical + pixelWidth / 2.0f,
            y
        );
        dc.drawText(
            _cachedValues.xHalfPhysical,
            y +
                direction * 2 +
                (direction *
                    dc.getTextDimensions(
                        foundName,
                        settings.dataFieldTextSize as Graphics.FontType
                    )[1]) /
                    2,
            settings.dataFieldTextSize as Graphics.FontType,
            foundName,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // make this a const
        var scaleFromEdge = 75; // guestimate

        var currentScale = _cachedValues.currentScale;
        var centerPosition = _cachedValues.centerPosition;

        if (settings.displayLatLong) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            if (currentScale != 0f) {
                var latLong = RectangularPoint.xyToLatLon(
                    centerPosition.x / currentScale,
                    centerPosition.y / currentScale
                );
                if (latLong != null) {
                    var txt = latLong[0].format("%.3f") + ", " + latLong[1].format("%.3f");
                    dc.drawText(
                        _cachedValues.xHalfPhysical,
                        dc.getHeight() - scaleFromEdge,
                        Graphics.FONT_XTINY,
                        txt,
                        Graphics.TEXT_JUSTIFY_CENTER
                    );
                }
            }
        }
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

        var userPosRotatedX =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * userPosUnrotatedX -
            rotateSin * userPosUnrotatedY;
        var userPosRotatedY =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * userPosUnrotatedX + rotateCos * userPosUnrotatedY);

        var triangleSizeY = 10;
        var triangleSizeX = 4;
        var triangleTopX = userPosRotatedX;
        var triangleTopY = userPosRotatedY - triangleSizeY;

        var triangleLeftX = triangleTopX - triangleSizeX;
        var triangleLeftY = userPosRotatedY + triangleSizeY;

        var triangleRightX = triangleTopX + triangleSizeX;
        var triangleRightY = triangleLeftY;

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
        dc.setPenWidth(6);
        dc.drawLine(triangleTopX, triangleTopY, triangleRightX, triangleRightY);
        dc.drawLine(triangleRightX, triangleRightY, triangleLeftX, triangleLeftY);
        dc.drawLine(triangleLeftX, triangleLeftY, triangleTopX, triangleTopY);
    }

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
}
