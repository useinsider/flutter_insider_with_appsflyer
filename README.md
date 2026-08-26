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
