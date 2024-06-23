import 'package:flutter/services.dart';

class FlutterInsiderUtils {
  static Future<void> putException(MethodChannel methodChannel, Object exception) async {
    Map<String, dynamic> args = <String, dynamic>{};

    args["exception"] = exception.toString();

    methodChannel.invokeMethod('putException', args);
  }

  static getContentOptimizerMap(String variableName, dynamic defaultValue, int dataType, MethodChannel channel) {
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
    return date.toUtc().add(date.timeZoneOffset).toIso8601String();
  }
}
