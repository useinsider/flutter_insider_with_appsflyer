import 'package:flutter/services.dart';
import 'utils.dart';
import 'constants.dart';

/// Builder for tagging custom events with typed parameters.
///
/// Obtain an instance via [FlutterInsider.tagEvent], chain `addParameter*`
/// calls, then dispatch with [build]:
///
/// ```dart
/// await FlutterInsider.Instance
///     .tagEvent('add_to_favorites')
///     .addParameterWithString('product_id', 'sku-123')
///     .addParameterWithDouble('price', 29.99)
///     .build();
/// ```
///
/// The event is not delivered to the native SDK until [build] is called.
class FlutterInsiderEvent {
  String? _name;
  List<Map<String, dynamic>> _parameters = [];
  late MethodChannel _channel;

  FlutterInsiderEvent(MethodChannel methodChannel, String name) {
    this._channel = methodChannel;
    this._name = name;
  }

  /// Adds a string-typed parameter.
  FlutterInsiderEvent addParameterWithString(String key, String value) {
    try {
      this._parameters.add({
        'type': 'string',
        'key': key,
        'value': value,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds an integer-typed parameter.
  FlutterInsiderEvent addParameterWithInt(String key, int value) {
    try {
      this._parameters.add({
        'type': 'integer',
        'key': key,
        'value': value,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a double-typed parameter.
  FlutterInsiderEvent addParameterWithDouble(String key, double value) {
    try {
      this._parameters.add({
        'type': 'double',
        'key': key,
        'value': value,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a boolean-typed parameter.
  FlutterInsiderEvent addParameterWithBoolean(String key, bool value) {
    try {
      this._parameters.add({
        'type': 'boolean',
        'key': key,
        'value': value,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a date-typed parameter. Stored as epoch milliseconds on the native
  /// side.
  FlutterInsiderEvent addParameterWithDate(String key, DateTime value) {
    try {
      final int epochMs = value.millisecondsSinceEpoch;
      this._parameters.add({
        'type': 'date',
        'key': key,
        'value': epochMs.toString(),
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a string-array parameter, dropping any null or empty entries.
  FlutterInsiderEvent addParameterWithStringArray(
      String key, List<String> values) {
    try {
      List<String>? validArray =
          FlutterInsiderUtils.validateStringArray(values);
      if (validArray == null) {
        validArray = [];
      }
      this._parameters.add({
        'type': 'strings',
        'key': key,
        'value': validArray,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a string-array parameter without validation.
  ///
  /// Prefer [addParameterWithStringArray], which filters invalid entries.
  @Deprecated('Use addParameterWithStringArray instead')
  FlutterInsiderEvent addParameterWithArray(String key, List<String> value) {
    try {
      this._parameters.add({
        'type': 'strings',
        'key': key,
        'value': value,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Adds a numeric-array parameter, dropping any non-finite entries.
  FlutterInsiderEvent addParameterWithNumericArray(
      String key, List<num> values) {
    try {
      List<num>? validArray = FlutterInsiderUtils.validateNumericArray(values);
      if (validArray == null) {
        validArray = [];
      }
      this._parameters.add({
        'type': 'numbers',
        'key': key,
        'value': validArray,
      });
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  /// Dispatches the event to the native Insider SDK.
  ///
  /// Call this once after attaching all parameters; the builder is single-use.
  Future<void> build() async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["name"] = _name;
      args["parameters"] = _parameters;
      await _channel.invokeMethod(Constants.TAG_EVENT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }
}
