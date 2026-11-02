import 'package:flutter/foundation.dart';
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
  /// Stands in for an omitted `removeObjectsFromCustomAttribute` match, which
  /// Dart cannot otherwise tell from an explicit `null`. A non-const copy is
  /// not `identical` to it and its key fails native's own name rule, so it is
  /// refused rather than read as the wildcard.
  static const Map<String, Object> _matchNotGiven = <String, Object>{
    '__insider_match_not_given__': true
  };

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
      _setUserAttribute(
          Constants.SET_BIRTHDAY, birthday.millisecondsSinceEpoch.toString());
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
      // The string crossing the channel is read back as a 32-bit int: Android
      // throws in `Integer.parseInt`, iOS clamps in `intValue`.
      if (!FlutterInsiderUtils.isSendableInteger(
          Constants.SET_AGE, 'age', age)) {
        return this;
      }
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

  /// Records the user's promotional opt-in consent (Mobile Promotional
  /// Consent). Stored at the user (profile) level and synced to UCD for push
  /// targeting. When never set, the user is treated as not opted in.
  FlutterInsiderUser setPromotionalOptin(bool promotionalOptin) {
    try {
      _setUserAttribute(
          Constants.SET_PROMOTIONAL_OPTIN, promotionalOptin.toString());
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
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_STRING, key)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableInteger(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, key, value)) {
        return this;
      }
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_INT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Sets a double-typed custom attribute on the user. NaN and infinite values
  /// are ignored with a warning.
  FlutterInsiderUser setCustomAttributeWithDouble(String key, double value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableDouble(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE, key, value)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN, key)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_DATE, key)) {
        return this;
      }
      Map<String, dynamic>? args =
          _createMapForMethodCall(key, value.millisecondsSinceEpoch.toString());
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
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY, key)) {
        return this;
      }
      Map<String, dynamic>? args = _createMapForMethodCall(key, value);
      _channel.invokeMethod(Constants.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Appends [objects] to the array-of-objects custom attribute [key].
  ///
  /// Each object may hold `String`, `int`, `double`, `bool`, `DateTime`, an
  /// `Iterable` of strings or numbers (a `List` or a `Set`) or a nested
  /// `Map<String, Object>` value.
  ///
  /// Two layers drop things, and they drop different things. This SDK drops a
  /// NaN or infinite number, an array holding one, a null value, a key that
  /// closes a cycle, and — mirroring what native would drop silently — a key
  /// that fails native's name rule (`^[a-z][0-9a-z_]*$`), a string longer than
  /// 500 characters and a map nested deeper than two levels. Each one is named
  /// in a single warning per call, and an object left with no key is dropped
  /// whole. The object count and per-object key limits stay native's to
  /// enforce: the latter is a partner setting this SDK cannot know.
  ///
  /// The call is ignored, with a warning, when [objects] is empty or when no
  /// object keeps a key — either way there would be nothing to write.
  FlutterInsiderUser addObjectsToCustomAttribute(
      String key, List<Map<String, Object>> objects) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.ADD_OBJECTS_TO_CUSTOM_ATTRIBUTE, key)) {
        return this;
      }
      // Native treats an empty list as a no-op and says so only on its own
      // log channel, so stop here where the developer can see it.
      if (objects.isEmpty) {
        debugPrint('[Insider] '
            '${Constants.ADD_OBJECTS_TO_CUSTOM_ATTRIBUTE} ignored the call: '
            'there are no objects to add.');
        return this;
      }
      final serialized = FlutterInsiderUtils.serializeObjectsWithWarning(
          objects, Constants.ADD_OBJECTS_TO_CUSTOM_ATTRIBUTE);
      // Every object lost all of its keys: the call would succeed and write
      // nothing, which is the shape this round exists to remove.
      if (FlutterInsiderUtils.nothingSurvived(serialized)) return this;
      Map<String, dynamic> args = <String, dynamic>{};
      args["key"] = key;
      args["value"] = serialized;
      _channel
          .invokeMethod(Constants.ADD_OBJECTS_TO_CUSTOM_ATTRIBUTE, args)
          .catchError((Object error) => FlutterInsiderUtils.putBridgeError(
              _channel, Constants.ADD_OBJECTS_TO_CUSTOM_ATTRIBUTE, error));
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Merges [value] into **every** object of the array-of-objects custom
  /// attribute [key] that matches [match].
  ///
  /// The call is ignored, with a warning, when [match] is empty, when [value]
  /// is empty or keeps no key, or when an entry of [match] cannot be sent to
  /// native — a narrowed match would update more objects than requested, and
  /// an empty patch would blank every object it matched.
  FlutterInsiderUser mergeObjectsInCustomAttribute(
      String key, Map<String, Object> match, Map<String, Object> value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE, key)) {
        return this;
      }
      final typedMatch =
          _serializeMatch(match, Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE);
      if (typedMatch == null) return this;
      // Native ignores a merge whose value carries no key, and reports it only
      // on its own log channel. An empty value has nothing to merge anyway.
      if (value.isEmpty) {
        debugPrint('[Insider] '
            '${Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE} ignored the call: '
            'an empty value has nothing to merge.');
        return this;
      }

      Map<String, dynamic> args = <String, dynamic>{};
      args["key"] = key;
      args["match"] = typedMatch;
      final typedValue = FlutterInsiderUtils.serializeObjectWithWarning(
          value, Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE);
      // The value kept nothing, so the merge would write nothing. The helper
      // above already warned, naming the paths when there were any to name.
      if (typedValue.isEmpty) return this;
      args["value"] = typedValue;
      _channel
          .invokeMethod(Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE, args)
          .catchError((Object error) => FlutterInsiderUtils.putBridgeError(
              _channel, Constants.MERGE_OBJECTS_IN_CUSTOM_ATTRIBUTE, error));
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Removes **every** object of the array-of-objects custom attribute [key]
  /// that matches [match].
  ///
  /// Call it **without** a [match] to clear the whole attribute; that cannot
  /// be undone, and it warns when it happens. Omitting the argument is the
  /// only way to ask for that. A [match] that is given but empty, or given as
  /// an explicit `null`, is refused instead of being treated as the wildcard,
  /// because a match variable that turns out empty is far more often a bug
  /// than an intent to wipe the attribute.
  ///
  /// The call is also ignored if an entry of [match] cannot be sent to
  /// native, because a narrowed match would remove more objects than
  /// requested.
  FlutterInsiderUser removeObjectsFromCustomAttribute(String key,
      [Map<String, Object>? match = _matchNotGiven]) {
    try {
      // `identical`, not `match == null`: an explicit null is almost always a
      // variable that came out empty, and wiping the attribute cannot be undone.
      if (!identical(match, _matchNotGiven) && match == null) {
        debugPrint('[Insider] '
            '${Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE} ignored the '
            'call: a null match is not the wildcard. Call it without a match '
            'to remove every object.');
        return this;
      }
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE, key)) {
        return this;
      }
      Map<String, dynamic> args = <String, dynamic>{};
      args["key"] = key;
      if (identical(match, _matchNotGiven)) {
        // Native takes the wildcard path here and warns about it, but only on
        // its own log channel, which the app developer never sees.
        debugPrint('[Insider] '
            '${Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE} is removing '
            'every object of \'$key\' because no match was given. This '
            'cannot be undone.');
      } else {
        final typedMatch = _serializeMatch(
            match!, Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE);
        if (typedMatch == null) return this;
        args["match"] = typedMatch;
      }
      _channel
          .invokeMethod(Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE, args)
          .catchError((Object error) => FlutterInsiderUtils.putBridgeError(
              _channel, Constants.REMOVE_OBJECTS_FROM_CUSTOM_ATTRIBUTE, error));
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Serializes [match], or returns null and warns when the match cannot be
  /// sent as written.
  ///
  /// An explicitly empty match is refused. Native cannot tell "no match given"
  /// from "an empty match given" — both overloads collapse to the same null —
  /// and for `remove` that means wiping the attribute. Dart keeps the two
  /// apart, so this is not a divergence from native but the restoration of
  /// information the native signature loses.
  List<Map<String, Object>>? _serializeMatch(
      Map<String, Object> match, String methodName) {
    if (match.isEmpty) {
      debugPrint('[Insider] $methodName ignored the call: an empty match '
          'would remove every object. Call it without a match if that is '
          'what you intended.');
      return null;
    }

    final typedMatch = FlutterInsiderUtils.serializeObject(match);
    final dropped = FlutterInsiderUtils.droppedKeyPaths(match, typedMatch);
    if (dropped.isEmpty) return typedMatch;

    debugPrint('[Insider] $methodName ignored: the match contains values that '
        'cannot be sent to native (${dropped.join(', ')}). Sending the rest '
        'would match more objects than requested.');
    return null;
  }

  /// Removes a previously set custom attribute by [key].
  FlutterInsiderUser unsetCustomAttribute(String key) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          Constants.UNSET_CUSTOM_ATTRIBUTE, key)) {
        return this;
      }
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
  /// Insider ID once the native side has merged the user. An empty identifier
  /// set is refused with a warning and [insiderIDResult] is called with the
  /// empty string, because native would answer such a call with nothing at
  /// all.
  ///
  /// The empty string is what the Android bridge already sends when native
  /// yields no Insider ID, and unlike `null` it also satisfies a callback
  /// whose parameter is a non-nullable `String`.
  void login(FlutterInsiderIdentifiers identifiers,
      {Function? insiderIDResult}) {
    try {
      Map? givenIdentifiers = identifiers.getIdentifiers();
      if (!FlutterInsiderUtils.isSendableIdentifierSet(
          Constants.LOGIN, givenIdentifiers)) {
        insiderIDResult?.call('');

        return;
      }
      Map<String, dynamic> args = <String, dynamic>{};
      args["identifiers"] = givenIdentifiers;
      if (insiderIDResult != null) {
        args["insiderID"] = "insiderID";

        _channel.invokeMethod(Constants.LOGIN, args).then((insiderID) {
          insiderIDResult(insiderID);
        }).catchError((error) {
          FlutterInsiderUtils.putException(_channel, error);
        });
        return;
      }
      _channel.invokeMethod(Constants.LOGIN, args).catchError((error) {
        FlutterInsiderUtils.putException(_channel, error);
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Identifies the user via [identifiers] and resolves to the merged Insider
  /// ID; the awaitable form of native `login` with `insiderIDResult`.
  ///
  /// Resolves to `null` when no ID is delivered, the native call fails or
  /// [timeout] elapses: the native SDK answers only on a successful merge, not
  /// when offline. A timeout does not cancel the native call. Never throws.
  /// An empty [identifiers] set is not sent and resolves to `null`, as `login`.
  ///
  /// [timeout] must be positive. After a `null`, read the current ID with
  /// `FlutterInsider.Instance.getInsiderID()`.
  Future<String?> loginAsync(FlutterInsiderIdentifiers identifiers,
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      Map? givenIdentifiers = identifiers.getIdentifiers();
      if (!FlutterInsiderUtils.isSendableIdentifierSet(
          Constants.LOGIN, givenIdentifiers)) {
        return null;
      }
      Map<String, dynamic> args = <String, dynamic>{};
      args["identifiers"] = givenIdentifiers;
      args["insiderID"] = "insiderID";

      return await _insiderIDReply(Constants.LOGIN, args, timeout);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return null;
    }
  }

  /// Logs the current user out, keeping the existing Insider ID intact.
  ///
  /// The returned [Future] completes when the native SDK call has returned.
  /// Errors are reported to the native SDK and never thrown.
  Future<void> logout() async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      await _channel.invokeMethod(Constants.LOGOUT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Logs the user out and resets the Insider ID, optionally attaching
  /// [additionalIdentifiers] to the new anonymous identity.
  ///
  /// If [insiderIDResult] is provided, it is invoked with the new Insider ID.
  void logoutResettingInsiderID(
      List<FlutterInsiderIdentifiers>? additionalIdentifiers,
      {Function? insiderIDResult}) {
    try {
      Map<String, dynamic> args = _resetArgs(additionalIdentifiers);
      if (insiderIDResult != null) {
        args["insiderIDResult"] = "insiderIDResult";
        _channel
            .invokeMethod(Constants.LOGOUT_RESETTING_INSIDER_ID, args)
            .then((insiderID) {
          insiderIDResult(insiderID);
        }).catchError((error) {
          FlutterInsiderUtils.putException(_channel, error);
        });
        return;
      }
      _channel
          .invokeMethod(Constants.LOGOUT_RESETTING_INSIDER_ID, args)
          .catchError((error) {
        FlutterInsiderUtils.putException(_channel, error);
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Logs the user out and resolves to the new Insider ID; the awaitable form
  /// of native `logoutResettingInsiderID` with `insiderIDResult`.
  ///
  /// Resolves to `null` when no ID is delivered, the native call fails or
  /// [timeout] elapses: the native SDK answers only on a successful reset. A
  /// timeout does not cancel the native call. Never throws.
  ///
  /// [timeout] must be positive. After a `null`, read the current ID with
  /// `FlutterInsider.Instance.getInsiderID()`.
  Future<String?> logoutResettingInsiderIDAsync(
      List<FlutterInsiderIdentifiers>? additionalIdentifiers,
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      Map<String, dynamic> args = _resetArgs(additionalIdentifiers);
      args["insiderIDResult"] = "insiderIDResult";

      return await _insiderIDReply(
          Constants.LOGOUT_RESETTING_INSIDER_ID, args, timeout);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return null;
    }
  }

  Map<String, dynamic> _resetArgs(
      List<FlutterInsiderIdentifiers>? additionalIdentifiers) {
    Map<String, dynamic> args = <String, dynamic>{};
    if (additionalIdentifiers != null && additionalIdentifiers.isNotEmpty) {
      List<Map<String, String>?> identifiersList = [];
      for (var identifier in additionalIdentifiers) {
        final Map? identifiers = identifier.getIdentifiers();
        identifiersList.add(
            identifiers == null ? null : Map<String, String>.from(identifiers));
      }
      args["additionalIdentifiers"] = identifiersList;
    }
    return args;
  }

  // The error handler sits on the channel call, not on the timeout, so a
  // native failure that arrives after the timeout is still reported.
  Future<String?> _insiderIDReply(
      String method, Map<String, dynamic> args, Duration timeout) async {
    final Object? raw = await _channel
        .invokeMethod<Object?>(method, args)
        .catchError((Object error) {
      FlutterInsiderUtils.putException(_channel, error);
      return null;
    }).timeout(timeout, onTimeout: () => null);
    return _normaliseInsiderID(raw);
  }

  // Without an ID Android answers "" and iOS answers nil, or [] on the
  // flag-less path; only a non-empty String is an Insider ID.
  String? _normaliseInsiderID(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }
}
