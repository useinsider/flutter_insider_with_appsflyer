import 'package:flutter/services.dart';
import 'package:flutter_insider/src/identifiers.dart';
import 'utils.dart';
import 'constants.dart';

/// Builder-style API for setting attributes on the current Insider user and
/// for managing identification (login/logout).
///
/// Obtain an instance through [FlutterInsider.getCurrentUser]; setters return
/// `this` so they can be chained:
///
/// ```dart
/// FlutterInsider.Instance
///     .getCurrentUser()
///     ?.setName('Ada')
///     .setEmail('ada@example.com')
///     .setEmailOptin(true);
/// ```
///
/// All setters forward to the native Insider SDK via the shared method
/// channel; exceptions are reported to the SDK through
/// [FlutterInsiderUtils.putException] and never thrown to the caller.
class FlutterInsiderUser {
  late MethodChannel _channel;

  FlutterInsiderUser(MethodChannel methodChannel) {
    this._channel = methodChannel;
  }

  /// Sets the user's gender. Pass one of the [InsiderGender] constants.
  FlutterInsiderUser setGender(int gender) {
    try {
      _setUserAttribute(Constants.SET_GENDER, gender);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's [birthday]. Stored as epoch milliseconds on the native
  /// side.
  FlutterInsiderUser setBirthday(DateTime birthday) {
    try {
      _setUserAttribute(Constants.SET_BIRTHDAY, birthday.millisecondsSinceEpoch.toString());
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the user's first name.
  FlutterInsiderUser setName(String name) {
    try {
      _setUserAttribute(Constants.SET_NAME, name);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's surname / last name.
  FlutterInsiderUser setSurname(String surname) {
    try {
      _setUserAttribute(Constants.SET_SURNAME, surname);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's preferred language as an ISO 639-1 code (e.g. `tr`).
  FlutterInsiderUser setLanguage(String language) {
    try {
      _setUserAttribute(Constants.SET_LANGUAGE, language);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's locale (e.g. `tr_TR`).
  FlutterInsiderUser setLocale(String locale) {
    try {
      _setUserAttribute(Constants.SET_LOCALE, locale);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's Facebook account identifier.
  FlutterInsiderUser setFacebookID(String facebookID) {
    try {
      _setUserAttribute(Constants.SET_FACEBOOK_ID, facebookID);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's Twitter / X account identifier.
  FlutterInsiderUser setTwitterID(String twitterID) {
    try {
      _setUserAttribute(Constants.SET_TWITTER_ID, twitterID);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's age in years.
  FlutterInsiderUser setAge(int age) {
    try {
      _setUserAttribute(Constants.SET_AGE, age.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Records the user's SMS opt-in consent.
  FlutterInsiderUser setSMSOptin(bool smsOptin) {
    try {
      _setUserAttribute(Constants.SET_SMS_OPTIN, smsOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Records the user's email opt-in consent.
  FlutterInsiderUser setEmailOptin(bool emailOptin) {
    try {
      _setUserAttribute(Constants.SET_EMAIL_OPTIN, emailOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Records the user's location-tracking opt-in consent.
  FlutterInsiderUser setLocationOptin(bool locationOptin) {
    try {
      _setUserAttribute(Constants.SET_LOCATION_OPTIN, locationOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Records the user's push-notification opt-in consent.
  FlutterInsiderUser setPushOptin(bool pushOptin) {
    try {
      _setUserAttribute(Constants.SET_PUSH_OPTIN, pushOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Records the user's WhatsApp opt-in consent.
  FlutterInsiderUser setWhatsappOptin(bool whatsappOptin) {
    try {
      _setUserAttribute(Constants.SET_WHATSAPP_OPTIN, whatsappOptin.toString());
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's email address.
  FlutterInsiderUser setEmail(String email) {
    try {
      _setUserAttribute(Constants.SET_EMAIL, email);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets the user's phone number in E.164 format (e.g. `+905551234567`).
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

  /// Sets a string-typed custom attribute on the user.
  FlutterInsiderUser setCustomAttributeWithString(String key, String value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_STRING, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets an integer-typed custom attribute on the user.
  FlutterInsiderUser setCustomAttributeWithInt(String key, int value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets a double-typed custom attribute on the user.
  FlutterInsiderUser setCustomAttributeWithDouble(String key, double value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets a boolean-typed custom attribute on the user.
  FlutterInsiderUser setCustomAttributeWithBoolean(String key, bool value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets a date-typed custom attribute on the user. Stored as epoch
  /// milliseconds on the native side.
  FlutterInsiderUser setCustomAttributeWithDate(String key, DateTime value) {
    try {
      Map<String, dynamic>? args = _createMapForMethodCall(
          key, value.millisecondsSinceEpoch.toString());
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_DATE, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets a string-array-typed custom attribute on the user.
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

  /// Removes a previously set custom attribute by [key].
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

  /// Identifies the user via one or more [identifiers] (email, phone, user
  /// ID, custom).
  ///
  /// If [insiderIDResult] is provided, it is invoked with the resulting
  /// Insider ID once the native side has merged the user.
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

  /// Logs the current user out, keeping the existing Insider ID intact.
  void logout() {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      _channel.invokeMethod(Constants.LOGOUT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Logs the user out and resets the Insider ID, optionally attaching
  /// [additionalIdentifiers] to the new anonymous identity.
  ///
  /// If [insiderIDResult] is provided, it is invoked with the new Insider ID.
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
