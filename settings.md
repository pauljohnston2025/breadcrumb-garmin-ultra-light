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

### Display Lat/Long

Determines if the current latitude and longitude are displayed on the watch screen.

### Max Track Points

The maximum number of coordinates to store for the current track the user is moving along. Each coordinate point contains a latitude, longitude and altitude. A smaller number should be used to conserve memory and cpu. Larger numbers results in a smoother track line drawn on screen.   

### Use Track As Heading Speed 

If the user travels above this speed (in m/s) we will use the last few track points to get a bearing (for screen rotations) instead of the devices magnetic compass. This is mostly helpful for when running or any activity where your wrist is likely to be moving around alot, since it is hard to hold your wrist still enough to see the direction of travel. It also stops any delay when first looking at the watch, since it may have rendered when your wrist was not angled straight ahead.

0 - Always use track
large number (eg. 1000) - Never use track
0.5 - Use track when traveling faster than 0.5m/s and magnetic compass when traveling slower (stopped)

This method of calculating the heading may result in slow updates to the heading angle, due to it needing a few points after a turn in order to know the turn has happened. This is most noticeable directly after exiting a corner, it may take a second or 2 for the heading to update.

For best results:  

[Compute Interval](#compute-interval) should be set to 1 (or a smaller number) in order to log as many track points as possible. Higher values of compute interval will result in delayed angle changes to the heading when turning corners.  
[Min Track Point Distance (m)](#min-track-point-distance-m) should be set to 0 so all points are stored, which will result in smoother corner transitions.

If setting `Use Track As Heading Speed ` to 0 the heading will not update when stationary. This is because the gps will ping around on your current location, and would result in constant changes to the heading if we kept updating it based on the last track points. 


### Min Track Point Distance (m)

The minimum distance (in meters) between 2 track points in order to store them in teh current track. Larger values will result in a more granular track an require less operations of [Track Point Reduction Method](#track-point-reduction-method) which should increase battery performance. The number of track points will never exceed [Max Track Points](#max-track-points).

### Compute Interval

The number of seconds that need to elapse before we try and add or next track point. Higher values should result in better battery performance (less calculations), but will also mean you need to wait longer for the map and track to update. This setting is also used to control how often to refresh the buffer if using a buffered render mode. A lower number should be used for high speed activities such as cycling.

### Center User Offset Y

Offsets the users vertical position by a fraction of the screen size. Larger values will move the position further down the screen. eg. 0.5 - user in the middle, 0.75 user 3/4 of the way down the screen (near the bottom), 0.25 user near the top of the screen. Larger values are generally preferred, as it allow you to see more of the route in front of the users position. The users offset only applies when 'zooming' around the user, see [Zoom At Pace Mode](#zoom-at-pace-mode). Note: The offset can also be applied if you have manually zoomed into the map and have overridden the Zoom At Pace Mode.  

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

### Enable Routes

Global route enable/disable flag. If disabled turns off all routes, or if enabled allows routes that are enabled to render.

Note: the Ultra Light version only supports a single route at a time.

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
