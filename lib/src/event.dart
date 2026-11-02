import 'package:flutter/foundation.dart';
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
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithString', key)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithInt', key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableInteger(
          'addParameterWithInt', key, value)) {
        return this;
      }
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

  /// Adds a double-typed parameter. NaN and infinite values are ignored with a
  /// warning.
  FlutterInsiderEvent addParameterWithDouble(String key, double value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithDouble', key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableDouble(
          'addParameterWithDouble', key, value)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithBoolean', key)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithDate', key)) {
        return this;
      }
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

  /// Adds a string-array parameter.
  FlutterInsiderEvent addParameterWithStringArray(
      String key, List<String> values) {
    try {
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithStringArray', key)) {
        return this;
      }
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

  /// Adds a string-array parameter.
  ///
  /// Prefer [addParameterWithStringArray]; this name is kept for
  /// compatibility only.
  @Deprecated('Use addParameterWithStringArray instead')
  FlutterInsiderEvent addParameterWithArray(String key, List<String> value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithArray', key)) {
        return this;
      }
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
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithNumericArray', key)) {
        return this;
      }
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

  /// Adds an array-of-objects parameter.
  ///
  /// Each object accepts the same value types as
  /// `FlutterInsiderUser.addObjectsToCustomAttribute` (this library does not
  /// import that class, so the name is not a resolvable dartdoc reference).
  ///
  /// Event object arrays are insert-only on the Insider backend: once sent
  /// they cannot be updated or used as a filter. That is a backend rule, not
  /// something this code enforces — see MOB-29348.
  ///
  /// The parameter is dropped, with a warning, when [objects] is empty or
  /// when no object keeps a key. The event itself is still sent with its
  /// other parameters.
  FlutterInsiderEvent addParameterWithObjectArray(
      String key, List<Map<String, Object>> objects) {
    try {
      if (!FlutterInsiderUtils.isSendableKey('addParameterWithObjectArray', key)) {
        return this;
      }
      // Native treats an empty list as a no-op, so say so where it is
      // visible. The event itself still goes out, so name the parameter.
      if (objects.isEmpty) {
        debugPrint('[Insider] addParameterWithObjectArray ignored the '
            'parameter: there are no objects to add.');
        return this;
      }
      // The event itself still goes out with its other parameters, so the
      // warning must say the parameter was dropped, not the call.
      final serialized = FlutterInsiderUtils.serializeObjectsWithWarning(
          objects, 'addParameterWithObjectArray',
          subject: 'parameter');
      // Every object lost all of its keys, so the parameter would carry
      // nothing; native writes nothing for it either way.
      if (FlutterInsiderUtils.nothingSurvived(serialized)) return this;
      this._parameters.add({
        'type': 'objects',
        'key': key,
        'value': serialized,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
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
