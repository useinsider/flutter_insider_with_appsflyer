/// Flutter plugin for the Insider mobile SDK.
///
/// Exposes Insider's user tracking, product events, push notifications,
/// smart recommendations, content optimizer, message center and App Cards
/// features to Flutter apps via platform channels.
///
/// Entry point: [FlutterInsider.Instance]. Initialise the SDK once during
/// app startup with [FlutterInsider.init], then use the facade methods to
/// emit events, identify users (via [FlutterInsider.getCurrentUser]) and
/// fetch personalised content.
library flutter_insider;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'src/insider_app_cards.dart';
import 'src/user.dart';
import 'src/product.dart';
import 'src/event.dart';
import 'src/utils.dart';
import 'src/constants.dart';
import 'enum/InsiderCloseButtonPosition.dart';
import 'src/identifiers.dart';

export 'src/insider_app_cards.dart';
export 'src/app_cards_models.dart';
export 'src/app_cards_error.dart';

/// Singleton facade over the native Insider SDK.
///
/// Access via [FlutterInsider.Instance]. Initialise once with [init] (or
/// [initWithCustomEndpoint]) before calling any other method.
class FlutterInsider {
  /// The shared singleton instance.
  static FlutterInsider Instance = new FlutterInsider();
  InsiderCloseButtonPosition closeButtonPosition = InsiderCloseButtonPosition();
  static FlutterInsiderUser? _insiderUser;
  static FlutterInsiderAppCards? _insiderAppCards;
  static const MethodChannel _channel = const MethodChannel('flutter_insider');
  static const EventChannel _eventChannel = const EventChannel(
    'flutter_insider_event',
  );
  static const EventChannel _insiderIDListener = const EventChannel(
    'insider_id_listener',
  );

  Future<void> initFlutterBase(
    String partnerName,
    String appGroup,
    String? customEndpoint,
  ) async {
    _insiderUser = new FlutterInsiderUser(_channel);
    _insiderAppCards = new FlutterInsiderAppCards(_channel);

    Map<String, dynamic> args = <String, dynamic>{};

    args["appGroup"] = appGroup;
    args["partnerName"] = partnerName;
    args["sdkVersion"] = "F-5.0.3+nh";

    if (customEndpoint != null) {
      args["customEndpoint"] = customEndpoint;

      await _channel.invokeMethod(Constants.INIT_WITH_CUSTOM_ENDPOINT, args);

      return;
    }

    await _channel.invokeMethod(Constants.INIT_WITH_LAUNCH_OPTIONS, args);
  }

