# Screenshoots

Apple has certain [specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications) for the screenshots required for App Store app submissions.

## Simulators

As of this writing screenshots from these devices satisifies their requirements:
```
xcrun simctl create "5.5" "iPhone 8 Plus" iOS16.0
xcrun simctl create "6.7" "iPhone 15 Plus" iOS17.0
```

> Note that installation of additional xcode simulator runtimes may be required.

## Screenshot stages

The app should be installed with the network "N1 A/S" selected.

These are the stages to screenshot for each of the simulators mentioned above.

|Name|Modes|Description|
|---|---|---|
|Price list|Light, Dark|The dashboard with the active hour highlighted in the middle of the screen|
|Hourly details|Light, Dark|The details of the active hour|
|Notification|Light, Dark|Creation of a new notification with all values set to default|
