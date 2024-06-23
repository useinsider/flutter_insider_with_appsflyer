import 'dart:async';
import 'constants.dart';

class FlutterInsiderIdentifiers {
  Map<String, String>? identifiers;

  FlutterInsiderIdentifiers() {
    identifiers = new Map<String, String>();
  }

  Future<FlutterInsiderIdentifiers> addEmail(String email) async {
    if (email == null) return this;

    identifiers!.addAll({Constants.ADD_EMAIL: email});

    return this;
  }

  Future<FlutterInsiderIdentifiers> addPhoneNumber(String phoneNumber) async {
    if (phoneNumber == null) return this;

    identifiers!.addAll({Constants.ADD_PHONE_NUMBER: phoneNumber});

    return this;
  }

  Future<FlutterInsiderIdentifiers> addUserID(String userID) async {
    if (userID == null) return this;

    identifiers!.addAll({Constants.ADD_USER_ID: userID});

    return this;
  }

  Future<FlutterInsiderIdentifiers> addCustomIdentifier(String key, String value) async {
    if (key == null || value == null) return this;

    identifiers!.addAll({key: value});
    
    return this;
  }

  Future<Map?> getIdentifiers() async {
    return identifiers;
  }
}
