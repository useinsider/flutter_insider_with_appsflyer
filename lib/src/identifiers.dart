import 'constants.dart';

class FlutterInsiderIdentifiers {
  Map<String, String>? identifiers;

  FlutterInsiderIdentifiers() {
    identifiers = new Map<String, String>();
  }

  FlutterInsiderIdentifiers addEmail(String email) {
    identifiers!.addAll({Constants.ADD_EMAIL: email});
    return this;
  }

  FlutterInsiderIdentifiers addPhoneNumber(String phoneNumber) {
    identifiers!.addAll({Constants.ADD_PHONE_NUMBER: phoneNumber});
    return this;
  }

  FlutterInsiderIdentifiers addUserID(String userID) {
    identifiers!.addAll({Constants.ADD_USER_ID: userID});
    return this;
  }

  FlutterInsiderIdentifiers addCustomIdentifier(String key, String value) {
    identifiers!.addAll({key: value});
    return this;
  }

  Map? getIdentifiers() {
    return identifiers;
  }
}
