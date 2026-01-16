import 'package:flutter/services.dart';

class FlutterInsiderUtils {
  static Future<void> putException(MethodChannel methodChannel,
      Object exception) async {
    Map<String, dynamic> args = <String, dynamic>{};

    args["exception"] = exception.toString();

    methodChannel.invokeMethod('putException', args);
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
}