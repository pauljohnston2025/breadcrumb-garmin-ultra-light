// layout inspired by https://github.com/vtrifonov-esfiddle/ConnectIqDataPickers
// but I have simplified the ui significantly

import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

(:settingsView,:menu2)
class PositionPickerGeneric {
    private var choices as Array<String>;
    private var choicePositions as Array<[Float, Float]>;
    private var halfWidth as Number?;
    private var halfHitboxSize as Number = 35;
    private var currentSelected as Number = 0; // needs to always be a valid index of choices array

    function initialize(choices as Array<String>) {
        self.choices = choices;
        choicePositions = [];
        halfWidth = null;
    }

    function onLayout(dc as Dc) as Void {
        halfWidth = dc.getWidth() / 2;
        choicePositions = pointsOnCircle(
            halfWidth,
            halfWidth,
            halfWidth - halfHitboxSize,
            choices.size()
        );
    }

    private function pointsOnCircle(
        centerX as Number,
        centerY as Number,
        radius as Number,
        numPoints as Number
    ) as Array<[Float, Float]> {
        var points = new [numPoints];
        var angleIncrement = (2 * Math.PI) / numPoints;

        // Shift the starting position to -90 degrees (Top of the screen)
        var startAngleShift = -Math.PI / 2;

        for (var i = 0; i < numPoints; i++) {
            // Apply the shift to every point
            var angle = i * angleIncrement + startAngleShift;

            var x = centerX + radius * Math.cos(angle).toFloat();
            var y = centerY + radius * Math.sin(angle).toFloat();

            points[i] = [x, y];
        }

        if (numPoints > 1) {
            halfHitboxSize =
                distance(points[0][0] as Float, points[0][1]as Float, points[1][0]as Float, points[1][1]as Float).toNumber() / 2;
        }

        return points as Array<[Float, Float]>;
    }

    function onUpdate(dc as Dc) as Void {
        var bgColour = backgroundColourInner();
        dc.setColor(Graphics.COLOR_WHITE, bgColour);
        dc.clear();
        drawText(dc);
        dc.setColor(Graphics.COLOR_WHITE, bgColour);
        dc.setPenWidth(4);
        for (var i = 0; i < choicePositions.size(); ++i) {
            var point = choicePositions[i];
            var pointX = point[0];
            var pointY = point[1];
            var choice = self.choices[i];
            dc.drawText(
                pointX,
                pointY,
                Graphics.FONT_SMALL,
                choice,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
        var selected = choicePositions[currentSelected];
        dc.drawCircle(selected[0], selected[1], halfHitboxSize);
    }

    function drawText(dc as Dc) as Void;

    function confirm() as Void {
        performAction(currentSelected);
    }

    function previousSelection() as Void {
        --currentSelected;
        if (currentSelected < 0) {
            currentSelected = choicePositions.size() - 1;
        }
        forceRefresh();
    }

    function nextSelection() as Void {
        ++currentSelected;
        if (currentSelected >= choicePositions.size()) {
            currentSelected = 0;
        }
        forceRefresh();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onTap(x as Number, y as Number) as Boolean {
        // for touch devices if we press the ok button exit immediately
        var tapIndex = indexOfTap(x, y);
        if (tapIndex == null) {
            return false;
        }

        return performAction(tapIndex);
    }

    function indexOfTap(x as Number, y as Number) as Number? {
        for (var i = 0; i < choicePositions.size(); i++) {
            var point = choicePositions[i];
            var pointX = point[0];
            var pointY = point[1];

            // Check if the tap is within the hit box
            if (inHitbox(x, y, pointX, pointY, halfHitboxSize.toFloat())) {
                currentSelected = i;
                return i;
            }
        }

        return null;
    }

    // performAction for the current index
    // eg.
    // onReading(myLookupThingToDo[tapIndex]);
    // WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    protected function performAction(tapIndex as Number) as Boolean {
        return false;
    }
    protected function backgroundColourInner() as Number {
        return Graphics.COLOR_BLACK;
    }
}

function stringToStringArray(charset as String) as Array<String> {
    var stringArr = [] as Array<String>;
    for (var i = 0; i < charset.length(); ++i) {
        stringArr.add(charset.substring(i, i + 1) as String);
    }
    return stringArr;
}

(:settingsView,:menu2)
class NumberPicker extends PositionPickerGeneric {
    private var _charset as String;
    private var maxLength as Number;
    private var currentVal as String;
    private var myText as WatchUi.Text;

    function initialize(charset as String, maxLength as Number) {
        self._charset = charset;
        self.maxLength = maxLength;
        self.currentVal = "";
        myText = new WatchUi.Text({
            :text => "",
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
        });

        var stringArr = (["OK"] as Array<String>).addAll(stringToStringArray(charset));
        PositionPickerGeneric.initialize(stringArr as Array<String>);
    }

    function drawText(dc as Dc) as Void {
        myText.draw(dc);
    }

    function performAction(tapIndex as Number) as Boolean {
        if (tapIndex == 0) {
            // we are on the 'OK' button
            onReading(currentVal);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }

        if (currentVal.length() >= maxLength) {
            return false; // can't handle it
        }

        if (tapIndex != 0) {
            currentVal += self._charset.substring(tapIndex - 1, tapIndex);
        }

        myText.setText(currentVal);

        forceRefresh();
        return true;
    }

    function onBack() as Void {
        if (currentVal.length() <= 0) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return;
        }

        var subStr = currentVal.substring(null, -1);
        if (subStr != null) {
            currentVal = subStr;
            myText.setText(currentVal);
            forceRefresh();
        }
    }

    protected function backgroundColourInner() as Number {
        return backgroundColour(currentVal);
    }

    protected function backgroundColour(value as String) as Number {
        return Graphics.COLOR_BLACK;
    }

    protected function onReading(value as String) as Void;
}

(:settingsView,:menu2)
class SettingsFloatPicker extends NumberPicker {
    private var callback as (Method(value as Float) as Void);
    private var parent as Renderable;
    private var defaultVal as Float;
    function initialize(
        callback as (Method(value as Float) as Void),
        defaultVal as Float,
        parent as Renderable
    ) {
        NumberPicker.initialize("-0123456789.", 10);
        self.defaultVal = defaultVal;
        self.callback = callback;
        self.parent = parent;
    }

