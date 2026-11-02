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

### 5.5.0+nh

* **BREAKING**: The plugin no longer depends on InsiderHybrid (Android `com.useinsider:insiderhybrid`, iOS `InsiderHybrid` pod and SwiftPM product). A host app that used InsiderHybrid classes through this plugin must declare that dependency itself.
* Added `loginAsync` and `logoutResettingInsiderIDAsync` methods that return the Insider ID as a `Future<String?>`, resolving after the native SDK completes the identity merge.
* Made `login`, `logout`, and `logoutResettingInsiderID` awaitable; each now returns a `Future` that completes when the native call returns.
* Made `disableInAppMessages`, `enableInAppMessages`, and `handleUniversalLink` awaitable.
* Made App Cards `view`, `click`, and `clickButton` awaitable; each returns a `Future<void>` that completes when the native call returns.
* Added `deeplinkType` field to `InsiderAppCard` deeplink action, exposing the link type as `InsiderAppCardDeeplinkType` (`urlScheme`, `internal`, `external`, `unknown`).
* Fixed `loginAsync` to skip the native call and warn when the identifier set is empty.
* Fixed `login` and `logoutResettingInsiderID` to preserve the delivered Insider ID when the `insiderIDResult` callback throws.
* Fixed App Cards `url` field to treat non-string values in the native payload as unset instead of throwing a `TypeError`.
* Fixed iOS event callbacks to skip a nil sink, preventing a crash when an SDK callback fires before Dart starts listening.
* Fixed `getMessageCenterData` to return an empty result on a native failure instead of never completing.

### 5.5.0

* **BREAKING**: The plugin no longer depends on InsiderHybrid (Android `com.useinsider:insiderhybrid`, iOS `InsiderHybrid` pod and SwiftPM product). A host app that used InsiderHybrid classes through this plugin must declare that dependency itself.
* Added `loginAsync` and `logoutResettingInsiderIDAsync` methods that return the Insider ID as a `Future<String?>`, resolving after the native SDK completes the identity merge.
* Made `login`, `logout`, and `logoutResettingInsiderID` awaitable; each now returns a `Future` that completes when the native call returns.
* Made `disableInAppMessages`, `enableInAppMessages`, and `handleUniversalLink` awaitable.
* Made App Cards `view`, `click`, and `clickButton` awaitable; each returns a `Future<void>` that completes when the native call returns.
* Added `deeplinkType` field to `InsiderAppCard` deeplink action, exposing the link type as `InsiderAppCardDeeplinkType` (`urlScheme`, `internal`, `external`, `unknown`).
* Fixed `loginAsync` to skip the native call and warn when the identifier set is empty.
* Fixed `login` and `logoutResettingInsiderID` to preserve the delivered Insider ID when the `insiderIDResult` callback throws.
* Fixed App Cards `url` field to treat non-string values in the native payload as unset instead of throwing a `TypeError`.
* Fixed iOS event callbacks to skip a nil sink, preventing a crash when an SDK callback fires before Dart starts listening.
* Fixed `getMessageCenterData` to return an empty result on a native failure instead of never completing.

### 5.4.0+nh

* Added `addObjectsToCustomAttribute`, `mergeObjectsInCustomAttribute`, and `removeObjectsFromCustomAttribute` to user attributes, and `addParameterWithObjectArray` to events, for array-of-objects custom attributes and event parameters.
* Fixed non-finite (NaN, infinite) numbers being silently forwarded to native, which broke payload serialization on both platforms; affected product events now fire with valid products only.
* Fixed `login` leaving the caller's callback unanswered when the identifier set is empty.
* Fixed blank attribute names and blank object-entry keys being silently dropped by native; the SDK now warns and skips them before the call reaches the channel.
* Fixed custom parameter array serialization to match native behavior: non-finite elements are now filtered element-wise on the flat path, and mixed-type arrays are dropped with a warning.
* Fixed object attribute serialization so that nesting depth, string-length limits, and empty-object handling match native sanitization rules.
* Fixed cart and wishlist page visits to filter only products with non-finite prices rather than dropping the entire call.
* Fixed `Set` and other `Iterable` values in object attributes being dropped; they are now sent as arrays on both platforms.
* Fixed native bridge handling of unknown type tags, out-of-range dates, fractional integers, and cyclic maps to align with native behavior.
* Android & iOS SDK updated. (Android: 17.3.2, Android Hybrid: 1.4.0, iOS: 16.3.0, iOS Geofence: 1.3.0, iOS Hybrid: 1.8.0)
* Known platform difference: on iOS, `getSmartRecommendation` now returns an empty map when GDPR consent is false or the locale or currency is empty; on Android the same call still never completes.
* Known platform difference: on iOS, `getMessageCenterData` returns the messages wrapped as `[{data: [...]}]`; on Android it returns the message list directly.

### 5.4.0

* Added `addObjectsToCustomAttribute`, `mergeObjectsInCustomAttribute`, and `removeObjectsFromCustomAttribute` to user attributes, and `addParameterWithObjectArray` to events, for array-of-objects custom attributes and event parameters.
* Fixed non-finite (NaN, infinite) numbers being silently forwarded to native, which broke payload serialization on both platforms; affected product events now fire with valid products only.
* Fixed `login` leaving the caller's callback unanswered when the identifier set is empty.
* Fixed blank attribute names and blank object-entry keys being silently dropped by native; the SDK now warns and skips them before the call reaches the channel.
* Fixed custom parameter array serialization to match native behavior: non-finite elements are now filtered element-wise on the flat path, and mixed-type arrays are dropped with a warning.
* Fixed object attribute serialization so that nesting depth, string-length limits, and empty-object handling match native sanitization rules.
* Fixed cart and wishlist page visits to filter only products with non-finite prices rather than dropping the entire call.
* Fixed `Set` and other `Iterable` values in object attributes being dropped; they are now sent as arrays on both platforms.
* Fixed native bridge handling of unknown type tags, out-of-range dates, fractional integers, and cyclic maps to align with native behavior.
* Android & iOS SDK updated. (Android: 17.3.2, Android Hybrid: 1.4.0, iOS: 16.3.0, iOS Geofence: 1.3.0, iOS Hybrid: 1.8.0)
* Known platform difference: on iOS, `getSmartRecommendation` now returns an empty map when GDPR consent is false or the locale or currency is empty; on Android the same call still never completes.
* Known platform difference: on iOS, `getMessageCenterData` returns the messages wrapped as `[{data: [...]}]`; on Android it returns the message list directly.

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
