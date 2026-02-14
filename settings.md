# Prerequisites

If trying to send routes to the watch app you will require a bluetooth connection with a phone running the [Companion App](https://github.com/pauljohnston2025/breadcrumb-mobile.git), and the [garmin connect app](https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile&hl=en_AU).  
If you just wish to use the breadcrumb track feature (a trail of your current track), it can be used without any phone connection.  

This is a datafield, not a full fledged app, it runs in the context of native activity.  
The datafield is expected to be used to cover the full available area of a round watchface.  
It will still work with non-round devices or partial layouts, but the full feature set of the ui will not be possible due to the limited space.

To add datafield to a native app:

1. Open the app (eg. running), you do not have to start the activity, just open it.
1. Long press to open settings (or use the touchscreen to press settings)
1. Navigate to Data Screens
1. Select screen
1. Choose layout - recommended full screen layout
1. Edit data fields - choose the 'BreadCrumbDataField' from the 'ConnectIQ Fields' menu

Some helpful guides on adding data fields:

- [For the venu range](https://support.garmin.com/en-AU/?faq=gyywAozBuAAGlvfzvR9VZ8&identifier=707572&searchQuery=data%20field&tab=topics)
- [A more thorough explanation for a different app](https://support.garmin.com/en-AU/?faq=3HkHX1wT6U7TeNB7YHfiT7&identifier=707572&searchQuery=data%20field&tab=topics)


Note: Some older devices less than API Level 3.2.0 are limited to messages from the companion app once every 5 minutes, this is a garmin limitation due to them not having support for Background.registerForPhoneAppMessageEvent. This means any route sending, settings loading, or any messages from the companion app can take up to 5 minutes to take effect. You can see your api version at https://developer.garmin.com/connect-iq/compatible-devices/. Any devices that support registering for phone ap messages should see no delay in the companion app messages, though will still need to have the datafield app in the foreground for some messages to take effect.

---

All settings are editable from 4 places.

Please note: All settings are entered in metric (meters or seconds) because there is no way for me to support both without bloating the app considerably. The watch will render the distance and elevation scales based on the units set on the watches system settings.  

- The [connect iq store](#garmin-settings-connect-iq-store) where you installed the app.
- [On Device](#on-device)
- [Companion App](https://github.com/pauljohnston2025/breadcrumb-mobile/blob/master/manual.md#device-settings-page)
- [On Screen UI](#ui-mode)

The connectiq store does not work for all settings (namely route configuration), use the on device or companion app settings instead.

# Garmin Settings (Connect Iq Store)

Please note: The nested garmin settings have a strange behaviour of the app is not running when the settings are saved. Please ensure the datafields in running in the foreground to have the best experience when editing the settings through garmin connect iq see detailed note at: https://github.com/pauljohnston2025/breadcrumb-garmin/issues/6#issuecomment-3315417515

---

# General

### Mode Display Order

Changes the order that modes are displayed in, modes can be removed entirely by omitting them from the list. CSV integer list of [display modes](#display-mode).  
An empty list forces the mode to not change when pressing the 'next mode' button. This can be useful for locking the display to a user selected mode.  
Note: Even with this setting, users can manually select a mode to display that is not in this list, when the 'next mode' is pressed we will return to cycling through modes, and may never return to the mode that was manually selected if it is not in the list.  

eg. 

0,1,2 - Each button press of the 'next mode' will go Track/Route -> Elevation -> Map Move -> <loop back to start>

1,3,2 - Elevation -> Debug -> Map Move -> <loop back to start>

1 - Just show the Elevation page, nothing else

<empty list> - Stay on whatever page the user manually selected (disables the 'next mode' button)

Numbers MUST not appear twice in the list also numbers that are not in the modes list below MUST not be included.



### Display Mode

Configure which screen is displayed for the datafield.

0 - Track/Route - Current track, and any loaded routes, will be shown  
![](images/track-full.png)  
1 - Elevation - An elevation chart showing current distance traveled, current elevation and the route/track profile.  
![](images/elevation.png)  
2 - Map Move - Allows panning around the map at a set zoom.  
![](images/settings/mapmove.png)    
3 - Debug - A debug screen that may be removed in future releases. Shows the current state of the app.  
![](images/settings/debug.png)  
4 - map move zoom (similar to map move page, but only allows zooming in and out (larger hitbox area)
5 - map move up/down (similar to map move page, but only allows moving up and down (larger hitbox area)
6 - map move left/right (similar to map move page, but only allows moving left and right (larger hitbox area)

### Display Lat/Long

Determines if the current latitude and longitude are displayed on the watch screen.

### Map Move Screen Size

How far to move across the screen when panning the map using the on screen ui. Relative to screen size, eg. 0.3 moves a third of the screen, 0.5 moves half the screen.   

---

### UI Mode

There is an on screen ui that can be used to control different parts of the watch app, this ui can be hidden or entirely disabled.  
Note: There is a limitation on garmin that datafields can only receive tap events see [input-handling](https://developer.garmin.com/connect-iq/core-topics/input-handling/), this also means I cannot handle any physical button presses. All of the settings should be configurable from the companion app without using the onscreen ui.  

Show On Top - Show the ui and the current state of everything its controlling  
Hidden - Still responds to touch but does not display the current state  
Disabled - No touch handling, no display of state

The ui appears on most screens, but is limited to what that screen can do.

The Track/Route page allows you to do the most with the onscreen ui.  
![](images/settings/uimodetrackfullsize.png)

Clear Route - Will prompt you if you are sure, and let you clear all routes on the device  
Zoom at Pace Mode - See [Zoom At Pace Mode](#zoom-at-pace-mode)

- M - zoom when moving
- S - zoom when stopped
- N - Never zoom
- A - Always zoom
- R - Routes Without Track

Return To User - Allows you to return to the users location, and resume using Zoom at Pace Mode to determine the scale and zoom level. It is only shown when the map has been panned or zoomed away from the users location.  
Display Mode - See [Display Mode](#display-mode)

- T - Track/Route
- E - Elevation
- M - Map Move
- D - Debug
- Z - Map move zoom
- V - Map move up/down
- H - Map move left/right

`+` Button (top of screen) allows zooming into the current location  
`-` Button (bottom of screen) allows zooming out of the current location  

Other Screens:  
Map move allows you to pan around the map, clear routes and toggle the display mode. see [Map Move Screen Size](#map-move-screen-size) for configuring how far to move.
Elevation allows you to clear routes and toggle display mode.  
The debug screen only allows you to toggle the display mode.

---

### Elevation Mode

Stacked - Draw all routes and the current track ontop of each other, the first point of each route will be on the left of the screen  
Route 1 - Blue, Route 2 - Red, Current Track - Green  
![](images/settings/elevationstacked.png)  
OrderedRoutes - Draw all routes one after the other, and overlay the track ontop. Generally best when each route is a different part of an overall route, eg. triathlons. Ensure you load the routes in the correct order on the device, an incorrect order will lead to elevation data being in the wrong spot.  
Route 1 - Blue, Route 2 - Red, Current Track - Green  
![](images/settings/elevationorderedroutes.png)

---

### Compute Interval

The number of seconds that need to elapse before we try and add or next track point. Higher values should result in better battery performance (less calculations), but will also mean you need to wait longer for the map and track to update. This setting is also used to control how often to refresh the buffer if using a buffered render mode. A lower number should be used for high speed activities such as cycling.

---

### Render Mode

Unbuffered Rotations - Renders the breadcrumb trail by rotating the map in the users direction of travel.  
No Buffer No Rotations - The breadcrumb trail is always north facing, and will not rotate when the user turns.

### Center User Offset Y

Offsets the users vertical position by a fraction of the screen size. Larger values will move the position further down the screen. eg. 0.5 - user in the middle, 0.75 user 3/4 of the way down the screen (near the bottom), 0.25 user near the top of the screen. Larger values are generally preferred, as it allow you to see more of the route in front of the users position. The users offset only applies when 'zooming' around the user, see [Zoom At Pace Mode](#zoom-at-pace-mode). Note: The offset can also be applied if you have manually zoomed into the map and have overridden the Zoom At Pace Mode.  

---

# Track

### Max Track Points

The maximum number of coordinates to store for the current track the user is moving along. Each coordinate point contains a latitude, longitude and altitude. A smaller number should be used to conserve memory and cpu. Larger numbers results in a smoother track line drawn on screen.   

### Track Style

***BEWARE***
Anything with (CPU Intensive) might crash with watchdog errors, since it uses line interpolations to draw the line in multiple sections.

Determines the visual appearance of your breadcrumb trail.

* Line: A standard continuous solid line.  
* Dashed: A dashed line path. (CPU Intensive)   
* Raw Points: Dots drawn only at actual GPS coordinates.  
* Points: Dots spaced evenly along the path using interpolation. (CPU Intensive)  
* Raw Boxes: Square outlines only at actual GPS coordinates.  
* Boxes: Square outlines spaced evenly along the path. (CPU Intensive)  
* Raw Filled Squares: Solid squares only at actual GPS coordinates.  
* Filled Squares: Solid squares spaced evenly along the path. (CPU Intensive)  
* Raw Circle Outlines: Hollow circles only at actual GPS coordinates.  
* Circle Outlines: Hollow circles spaced evenly along the path. (CPU Intensive)  
* Checkerboard: Tiled dual-tone pattern. Excellent for distinguishing overlapping tracks (Texture).  
* Hazard Stripes: High-contrast diagonal stripes (Texture).  
* Dot Matrix: A mesh-like texture that makes the track look semi-transparent (Texture).  
* Polka Dot: Stylized dots; provides a clear but non-distracting path (Texture).  
* Diamond Scale: Overlapping geometric pattern resembling scales (Texture).  

(Raw) Styles should be used with a high [Max Track Points](#max-track-points) or [Coordinate Point Limit](https://github.com/pauljohnston2025/breadcrumb-mobile/blob/master/manual.md#routes) so that the points/boxes appear along the whole path, rather than just at the corners. For best results you should use [Track Point Reduction Method](#track-point-reduction-method) `Downsample` so that points are kept a consistent distance apart.  

(Texture) denotes styles that are generated with a texture, this may only work on some supported devices.

Performance Note: Styles labeled as (CPU Intensive) use interpolation to create a smooth, high-density visual path. This requires significantly more calculations per frame than "Raw" or "Line" styles and may impact battery life, or result in watchdog errors that cause a crash, use them with care.

### Track Width

The thickness (in pixels) of the track drawn on the screen. Default is usually 4 pixels. Larger widths make the track easier to see but may obscure map details.  
Be careful about making the track/route too wide, it leads to more pixels needing to be drawn, and can slow down the renders (especially if using a texture).


### Use Track As Heading Speed 

If the user travels above this speed (in m/s) we will use 2 last recorded points to get a bearing (for screen rotations) instead of the devices magnetic compass. This is mostly helpful for when running or any activity where your wrist is likely to be moving around alot, since it is hard to hold your wrist still enough to see the direction of travel. It also stops any delay when glancing at the watch during the run, since it may have rendered when your wrist was not angled straight ahead.

0 - Always use track  
large number (eg. 1000) - Never use track  
0.5 - Use track when traveling faster than 0.5m/s and magnetic compass when traveling slower (stopped)  

This method of calculating the heading may result in slow updates to the heading angle, due to it needing a few points after a turn in order to know the turn has happened. This is most noticeable directly after exiting a corner, it may take a second or 2 for the heading to update.

For best results:  

If setting `Use Track As Heading Speed ` to 0 the heading will not update when stationary. This is because the gps will ping around on your current location, and would result in constant changes to the heading if we kept updating it based on the last track points. 


### Min Track Point Distance (m)

The minimum distance (in meters) between 2 track points in order to store them in teh current track. Larger values will result in a more granular track an require less operations of [Track Point Reduction Method](#track-point-reduction-method) which should increase battery performance. The number of track points will never exceed [Max Track Points](#max-track-points).

### Track Point Reduction Method

How to reduce the number of track points when we reach [Max Track Points](#max-track-points). When the limit is reached restrictPoints is called with the selected method.

Downsample - A dumb but battery and cpu efficient method to remove half of the points from the track. It keeps every second point, so may remove corner points from the track.

Reumann Witkam - A smart but computationally heavy method of removing only points that are needed. It tries to only keep only the corner points, as straight lines down a road can be just 2 points. It may use more battery and will result in more calls to restrictPoints since it does not remove all points. Based on https://psimpl.sourceforge.net/reumann-witkam.html . Falls back to the `Downsample` strategy if not enough points are removed.

---

# Data Field

### Top Data Field Type

Breadcrumb supports adding datafield values to the top and bottom of the screen. 

The currently supported fields are:

* None - Nothing displayed
* Map Scale - Scale bar for map distance
* Altitude - Current elevation
* Avg Heart Rate - Average heart rate
* Avg Speed - Average speed
* Heart Rate - Current heart rate
* Speed - Current speed
* Distance - Distance traveled
* Time - Elapsed time
* Total Ascent - Total elevation gain
* Total Descent - Total elevation loss
* Avg Pace - Average pace
* Pace - Current pace


### Bottom Data Field Type

Same as [Top Data Field Type](#top-data-field-type) but at the bottom of the screen.

### Data Field Text Size

The text size for the top and bottom data fields.  

---

# Zoom At Pace

Controls how the app zooms around the user, ie. it changes the viewport (based on speed or not).

### Zoom At Pace Mode

Controls the zoom level at different speeds

Zoom When Moving - Typically used for a running/hiking so you can see the next upcoming turn whilst you are moving. When stopped the map will return to fully zoomed out so you can investigate your position on the overall route.  
Zoom When Stopped - Inverse of Zoom When Moving.  
Never Zoom - Always shows the full route/track overview.  
Always Zoom - Always shows `Zoom At Pace Meters` regardless of the speed.  
Routes Without Tack - Same as `Never Zoom` but does not include the track in the bounding box. Useful for caching a route, Can view the route without the current location changing the map zoom. Also handy for users that do not care about venturing outside the route area.

### Zoom At Pace Meters Around User

How far, in meters, to render around the user when zoomed in. This is also a 'minimum' render distance for when the bounding box of the current track/route is too small. If we allow rendering of really small bounding boxes, it zooms in too far and results in blury maps.

### Zoom At Pace Speed

How fast, in m/s, the user needs to be moving in order to trigger zoom changes.

---

# Alerts

Calculating off track alerts (either Draw Line To Closest Point, or Off Track Alerts) is a computationally heavy task. This means if there are multiple large routes the watch can error out with a watchdog error if our code executes too long. I have tested with up to 3 large routes on my venu2s, and it seems to handle it. Only enabled routes are taken into consideration. For multiple enabled routes, you are considered on-track if you are on at least one of the tracks. See the [Routes](#routes) section for use cases of multiple routes, eg. triathlons.

### Off Track Distance

The number of meters you need to be off track for an alert to be triggered or a line to be drawn back to the track.

### Off Track Check Interval

How often, in seconds, to run the calculation of off track alerts (since its expensive). Once you rejoin the track, a line will continue to be draw to the closest point on the closest enabled route until we recalculate. eg. an interval of 60 will mean the line will still be drawn for up to 1minute after we rejoin the track. This number should be set to multiple of [Off Track Alerts Max Report Interval](#off-track-alerts-max-report-interval) for best results, as an alert will only fire when we check if we are off track. eg. Set this to check once every 30 seconds, but set [Off Track Alerts Max Report Interval](#off-track-alerts-max-report-interval) to 60 so that we only get notified every minute when we are trying to rejoin the track. If this is set higher than [Off Track Alerts Max Report Interval](#off-track-alerts-max-report-interval) the alert interval effectively becomes the check interval. Note: alerts are only checked if the last track point changes, if you stand in the same spot after leaving the track, no further alerts will be triggered.

### Draw Line To Closest Point

Draw a line to the closests point on the closest enabled route.

### Draw Cheverons

Draw arrows in the direction of travel. Uses off track calculation to know where we are up to on the track, and draws arrows for the next few points on the trail.  

### Off Track Alerts

Trigger an alert when you leave a route by `Off Track Distance`.

### Wrong Direction Alerts

Trigger an alert when you navigate the track in the wrong direction.

### Turn Alert Time (s)

Enabled turn-by-turn navigation (requires directions to be sent from the companion app).  
The number correlates to the time away from the turn the alert will fire (based on current speed). Ie. if set to 20 an alert will fire 20s before we reach the turn, based on the current speed of travel, if we are moving at 2m/s the alert will fire 40m before the turn.  
Set to -1 to disable turn alerts.  
See [Min Turn Alert Distance (m)](#min-turn-alert-distance-m) for configuring the minimum distance.  

Note: If your are off track the direction shown in the turn alert may be incorrect, this is because the direction is precomputed assuming you are on track, this is for performance reasons to avoid tripping the watchdog.

Ensure to enable [Turn Point Limit](https://github.com/pauljohnston2025/breadcrumb-mobile/blob/master/manual.md#routes) in the companion app in order to send the directions to the watch to enable turn-by-turn navigation.

Note: The turn-by-turn angle given by the alert is only an indication of the angle to turn only, I hope to improve on the algorithm I use to determine the angle in future releases. It should not be relied upon for perfect accuracy, and you should glance down at the watch to get an accurate indication on which direction to follow on the route.

I strongly suggest enabling off track alerts when using this feature, to ensure better detection of upcoming turns, it will also assist if you happen to take the wrong turn at an intersection. The turn-by-turn is just to make you aware that you should be turning off the current heading soon, to avoid accidentally continuing straight on the path.

### Min Turn Alert Distance (m)

Configures the minimum distance for turn alerts, useful for when moving at slow speeds ensures that we do not have to be directly on the corner (when the time based alert reaches 1m or something very small).  
Set to -1 to disable the minimum distance check.

If you want a distance only based turn alert. eg. Always trigger the alert 10m from the corner. Set `Min Turn Alert Distance (m) = 10` and `Turn Alert Time (s) = -1`.  
For time based only Set `Min Turn Alert Distance (m) = -1` and `Turn Alert Time (s) = <desired time>`.

### Off Track Alerts Max Report Interval

How often, in seconds, an alert should fire. Alerts will continue firing until you return to the planned route (or reach a section of another enabled route). Also controls the max alert speed for [Wrong Direction Alerts](#wrong-direction-alerts)

### Off Track Alerts Alert Type

**Toast (notification)**: Some devices have issues with alerts rendering, so you can use a toast. This is the default as it does not require enabling alerts on the device.  
**Alerts**: Send an alert instead of a toast, to use this you need to also enable alerts for the datafield in the activity settings. see [Through Alerts](#through-alerts). Also controls the alert type for [Wrong Direction Alerts](#wrong-direction-alerts)  
**Image**: Same as `Alerts` but implemented locally rather than through garmins `showAlert`. This makes them more stable (no exception handling because of a currently active alert that we cannot replace), and ensures the latest alert is always show.

---

### Colours

Should be set to a valid hex code RRGGBB not all are required eg. FF00 will render as green

Track Colour - The colour of the in progress track  
Track Colour 2 - The secondary colour of the in progress track (only used in some track styles) 
Default Route Colour - The default colour of newly loaded routes
Elevation Colour - The colour of the scale/numbers on the elevation page  
User Colour - The colour of the user triangle (current user position)  
Normal Mode Colour - The colour of scale/numbers on the track/routes page  
UI Colour - The colour of the on screen ui  
Debug Colour - The colour of the debug page

---

### Routes

Garmin has an issue with array settings where they cannot be modified by the connect iq app. It appears to be a known issue, but unlikely to be solved. Per route settings should be edited from the watch or android app only.

### Enable Routes

Global route enable/disable flag. If disabled turns off all routes, or if enabled allows routes that are enabled to render.

### Display Route Names

enabled:
![](images/settings/routenamesenabled.png)
disabled:
![](images/settings/routenamesdisabled.png)

### Max Routes

The maximum number of routes to store on the device, set to 1 if you want each new route loaded on the device to be the only one shown. Multiple routes are handy to add different parts of a course, or for multisport activities such as triathlons, each part of the course can be a separate colour. On some low memory devices this is hard coded to 1 and the setting cannot be changed.  

### Per Route settings

Id - The id of the route - read only  
Name - Defaults to the route name that was added, but can be modified to anything you desire.  
Enabled - If this route appears on any of the device screens, routes can be disabled so that multiple routes can be pre loaded and enabled when needed. eg. Day 1, Day 2.  
Route Colour - The colour of the route.  
Route Colour 2 - The secondary colour of the route (only used with some route styles).  
Reversed - To reverse the direction of the route.  
Style - see [Track Style](#track-style).  
Width - see [Track Width](#track-width).  

---

# Debug Settings

The watch app has a bunch of debug data to aid in development and help with bug reporting. Most users will not need to touch these settings, but some users may find it useful or like the look of the additional detail it provides. The debug settings and exactly what they control (and how they are displayed) can change at any time, some of them may be moved into other settings sections once they are stable.

Note: Not all debug settings will work on all release builds, a message will be displayed if it has been compiled out and it is enabled.

### Show Points

*REMOVED* use [Track Style](#track-style) instead

![](images/settings/debug-points.png)
![](images/settings/debug-points-zoomed.png)

### Draw Line To Closest Point On Track

Similar to the off track alerts line, but draws the line to the closest point on the track. This is not always the current location, as

### Include Debug Page In On Screen Ui

*REMOVED* use [Mode Display Order](#mode-display-order) instead

### Draw Hit Boxes

Show the hit-boxes for onscreen ui touches.

### Show Turn Points

Draws a circle around all of the turns that are in a route. The circle corresponds to [Turn Alert Time (s)](#turn-alert-time-s).

### Show Turn Point Text Under Index

Display information about the turns on the route (angle of turn, index of tun in coordinates), only for the first 'Show Turn Point Text Under Index' turns on the route.   


---

### Return To User

Return to the users location, and automatic scaling. Use this after you have manually zoomed, or set the displayed latitude/longitude. Users with the on screen ui can also touch the crosshairs to return to the users location.  


### Restore Defaults

Clear all storage and reset settings to their default values.

---

# On Device

Only some high memory devices allow configuring the settings directly from the watch, all other devices will need to use an alternate method for configuring the settings.  
It is much easier to configure the settings from the ConnectIQ store, or through the companion app, but it is possible to use the on device settings. All of the settings should have the same names, see above for explanation on each setting.

![](images/settings/ondevice.png)
![](images/settings/numberpicker.png)

To use the number/colour pickers entering the value by touching characters/numbers on the screen then confirmed/removed by pressing the device buttons. Confirm to confirm on screen selection, back to delete a character or exit without making a change.  
Devices that have multiple buttons can also use the up/down buttons to move the cursor around the screen.

### Before Activity Start

To edit settings from on device (on venu series):

- Ensure the data field is added to your activity of choice
- Open the app (eg. running). DO NOT start the activity, you can only edit before activity start.
- Use touch screen to slide up settings. DO NOT long press, as that only gives you access to the run settings (layouts etc.), not our settings
- You should now see a menu 'ConnectIQ Fields'
- From here we can select 'BreadcrumbDataField' and modify our settings

### Through Alerts

Settings can now also be now be edited through the alerts menu (on venu series):

- Ensure the data field is added to your activity of choice
- Open the app (eg. running). Start the activity.
- Long press the bottom button to open run settings
- Click Alerts / Add new
- Scroll down to 'Connect IQ'
- From here we can select 'BreadcrumbDataField' and modify our settings
- Opening the settings again can be found in the alerts tab (click 'BreadcrumbDataField' then modify settings)
