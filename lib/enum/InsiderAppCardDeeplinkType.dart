/// Deeplink type identifiers resolved by `InsiderAppCardDeeplinkAction`.
///
/// Tells the host app how to open the action's `url`.
class InsiderAppCardDeeplinkType {
  /// The link is a custom URL scheme handled by the app itself.
  static const String URL_SCHEME = "url_scheme";

  /// The link opens in the in-app browser.
  static const String INTERNAL = "internal";

  /// The link opens in the system browser.
  static const String EXTERNAL = "external";

  /// No URL field has a non-empty value.
  static const String UNKNOWN = "unknown";
}
