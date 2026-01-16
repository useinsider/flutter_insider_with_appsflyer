import 'package:flutter/services.dart';
import 'package:flutter_insider/src/identifiers.dart';
import 'utils.dart';
import 'constants.dart';

class FlutterInsiderUser {
  late MethodChannel _channel;

  FlutterInsiderUser(MethodChannel methodChannel) {
    this._channel = methodChannel;
  }

  FlutterInsiderUser setGender(int gender) {
    try {
      _setUserAttribute(Constants.SET_GENDER, gender);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setBirthday(DateTime birthday) {
    try {
      _setUserAttribute(Constants.SET_BIRTHDAY,
          FlutterInsiderUtils.getDateForParsing(birthday));
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setName(String name) {
    try {
      _setUserAttribute(Constants.SET_NAME, name);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setSurname(String surname) {
    try {
      _setUserAttribute(Constants.SET_SURNAME, surname);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setLanguage(String language) {
    try {
      _setUserAttribute(Constants.SET_LANGUAGE, language);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setLocale(String locale) {
    try {
      _setUserAttribute(Constants.SET_LOCALE, locale);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setFacebookID(String facebookID) {
    try {
      _setUserAttribute(Constants.SET_FACEBOOK_ID, facebookID);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setTwitterID(String twitterID) {
    try {
      _setUserAttribute(Constants.SET_TWITTER_ID, twitterID);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setAge(int age) {
    try {
      _setUserAttribute(Constants.SET_AGE, age.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setSMSOptin(bool smsOptin) {
    try {
      _setUserAttribute(Constants.SET_SMS_OPTIN, smsOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setEmailOptin(bool emailOptin) {
    try {
      _setUserAttribute(Constants.SET_EMAIL_OPTIN, emailOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setLocationOptin(bool locationOptin) {
    try {
      _setUserAttribute(Constants.SET_LOCATION_OPTIN, locationOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setPushOptin(bool pushOptin) {
    try {
      _setUserAttribute(Constants.SET_PUSH_OPTIN, pushOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setWhatsappOptin(bool whatsappOptin) {
    try {
      _setUserAttribute(Constants.SET_WHATSAPP_OPTIN, whatsappOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setEmail(String email) {
    try {
      _setUserAttribute(Constants.SET_EMAIL, email);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setPhoneNumber(String phoneNumber) {
    try {
      _setUserAttribute(Constants.SET_PHONE_NUMBER, phoneNumber);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  _setUserAttribute(String key, dynamic value) {
    try {
      if (value == null) return;
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(key, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  _createMapForMethodCall(String key, dynamic value) {
    try {
      if (value == null) return null;
      Map<String, dynamic> map = <String, dynamic>{};
      map["key"] = key;
      map["value"] = value;
      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  FlutterInsiderUser setCustomAttributeWithString(String key, String value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_STRING, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithInt(String key, int value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithDouble(String key, double value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithBoolean(String key, bool value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithDate(String key, DateTime value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(
          key, FlutterInsiderUtils.getDateForParsing(value));
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DATE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithArray(
      String key, List<String> value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser unsetCustomAttribute(String key) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["key"] = key;
      _channel.invokeMethod(Constants.UNSET_CUSTOM_ATTRIBUTE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  void login(FlutterInsiderIdentifiers identifiers,
      {Function? insiderIDResult}) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["identifiers"] = identifiers.getIdentifiers();
      if (insiderIDResult != null) {
        args["insiderID"] = "insiderID";

        _channel.invokeMethod(Constants.LOGIN, args).then((insiderID) {
          insiderIDResult(insiderID);
        }).catchError((error) {
          FlutterInsiderUtils.putException(_channel, error);
        });
        return;
      }
      _channel.invokeMethod(Constants.LOGIN, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  void logout() {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      _channel.invokeMethod(Constants.LOGOUT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  void logoutResettingInsiderID(List<FlutterInsiderIdentifiers>? additionalIdentifiers,
      {Function? insiderIDResult}) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (additionalIdentifiers != null && additionalIdentifiers.isNotEmpty) {
        List<Map<String, String>?> identifiersList = [];
        for (var identifier in additionalIdentifiers) {
          identifiersList.add(identifier.getIdentifiers() as Map<String, String>?);
        }
        args["additionalIdentifiers"] = identifiersList;
      }
      if (insiderIDResult != null) {
        args["insiderIDResult"] = "insiderIDResult";
        _channel.invokeMethod(Constants.LOGOUT_RESETTING_INSIDER_ID, args).then((insiderID) {
          insiderIDResult(insiderID);
        }).catchError((error) {
          FlutterInsiderUtils.putException(_channel, error);
        });
        return;
      }
      _channel.invokeMethod(Constants.LOGOUT_RESETTING_INSIDER_ID, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }
}
