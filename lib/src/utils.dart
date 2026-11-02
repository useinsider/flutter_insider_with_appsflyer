import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Internal helpers shared by the public Flutter API surfaces.
///
/// Most members are implementation details of the plugin; only
/// [serializeCustomParameters] and [putException] are documented here as they
/// appear in dartdoc references from the public API.
class FlutterInsiderUtils {
  /// Forwards a caught exception to the native Insider SDK as a non-fatal
  /// error report. Fire-and-forget — never re-throws.
  ///
  /// The returned future never completes with an error either. Callers do not
  /// await it, so a rejection would surface as an unhandled zone error in the
  /// host app — its console, and its crash reporter if one is wired up. That is
  /// exactly backwards: this path only runs once something has already gone
  /// wrong inside the plugin, and reporting it must not become a second failure
  /// the customer sees. Every rejection is swallowed — most often a
  /// `MissingPluginException` when the channel is not wired up, or a
  /// `PlatformException` the native handler returns for any throw of its own.
  static Future<void> putException(
      MethodChannel methodChannel, Object exception) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      // Inside the try as well: a custom exception with a throwing toString()
      // would otherwise reject the future this doc promises never rejects.
      args["exception"] = exception.toString();

      await methodChannel.invokeMethod('putException', args);
    } catch (_) {
      // Deliberately swallowed; see the doc comment above.
    }
  }

  /// The key rule both native SDKs enforce, copied from Android
  /// `StaticUtils.isNameValid` / `NAME_PATTERN` (`StaticUtils.java:102`) and
  /// its iOS counterpart. A key that fails it is dropped natively without
  /// reaching the developer's console, and an object whose keys all fail is
  /// dropped whole — so the whole call can write nothing.
  static final RegExp nativeKeyPattern = RegExp(r'^[a-z][0-9a-z_]*$');

  /// Copied from native `Constants.OBJECT_VALUE_MAX_STRING_LENGTH`. A longer
  /// string value is dropped by the object sanitizer.
  static const int maxObjectStringLength = 500;

  /// Copied from native `Constants.OBJECT_VALUE_MAX_NESTING_DEPTH`. A map
  /// nested deeper than this is dropped by the object sanitizer.
  ///
  /// This also bounds the recursion: a deep chain can no longer overflow the
  /// stack, so no separate stack-safety ceiling is needed behind it.
  static const int maxObjectNestingDepth = 2;

  /// Returns true when [key] can name an attribute. Otherwise warns naming
  /// [methodName] and returns false: native rejects a blank attribute name
  /// without a word, so the call is dropped here where the developer sees it.
  static bool isSendableKey(String methodName, String key) {
    if (key.trim().isEmpty) {
      debugPrint('[Insider] $methodName ignored the call: an empty or '
          'whitespace-only key cannot be sent to native.');

      return false;
    }

    if (!nativeKeyPattern.hasMatch(key)) {
      debugPrint('[Insider] $methodName ignored the call: a key must start '
          'with a lowercase letter and hold only lowercase letters, digits '
          'and underscores.');

      return false;
    }

    return true;
  }

  /// Returns true when [value] can be sent as an identifier. Otherwise warns
  /// naming [methodName] and returns false: native drops a blank identifier
  /// value without a word, so the call is dropped here where it is visible.
  ///
  /// Only an exactly empty value is rejected, not a whitespace-only one:
  /// native accepts `'   '` for `addUserID` and `addCustomIdentifier`
  /// (`InsiderIdentifiers.java:41`, `InsiderIdentifiers.m:54`).
  ///
  /// Content validation — the e-mail and phone regexes — stays native-side,
  /// unlike the key rule, the 500-character cap and the nesting limit this
  /// file does mirror. The test is what a wrong mirror would cost: a
  /// structural rule is binary, so mirroring it wrong changes nothing, while
  /// a content judgement mirrored wrong rejects a value native accepts and
  /// breaks a working call.
  static bool isSendableIdentifierValue(String methodName, String value) {
    if (value.isNotEmpty) return true;

    debugPrint('[Insider] $methodName ignored the call: an empty value cannot '
        'be sent to native.');

    return false;
  }

  /// Returns true when [identifiers] can identify a user. Otherwise warns
  /// naming [methodName] and returns false.
  ///
  /// An empty set is not merely a no-op: native `login` returns early without
  /// invoking its `InsiderIDResult` callback when the set carries no entry
  /// (`InsiderUser.java`, `InsiderUser.m`), so the channel result is never
  /// delivered and the caller's future never completes. Refusing the call
  /// here is what keeps that future answerable.
  static bool isSendableIdentifierSet(String methodName, Map? identifiers) {
    if (identifiers != null && identifiers.isNotEmpty) return true;

    debugPrint('[Insider] $methodName ignored the call: the identifier set is '
        'empty, so there is nothing to identify the user with.');

    return false;
  }

  /// The largest magnitude both native bridges can carry in an `int`
  /// parameter. The 32-bit floor (-2147483648) is deliberately excluded so
  /// that every wrapper states one number instead of an asymmetric range.
  static const int MAX_SENDABLE_INTEGER = 2147483647;

  /// Returns true when [value] fits the 32-bit range both bridges narrow to.
  /// Otherwise warns naming [methodName] and [key] and returns false.
  ///
  /// A wider value is not merely lost: the Android bridge narrows it
  /// (`3000000000` becomes `-1294967296`) or throws on the user-attribute
  /// path, and iOS wraps it the same way, so the same call writes a different
  /// wrong number on each platform.
  static bool isSendableInteger(String methodName, String key, int value) {
    if (value >= -MAX_SENDABLE_INTEGER && value <= MAX_SENDABLE_INTEGER) {
      return true;
    }

    debugPrint('[Insider] $methodName ignored $key: only whole numbers within '
        'the 32-bit range can be sent to native.');

    return false;
  }

  /// Warns that [methodName] was not sent because the price of [productID] is
  /// not finite. The construction-time warning alone does not say which call
  /// was dropped, so every skip names itself.
  static void warnUnsendablePrice(String methodName, String productID) {
    debugPrint('[Insider] $methodName skipped ${_productLabel(productID)}: its '
        'price is NaN or infinite, so the call carrying it was not sent.');
  }

  /// Names a product in a warning. A product without an id would otherwise
  /// leave the sentence without a subject, as the other wrappers found too.
  static String _productLabel(String productID) =>
      productID.trim().isEmpty ? 'a product with no id' : productID;

  /// Warns that [methodName] left [productIDs] out because their price is not
  /// finite. Unlike [warnUnsendablePrice] the call itself still reaches native
  /// with the remaining products, so the wording must not claim otherwise.
  static void warnUnsendableProducts(
      String methodName, List<String> productIDs) {
    if (productIDs.isEmpty) return;

    final labels = productIDs.map(_productLabel).join(', ');

    debugPrint('[Insider] $methodName left out $labels: their price is NaN or '
        'infinite. The rest of the call was still sent.');
  }

  /// Reports a native bridge rejection: the developer sees a warning in their
  /// own console, the SDK still receives the exception. The bridge itself can
  /// only report to [putException], so this is where the warning belongs.
  static Future<void> putBridgeError(
      MethodChannel methodChannel, String methodName, Object error) {
    debugPrint('[Insider] $methodName was rejected by the native bridge: '
        '$error. The call was not sent.');
    return putException(methodChannel, error);
  }

  static getContentOptimizerMap(String variableName, dynamic defaultValue,
      int dataType, MethodChannel channel) {
    try {
      Map<String, dynamic> map = <String, dynamic>{};

      map["variableName"] = variableName;
      map["defaultValue"] = defaultValue;
      map["dataType"] = dataType;

      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(channel, Exception);
    }

    return null;
  }

  /// Returns true when [value] is finite. Otherwise prints a warning naming
  /// [methodName] and [key] and returns false: NaN and infinite numbers break
  /// native payload serialization (Android drops the enclosing parameter
  /// block, iOS the whole session stop request).
  static bool isSendableDouble(String methodName, String key, double value) {
    if (value.isFinite) return true;
    debugPrint('[Insider] $methodName ignored $key: NaN and infinite numbers '
        'cannot be sent to native.');
    return false;
  }

  static String getDateForParsing(DateTime date) {
    int milliseconds = date.millisecondsSinceEpoch;
    DateTime dateWithMilliseconds =
        DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return dateWithMilliseconds
        .toUtc()
        .add(date.timeZoneOffset)
        .toIso8601String();
  }

  /// Returns [values] unchanged. Empty entries are kept: both native SDKs
  /// only type-check a string array, so dropping them here would send a
  /// different array than a native or React Native integration does.
  static List<String>? validateStringArray(List<String>? values) => values;

  /// Drops non-finite entries, mirroring what both native SDKs do with a
  /// numeric array. An array left empty is kept as an empty array, which is
  /// what native stores for it.
  static List<num>? validateNumericArray(List<num>? values) {
    if (values == null) return null;

    return values.where((e) => e.isFinite).toList();
  }

  /// Serialises a `<String, Object>` map of custom parameters into the typed
  /// list format `[{type, key, value}]` expected by both native bridges.
  ///
  /// Supported value types: `bool`, `int`, `double`, `String`, `DateTime`
  /// (epoch milliseconds), `List<String>`, `List<num>`.
  ///
  /// Unsupported entries, and entries whose key native would reject, are
  /// dropped. Native drops them too but reports it only on its own log
  /// channel, so this path names every one of them in the warning families
  /// below.
  ///
  /// A non-finite scalar is dropped for a different reason — native does not
  /// just skip it, it breaks the payload around it (Android loses the enclosing
  /// parameter block, iOS the whole stop request), so the value must never
  /// reach the bridge. Do not remove that filter to "match native".
  ///
  /// Arrays follow what native does with a plain array setter: a non-finite
  /// entry is filtered out and the rest of the array is still sent, and an
  /// array that is empty — whether the caller passed it empty or the filter
  /// emptied it — keeps its key. An empty `List<String>` is sent as a string
  /// array and an empty `List<num>` as a numeric array; an untyped empty list
  /// carries no element type, so it falls back to the numeric type the React
  /// Native and WebView SDKs default to.
  ///
  /// Two of these array losses are partial and invisible to native, so this
  /// path warns about them itself: the keys a non-finite element was filtered
  /// out of, and the date or boolean arrays neither native SDK can store.
  static List<Map<String, Object>> serializeCustomParameters(
      Map<String, Object> params) {
    final drops = <_DropReason, List<String>>{};
    final serialized =
        _serialize(params, allowNestedObjects: false, drops: drops);
    _warnFlatDrops(drops);
    return serialized;
  }

  /// Warns about every entry the flat parameter path dropped.
  ///
  /// The classification is recorded by [_serialize] itself rather than
  /// recomputed here: a second walk that re-derives why a key was dropped is
  /// free to disagree with the walk that actually dropped it.
  static void _warnFlatDrops(Map<_DropReason, List<String>> drops) {
    void warn(_DropReason reason, String sentence) {
      final keys = drops[reason];
      if (keys == null || keys.isEmpty) return;
      debugPrint('[Insider] customParameters dropped $sentence '
          'The rest of the call was still sent.');
    }

    final blank = drops[_DropReason.blankKey]?.length ?? 0;
    if (blank > 0) {
      debugPrint('[Insider] customParameters dropped $blank '
          '${blank == 1 ? 'entry' : 'entries'}: an empty or whitespace-only '
          'key cannot be sent to native. The rest of the call was still sent.');
    }
    warn(
        _DropReason.invalidKey,
        '${drops[_DropReason.invalidKey]?.join(', ')}: a key must start with a '
        'lowercase letter and hold only lowercase letters, digits and '
        'underscores.');
    warn(
        _DropReason.unusableValue,
        '${drops[_DropReason.unusableValue]?.join(', ')}: the value is not a '
        'string, number, boolean, Date or array of those.');
    warn(
        _DropReason.mixedList,
        '${drops[_DropReason.mixedList]?.join(', ')}: a list must hold one '
        'type, and this one holds several.');
    warn(
        _DropReason.nonFiniteScalar,
        'values that cannot be sent to native: '
        '${drops[_DropReason.nonFiniteScalar]?.join(', ')}. NaN and '
        'infinite numbers cannot be sent to native.');
    warn(
        _DropReason.filteredArray,
        'non-finite elements from: '
        '${drops[_DropReason.filteredArray]?.join(', ')}. NaN and infinite '
        'numbers cannot be sent to native.');
    warn(
        _DropReason.unsupportedList,
        '${drops[_DropReason.unsupportedList]?.join(', ')}: the native SDKs '
        'store neither date arrays nor boolean arrays.');
  }

  /// Serialises one array-of-objects entry into the typed list format.
  ///
  /// Same types as [serializeCustomParameters], plus any `Iterable` of
  /// strings or numbers (such as a `Set`) sent as an array, and a nested
  /// `Map<String, Object>` encoded as `{type: 'object', value: [...]}`. NaN
  /// and infinite numbers are dropped, and unlike the flat parameter path an
  /// array holding one of them is dropped as a whole, as is an empty array —
  /// that is what the native object sanitizer does. A key pointing back at a
  /// map already being serialized is dropped as a cycle, and so is a key
  /// nested deeper than native's own two-level limit.
  static List<Map<String, Object>> serializeObject(Map<String, Object> object) {
    return _serialize(object, allowNestedObjects: true);
  }

  /// Serialises [object] like [serializeObject] and, when an entry cannot be
  /// sent to native, prints a warning naming [methodName] and the dropped key
  /// paths. The native SDK logs its own rejections, but never sees these.
  static List<Map<String, Object>> serializeObjectWithWarning(
      Map<String, Object> object, String methodName) {
    final serialized = serializeObject(object);
    // An object that kept nothing carries nothing, so the warning must not
    // claim the rest of the call went out.
    _warnDroppedValues(methodName, droppedKeyPaths(object, serialized),
        anySurvived: serialized.isNotEmpty);
    return serialized;
  }

  /// Serialises each of [objects] like [serializeObject] and prints one
  /// warning for the whole call, prefixing each dropped key path with the
  /// object's index (`0.tags, 1.address.city`).
  static List<List<Map<String, Object>>> serializeObjectsWithWarning(
      List<Map<String, Object>> objects, String methodName,
      {String subject = 'call'}) {
    final dropped = <String>[];
    final kept = <List<Map<String, Object>>>[];
    for (var index = 0; index < objects.length; index++) {
      final serialized = serializeObject(objects[index]);
      final paths = droppedKeyPaths(objects[index], serialized, '$index');
      if (serialized.isEmpty && paths.isEmpty) {
        // The object carried no entry at all, so there is no key to name.
        // Report the object itself, or its loss is invisible when the rest of
        // the list survives.
        dropped.add('$index');
      } else {
        dropped.addAll(paths);
      }
      // An object that kept no key is dropped from the list, as the native
      // sanitizer does (`StaticUtils.sanitizeObjectList` only appends a
      // non-null result). Sending an empty placeholder would claim a position
      // in the array that native never stores.
      if (serialized.isNotEmpty) kept.add(serialized);
    }
    _warnDroppedValues(methodName, dropped,
        anySurvived: kept.isNotEmpty, subject: subject);
    return kept;
  }

  /// True when [serialized] carries no object at all, so the call would reach
  /// native with nothing to write.
  static bool nothingSurvived(List<List<Map<String, Object>>> serialized) =>
      serialized.isEmpty;

  static void _warnDroppedValues(String methodName, List<String> dropped,
      {bool anySurvived = true, String subject = 'call'}) {
    // An entry that carries nothing still gets named: the object-array path
    // reports its index, and the three callers refuse an outright empty
    // input before reaching here, so there is no unnamed loss left to report.
    if (dropped.isEmpty) return;
    debugPrint('[Insider] $methodName dropped values that cannot be sent to '
        'native: ${dropped.join(', ')}. ${anySurvived ? 'The rest of the call '
            'was still sent.' : 'Nothing was left to send, so the $subject was '
            'ignored.'}');
  }

  /// Returns the dotted key path of every entry of [source] that
  /// [serialized], the output of [serializeObject] for [source], dropped.
  static List<String> droppedKeyPaths(
      Map source, List<Map<String, Object>> serialized,
      [String? prefix]) {
    final serializedByKey = <Object, Map<String, Object>>{
      for (final entry in serialized) entry['key']!: entry,
    };
    final dropped = <String>[];
    for (final entry in source.entries) {
      // A blank key would render as nothing in the warning, so name it.
      final label = entry.key is String && (entry.key as String).trim().isEmpty
          ? '<empty key>'
          : '${entry.key}';
      final path = prefix == null ? label : '$prefix.$label';
      final serializedEntry =
          entry.key is String ? serializedByKey[entry.key] : null;
      if (serializedEntry == null) {
        dropped.add(path);
        continue;
      }
      final nestedSerialized = serializedEntry['value'];
      if (serializedEntry['type'] == 'object' &&
          entry.value is Map &&
          nestedSerialized is List<Map<String, Object>>) {
        dropped.addAll(
            droppedKeyPaths(entry.value as Map, nestedSerialized, path));
      }
    }
    return dropped;
  }

  /// Returns [map] typed as `Map<String, Object>`, without its non-string
  /// keys and null values. Accepts maps whose static value type is `dynamic`,
  /// such as `jsonDecode` output. Dropping only the invalid keys, rather than
  /// the whole map, matches how the native SDKs sanitize a nested object.
  static Map<String, Object> _asObjectMap(Map map) {
    return <String, Object>{
      for (final entry in map.entries)
        if (entry.key is String && entry.value != null)
          entry.key as String: entry.value as Object,
    };
  }

  /// Whether [e] is a value the flat path could send as a lone parameter, so
  /// that a list of several such kinds is reported as mixed rather than as an
  /// unusable value.
  /// Whether [e] is a number native cannot carry. The flat path filters these
  /// out of a **pure number** list, mirroring what native's own
  /// `validateNumericArray` does to a `Number[]`. A list of mixed kinds is not
  /// filtered: native has no setter for it, so there is no behaviour to
  /// mirror and the whole list is dropped instead.
  static bool _isUnsendableNumber(Object? e) => e is num && !e.isFinite;

  /// Whether [e] is one of the kinds the flat path knows how to type, which is
  /// what separates a mixed list from an unusable one. It is not a claim that
  /// [e] would survive on its own: a NaN is a `num` and passes here, while a
  /// lone NaN is dropped.
  static bool _isSendableListElement(Object? e) =>
      e is String || e is num || e is bool || e is DateTime;

  static List<Map<String, Object>> _serialize(Map<String, Object> params,
      {required bool allowNestedObjects,
      Map<_DropReason, List<String>>? drops,
      List<Object>? ancestors,
      int level = 1}) {
    // The root map is an ancestor too: a key pointing back at it is a cycle.
    final List<Object> stack = ancestors ?? <Object>[params];
    List<Map<String, Object>> result = [];
    void drop(_DropReason reason, String key) =>
        drops?.putIfAbsent(reason, () => <String>[]).add(key);
    params.forEach((key, value) {
      // Native drops an entry whose name is blank and logs it on its own side.
      // Dropping it here lets the object paths name it in the existing
      // warning, and the flat path count it in its blank-key family.
      if (key.trim().isEmpty) {
        drop(_DropReason.blankKey, key);
        return;
      }
      // Native drops a key that fails its name rule, and an object whose keys
      // all fail is dropped whole - so the call can end up writing nothing.
      if (!nativeKeyPattern.hasMatch(key)) {
        drop(_DropReason.invalidKey, key);
        return;
      }
      if (allowNestedObjects && value is Map) {
        // A map that is already being serialized higher up is a cycle. Drop
        // that key only, as the WebView SDK does, instead of letting the
        // recursion overflow and lose the whole call.
        if (stack.any((ancestor) => identical(ancestor, value))) return;
        // Native's own nesting limit, counted exactly as native counts it:
        // the top-level object is level 1, and a map value lives one level
        // deeper than its container (`StaticUtils.sanitizeObjectValue`).
        // This is also what keeps the recursion bounded, so no separate
        // stack-safety ceiling is reachable behind it.
        if (level >= maxObjectNestingDepth) return;
        stack.add(value);
        final nested = _serialize(_asObjectMap(value),
            allowNestedObjects: true, ancestors: stack, level: level + 1);
        stack.removeLast();
        // A nested object that kept nothing is dropped with its key, as
        // `StaticUtils.sanitizeNestedObject` does by returning null for an
        // empty result. Keeping the key would send a hole native never
        // stores, and would hide the loss from the dropped-path warning.
        if (nested.isEmpty) return;
        result.add({'type': 'object', 'key': key, 'value': nested});
      } else if (value is bool) {
        result.add({'type': 'boolean', 'key': key, 'value': value});
      } else if (value is int) {
        result.add({'type': 'integer', 'key': key, 'value': value});
      } else if (value is double) {
        // A non-finite number breaks native payload serialization: Android
        // loses the enclosing parameter block, iOS the whole stop request.
        if (value.isFinite) {
          result.add({'type': 'double', 'key': key, 'value': value});
        } else {
          drop(_DropReason.nonFiniteScalar, key);
        }
      } else if (value is String) {
        // Native drops a longer string value, and a value it drops takes its
        // key with it (`StaticUtils.sanitizeObjectDroppingInvalidKeys`).
        if (allowNestedObjects && value.length > maxObjectStringLength) return;
        result.add({'type': 'string', 'key': key, 'value': value});
      } else if (value is DateTime) {
        result.add({
          'type': 'date',
          'key': key,
          'value': value.millisecondsSinceEpoch
        });
      } else if (value is List || (allowNestedObjects && value is Iterable)) {
        // A Set reaches native Android as an array but is dropped by native
        // iOS; sending every Iterable as a list gives one result on both.
        final raw = value is List ? value : (value as Iterable).toList();
        // The flat path decides the list's type on what actually crosses:
        // native filters element by element there, so `[NaN, 'a']` is a string
        // array. Inside an object native drops the whole array instead.
        // Only a pure number list is filtered: native has a `Number[]` setter
        // whose `validateNumericArray` drops non-finite elements, so mirroring
        // it is mirroring native. A list of mixed kinds has no native setter
        // at all, so choosing a type for it and filtering the rest away would
        // send an array the caller never wrote. Cordova drops those too.
        final filtered = !allowNestedObjects &&
            raw.every((e) => e is num) &&
            raw.any(_isUnsendableNumber);
        final list =
            filtered ? raw.where((e) => !_isUnsendableNumber(e)).toList() : raw;
        if (list.isEmpty) {
          // Native keeps the key for an empty array, so the flat path sends it
          // too. Dart keeps the declared element type at run time, so an empty
          // List<String> still goes as a string array; only an untyped empty
          // list has to fall back, and it falls back to the numeric type the
          // other wrappers default to.
          if (!allowNestedObjects) {
            result.add({
              'type': value is List<String> ? 'string_array' : 'numeric_array',
              'key': key,
              'value': <Object>[],
            });
          }
        } else if (list.every((e) => e is String)) {
          // Inside an object native drops the WHOLE array when any element is
          // over the limit (`StaticUtils.sanitizeObjectArrayValue` returns
          // null), unlike the scalar case where only that key goes.
          if (allowNestedObjects &&
              list.any((e) => (e as String).length > maxObjectStringLength)) {
            return;
          }
          result.add({'type': 'string_array', 'key': key, 'value': list});
        } else if (list.every((e) => e is num)) {
          if (allowNestedObjects) {
            // Inside an object native drops an array that holds an unsendable
            // number, so the key goes with it.
            if (list.every((e) => (e as num).isFinite)) {
              result.add({'type': 'numeric_array', 'key': key, 'value': list});
            }
          } else {
            // Non-finite elements were already filtered out above, which is
            // what native does on this path even when nothing is left.
            result.add({'type': 'numeric_array', 'key': key, 'value': list});
          }
        } else if (list.every((e) => e is bool) ||
            list.every((e) => e is DateTime)) {
          // Neither native SDK stores a date or boolean array.
          drop(_DropReason.unsupportedList, key);
        } else if (list.every(_isSendableListElement)) {
          // Its own reason: every element is of a kind the flat path knows,
          // and what the list lacks is the single type native tags an array
          // by. Not every element is sendable on its own — a NaN next to a
          // string lands here, and a lone NaN would be dropped — but the
          // list's problem is still its mixed kinds, so that is what is said.
          drop(_DropReason.mixedList, key);
        } else {
          drop(_DropReason.unusableValue, key);
        }
        // Only a pure number list is filtered, and a filtered pure number
        // list is still a pure number list, so it cannot also be dropped -
        // one key can never earn both warnings.
        if (filtered) drop(_DropReason.filteredArray, key);
      } else {
        // Maps, Sets and anything else the flat path cannot type.
        drop(_DropReason.unusableValue, key);
      }
    });
    return result;
  }
}

/// Why the flat parameter path dropped an entry. Recorded by the serializer as
/// it drops, so the warning cannot disagree with the payload.
enum _DropReason {
  blankKey,
  invalidKey,
  unusableValue,
  mixedList,
  nonFiniteScalar,
  filteredArray,
  unsupportedList,
}
