import 'package:flutter/services.dart';
import 'utils.dart';
import 'constants.dart';

class FlutterInsiderEvent {
  String? _name;
  Map<String, dynamic> _parameters = new Map();
  late MethodChannel _channel;

  FlutterInsiderEvent(MethodChannel methodChannel, String name) {
    this._channel = methodChannel;
    this._name = name;
  }

  FlutterInsiderEvent addParameterWithString(String key, String value) {
    try {
      this._parameters[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithInt(String key, int value) {
    try {
      this._parameters[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithDouble(String key, double value) {
    try {
      this._parameters[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithBoolean(String key, bool value) {
    try {
      this._parameters[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithDate(String key, DateTime value) {
    try {
      this._parameters[key] = FlutterInsiderUtils.getDateForParsing(value);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithStringArray(
      String key, List<String> values) {
    try {
      List<String>? validArray =
          FlutterInsiderUtils.validateStringArray(values);
      if (validArray == null) {
        validArray = [];
      }
      this._parameters[key] = validArray;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  @Deprecated('Use addParameterWithStringArray instead')
  FlutterInsiderEvent addParameterWithArray(String key, List<String> value) {
    try {
      this._parameters[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderEvent addParameterWithNumericArray(
      String key, List<num> values) {
    try {
      List<num>? validArray = FlutterInsiderUtils.validateNumericArray(values);
      if (validArray == null) {
        validArray = [];
      }
      this._parameters[key] = validArray;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

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
