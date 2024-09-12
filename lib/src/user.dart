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
      if (gender == null) return this;

      _setUserAttribute(Constants.SET_GENDER, gender);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setBirthday(DateTime birthday) {
    try {
      if (birthday == null) return this;

      _setUserAttribute(Constants.SET_BIRTHDAY, FlutterInsiderUtils.getDateForParsing(birthday));

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setName(String name)  {
    try {
      if (name == null) return this;

      _setUserAttribute(Constants.SET_NAME, name);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setSurname(String surname) {
    try {
      if (surname == null) return this;

      _setUserAttribute(Constants.SET_SURNAME, surname);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setLanguage(String language) {
    try {
      if (language == null) return this;
      _setUserAttribute(Constants.SET_LANGUAGE, language);
      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setLocale(String locale) {
    try {
      if (locale == null) return this;

      _setUserAttribute(Constants.SET_LOCALE, locale);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setFacebookID(String facebookID) {
    try {
      if (facebookID == null) return this;

      _setUserAttribute(Constants.SET_FACEBOOK_ID, facebookID);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setTwitterID(String twitterID) {
    try {
      if (twitterID == null) return this;

      _setUserAttribute(Constants.SET_TWITTER_ID, twitterID);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setAge(int age) {
    try {
      if (age == null) return this;

      _setUserAttribute(Constants.SET_AGE, age.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setSMSOptin(bool smsOptin) {
    try {
      if (smsOptin == null) return this;

      _setUserAttribute(Constants.SET_SMS_OPTIN, smsOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setEmailOptin(bool emailOptin) {
    try {
      if (emailOptin == null) return this;
      
      _setUserAttribute(Constants.SET_EMAIL_OPTIN, emailOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setLocationOptin(bool locationOptin) {
    try {
      if (locationOptin == null) return this;

      _setUserAttribute(Constants.SET_LOCATION_OPTIN, locationOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setPushOptin(bool pushOptin) {
    try {
      if (pushOptin == null) return this;

      _setUserAttribute(Constants.SET_PUSH_OPTIN, pushOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setWhatsappOptin(bool whatsappOptin) {
    try {
      if (whatsappOptin == null) return this;

      _setUserAttribute(Constants.SET_WHATSAPP_OPTIN, whatsappOptin.toString());

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setEmail(String email) {
    try {
      if (email == null) return this;

      _setUserAttribute(Constants.SET_EMAIL, email);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setPhoneNumber(String phoneNumber) {
    try {
      if (phoneNumber == null) return this;

      _setUserAttribute(Constants.SET_PHONE_NUMBER, phoneNumber);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  _setUserAttribute(String key, dynamic value) {
    try {
      if (key == null || value == null) return;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(key, args);
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

  FlutterInsiderUser setCustomAttributeWithString(String key, String value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_STRING, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setCustomAttributeWithInt(String key, int value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setCustomAttributeWithDouble(String key, double value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setCustomAttributeWithBoolean(String key, bool value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser setCustomAttributeWithDate(String key, DateTime value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, FlutterInsiderUtils.getDateForParsing(value));

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DATE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderUser setCustomAttributeWithArray(String key, List<String> value) {
    try {
      if (key == null || value == null) return this;

      Map<String, dynamic>? args = _createMapForMethodCall(key, value);

      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderUser unsetCustomAttribute(String key) {
    try {
      if (key == null) return this;

      Map<String, dynamic> args = <String, dynamic>{};
      
      args["key"] = key;

      _channel.invokeMethod(Constants.UNSET_CUSTOM_ATTRIBUTE, args);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  void login(FlutterInsiderIdentifiers identifiers, {Function? insiderIDResult}) {
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
}
