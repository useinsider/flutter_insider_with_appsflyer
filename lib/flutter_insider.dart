import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'src/user.dart';
import 'src/product.dart';
import 'src/event.dart';
import 'src/utils.dart';
import 'src/constants.dart';
import 'enum/InsiderCloseButtonPosition.dart';
import 'src/identifiers.dart';

class FlutterInsider {
  static FlutterInsider Instance = new FlutterInsider();
  InsiderCloseButtonPosition closeButtonPosition = InsiderCloseButtonPosition();
  static FlutterInsiderUser? _insiderUser;
  static const MethodChannel _channel = const MethodChannel('flutter_insider');
  static const EventChannel _eventChannel =
      const EventChannel('flutter_insider_event');
  static const EventChannel _insiderIDListener =
      const EventChannel('insider_id_listener');

  Future<void> initFlutterBase(
      String partnerName, String appGroup, String? customEndpoint) async {
    _insiderUser = new FlutterInsiderUser(_channel);

    Map<String, dynamic> args = <String, dynamic>{};

    args["appGroup"] = appGroup;
    args["partnerName"] = partnerName;
    args["sdkVersion"] = "F-4.1.0+nh";

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

      if (map["type"] != null &&
          map["data"] != null &&
          callbackType == Constants.CALLBACK_EVENT) {
        function(map["type"], map["data"]);
      } else if (callbackType == Constants.CALLBACK_FOREGROUND_PUSH) {
        function(map);
      }
    }, onError: (dynamic error) {
      FlutterInsiderUtils.putException(_channel, error);
    });
  }

  Future<void> init(
      String partnerName, String appGroup, Function function) async {
    try {
      registerEventChannel(function, Constants.CALLBACK_EVENT);
      await initFlutterBase(partnerName, appGroup, null);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> initWithCustomEndpoint(String partnerName, String appGroup,
      String customEndpoint, Function function) async {
    try {
      await initFlutterBase(partnerName, appGroup, customEndpoint);
      registerEventChannel(function, Constants.CALLBACK_EVENT);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> registerWithQuietPermission(bool permission) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["permission"] = permission;
      await _channel.invokeMethod(
          Constants.REGISTER_WITH_QUIET_PERMISSION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIDFACollection(bool enableIDFACollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableIDFACollection"] = enableIDFACollection;
      await _channel.invokeMethod(Constants.ENABLE_IDFA_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableCarrierCollection(bool enableCarrierCollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableCarrierCollection"] = enableCarrierCollection;
      await _channel.invokeMethod(Constants.ENABLE_CARRIER_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIpCollection(bool enableIpCollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableIpCollection"] = enableIpCollection;
      await _channel.invokeMethod(Constants.ENABLE_IP_COLLECTION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableLocationCollection(bool enableLocationCollection) async {
    try {
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

  Future<void> setAllowsBackgroundLocationUpdates(
      bool allowsBackgroundLocationUpdates) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["allowsBackgroundLocationUpdates"] = allowsBackgroundLocationUpdates;
      await _channel.invokeMethod(
          Constants.SET_ALLOWS_BACKGROUND_LOCATION_UPDATES, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Handles a push notification with the given notification data.
  ///
  /// On Android, this method displays the notification in the notification center using the provided data.
  /// On iOS, this method directly processes and triggers the notification data.
  Future<void> handleNotification(Map<String, dynamic> notification) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["notification"] = notification['data'];
      await _channel.invokeMethod(Constants.HANDLE_NOTIFICATION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Triggers the push process directly with the given notification data.
  ///
  /// Unlike [handleNotification], this method directly processes and triggers the notification data
  /// on both Android and iOS platforms without displaying it in the notification center.
  Future<void> triggerPushProcessWithNotificationData(Map<String, String> data) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["notification"] = data;
      await _channel.invokeMethod(Constants.TRIGGER_PUSH_PROCESS_WITH_NOTIFICATION_DATA, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setGDPRConsent(bool consent) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["consent"] = consent;
      await _channel.invokeMethod(Constants.SET_GDPR_CONSENT, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setMobileAppAccess(bool mobileAppAccess) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["mobileAppAccess"] = mobileAppAccess;
      await _channel.invokeMethod(Constants.SET_MOBILE_APP_ACCESS, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<String?> getContentStringWithName(
      String variableName, String defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final String? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_STRING_WITH_NAME, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<int?> getContentIntWithName(
      String variableName, int defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final int? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_INT_WITH_NAME, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<bool?> getContentBoolWithName(
      String variableName, bool defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final bool? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_BOOL_WITH_NAME, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<String?> getContentStringWithoutCache(
      String variableName, String defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final String? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_STRING_WITHOUT_CACHE, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<int?> getContentIntWithoutCache(
      String variableName, int defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final int? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_INT_WITHOUT_CACHE, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<bool?> getContentBoolWithoutCache(
      String variableName, bool defaultValue, int dataType) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
          variableName, defaultValue, dataType, _channel);
      final bool? returnValue = await _channel.invokeMethod(
          Constants.GET_CONTENT_BOOL_WITHOUT_CACHE, args);
      return returnValue;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<void> removeInapp() async {
    try {
      await _channel.invokeMethod(Constants.REMOVE_INAPP);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitHomePage({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_HOME_PAGE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitListingPage(List<String> taxonomy, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["taxonomy"] = taxonomy;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_LISTING_PAGE, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> visitProductDetailPage(FlutterInsiderProduct product, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_PRODUCT_DETAIL_PAGE, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> visitCartPage(List<FlutterInsiderProduct> products, {String? saleID, Map<String, Object>? customParameters}) async {
    try {
      var list = List<Map>.filled(0, <String, dynamic>{}, growable: true);
      Map<String, dynamic> args = <String, dynamic>{};
      for (var product in products) {
        Map<String, dynamic> map = <String, dynamic>{};
        map['requiredFields'] = product.requiredFields;
        map['optionalFields'] = product.optionalFields;
        map['productCustomParameters'] = product.customParameters;
        list.add(map);
      }
      args[Constants.PRODUCTS] = list;
      if (saleID != null && saleID.isNotEmpty) {
        args['saleID'] = saleID;
      }
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_CART_PAGE, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> visitWishlistPage(List<FlutterInsiderProduct> products, {Map<String, Object>? customParameters}) async {
    try {
      var list = List<Map>.filled(0, <String, dynamic>{}, growable: true);
      Map<String, dynamic> args = <String, dynamic>{};
      for (var product in products) {
        Map<String, dynamic> map = <String, dynamic>{};
        map['requiredFields'] = product.requiredFields;
        map['optionalFields'] = product.optionalFields;
        map['productCustomParameters'] = product.customParameters;
        list.add(map);
      }
      args[Constants.PRODUCTS] = list;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_WISHLIST_PAGE, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  FlutterInsiderUser? getCurrentUser() {
    return _insiderUser;
  }

  FlutterInsiderProduct createNewProduct(String productID, name,
      List<String> taxonomy, String imageURL, double price, String currency) {
    return new FlutterInsiderProduct(
        _channel, productID, name, taxonomy, imageURL, price, currency);
  }

  Future<void> itemPurchased(
      String uniqueSaleID, FlutterInsiderProduct product, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['uniqueSaleID'] = uniqueSaleID;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_PURCHASED, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> itemAddedToCart(FlutterInsiderProduct product, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_ADDED_TO_CART, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> itemRemovedFromCart(String productID, {String? saleID, Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['productID'] = productID;
      if (saleID != null && saleID.isNotEmpty) {
        args['saleID'] = saleID;
      }
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_REMOVED_FROM_CART, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> cartCleared({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.CART_CLEARED, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> itemAddedToWishlist(FlutterInsiderProduct product, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_ADDED_TO_WISH_LIST, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> itemRemovedFromWishlist(String productID, {Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['productID'] = productID;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_REMOVED_FROM_WISH_LIST, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> wishlistCleared({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.WISH_LIST_CLEARED, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  FlutterInsiderEvent tagEvent(String eventName) {
    return new FlutterInsiderEvent(_channel, eventName);
  }

  Future<Map?> getSmartRecommendation(
      int recommendationID, String locale, String currency) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['currency'] = currency;
      Map? map =
          await _channel.invokeMethod(Constants.GET_SMART_RECOMMENDATION, args);
      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<Map?> getSmartRecommendationWithProduct(FlutterInsiderProduct product,
      int recommendationID, String locale) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['customParameters'] = product.customParameters;
      Map? map = await _channel.invokeMethod(
          Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT, args);
      return map;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return null;
    }
  }

  Future<Map?> getSmartRecommendationWithProductIDs(List<String> productIDs,
      int recommendationID, String locale, String currency) async {
    try {
      productIDs.asMap().forEach((index, value) {
        if (value.trim() == "") {
          productIDs[index] = "";
        }
      });
      Map<String, dynamic> args = <String, dynamic>{};
      args['productIDs'] = productIDs;
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['currency'] = currency;
      Map? map = await _channel.invokeMethod(
          Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT_IDS, args);
      return map;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<void> clickSmartRecommendationProduct(
      int recommendationID, FlutterInsiderProduct product) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['customParameters'] = product.customParameters;
      await _channel.invokeMethod(
          Constants.CLICK_SMART_RECOMMENDATION_PRODUCT, args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<List?> getMessageCenterData(DateTime startDate, DateTime endDate, int limit) async {
    try {
      if (startDate.compareTo(endDate) == 0 || startDate.compareTo(endDate) > 0)
        return List<Map>.filled(0, <String, dynamic>{}, growable: false);

      Map<String, dynamic> args = <String, dynamic>{};
      args['startDate'] = startDate.millisecondsSinceEpoch;
      args['endDate'] = endDate.millisecondsSinceEpoch;
      args['limit'] = limit;
      List? list = await _channel.invokeMethod(Constants.GET_MESSAGE_CENTER_DATA, args);
      return list;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<List?> getMessageCenterDataWithIdentifiers(DateTime startDate, DateTime endDate, FlutterInsiderIdentifiers identifiers, int limit) async {
    try {
      if (startDate.compareTo(endDate) == 0 || startDate.compareTo(endDate) > 0)
        return List<Map>.filled(0, <String, dynamic>{}, growable: false);

      Map<String, dynamic> args = <String, dynamic>{};
      args['startDate'] = startDate.millisecondsSinceEpoch;
      args['endDate'] = endDate.millisecondsSinceEpoch;
      args['identifiers'] = identifiers.getIdentifiers();
      args['limit'] = limit;
      List? list = await _channel.invokeMethod(Constants.GET_MESSAGE_CENTER_DATA_WITH_IDENTIFIERS, args);
      return list;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<void> signUpConfirmation({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] = FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.SIGN_UP_CONFIRMATION, args);
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

  void handleUniversalLink(String url) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['universalLink'] = url;
      _channel.invokeMethod(Constants.HANDLE_UNIVERSAL_LINK, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setInternalBrowserCloseButtonPosition(String position) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["position"] = position;
      await _channel.invokeMethod(Constants.SET_INTERNAL_BROWSER_CLOSE_BUTTON_POSITION, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }
}
