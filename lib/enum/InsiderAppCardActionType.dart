/// Action type identifiers used by App Card buttons and cards.
///
/// Each [InsiderAppCardAction] subclass exposes one of these strings via its
/// `actionType` field so consumers can disambiguate the action kind without
/// reflection.
class InsiderAppCardActionType {
  /// The action navigates the user via a deep link, internal browser, or
  /// external browser. Backed by [InsiderAppCardDeeplinkAction].
  static const String DEEP_LINK = "deep_link";

  /// The action opens the operating-system app settings page. Backed by
  /// [InsiderAppCardOpenSettingsAction].
  static const String OPEN_SETTINGS = "open_settings";

  /// The action triggers an in-product feedback flow. Backed by
  /// [InsiderAppCardFeedbackAction].
  static const String FEEDBACK = "feedback";
}
