# flutter_insider_with_appsflyer

This plugin is a custom plugin that includes both Insider and AppsFlyer SDKs.

## Getting Started

To integrate, add the following code to your `pubspec.yaml` file.

```
dependencies:
  flutter_insider_with_appsflyer:
    git:
      url: https://github.com/useinsider/flutter_insider_with_appsflyer
      ref: main
```

### Note

This is a custom plugin. Please consult with Insider plugin providers before integrating.

## Changelog

<details>
<summary><b>Recent releases</b> (click to expand)</summary>

<!-- CHANGELOG:START -->

### 5.3.0+nh

* **BREAKING**: Minimum supported Flutter version raised to 3.0.0. App Frames uses `PlatformViewsService.initExpensiveAndroidView`, added in Flutter 3.0.
* **BREAKING**: CocoaPods iOS deployment target raised to 12.2, matching `InsiderMobile` 16.2.0 and `InsiderHybrid` 1.8.0. Swift Package Manager stays at 12.0.
* Added `InsiderAppFramesView` widget with auto-height, a typed error model, and action callbacks.
* App Frames content lifecycle is reported through `onStatusChanged(status, previousStatus)` and the `InsiderAppFramesViewStatus` enum.
* Added `InsiderAppFramesViewStatus.unknown` for statuses reported by a newer native SDK; the widget collapses the frame on unknown statuses.
* Fixed `disabled` status to collapse the App Frame, matching both native SDKs.
* `InsiderAppFramesError.cause` now exposes the originating failure wrapped by the native SDKs.
* App Frames is a partner opt-in; enable via `com.useinsider.insider.APP_FRAMES_ENABLED` meta-data on Android or `App Frames Enabled` in `Info.plist` on iOS.
* Android: the plugin now depends on `androidx.webkit` for App Frames runtime support.
* Added optional `app` parameter to `init` and `initWithCustomEndpoint` to forward an app identifier to native SDKs.
* Fixed App Frames compilation on both CocoaPods and SwiftPM channels.
* Android & iOS SDK updated. (Android: 17.3.0, Android Hybrid: 1.4.0, iOS: 16.2.0, iOS Hybrid: 1.8.0)

### 5.3.0

* **BREAKING**: Minimum supported Flutter version raised to 3.0.0. App Frames uses `PlatformViewsService.initExpensiveAndroidView`, added in Flutter 3.0.
* **BREAKING**: CocoaPods iOS deployment target raised to 12.2, matching `InsiderMobile` 16.2.0 and `InsiderHybrid` 1.8.0. Swift Package Manager stays at 12.0.
* Added `InsiderAppFramesView` widget with auto-height, a typed error model, and action callbacks.
* App Frames content lifecycle is reported through `onStatusChanged(status, previousStatus)` and the `InsiderAppFramesViewStatus` enum.
* Added `InsiderAppFramesViewStatus.unknown` for statuses reported by a newer native SDK; the widget collapses the frame on unknown statuses.
* Fixed `disabled` status to collapse the App Frame, matching both native SDKs.
* `InsiderAppFramesError.cause` now exposes the originating failure wrapped by the native SDKs.
* App Frames is a partner opt-in; enable via `com.useinsider.insider.APP_FRAMES_ENABLED` meta-data on Android or `App Frames Enabled` in `Info.plist` on iOS.
* Android: the plugin now depends on `androidx.webkit` for App Frames runtime support.
* Added optional `app` parameter to `init` and `initWithCustomEndpoint` to forward an app identifier to native SDKs.
* Fixed App Frames compilation on both CocoaPods and SwiftPM channels.
* Android & iOS SDK updated. (Android: 17.3.0, Android Hybrid: 1.4.0, iOS: 16.2.0, iOS Hybrid: 1.8.0)

### 5.2.0+nh

* iOS SDK updated. (iOS: 15.2.0)

### 5.2.0

* iOS SDK updated. (iOS: 15.2.0)

### 5.1.1+nh

* iOS SDK updated. (iOS: 15.1.3)

### 5.1.1

* iOS SDK updated. (iOS: 15.1.3)

### 5.1.0+nh

* Android & iOS SDK updated. (Android: 16.0.9, iOS: 15.1.2)
* Added category support to App Cards; `InsiderAppCard` now exposes partner-defined category data (id and name).
* Fixed `getCampaigns` to skip malformed category elements instead of failing the entire response.

<!-- CHANGELOG:END -->

</details>

For the full version history, see [CHANGELOG.md](CHANGELOG.md).
