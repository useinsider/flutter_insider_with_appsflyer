import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'src/user.dart';
import 'src/product.dart';
import 'src/event.dart';
import 'src/utils.dart';
import 'src/constants.dart';

class FlutterInsider {
  static FlutterInsider Instance = new FlutterInsider();
  static FlutterInsiderUser? _insiderUser;
  static const MethodChannel _channel = const MethodChannel('flutter_insider');
  static const EventChannel _eventChannel = const EventChannel('flutter_insider_event');
  static const EventChannel _insiderIDListener = const EventChannel('insider_id_listener');

  Future<void> initFlutterBase(String partnerName, String appGroup, String? customEndpoint) async {
    _insiderUser = new FlutterInsiderUser(_channel);

    Map<String, dynamic> args = <String, dynamic>{};

    args["appGroup"] = appGroup;
    args["partnerName"] = partnerName;
    args["sdkVersion"] = "F-3.13.1+nh";

    if (customEndpoint != null) {
      args["customEndpoint"] = customEndpoint;

      await _channel.invokeMethod(Constants.INIT_WITH_CUSTOM_ENDPOINT, args);

      return;
    }

    await _channel.invokeMethod(Constants.INIT_WITH_LAUNCH_OPTIONS, args);
  }

  void registerEventChannel(Function function, String callbackType) {
    _eventChannel.receiveBroadcastStream().listen((event) {
      Map<String, dynamic> map = jsonDecode(event);

      if (map["type"] != null && map["data"] != null && callbackType == Constants.CALLBACK_EVENT) {
        function(map["type"], map["data"]);
      } else if (callbackType == Constants.CALLBACK_FOREGROUND_PUSH) {
        function(map);
      }
    }, onError: (dynamic error) {
      FlutterInsiderUtils.putException(_channel, error);
    });
  }

