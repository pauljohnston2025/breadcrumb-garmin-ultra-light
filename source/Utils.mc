import Toybox.Lang;
import Toybox.System;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Math;
import Toybox.Application;
import Toybox.WatchUi;

const FLOAT_MIN = -340282346638528859811704183484516925440.0;
const FLOAT_MAX = 340282346638528859811704183484516925440.0;
const NUMBER_MAX = 0x7fffffff;

(:inline)
function maxF(lhs as Float, rhs as Float) as Float {
    return lhs > rhs ? lhs : rhs;
}

(:inline)
function maxN(lhs as Number, rhs as Number) as Number {
    return lhs > rhs ? lhs : rhs;
}

(:inline)
function minF(lhs as Float, rhs as Float) as Float {
    return lhs < rhs ? lhs : rhs;
}

(:inline)
function minN(lhs as Number, rhs as Number) as Number {
    return lhs < rhs ? lhs : rhs;
}

(:inline)
function abs(val as Float) as Float {
    return val < 0 ? -val : val;
}

(:inline)
function absN(val as Number) as Number {
    return val < 0 ? -val : val;
}

// from https://forums.garmin.com/developer/connect-iq/f/discussion/338071/testing-for-nan/1777041#1777041
(:inline)
function isnan(a as Float) as Boolean {
    return a != a;
}

(:debug,:inline)
function logLevel(lvl as String, message as String) as Void {
    System.println("" + Time.now().value() + " " + lvl + " " + message);
}

(:release,:inline)
function logLevel(lvl as String, message as String) as Void {}

(:debug,:inline)
function logE(message as String) as Void {
    logLevel("E", message);
}

(:release,:inline)
function logE(message as String) as Void {}

(:debug,:inline)
function logD(message as String) as Void {
    logLevel("D", message);
}

(:release,:inline)
function logD(message as String) as Void {}

(:debug,:inline)
function logT(message as String) as Void {
    logLevel("T", message);
}

(:release,:inline)
function logT(message as String) as Void {}

(:debug,:inline,:background)
function logB(message as String) as Void {
    System.println("" + Time.now().value() + " " + "B" + " " + message);
}

(:release,:inline,:background)
function logB(message as String) as Void {
}

function distance(x1 as Float, y1 as Float, x2 as Float, y2 as Float) as Float {
    var xDist = x2 - x1;
    var yDist = y2 - y1;
    return Math.sqrt(xDist * xDist + yDist * yDist).toFloat();
}

function inHitbox(
    x as Number,
    y as Number,
    hitboxX as Float,
    hitboxY as Float,
    halfHitboxSize as Float
) as Boolean {
    return (
        y > hitboxY - halfHitboxSize &&
        y < hitboxY + halfHitboxSize &&
        x > hitboxX - halfHitboxSize &&
        x < hitboxX + halfHitboxSize
    );
}

function mustUpdate() as Void {
    WatchUi.showToast(Rez.Strings.mustUpdate, {});
}

(:release)
function breadcrumbContextWasNull() as Void {
}
    
(:debug)
function breadcrumbContextWasNull() as Void {
    logE("breadcrumb context was null");
    throw new Exception();
}
