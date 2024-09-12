import 'constants.dart';

class FlutterInsiderIdentifiers {
  Map<String, String>? identifiers;

  FlutterInsiderIdentifiers() {
    identifiers = new Map<String, String>();
  }

  FlutterInsiderIdentifiers addEmail(String email) {
    if (email == null) return this;

    identifiers!.addAll({Constants.ADD_EMAIL: email});

    return this;
  }

  FlutterInsiderIdentifiers addPhoneNumber(String phoneNumber) {
    if (phoneNumber == null) return this;

    identifiers!.addAll({Constants.ADD_PHONE_NUMBER: phoneNumber});

    return this;
  }

  FlutterInsiderIdentifiers addUserID(String userID) {
    if (userID == null) return this;

    identifiers!.addAll({Constants.ADD_USER_ID: userID});

    return this;
  }

  FlutterInsiderIdentifiers addCustomIdentifier(String key, String value) {
    if (key == null || value == null) return this;

    identifiers!.addAll({key: value});
    
    return this;
  }

  Map? getIdentifiers() {
    return identifiers;
  }
}