  Future<void> init(String partnerName, String appGroup, Function function) async {
    try {
      if (partnerName == null || appGroup == null || function == null) return;
      
      registerEventChannel(function, Constants.CALLBACK_EVENT);
      initFlutterBase(partnerName, appGroup, null);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> initWithCustomEndpoint(
    String partnerName, String appGroup, String customEndpoint, Function function) async {
    try {
      if (partnerName == null || appGroup == null || customEndpoint == null || function == null) return;

      initFlutterBase(partnerName, appGroup, customEndpoint);
      registerEventChannel(function, Constants.CALLBACK_EVENT);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> registerWithQuietPermission(bool permission) async {
    try {
      if (permission == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args["permission"] = permission;

      await _channel.invokeMethod(Constants.REGISTER_WITH_QUIET_PERMISSION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIDFACollection(bool enableIDFACollection) async {
    try {
      if (enableIDFACollection == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args["enableIDFACollection"] = enableIDFACollection;

      await _channel.invokeMethod(Constants.ENABLE_IDFA_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableCarrierCollection(bool enableCarrierCollection) async {
    try {
      if (enableCarrierCollection == null) return;
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableCarrierCollection"] = enableCarrierCollection;
      await _channel.invokeMethod(Constants.ENABLE_CARRIER_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIpCollection(bool enableIpCollection) async {
    try {
      if (enableIpCollection == null) return;
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableIpCollection"] = enableIpCollection;
      await _channel.invokeMethod(Constants.ENABLE_IP_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableLocationCollection(bool enableLocationCollection) async {
    try {
      if (enableLocationCollection == null) return;
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableLocationCollection"] = enableLocationCollection;
      await _channel.invokeMethod(Constants.ENABLE_LOCATION_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> startTrackingGeofence() async {
    try {
      await _channel.invokeMethod(Constants.START_TRACKING_GEOFENCE);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> handleNotification(Map<String, dynamic> notification) async {
    try {
      if (notification == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args["notification"] = notification['data'];

      await _channel.invokeMethod(Constants.HANDLE_NOTIFICATION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setGDPRConsent(bool consent) async {
    try {
      if (consent == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args["consent"] = consent;

      await _channel.invokeMethod(Constants.SET_GDPR_CONSENT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<String?> getContentStringWithName(String variableName, String defaultValue, int dataType) async {
    try {
      if (variableName == null || defaultValue == null || dataType == null)
        return defaultValue;

      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName, defaultValue, dataType, _channel);

      final String? returnValue = await _channel.invokeMethod(Constants.GET_CONTENT_STRING_WITH_NAME, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return defaultValue;
  }

  Future<int?> getContentIntWithName(String variableName, int defaultValue, int dataType) async {
    try {
      if (variableName == null || defaultValue == null || dataType == null)
        return defaultValue;

      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);

      final int? returnValue = await _channel.invokeMethod(Constants.GET_CONTENT_INT_WITH_NAME, args);

      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return defaultValue;
  }

  Future<bool?> getContentBoolWithName(String variableName, bool defaultValue, int dataType) async {
    try {
      if (variableName == null || defaultValue == null || dataType == null)
        return defaultValue;

      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);

      final bool? returnValue = await _channel.invokeMethod(Constants.GET_CONTENT_BOOL_WITH_NAME, args);

      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return defaultValue;
  }

  Future<void> removeInapp() async {
    try {
      await _channel.invokeMethod(Constants.REMOVE_INAPP);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitHomePage() async {
    try {
      await _channel.invokeMethod(Constants.VISIT_HOME_PAGE);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitListingPage(List<String> taxonomy) async {
    try {
      if (taxonomy == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args["taxonomy"] = taxonomy;

      await _channel.invokeMethod(Constants.VISIT_LISTING_PAGE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitProductDetailPage(FlutterInsiderProduct product) async {
    try {
      if (product == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args[Constants.PRODUCT_MUST_MAP] = product.productMustMap;
      args[Constants.PRODUCT_OPT_MAP] = product.productOptMap;

      await _channel.invokeMethod(Constants.VISIT_PRODUCT_DETAIL_PAGE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitCartPage(List<FlutterInsiderProduct> products) async {
    try {
      if (products == null) return;

      var list = List<Map>.filled(0, <String, dynamic>{}, growable: true);
      Map<String, dynamic> args = <String, dynamic>{};

      for (var product in products) {
        Map<String, dynamic> map = <String, dynamic>{};

        map[Constants.PRODUCT_MUST_MAP] = product.productMustMap;
        map[Constants.PRODUCT_OPT_MAP] = product.productOptMap;

        list.add(map);
      }

      args[Constants.PRODUCTS] = list;

      await _channel.invokeMethod(Constants.VISIT_CART_PAGE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  FlutterInsiderUser? getCurrentUser() {
    return _insiderUser;
  }

  FlutterInsiderProduct createNewProduct(
    String productID, name, List<String> taxonomy, String imageURL, double price, String currency) {
    return new FlutterInsiderProduct(_channel, productID, name, taxonomy, imageURL, price, currency);
  }

  Future<void> itemPurchased(String uniqueSaleID, FlutterInsiderProduct product) async {
    try {
      if (uniqueSaleID == null || product == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args['uniqueSaleID'] = uniqueSaleID;
      args['productMustMap'] = product.productMustMap;
      args['productOptMap'] = product.productOptMap;

      await _channel.invokeMethod(Constants.ITEM_PURCHASED, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> itemAddedToCart(FlutterInsiderProduct product) async {
    try {
      if (product == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args['productMustMap'] = product.productMustMap;
      args['productOptMap'] = product.productOptMap;

      await _channel.invokeMethod(Constants.ITEM_ADDED_TO_CART, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> itemRemovedFromCart(String productID) async {
    try {
      if (productID == null) return;
      
      Map<String, dynamic> args = <String, dynamic>{};

      args['productID'] = productID;

      await _channel.invokeMethod(Constants.ITEM_REMOVED_FROM_CART, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> cartCleared() async {
    try {
      await _channel.invokeMethod(Constants.CART_CLEARED);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  FlutterInsiderEvent tagEvent(String eventName) {
    return new FlutterInsiderEvent(_channel, eventName);
  }

  Future<Map?> getSmartRecommendation(int recommendationID, String locale, String currency) async {
    try {
      if (recommendationID == null || locale == null || currency == null)
        return new Map();

      Map<String, dynamic> args = <String, dynamic>{};

      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['currency'] = currency;

      Map? map = await _channel.invokeMethod(Constants.GET_SMART_RECOMMENDATION, args);

      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return null;
  }

  Future<Map?> getSmartRecommendationWithProduct(
    FlutterInsiderProduct product, int recommendationID, String locale) async {
    try {
      if (locale == null || recommendationID == null || product == null)
        return new Map();

      Map<String, dynamic> args = <String, dynamic>{};

      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['productMustMap'] = product.productMustMap;
      args['productOptMap'] = product.productOptMap;

      Map? map = await _channel.invokeMethod(Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT, args);

      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return null;
  }

  Future<Map?> getSmartRecommendationWithProductIDs(List<String> productIDs, int recommendationID, String locale, String currency) async {
    try {
      if (locale == null || recommendationID == null || productIDs == null)
        return new Map();

      productIDs.asMap().forEach((index, value) {
        if (value == null || value.trim() == "") {
          productIDs[index] = "";
        }
      });

      Map<String, dynamic> args = <String, dynamic>{};

      args['productIDs'] = productIDs;
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['currency'] = currency;

      Map? map = await _channel.invokeMethod(Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT_IDS, args);

      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> clickSmartRecommendationProduct(int recommendationID, FlutterInsiderProduct product) async {
    try {
      if (recommendationID == null || product == null) return;

      Map<String, dynamic> args = <String, dynamic>{};

      args['recommendationID'] = recommendationID;
      args['productMustMap'] = product.productMustMap;
      args['productOptMap'] = product.productOptMap;

      await _channel.invokeMethod(Constants.CLICK_SMART_RECOMMENDATION_PRODUCT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<List?> getMessageCenterData(DateTime startDate, DateTime endDate, int limit) async {
    try {
      if (startDate == null ||
          endDate == null ||
          limit == null ||
          startDate.compareTo(endDate) == 0 ||
          startDate.compareTo(endDate) > 0)
        return List<Map>.filled(0, <String, dynamic>{}, growable: false);
      
      Map<String, dynamic> args = <String, dynamic>{};

      args['startDate'] = FlutterInsiderUtils.getDateForParsing(startDate);
      args['endDate'] = FlutterInsiderUtils.getDateForParsing(endDate);
      args['limit'] = limit;

      List? list = await _channel.invokeMethod(Constants.GET_MESSAGE_CENTER_DATA, args);

      return list;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return null;
  }

  Future<void> signUpConfirmation() async {
    try {
      await _channel.invokeMethod(Constants.SIGN_UP_CONFIRMATION);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setActiveForegroundPushView() async {
    try {
      await _channel.invokeMethod(Constants.SET_ACTIVE_FOREGROUND_PUSH_VIEW);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setForegroundPushCallback(Function callback) async {
    try {
      registerEventChannel(callback, Constants.CALLBACK_FOREGROUND_PUSH);

      await _channel.invokeMethod(Constants.SET_FOREGROUND_PUSH_CALLBACK);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> reinitWithPartnerName(String newPartnerName) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      args['newPartnerName'] = newPartnerName;

      await _channel.invokeMethod(Constants.REINIT_WITH_PARTNER_NAME, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<String?> getInsiderID() async {
    try {
      return await _channel.invokeMethod(Constants.GET_INSIDER_ID);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);

      return null;
    }
  }

  Future<void> registerInsiderIDListener(Function callback) async {
    try {
      _insiderIDListener.receiveBroadcastStream().listen((insiderID) {
        callback(insiderID);
      }, onError: (dynamic error) {
        FlutterInsiderUtils.putException(_channel, error);
      });

      await _channel.invokeMethod(Constants.REGISTER_INSIDER_ID_LISTENER);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setPushToken(String pushToken) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      args['pushToken'] = pushToken;

      await _channel.invokeMethod(Constants.SET_PUSH_TOKEN, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  void disableInAppMessages() {
    try {
      _channel.invokeMethod(Constants.DISABLE_IN_APP_MESSAGES);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  void enableInAppMessages() {
    try {
      _channel.invokeMethod(Constants.ENABLE_IN_APP_MESSAGES);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }
}
