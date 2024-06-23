import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_insider/src/identifiers.dart';
import 'utils.dart';
import 'constants.dart';

class FlutterInsiderUser {
  late MethodChannel _channel;

  FlutterInsiderUser(MethodChannel methodChannel) {
    this._channel = methodChannel;
  }

  Future<FlutterInsiderUser> setGender(int gender) async {
    try {
      if (gender == null) return this;

      _setUserAttribute(Constants.SET_GENDER, gender);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setBirthday(DateTime birthday) async {
    try {
      if (birthday == null) return this;

      _setUserAttribute(Constants.SET_BIRTHDAY, FlutterInsiderUtils.getDateForParsing(birthday));

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setName(String name) async {
    try {
      if (name == null) return this;

      _setUserAttribute(Constants.SET_NAME, name);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setSurname(String surname) async {
    try {
      if (surname == null) return this;

      _setUserAttribute(Constants.SET_SURNAME, surname);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setLanguage(String language) async {
    try {
      if (language == null) return this;
      _setUserAttribute(Constants.SET_LANGUAGE, language);
      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  Future<FlutterInsiderUser> setLocale(String locale) async {
    try {
      if (locale == null) return this;

      _setUserAttribute(Constants.SET_LOCALE, locale);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setFacebookID(String facebookID) async {
    try {
      if (facebookID == null) return this;

      _setUserAttribute(Constants.SET_FACEBOOK_ID, facebookID);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setTwitterID(String twitterID) async {
    try {
      if (twitterID == null) return this;

      _setUserAttribute(Constants.SET_TWITTER_ID, twitterID);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setAge(int age) async {
    try {
      if (age == null) return this;

      _setUserAttribute(Constants.SET_AGE, age.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setSMSOptin(bool smsOptin) async {
    try {
      if (smsOptin == null) return this;

      _setUserAttribute(Constants.SET_SMS_OPTIN, smsOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setEmailOptin(bool emailOptin) async {
    try {
      if (emailOptin == null) return this;
      
      _setUserAttribute(Constants.SET_EMAIL_OPTIN, emailOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  Future<FlutterInsiderUser> setLocationOptin(bool locationOptin) async {
    try {
      if (locationOptin == null) return this;

      _setUserAttribute(Constants.SET_LOCATION_OPTIN, locationOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setPushOptin(bool pushOptin) async {
    try {
      if (pushOptin == null) return this;

      _setUserAttribute(Constants.SET_PUSH_OPTIN, pushOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setWhatsappOptin(bool whatsappOptin) async {
    try {
      if (whatsappOptin == null) return this;

      _setUserAttribute(Constants.SET_WHATSAPP_OPTIN, whatsappOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setEmail(String email) async {
    try {
      if (email == null) return this;

      _setUserAttribute(Constants.SET_EMAIL, email);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setPhoneNumber(String phoneNumber) async {
    try {
      if (phoneNumber == null) return this;

      _setUserAttribute(Constants.SET_PHONE_NUMBER, phoneNumber);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  _setUserAttribute(String key, dynamic value) async {
    try {
      if (key == null || value == null) return;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(key, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  _createMapForMethodCall(String key, dynamic value) {
    try {
      if (key == null || value == null) return;

      Map<String, dynamic> map = <String, dynamic>{};

      map["key"] = key;
      map["value"] = value;

      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return null;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithString(String key, String value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_STRING, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithInt(String key, int value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithDouble(String key, double value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithBoolean(String key, bool value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithDate(String key, DateTime value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, FlutterInsiderUtils.getDateForParsing(value));

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DATE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  Future<FlutterInsiderUser> setCustomAttributeWithArray(String key, List<String> value) async {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      await _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future<FlutterInsiderUser> unsetCustomAttribute(String key) async {
    try {
      if (key == null) return this;

      Map<String, dynamic> args = <String, dynamic>{};
      
      args["key"] = key;

      await _channel.invokeMethod(Constants.UNSET_CUSTOM_ATTRIBUTE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future login(FlutterInsiderIdentifiers identifiers, {Function? insiderIDResult}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      args["identifiers"] = await identifiers.getIdentifiers();

      if (insiderIDResult != null) {
        args["insiderID"] = "insiderID";

        String? insiderID = await _channel.invokeMethod(Constants.LOGIN, args);

        insiderIDResult(insiderID);

        return this;
      }

      await _channel.invokeMethod(Constants.LOGIN, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  Future logout() async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      await _channel.invokeMethod(Constants.LOGOUT, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    
    return this;
  }
}
