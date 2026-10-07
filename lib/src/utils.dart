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
  static Future<void> putException(MethodChannel methodChannel,
      Object exception) async {
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

  static String getDateForParsing(DateTime date) {
    int milliseconds = date.millisecondsSinceEpoch;
    DateTime dateWithMilliseconds = DateTime.fromMillisecondsSinceEpoch(
        milliseconds);

    return dateWithMilliseconds
        .toUtc()
        .add(date.timeZoneOffset)
        .toIso8601String();
  }

  static List<String>? validateStringArray(List<String>? values) {
    try {
      if (values == null) return null;

      List<String> validArray = values.where((e) => e.isNotEmpty).toList();
      return validArray.isEmpty ? null : validArray;
    } catch (e, stack) {
      print("[ERROR] Exception in validateStringArray: $e\n$stack");
      return null;
    }
  }

  static List<num>? validateNumericArray(List<num>? values) {
    try {
      if (values == null) return null;

      List<num> validArray = values.where((e) => e.isFinite).toList();
      return validArray.isEmpty ? null : validArray;
    } catch (e, stack) {
      print("[ERROR] Exception in validateNumericArray: $e\n$stack");
      return null;
    }
  }

  /// Serialises a `<String, Object>` map of custom parameters into the typed
  /// list format `[{type, key, value}]` expected by both native bridges.
  ///
  /// Supported value types: `bool`, `int`, `double`, `String`, `DateTime`
  /// (epoch milliseconds), `List<String>`, `List<num>`. Unsupported entries
  /// are silently dropped.
  static List<Map<String, Object>> serializeCustomParameters(Map<String, Object> params) {
    List<Map<String, Object>> result = [];
    params.forEach((key, value) {
      if (value is bool) {
        result.add({'type': 'boolean', 'key': key, 'value': value});
      } else if (value is int) {
        result.add({'type': 'integer', 'key': key, 'value': value});
      } else if (value is double) {
        result.add({'type': 'double', 'key': key, 'value': value});
      } else if (value is String) {
        result.add({'type': 'string', 'key': key, 'value': value});
      } else if (value is DateTime) {
        result.add({'type': 'date', 'key': key, 'value': value.millisecondsSinceEpoch});
      } else if (value is List) {
        if (value.isNotEmpty && value.every((e) => e is String)) {
          result.add({'type': 'string_array', 'key': key, 'value': value});
        } else if (value.isNotEmpty && value.every((e) => e is num)) {
          result.add({'type': 'numeric_array', 'key': key, 'value': value});
        }
      }
    });
    return result;
  }
}
