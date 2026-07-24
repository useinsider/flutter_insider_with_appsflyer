import 'constants.dart';

/// Collects identifiers used to recognise a user across sessions and devices.
///
/// Build an instance, attach one or more identifiers, and pass it to
/// [FlutterInsiderUser.login] or [FlutterInsider.getMessageCenterDataWithIdentifiers]:
///
/// ```dart
/// final identifiers = FlutterInsiderIdentifiers()
///     .addEmail('ada@example.com')
///     .addUserID('user-42');
///
/// FlutterInsider.Instance.getCurrentUser()?.login(identifiers);
/// ```
class FlutterInsiderIdentifiers {
  /// Backing map of identifier key/value pairs.
  Map<String, String>? identifiers;

  FlutterInsiderIdentifiers() {
    identifiers = new Map<String, String>();
  }

  /// Attaches an email identifier.
  FlutterInsiderIdentifiers addEmail(String email) {
    identifiers!.addAll({Constants.ADD_EMAIL: email});
    return this;
  }

  /// Attaches a phone-number identifier (E.164 format).
  FlutterInsiderIdentifiers addPhoneNumber(String phoneNumber) {
    identifiers!.addAll({Constants.ADD_PHONE_NUMBER: phoneNumber});
    return this;
  }

  /// Attaches an external user ID assigned by your system.
  FlutterInsiderIdentifiers addUserID(String userID) {
    identifiers!.addAll({Constants.ADD_USER_ID: userID});
    return this;
  }

  /// Attaches a custom identifier under [key] with the given [value].
  FlutterInsiderIdentifiers addCustomIdentifier(String key, String value) {
    identifiers!.addAll({key: value});
    return this;
  }

  /// Returns the underlying map of identifiers, or `null` if none were
  /// attached.
  Map? getIdentifiers() {
    return identifiers;
  }
}
