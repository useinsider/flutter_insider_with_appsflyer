/// Callback action identifiers emitted to the function passed to
/// [FlutterInsider.init].
///
/// The callback receives the integer action type as its first argument and a
/// data payload as its second; switch on these constants to handle each kind.
class InsiderCallbackAction {
  /// User opened a push notification. Payload contains the notification data.
  static const int NOTIFICATION_OPEN = 0;

  /// User tapped a button inside an in-app message. Payload contains the
  /// button data.
  static const int INAPP_BUTTON_CLICK = 1;

  /// Temp store: user completed a purchase from an in-app surface.
  static const int TEMP_STORE_PURCHASE = 2;

  /// Temp store: user added an item to the cart from an in-app surface.
  static const int TEMP_STORE_ADDED_TO_CART = 3;

  /// Temp store: a custom action defined in the campaign was triggered.
  static const int TEMP_STORE_CUSTOM_ACTION = 4;

  /// In-app message was rendered to the user.
  static const int INAPP_SEEN = 5;

  /// A new Insider session has started.
  static const int SESSION_STARTED = 6;
}
