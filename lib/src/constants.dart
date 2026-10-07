class Constants {
  //channel names
  /// The plugin's single RPC channel, shared by the facade and every feature.
  static const String CHANNEL_NAME = "flutter_insider";

  /// Event channel carrying SDK callbacks (events, foreground push).
  static const String EVENT_CHANNEL_NAME = "flutter_insider_event";

  /// Event channel carrying Insider ID changes.
  static const String ID_LISTENER_CHANNEL_NAME = "insider_id_listener";

  static const String APP_IDENTIFIER = "appIdentifier";

  //method names
  static const String INIT_WITH_LAUNCH_OPTIONS = "initWithLaunchOptions";
  static const String INIT_WITH_CUSTOM_ENDPOINT = "initWithCustomEndpoint";
  static const String REGISTER_WITH_QUIET_PERMISSION =
      "registerWithQuietPermission";
  static const String START_TRACKING_GEOFENCE = "startTrackingGeofence";
  static const String SET_ALLOWS_BACKGROUND_LOCATION_UPDATES =
      "setAllowsBackgroundLocationUpdates";
  static const String HANDLE_NOTIFICATION = "handleNotification";
  static const String TRIGGER_PUSH_PROCESS_WITH_NOTIFICATION_DATA =
      "triggerPushProcessWithNotificationData";
  static const String SET_GDPR_CONSENT = "setGDPRConsent";
  static const String SET_MOBILE_APP_ACCESS = "setMobileAppAccess";
  static const String GET_CONTENT_STRING_WITH_NAME = "getContentStringWithName";
  static const String GET_CONTENT_INT_WITH_NAME = "getContentIntWithName";
  static const String GET_CONTENT_BOOL_WITH_NAME = "getContentBoolWithName";
  static const String GET_CONTENT_STRING_WITHOUT_CACHE =
      "getContentStringWithoutCache";
  static const String GET_CONTENT_INT_WITHOUT_CACHE =
      "getContentIntWithoutCache";
  static const String GET_CONTENT_BOOL_WITHOUT_CACHE =
      "getContentBoolWithoutCache";
  static const String MARK_CONTENT_OPTIMIZER_AS_SEEN =
      "markContentOptimizerAsSeen";
  static const String REMOVE_INAPP = "removeInapp";
  static const String VISIT_HOME_PAGE = "visitHomePage";
  static const String VISIT_LISTING_PAGE = "visitListingPage";
  static const String VISIT_PRODUCT_DETAIL_PAGE = "visitProductDetailPage";
  static const String VISIT_CART_PAGE = "visitCartPage";
  static const String VISIT_WISHLIST_PAGE = "visitWishlistPage";
  static const String ITEM_PURCHASED = "itemPurchased";
  static const String ITEM_ADDED_TO_CART = "itemAddedToCart";
  static const String ITEM_REMOVED_FROM_CART = "itemRemovedFromCart";
  static const String CART_CLEARED = "cartCleared";
  static const String ITEM_ADDED_TO_WISH_LIST = "itemAddedToWishlist";
  static const String ITEM_REMOVED_FROM_WISH_LIST = "itemRemovedFromWishlist";
  static const String WISH_LIST_CLEARED = "wishlistCleared";
  static const String SET_CUSTOM_ENDPOINT = "setCustomEndpoint";
  static const String GET_SMART_RECOMMENDATION = "getSmartRecommendation";
  static const String GET_SMART_RECOMMENDATION_WITH_PRODUCT =
      "getSmartRecommendationWithProduct";
  static const String GET_SMART_RECOMMENDATION_WITH_PRODUCT_IDS =
      "getSmartRecommendationWithProductIDs";
  static const String CLICK_SMART_RECOMMENDATION_PRODUCT =
      "clickSmartRecommendationProduct";
  static const String GET_MESSAGE_CENTER_DATA = "getMessageCenterData";
  static const String GET_APP_CARDS_CAMPAIGNS = "getAppCardsCampaigns";
  static const String GET_MESSAGE_CENTER_DATA_WITH_IDENTIFIERS =
      "getMessageCenterDataWithIdentifiers";
  static const String TAG_EVENT = "tagEvent";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_STRING =
      "setCustomAttributeWithString";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_INT =
      "setCustomAttributeWithInt";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE =
      "setCustomAttributeWithDouble";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN =
      "setCustomAttributeWithBoolean";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_DATE =
      "setCustomAttributeWithDate";
  static const String SET_CUSTOM_ATTRIBUTE_WITH_ARRAY =
      "setCustomAttributeWithArray";
  static const String UNSET_CUSTOM_ATTRIBUTE = "unsetCustomAttribute";
  static const String LOGIN = "login";
  static const String LOGOUT = "logout";
  static const String LOGOUT_RESETTING_INSIDER_ID = "logoutResettingInsiderID";
  static const String ENABLE_IDFA_COLLECTION = 'enableIDFACollection';
  static const String SIGN_UP_CONFIRMATION = 'signUpConfirmation';
  static const String SET_ACTIVE_FOREGROUND_PUSH_VIEW =
      'setActiveForegroundPushView';
  static const String SET_FOREGROUND_PUSH_CALLBACK =
      'setForegroundPushCallback';
  static const String REINIT_WITH_PARTNER_NAME = 'reinitWithPartnerName';
  static const String GET_INSIDER_ID = 'getInsiderID';
  static const String REGISTER_INSIDER_ID_LISTENER =
      'registerInsiderIDListener';
  static const String REGISTER_EVENT_LISTENER = 'registerEventListener';
  static const String UNREGISTER_EVENT_LISTENER = 'unregisterEventListener';
  static const String SET_PUSH_TOKEN = 'setPushToken';
  static const String DISABLE_IN_APP_MESSAGES = 'disableInAppMessages';
  static const String ENABLE_IN_APP_MESSAGES = 'enableInAppMessages';
  static const String HANDLE_UNIVERSAL_LINK = 'handleUniversalLink';

  static const String ENABLE_CARRIER_COLLECTION = 'enableCarrierCollection';
  static const String ENABLE_IP_COLLECTION = 'enableIpCollection';
  static const String ENABLE_LOCATION_COLLECTION = 'enableLocationCollection';
  static const String SET_INTERNAL_BROWSER_CLOSE_BUTTON_POSITION =
      'setInternalBrowserCloseButtonPosition';

  static const String ADD_EMAIL = "addEmail";
  static const String ADD_PHONE_NUMBER = "addPhoneNumber";
  static const String ADD_USER_ID = "addUserID";
  static const String PRODUCTS = "products";
  static const String PRODUCT_MUST_MAP = "productMustMap";
  static const String PRODUCT_OPT_MAP = "productOptMap";
  static const String CUSTOM_PARAMETERS = "customParameters";

  //user attributes
  static const String SET_GENDER = "setGender";
  static const String SET_BIRTHDAY = "setBirthday";
  static const String SET_NAME = "setName";
  static const String SET_SURNAME = "setSurname";
  static const String SET_LANGUAGE = "setLanguage";
  static const String SET_LOCALE = "setLocale";
  static const String SET_FACEBOOK_ID = "setFacebookID";
  static const String SET_TWITTER_ID = "setTwitterID";
  static const String SET_AGE = "setAge";
  static const String SET_SMS_OPTIN = "setSMSOptin";
  static const String SET_EMAIL_OPTIN = "setEmailOptin";
  static const String SET_LOCATION_OPTIN = "setLocationOptin";
  static const String SET_PUSH_OPTIN = "setPushOptin";
  static const String SET_WHATSAPP_OPTIN = "setWhatsappOptin";
  static const String SET_PROMOTIONAL_OPTIN = "setPromotionalOptin";
  static const String SET_EMAIL = "setEmail";
  static const String SET_PHONE_NUMBER = "setPhoneNumber";

  //product must have keys
  static const String PRODUCT_ID = "product_id";
  static const String PRODUCT_NAME = "name";
  static const String TAXONOMY = "taxonomy";
  static const String IMAGE_URL = "image_url";
  static const String UNIT_PRICE = "unit_price";
  static const String CURRENCY = "currency";

  //product optional keys
  static const String SUB_CATEGORY = "sub_category";
  static const String COLOR = "color";
  static const String VOUCHER_NAME = "voucher_name";
  static const String PROMOTION_NAME = "promotion_name";
  static const String SALE_PRICE = "sale_price";
  static const String SHIPPING_COST = "shipping_cost";
  static const String VOUCHER_DISCOUNT = "voucher_discount";
  static const String PROMOTION_DISCOUNT = "promotion_discount";
  static const String STOCK = "stock";
  static const String QUANTITY = "quantity";
  static const String SIZE = "size";
  static const String GROUP_CODE = "groupcode";
  static const String BRAND = "brnd";
  static const String SKU = "sku";
  static const String PRODUCT_GENDER = "ge";
  static const String MULTIPACK = "mlt";
  static const String PRODUCT_TYPE = "pt";
  static const String GTIN = "gt";
  static const String DESCRIPTION = "desc";
  static const String TAGS = "tags";
  static final String IS_IN_STOCK = "iis";
  static const String PRODUCT_URL = "url";

  // Callback Types
  static const String CALLBACK_EVENT = "event";
  static const String CALLBACK_FOREGROUND_PUSH = "foreground_push";
  static const String CALLBACK_INSIDER_ID_LISTENER = "insider_id_listener";

  static const String APP_CARDS_BUTTON_CLICK = "clickAppCardButton";
  static const String APP_CARDS_MARK_AS_READ = "appCardsMarkAsRead";
  static const String APP_CARDS_MARK_AS_UNREAD = "appCardsMarkAsUnread";
  static const String APP_CARDS_VIEW = "viewAppCard";
  static const String APP_CARDS_CLICK = "clickAppCard";

  // App Frames
  /// Platform view type registered by both native sides.
  static const String APP_FRAMES_VIEW_TYPE =
      "com.useinsider.insider.flutter_insider/app_frames_view";

  /// Prefix of the per-view MethodChannel. The platform view id is appended.
  static const String APP_FRAMES_CHANNEL_PREFIX = "flutter_insider_app_frames_";

  // App Frames: native -> Dart
  static const String APP_FRAMES_ON_STATUS_CHANGED = "onStatusChanged";
  static const String APP_FRAMES_ON_LOAD_FAILED = "onLoadFailed";
  static const String APP_FRAMES_ON_HEIGHT_CHANGE_REQUESTED =
      "onHeightChangeRequested";
  static const String APP_FRAMES_ON_DISMISS_REQUESTED = "onDismissRequested";
  static const String APP_FRAMES_ON_ACTION_TRIGGERED = "onActionTriggered";

  // App Frames: argument keys
  static const String APP_FRAMES_PLACEMENT_ID = "placementId";
  static const String APP_FRAMES_HEIGHT = "height";
  static const String APP_FRAMES_ACTION_DATA = "actionData";
  static const String APP_FRAMES_ERROR_CODE = "code";
  static const String APP_FRAMES_ERROR_MESSAGE = "message";
  static const String APP_FRAMES_DISMISS_CODE = "dismissCode";
  static const String APP_FRAMES_ERROR_CAUSE = "cause";
  static const String APP_FRAMES_STATUS = "status";
  static const String APP_FRAMES_PREVIOUS_STATUS = "previousStatus";

  // App Frames: status wire vocabulary. Matches the lowerCamelCase names both
  // native SDKs report (iOS `InsiderAppFramesViewStatusStringValue`).
  static const String APP_FRAMES_STATUS_DETACHED = "detached";
  static const String APP_FRAMES_STATUS_NO_PLACEMENT = "noPlacement";
  static const String APP_FRAMES_STATUS_DISABLED = "disabled";
  static const String APP_FRAMES_STATUS_RESOLVING = "resolving";
  static const String APP_FRAMES_STATUS_DOWNLOADING = "downloading";
  static const String APP_FRAMES_STATUS_RENDERING = "rendering";
  static const String APP_FRAMES_STATUS_UNAVAILABLE = "unavailable";
  static const String APP_FRAMES_STATUS_READY = "ready";
  static const String APP_FRAMES_STATUS_DISMISSED = "dismissed";
  static const String APP_FRAMES_STATUS_ERROR_RESOLVING = "errorResolving";
  static const String APP_FRAMES_STATUS_ERROR_DOWNLOADING = "errorDownloading";
  static const String APP_FRAMES_STATUS_ERROR_RENDERING = "errorRendering";
  static const String APP_FRAMES_STATUS_UNKNOWN = "unknown";
}