    protected function onReading(value as String) as Void {
        callback.invoke(Settings.parseFloatRaw("key", value, defaultVal));
        parent.rerender();
    }
}

(:settingsView,:menu2)
class SettingsNumberPicker extends NumberPicker {
    private var callback as (Method(value as Number) as Void);
    private var parent as Renderable;
    private var defaultVal as Number;

    function initialize(
        callback as (Method(value as Number) as Void),
        defaultVal as Number,
        parent as Renderable
    ) {
        NumberPicker.initialize("-0123456789", 10);
        self.defaultVal = defaultVal;
        self.callback = callback;
        self.parent = parent;
    }

    protected function onReading(value as String) as Void {
        callback.invoke(Settings.parseFloatRaw("key", value, defaultVal.toFloat()).toNumber());
        parent.rerender();
    }
}

(:settingsView,:menu2)
class RerenderIgnoredView extends WatchUi.View {
    function initialize() {
        View.initialize();

        // for some reason WatchUi.requestUpdate(); was not working so im pushing this view just to remove it, which should force a re-render
        // note: this seems to be a problem with datafields settings views on physical devices, appears to work fine on the sim
        // timer = new Timer.Timer();
        // need a timer running of this, since button presses from within the delegate were not triggering a reload
        // timer.start(method(:onTimer), 1000, true);
        // but timers are not available in the settings view (or at all in datafield)
        // "Module 'Toybox.Timer' not available to 'Data Field'"
    }

    function onLayout(dc as Dc) as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView,:menu2)
function forceRefresh() as Void {
    WatchUi.requestUpdate(); // sometimes does not work, but lets call it anyway
    WatchUi.pushView(new RerenderIgnoredView(), null, WatchUi.SLIDE_IMMEDIATE);
}

(:settingsView,:menu2)
class NumberPickerView extends WatchUi.View {
    private var picker as PositionPickerGeneric;

    function initialize(picker as PositionPickerGeneric) {
        self.picker = picker;
        View.initialize();

        // timer = new Timer.Timer();
        // need a timer running of this, since button presses from within the delegate were not triggering a reload
        // timer.start(method(:onTimer), 1000, true);
        // but timers are not available in the settings view (or at all in datafield)
        // "Module 'Toybox.Timer' not available to 'Data Field'"
    }

    function onLayout(dc as Dc) as Void {
        picker.onLayout(dc);
    }

    function onUpdate(dc as Dc) as Void {
        picker.onUpdate(dc);
        // logT("onUpdate");
        // Some exampls have the line below, do not do that, screen goes black (though it does work in the examples, guess just not when lanunched from menu?)
        // View.onUpdate(dc);
    }
}

(:settingsView,:menu2)
class NumberPickerDelegate extends WatchUi.BehaviorDelegate {
    private var picker as PositionPickerGeneric;

    function initialize(picker as PositionPickerGeneric) {
        self.picker = picker;
        WatchUi.BehaviorDelegate.initialize();
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        logT(
            "got number picker tap (x,y): (" +
                evt.getCoordinates()[0] +
                "," +
                evt.getCoordinates()[1] +
                ")"
        );

        var coords = evt.getCoordinates();
        var x = coords[0];
        var y = coords[1];

        return picker.onTap(x, y);
    }

    // for touch devices this is touching a section on the screen (we want to handle the onTap instead)
    // for non touch its the 'confirm' button
    // function onSelect() as Boolean {
    //     logT("got number picker onselect: ");
    //     picker.confirm();
    //     WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    //     return true;
    // }

    function onPreviousPage() as Boolean {
        logT("got number picker onPreviousPage: ");
        // fr255 the up/down buttons are on the left so up should go more clockwise ie. nextSelection
        // some other watches might be the other way around though, need to test (or wait for complaints)
        picker.nextSelection();
        return true;
    }

    function onNextPage() as Boolean {
        logT("got number picker onNextPage: ");
        // fr255 the up/down buttons are on the left so down should go more counter-clockwise ie. previousSelection
        // some other watches might be the other way around though, need to test (or wait for complaints)
        picker.previousSelection();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        logT("got number picker key event: " + key);
        if (key == WatchUi.KEY_ENTER) {
            picker.confirm();
            return true;
        }

        return false;
    }

    function onBack() as Boolean {
        // logT("got back");
        picker.onBack();
        return true;
    }
}
