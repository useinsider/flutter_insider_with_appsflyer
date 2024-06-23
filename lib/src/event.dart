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
      if (key == null || value == null) return this;

      this._parameters[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderEvent addParameterWithInt(String key, int value) {
    try {
      if (key == null || value == null) return this;

      this._parameters[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    
    return this;
  }

  FlutterInsiderEvent addParameterWithDouble(String key, double value) {
    try {
      if (key == null || value == null) return this;

      this._parameters[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderEvent addParameterWithBoolean(String key, bool value) {
    try {
      if (key == null || value == null) return this;

      this._parameters[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderEvent addParameterWithDate(String key, DateTime value) {
    try {
      if (key == null || value == null) return this;

      this._parameters[key] = value.toString();

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderEvent addParameterWithArray(String key, List<String> value) {
    try {
      if (key == null || value == null) return this;
      
      this._parameters[key] = value;

      return this;
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