  void registerEventChannel(Function function, String callbackType) {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        Map<String, dynamic> map = jsonDecode(event);

        if (map["type"] != null &&
            map["data"] != null &&
            callbackType == Constants.CALLBACK_EVENT) {
          function(map["type"], map["data"]);
        } else if (callbackType == Constants.CALLBACK_FOREGROUND_PUSH) {
          function(map);
        }
      },
      onError: (dynamic error) {
        FlutterInsiderUtils.putException(_channel, error);
      },
    );
  }

  /// Initialises the Insider SDK with the given [partnerName] and
  /// [appGroup], registering [function] as the callback that receives Insider
  /// events.
  ///
  /// The callback receives `(int actionType, dynamic data)`; switch on the
  /// constants in [InsiderCallbackAction] to handle each kind. Call once
  /// during app startup.
  Future<void> init(
    String partnerName,
    String appGroup,
    Function function,
  ) async {
    try {
      registerEventChannel(function, Constants.CALLBACK_EVENT);
      await initFlutterBase(partnerName, appGroup, null);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Initialises the SDK against a [customEndpoint] (typically a regional or
  /// staging gateway).
  ///
  /// Use only when instructed by Insider. Otherwise prefer [init].
  Future<void> initWithCustomEndpoint(
    String partnerName,
    String appGroup,
    String customEndpoint,
    Function function,
  ) async {
    try {
      await initFlutterBase(partnerName, appGroup, customEndpoint);
      registerEventChannel(function, Constants.CALLBACK_EVENT);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Registers the SDK with the user's *quiet permission* preference. When
  /// `true`, push registration proceeds without prompting the user.
  Future<void> registerWithQuietPermission(bool permission) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["permission"] = permission;
      await _channel.invokeMethod(
        Constants.REGISTER_WITH_QUIET_PERMISSION,
        args,
      );
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIDFACollection(bool enableIDFACollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableIDFACollection"] = enableIDFACollection;
      await _channel.invokeMethod(Constants.ENABLE_IDFA_COLLECTION, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableCarrierCollection(bool enableCarrierCollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableCarrierCollection"] = enableCarrierCollection;
      await _channel.invokeMethod(Constants.ENABLE_CARRIER_COLLECTION, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableIpCollection(bool enableIpCollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableIpCollection"] = enableIpCollection;
      await _channel.invokeMethod(Constants.ENABLE_IP_COLLECTION, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> enableLocationCollection(bool enableLocationCollection) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["enableLocationCollection"] = enableLocationCollection;
      await _channel.invokeMethod(Constants.ENABLE_LOCATION_COLLECTION, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> startTrackingGeofence() async {
    try {
      await _channel.invokeMethod(Constants.START_TRACKING_GEOFENCE);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setAllowsBackgroundLocationUpdates(
    bool allowsBackgroundLocationUpdates,
  ) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["allowsBackgroundLocationUpdates"] = allowsBackgroundLocationUpdates;
      await _channel.invokeMethod(
        Constants.SET_ALLOWS_BACKGROUND_LOCATION_UPDATES,
        args,
      );
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
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
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Triggers the push process directly with the given notification data.
  ///
  /// Unlike [handleNotification], this method directly processes and triggers the notification data
  /// on both Android and iOS platforms without displaying it in the notification center.
  Future<void> triggerPushProcessWithNotificationData(
    Map<String, String> data,
  ) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["notification"] = data;
      await _channel.invokeMethod(
        Constants.TRIGGER_PUSH_PROCESS_WITH_NOTIFICATION_DATA,
        args,
      );
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Records the user's GDPR consent decision. Pass `true` to enable
  /// tracking, `false` to disable.
  Future<void> setGDPRConsent(bool consent) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["consent"] = consent;
      await _channel.invokeMethod(Constants.SET_GDPR_CONSENT, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Toggles whether the SDK may communicate with Insider servers from the
  /// mobile app. `false` disables network activity.
  Future<void> setMobileAppAccess(bool mobileAppAccess) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["mobileAppAccess"] = mobileAppAccess;
      await _channel.invokeMethod(Constants.SET_MOBILE_APP_ACCESS, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Reads a string Content Optimizer variable.
  ///
  /// [variableName] is the variable defined in the Insider panel,
  /// [defaultValue] is returned when the variable is missing or fetching
  /// fails, and [dataType] is one of [ContentOptimizerDataType.CONTENT] or
  /// [ContentOptimizerDataType.ELEMENT].
  Future<String?> getContentStringWithName(
    String variableName,
    String defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final String? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_STRING_WITH_NAME,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  /// Reads an integer Content Optimizer variable. See
  /// [getContentStringWithName] for parameter semantics.
  Future<int?> getContentIntWithName(
    String variableName,
    int defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final int? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_INT_WITH_NAME,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  /// Reads a boolean Content Optimizer variable. See
  /// [getContentStringWithName] for parameter semantics.
  Future<bool?> getContentBoolWithName(
    String variableName,
    bool defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final bool? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_BOOL_WITH_NAME,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<String?> getContentStringWithoutCache(
    String variableName,
    String defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final String? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_STRING_WITHOUT_CACHE,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<int?> getContentIntWithoutCache(
    String variableName,
    int defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final int? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_INT_WITHOUT_CACHE,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  Future<bool?> getContentBoolWithoutCache(
    String variableName,
    bool defaultValue,
    int dataType,
  ) async {
    try {
      Map<String, dynamic>? args = FlutterInsiderUtils.getContentOptimizerMap(
        variableName,
        defaultValue,
        dataType,
        _channel,
      );
      final bool? returnValue = await _channel.invokeMethod(
        Constants.GET_CONTENT_BOOL_WITHOUT_CACHE,
        args,
      );
      return returnValue;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return defaultValue;
    }
  }

  /// Dismisses any in-app message currently being displayed.
  Future<void> removeInapp() async {
    try {
      await _channel.invokeMethod(Constants.REMOVE_INAPP);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Records a home-page visit, optionally enriched with [customParameters].
  Future<void> visitHomePage({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_HOME_PAGE, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Records a category / listing page visit identified by [taxonomy].
  Future<void> visitListingPage(
    List<String> taxonomy, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["taxonomy"] = taxonomy;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_LISTING_PAGE, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Records a product detail page visit. Build [product] via
  /// [createNewProduct].
  Future<void> visitProductDetailPage(
    FlutterInsiderProduct product, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_PRODUCT_DETAIL_PAGE, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records a cart page visit with the current cart [products] and an
  /// optional [saleID] correlating the cart to a downstream purchase.
  Future<void> visitCartPage(
    List<FlutterInsiderProduct> products, {
    String? saleID,
    Map<String, Object>? customParameters,
  }) async {
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
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_CART_PAGE, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records a wishlist page visit with the current wishlist [products].
  Future<void> visitWishlistPage(
    List<FlutterInsiderProduct> products, {
    Map<String, Object>? customParameters,
  }) async {
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
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.VISIT_WISHLIST_PAGE, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Returns the [FlutterInsiderUser] builder for the current user, or
  /// `null` if [init] has not yet completed.
  FlutterInsiderUser? getCurrentUser() {
    return _insiderUser;
  }

  /// Constructs a [FlutterInsiderProduct] with the catalog-required fields.
  ///
  /// Chain `set*` calls on the result to attach optional metadata (color,
  /// brand, stock, ...) before passing it to event APIs such as
  /// [visitProductDetailPage] or [itemAddedToCart].
  FlutterInsiderProduct createNewProduct(
    String productID,
    name,
    List<String> taxonomy,
    String imageURL,
    double price,
    String currency,
  ) {
    return new FlutterInsiderProduct(
      _channel,
      productID,
      name,
      taxonomy,
      imageURL,
      price,
      currency,
    );
  }

  /// Reports a purchase of [product] under the given [uniqueSaleID].
  ///
  /// Call once per purchased product; pass the same `uniqueSaleID` for all
  /// products belonging to the same order.
  Future<void> itemPurchased(
    String uniqueSaleID,
    FlutterInsiderProduct product, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['uniqueSaleID'] = uniqueSaleID;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_PURCHASED, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records that [product] was added to the cart.
  Future<void> itemAddedToCart(
    FlutterInsiderProduct product, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_ADDED_TO_CART, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records that the product identified by [productID] was removed from the
  /// cart, optionally tagging the open order via [saleID].
  Future<void> itemRemovedFromCart(
    String productID, {
    String? saleID,
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['productID'] = productID;
      if (saleID != null && saleID.isNotEmpty) {
        args['saleID'] = saleID;
      }
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_REMOVED_FROM_CART, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Records that the cart was cleared (all items removed).
  Future<void> cartCleared({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.CART_CLEARED, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> itemAddedToWishlist(
    FlutterInsiderProduct product, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['productCustomParameters'] = product.customParameters;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_ADDED_TO_WISH_LIST, args);
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  Future<void> itemRemovedFromWishlist(
    String productID, {
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['productID'] = productID;
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.ITEM_REMOVED_FROM_WISH_LIST, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> wishlistCleared({Map<String, Object>? customParameters}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.WISH_LIST_CLEARED, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Returns a [FlutterInsiderEvent] builder for a custom event named
  /// [eventName].
  ///
  /// Chain `addParameter*` calls to attach typed parameters and call
  /// [FlutterInsiderEvent.build] to dispatch the event.
  FlutterInsiderEvent tagEvent(String eventName) {
    return new FlutterInsiderEvent(_channel, eventName);
  }

  /// Fetches a Smart Recommendation by its [recommendationID].
  ///
  /// Returns the recommendation payload or `null` on failure. [locale] and
  /// [currency] are used for content localisation and price formatting.
  Future<Map?> getSmartRecommendation(
    int recommendationID,
    String locale,
    String currency,
  ) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['currency'] = currency;
      Map? map = await _channel.invokeMethod(
        Constants.GET_SMART_RECOMMENDATION,
        args,
      );
      return map;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<Map?> getSmartRecommendationWithProduct(
    FlutterInsiderProduct product,
    int recommendationID,
    String locale,
  ) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['locale'] = locale;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['customParameters'] = product.customParameters;
      Map? map = await _channel.invokeMethod(
        Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT,
        args,
      );
      return map;
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
      return null;
    }
  }

  Future<Map?> getSmartRecommendationWithProductIDs(
    List<String> productIDs,
    int recommendationID,
    String locale,
    String currency,
  ) async {
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
        Constants.GET_SMART_RECOMMENDATION_WITH_PRODUCT_IDS,
        args,
      );
      return map;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  Future<void> clickSmartRecommendationProduct(
    int recommendationID,
    FlutterInsiderProduct product,
  ) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['recommendationID'] = recommendationID;
      args['requiredFields'] = product.requiredFields;
      args['optionalFields'] = product.optionalFields;
      args['customParameters'] = product.customParameters;
      await _channel.invokeMethod(
        Constants.CLICK_SMART_RECOMMENDATION_PRODUCT,
        args,
      );
    } catch (e) {
      await FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Fetches Message Center entries dated between [startDate] and [endDate],
  /// up to [limit] items.
  ///
  /// Returns an empty list if `startDate >= endDate`. Returns `null` on
  /// failure.
  Future<List?> getMessageCenterData(
    DateTime startDate,
    DateTime endDate,
    int limit,
  ) async {
    try {
      if (startDate.compareTo(endDate) == 0 || startDate.compareTo(endDate) > 0)
        return List<Map>.filled(0, <String, dynamic>{}, growable: false);

      Map<String, dynamic> args = <String, dynamic>{};
      args['startDate'] = startDate.millisecondsSinceEpoch;
      args['endDate'] = endDate.millisecondsSinceEpoch;
      args['limit'] = limit;
      List? list = await _channel.invokeMethod(
        Constants.GET_MESSAGE_CENTER_DATA,
        args,
      );
      return list;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  /// Entry point for the App Cards API. See [FlutterInsiderAppCards].
  FlutterInsiderAppCards get appCards {
    if (_insiderAppCards == null) {
      _insiderAppCards = new FlutterInsiderAppCards(_channel);
    }
    return _insiderAppCards!;
  }

  Future<List?> getMessageCenterDataWithIdentifiers(
    DateTime startDate,
    DateTime endDate,
    FlutterInsiderIdentifiers identifiers,
    int limit,
  ) async {
    try {
      if (startDate.compareTo(endDate) == 0 || startDate.compareTo(endDate) > 0)
        return List<Map>.filled(0, <String, dynamic>{}, growable: false);

      Map<String, dynamic> args = <String, dynamic>{};
      args['startDate'] = startDate.millisecondsSinceEpoch;
      args['endDate'] = endDate.millisecondsSinceEpoch;
      args['identifiers'] = identifiers.getIdentifiers();
      args['limit'] = limit;
      List? list = await _channel.invokeMethod(
        Constants.GET_MESSAGE_CENTER_DATA_WITH_IDENTIFIERS,
        args,
      );
      return list;
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  /// Records a sign-up confirmation event after the user completes
  /// registration.
  Future<void> signUpConfirmation({
    Map<String, Object>? customParameters,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      if (customParameters != null) {
        args[Constants.CUSTOM_PARAMETERS] =
            FlutterInsiderUtils.serializeCustomParameters(customParameters);
      }
      await _channel.invokeMethod(Constants.SIGN_UP_CONFIRMATION, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  Future<void> setActiveForegroundPushView() async {
    try {
      await _channel.invokeMethod(Constants.SET_ACTIVE_FOREGROUND_PUSH_VIEW);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Registers [callback] to receive foreground push notifications while the
  /// app is in the foreground.
  Future<void> setForegroundPushCallback(Function callback) async {
    try {
      registerEventChannel(callback, Constants.CALLBACK_FOREGROUND_PUSH);
      await _channel.invokeMethod(Constants.SET_FOREGROUND_PUSH_CALLBACK);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Re-initialises the SDK against a different [newPartnerName]. Use sparingly
  /// — typically only in apps that switch tenants at runtime.
  Future<void> reinitWithPartnerName(String newPartnerName) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['newPartnerName'] = newPartnerName;
      await _channel.invokeMethod(Constants.REINIT_WITH_PARTNER_NAME, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Returns the current Insider ID, or `null` if it cannot be retrieved.
  Future<String?> getInsiderID() async {
    try {
      return await _channel.invokeMethod(Constants.GET_INSIDER_ID);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
      return null;
    }
  }

  /// Registers [callback] to be invoked whenever the Insider ID changes
  /// (e.g. after [FlutterInsiderUser.login] or
  /// [FlutterInsiderUser.logoutResettingInsiderID]).
  Future<void> registerInsiderIDListener(Function callback) async {
    try {
      _insiderIDListener.receiveBroadcastStream().listen(
        (insiderID) {
          callback(insiderID);
        },
        onError: (dynamic error) {
          FlutterInsiderUtils.putException(_channel, error);
        },
      );
      await _channel.invokeMethod(Constants.REGISTER_INSIDER_ID_LISTENER);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Forwards a [pushToken] obtained from FCM / APNs to the Insider SDK.
  Future<void> setPushToken(String pushToken) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['pushToken'] = pushToken;
      await _channel.invokeMethod(Constants.SET_PUSH_TOKEN, args);
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Suppresses in-app messages until [enableInAppMessages] is called.
  void disableInAppMessages() {
    try {
      _channel.invokeMethod(Constants.DISABLE_IN_APP_MESSAGES);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Re-enables in-app messages after a previous [disableInAppMessages].
  void enableInAppMessages() {
    try {
      _channel.invokeMethod(Constants.ENABLE_IN_APP_MESSAGES);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Lets the Insider SDK process a deep / universal link [url].
  ///
  /// Call from your `onLink` / `onAppLink` handler to route Insider campaign
  /// links correctly.
  void handleUniversalLink(String url) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['universalLink'] = url;
      _channel.invokeMethod(Constants.HANDLE_UNIVERSAL_LINK, args);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
  }

  /// Sets the close-button position for the Insider internal browser. Pass
  /// one of the [InsiderCloseButtonPosition] constants.
  Future<void> setInternalBrowserCloseButtonPosition(String position) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args["position"] = position;
      await _channel.invokeMethod(
        Constants.SET_INTERNAL_BROWSER_CLOSE_BUTTON_POSITION,
        args,
      );
    } catch (Exception) {
      await FlutterInsiderUtils.putException(_channel, Exception);
    }
  }
}
