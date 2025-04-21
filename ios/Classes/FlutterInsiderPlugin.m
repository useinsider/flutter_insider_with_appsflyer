#import "FlutterInsiderPlugin.h"
#import "InsiderIDStreamHandler.h"
#import <InsiderHybrid/InsiderHybridMethods.h>
#import <InsiderHybrid/InsiderHybrid.h>
#import <InsiderMobile/Insider.h>
#import <InsiderGeofence/InsiderGeofence.h>

int INVALID_DATA_TYPE = -1;
FlutterEventSink mEventSink;

@implementation FlutterInsiderPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:@"flutter_insider_event"
                                         binaryMessenger:[registrar messenger]];
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_insider"
                                     binaryMessenger:[registrar messenger]];
    FlutterEventChannel* insiderIDListenerChannel = [FlutterEventChannel
                                                      eventChannelWithName:@"insider_id_listener"
                                                      binaryMessenger:[registrar messenger]];

    FlutterInsiderPlugin* instance = [[FlutterInsiderPlugin alloc] init];
    InsiderIDStreamHandler* insiderIdStreamHandler = [[InsiderIDStreamHandler alloc] init];

    [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
    [insiderIDListenerChannel setStreamHandler:insiderIdStreamHandler];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:INIT_WITH_LAUNCH_OPTIONS]) {
        [self initWithLaunchOptions:call withResult:result];
    } else if ([call.method isEqualToString:INIT_WITH_CUSTOM_ENDPOINT]) {
        [self initWithCustomEndpoint:call withResult:result];
    } else if ([call.method isEqualToString:START_TRACKING_GEOFENCE]){
        [self startTrackingGeofence:call];
    } else if ([call.method isEqualToString:REGISTER_WITH_QUIET_PERMISSION]) {
        [self registerWithQuietPermission:call];
    } else if ([call.method isEqualToString:HANDLE_NOTIFICATION]) {
        [self handleNotification:call];
    } else if ([call.method isEqualToString:SET_GDPR_CONSENT]) {
        [self setGDPRConsent:call];
    } else if ([call.method isEqualToString:@"setMobileAppAccess"]) {
        [self setMobileAppAccess:call];
    } else if ([call.method isEqualToString:ENABLE_IDFA_COLLECTION]) {
        [self enableIDFACollection:call];
    } else if ([call.method isEqualToString:@"enableCarrierCollection"]) {
        [self enableCarrierCollection:call];
    } else if ([call.method isEqualToString:@"enableIpCollection"]) {
        [self enableIpCollection:call];
    } else if ([call.method isEqualToString:@"enableLocationCollection"]) {
        [self enableLocationCollection:call];
    } else if ([call.method isEqualToString:GET_CONTENT_STRING_WITH_NAME]) {
        [self getContentStringWithName:call withResult:result];
    } else if ([call.method isEqualToString:GET_CONTENT_INT_WITH_NAME]) {
        [self getContentIntWithName:call withResult:result];
    } else if ([call.method isEqualToString:GET_CONTENT_BOOL_WITH_NAME]) {
        [self getContentBoolWithName:call withResult:result];
    } else if ([call.method isEqualToString:@"getContentStringWithoutCache"]) {
        [self getContentStringWithoutCache:call withResult:result];
    } else if ([call.method isEqualToString:@"getContentIntWithoutCache"]) {
        [self getContentIntWithoutCache:call withResult:result];
    } else if ([call.method isEqualToString:@"getContentBoolWithoutCache"]) {
        [self getContentBoolWithoutCache:call withResult:result];
    } else if ([call.method isEqualToString:REMOVE_INAPP]) {
        [self removeInapp:call];
    } else if ([call.method isEqualToString:VISIT_HOME_PAGE]) {
        [self visitHomePage:call];
    } else if ([call.method isEqualToString:VISIT_LISTING_PAGE]) {
        [self visitListingPage:call];
    } else if ([call.method isEqualToString:VISIT_PRODUCT_DETAIL_PAGE]) {
        [self visitProductDetailPage:call];
    } else if ([call.method isEqualToString:VISIT_CART_PAGE]) {
        [self visitCartPage:call];
    } else if ([call.method isEqualToString:ITEM_PURCHASED]) {
        [self itemPurchased:call];
    } else if ([call.method isEqualToString:ITEM_ADDED_TO_CART]) {
        [self itemAddedToCart:call];
    } else if ([call.method isEqualToString:ITEM_REMOVED_FROM_CART]) {
        [self itemRemovedFromCart:call];
    } else if ([call.method isEqualToString:CART_CLEARED]) {
        [self cartCleared:call];
    } else if ([call.method isEqualToString:TAG_EVENT]) {
        [self tagEvent:call];
    } else if ([call.method isEqualToString:GET_SMART_RECOMMENDATION]) {
        [self getSmartRecommendation:call withResult:result];
    } else if ([call.method isEqualToString:GET_SMART_RECOMMENDATION_WITH_PRODUCT]) {
        [self getSmartRecommendationWithProduct:call withResult:result];
    } else if ([call.method isEqualToString:@"getSmartRecommendationWithProductIDs"]) {
        [self getSmartRecommendationWithProductIDs:call withResult:result];
    } else if ([call.method isEqualToString:CLICK_SMART_RECOMMENDATION_PRODUCT]) {
        [self clickSmartRecommendationProduct:call];
    } else if ([call.method isEqualToString:GET_MESSAGE_CENTER_DATA]) {
        [self getMessageCenter:call withResult:result];
    } else if ([call.method isEqualToString:SET_GENDER]) {
        [self setGender:call];
    } else if ([call.method isEqualToString:SET_BIRTHDAY]) {
        [self setBirthday:call];
    } else if ([call.method isEqualToString:SET_NAME]) {
        [self setName:call];
    } else if ([call.method isEqualToString:SET_SURNAME]) {
        [self setSurname:call];
    } else if ([call.method isEqualToString:SET_AGE]) {
        [self setAge:call];
    } else if ([call.method isEqualToString:SET_SMS_OPTIN]) {
        [self setSMSOptin:call];
    } else if ([call.method isEqualToString:@"setEmail"]) {
        [self setEmail:call];
    } else if ([call.method isEqualToString:SET_EMAIL_OPTIN]) {
        [self setEmailOptin:call];
    } else if ([call.method isEqualToString:@"setPhoneNumber"]) {
        [self setPhoneNumber:call];
    } else if ([call.method isEqualToString:SET_PUSH_OPTIN]) {
        [self setPushOptin:call];
    } else if ([call.method isEqualToString:SET_LOCATION_OPTIN]) {
        [self setLocationOptin:call];
    } else if ([call.method isEqualToString:SET_LANGUAGE]) {
        [self setLanguage:call];
    } else if ([call.method isEqualToString:SET_LOCALE]) {
        [self setLocale:call];
    } else if ([call.method isEqualToString:SET_FACEBOOK_ID]) {
        [self setFacebookID:call];
    } else if ([call.method isEqualToString:SET_TWITTER_ID]) {
        [self setTwitterID:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_STRING]) {
        [self setCustomAttributeWithString:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_INT]) {
        [self setCustomAttributeWithInt:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE]) {
        [self setCustomAttributeWithDouble:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN]) {
        [self setCustomAttributeWithBoolean:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_DATE]) {
        [self setCustomAttributeWithDate:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_ARRAY]) {
        [self setCustomAttributeWithArray:call];
    } else if ([call.method isEqualToString:UNSET_CUSTOM_ATTRIBUTE]) {
        [self unsetCustomAttribute:call];
    } else if ([call.method isEqualToString:LOGIN]) {
        [self login:call withResult:result];
    } else if ([call.method isEqualToString:LOGOUT]) {
        [self logout:call withResult:result];
    } else if ([call.method isEqualToString:PUT_EXCEPTION]) {
        [self putException:call];
    } else if ([call.method isEqualToString:SET_CUSTOM_ENDPOINT]) {
    } else if ([call.method isEqualToString:@"setWhatsappOptin"]) {
        [self setWhatsappOptin:call];
    } else if ([call.method isEqualToString:@"signUpConfirmation"]) {
        [self signUpConfirmation:call];
    } else if ([call.method isEqualToString:@"setForegroundPushCallback"]) {
        [self setForegroundPushCallback:call];
    } else if ([call.method isEqualToString:@"setActiveForegroundPushView"]) {
        [self setActiveForegroundPushView:call];
    } else if ([call.method isEqualToString:@"reinitWithPartnerName"]) {
        [self reinitWithPartnerName:call];
    } else if ([call.method isEqualToString:@"getInsiderID"]) {
        [self getInsiderID:call withResult:result];
    } else if ([call.method isEqualToString:@"registerInsiderIDListener"]) {
        [self registerInsiderIDListener:call];
    } else if ([call.method isEqualToString:@"setPushToken"]) {
    } else if ([call.method isEqualToString:@"disableInAppMessages"]) {
        [self disableInAppMessages:call];
    } else if ([call.method isEqualToString:@"enableInAppMessages"]) {
        [self enableInAppMessages:call];
    } else if ([call.method isEqualToString:@"visitWishlistPage"]) {
        [self visitWishlistPage:call];
    } else if ([call.method isEqualToString:@"itemAddedToWishlist"]) {
        [self itemAddedToWishlist:call];
    } else if ([call.method isEqualToString:@"itemRemovedFromWishlist"]) {
        [self itemRemovedFromWishlist:call];
    } else if ([call.method isEqualToString:@"wishlistCleared"]) {
        [self wishlistCleared:call];
    } else if ([call.method isEqualToString:@"handleUniversalLink"]) {
        [self handleUniversalLink:call];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initWithLaunchOptions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try{
        if (!call.arguments[@"partnerName"] || !call.arguments[@"sdkVersion"] || !call.arguments[@"appGroup"]) {
            result(@[]);
            return;
        }
        [Insider registerInsiderCallbackWithSelector:@selector(registerCallback:) sender:self];
        [Insider setHybridSDKVersion:call.arguments[@"sdkVersion"]];
        [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"]];
        [Insider hybridApplicationDidBecomeActive];
        result(@[]);
    } @catch (NSException *exception){
        [Insider sendError:exception desc:@"RNInsider.m - initWithAppGroup"];
    }
}

- (void)initWithCustomEndpoint:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try{
        if (!call.arguments[@"partnerName"] || !call.arguments[@"sdkVersion"] || !call.arguments[@"appGroup"] || !call.arguments[@"customEndpoint"]) {
            result(@[]);
            return;
        }
        [Insider registerInsiderCallbackWithSelector:@selector(registerCallback:) sender:self];
        [Insider setHybridSDKVersion:call.arguments[@"sdkVersion"]];
        [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"] customEndpoint:call.arguments[@"customEndpoint"]];
        [Insider hybridApplicationDidBecomeActive];
        result(@[]);
    } @catch (NSException *exception){
        [Insider sendError:exception desc:@"RNInsider.m - initWithAppGroup"];
    }
}

- (void)hybridIntent:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        //[Insider resumeSession];
        result(@[]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)registerWithQuietPermission:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"permission"]) return;
        [Insider registerWithQuietPermission:[call.arguments[@"permission"] boolValue]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)handleNotification:(FlutterMethodCall *)call {
    @try{
        if (!call.arguments[@"notification"]) return;
        NSDictionary *notificationPayload = call.arguments[@"notification"];
        [Insider handlePushLogWithUserInfo:notificationPayload];
        [Insider trackInteractiveLogWithUserInfo:notificationPayload];
    } @catch (NSException *e){
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)startTrackingGeofence:(FlutterMethodCall *)call {
    @try {
        [InsiderGeofence startTracking];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)enableIDFACollection:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"enableIDFACollection"]) return;
        [Insider enableIDFACollection:[call.arguments[@"enableIDFACollection"] boolValue]];
    } @catch (NSException *e){
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)enableCarrierCollection:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"enableCarrierCollection"]) return;
        [Insider enableCarrierCollection:[call.arguments[@"enableCarrierCollection"] boolValue]];
    } @catch (NSException *e){
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)enableIpCollection:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"enableIpCollection"]) return;
        [Insider enableIpCollection:[call.arguments[@"enableIpCollection"] boolValue]];
    } @catch (NSException *e){
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)enableLocationCollection:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"enableLocationCollection"]) return;
        [Insider enableLocationCollection:[call.arguments[@"enableLocationCollection"] boolValue]];
    } @catch (NSException *e){
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setGDPRConsent:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"consent"]) return;
        [Insider setGDPRConsent:[call.arguments[@"consent"] boolValue]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setMobileAppAccess:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"mobileAppAccess"]) return;
        [Insider setMobileAppAccess:[call.arguments[@"mobileAppAccess"] boolValue]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentStringWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        NSString *coResult = [Insider getContentStringWithName:call.arguments[@"variableName"] defaultString:call.arguments[@"defaultValue"] dataType:[call.arguments[@"dataType"] intValue]];
        result(coResult);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentIntWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        int coResult = [Insider getContentIntWithName:call.arguments[@"variableName"] defaultInt:[call.arguments[@"defaultValue"] intValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithInt:coResult]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentBoolWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        bool coResult = [Insider getContentBoolWithName:call.arguments[@"variableName"] defaultBool:[call.arguments[@"defaultValue"] boolValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithBool:coResult]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentStringWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        NSString *coResult = [Insider getContentStringWithoutCache:call.arguments[@"variableName"] defaultString:call.arguments[@"defaultValue"] dataType:[call.arguments[@"dataType"] intValue]];
        result(coResult);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentBoolWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        bool coResult = [Insider getContentBoolWithoutCache:call.arguments[@"variableName"] defaultBool:[call.arguments[@"defaultValue"] boolValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithBool:coResult]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getContentIntWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) return;
        int coResult = [Insider getContentIntWithoutCache:call.arguments[@"variableName"] defaultInt:[call.arguments[@"defaultValue"] intValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithInt:coResult]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)removeInapp:(FlutterMethodCall *)call {
    @try {
        [Insider removeInapp];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitHomePage:(FlutterMethodCall *)call {
    @try {
        [Insider visitHomepage];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitListingPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"taxonomy"]) return;
        [Insider visitListingPageWithTaxonomy:call.arguments[@"taxonomy"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitProductDetailPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[PRODUCT_MUST_MAP] || !call.arguments[PRODUCT_OPT_MAP]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[PRODUCT_MUST_MAP] productOptMap:call.arguments[PRODUCT_OPT_MAP]];
        [Insider visitProductDetailPageWithProduct:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitCartPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"products"]) return;
        [InsiderHybrid visitCartPage:call.arguments[@"products"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemPurchased:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"uniqueSaleID"] || !call.arguments[PRODUCT_MUST_MAP] || !call.arguments[PRODUCT_OPT_MAP]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[PRODUCT_MUST_MAP] productOptMap:call.arguments[PRODUCT_OPT_MAP]];
        [Insider itemPurchasedWithSaleID:call.arguments[@"uniqueSaleID"] product:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemAddedToCart:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[PRODUCT_MUST_MAP] || !call.arguments[PRODUCT_OPT_MAP]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[PRODUCT_MUST_MAP] productOptMap:call.arguments[PRODUCT_OPT_MAP]];
        [Insider itemAddedToCartWithProduct:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemRemovedFromCart:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"productID"]) return;
        [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)cartCleared:(FlutterMethodCall *)call {
    @try {
        [Insider cartCleared];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitWishlistPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"products"]) return;

        [Insider visitWishlistWithProducts:[InsiderHybrid convertArrayToInsiderProductArray:call.arguments[@"products"]]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemAddedToWishlist:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[PRODUCT_MUST_MAP] || !call.arguments[PRODUCT_OPT_MAP]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[PRODUCT_MUST_MAP] productOptMap:call.arguments[PRODUCT_OPT_MAP]];

        [Insider itemAddedToWishlistWithProduct:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemRemovedFromWishlist:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"productID"]) return;

        [Insider itemRemovedFromWishlistWithProductID:call.arguments[@"productID"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)wishlistCleared:(FlutterMethodCall *)call {
    @try {
        [Insider wishlistCleared];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getSmartRecommendation:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"currency"]) return;
        [Insider getSmartRecommendationWithID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] currency:call.arguments[@"currency"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getSmartRecommendationWithProduct:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"productMustMap"] || !call.arguments[@"productOptMap"]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[@"productMustMap"] productOptMap:call.arguments[@"productOptMap"]];
        [Insider getSmartRecommendationWithProduct:product recommendationID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getSmartRecommendationWithProductIDs:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"productIDs"] || !call.arguments[@"currency"]) return;

        [Insider getSmartRecommendationWithProductIDs:call.arguments[@"productIDs"] recommendationID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] currency:call.arguments[@"currency"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)clickSmartRecommendationProduct:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"productMustMap"] || !call.arguments[@"productOptMap"]) return;
        InsiderProduct *product = (InsiderProduct *)[InsiderHybrid createProduct:call.arguments[@"productMustMap"] productOptMap:call.arguments[@"productOptMap"]];
        [Insider clickSmartRecommendationProductWithID:[call.arguments[@"recommendationID"] intValue] product:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getMessageCenter:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"startDate"] || !call.arguments[@"endDate"] || !call.arguments[@"limit"]) return;
        [InsiderHybrid getMessageCenterDataWithLimit:[call.arguments[@"limit"] intValue] startDate:call.arguments[@"startDate"] endDate:call.arguments[@"endDate"] success:^(NSArray *messageCenterData) {
            result(messageCenterData);
        }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}
- (void)tagEvent:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"name"] || !call.arguments[@"parameters"]) return;
        InsiderEvent *event = [Insider tagEvent:call.arguments[@"name"]];
        event.addParameters(call.arguments[@"parameters"]);
        [event build];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setGender:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [InsiderHybrid setGender:[call.arguments[@"value"] intValue]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setBirthday:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [InsiderHybrid setBirthday:call.arguments[@"value"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setName:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setName(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setSurname:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setSurname(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setAge:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setAge([call.arguments[@"value"] intValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setPhoneNumber:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setPhoneNumber(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setSMSOptin:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setSMSOptin([call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setEmail:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setEmail(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setEmailOptin:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setEmailOptin([call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setPushOptin:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setPushOptin([call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setLocationOptin:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setLocationOptin([call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setLanguage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setLanguage(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setLocale:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setLocale(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setFacebookID:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setFacebookID(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setTwitterID:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setTwitterID(call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithString:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [Insider getCurrentUser].setCustomAttributeWithString(call.arguments[@"key"], call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithInt:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [Insider getCurrentUser].setCustomAttributeWithInt(call.arguments[@"key"], [call.arguments[@"value"] intValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithDouble:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [Insider getCurrentUser].setCustomAttributeWithDouble(call.arguments[@"key"], [call.arguments[@"value"] doubleValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithBoolean:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [Insider getCurrentUser].setCustomAttributeWithBoolean(call.arguments[@"key"], [call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithDate:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [InsiderHybrid setCustomAttributeWithDate:call.arguments[@"key"] value:call.arguments[@"value"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)setCustomAttributeWithArray:(FlutterMethodCall *)call{
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) return;
        [Insider getCurrentUser].setCustomAttributeWithArray(call.arguments[@"key"], call.arguments[@"value"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)unsetCustomAttribute:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"key"]) return;
        [Insider getCurrentUser].unsetCustomAttribute(call.arguments[@"key"]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)login:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"identifiers"]) return;
        NSMutableDictionary *identifiers  = call.arguments[@"identifiers"];
        InsiderIdentifiers *insiderIdentifiers = [[InsiderIdentifiers alloc] init];
        for (NSString *key in identifiers.allKeys){
            if([key isEqualToString:ADD_EMAIL]){
                insiderIdentifiers.addEmail([identifiers objectForKey:key]);
            } else if([key isEqualToString:ADD_PHONE_NUMBER]){
                insiderIdentifiers.addPhoneNumber([identifiers objectForKey:key]);
            } else if([key isEqualToString:ADD_USER_ID]){
                insiderIdentifiers.addUserID([identifiers objectForKey:key]);
            } else {
                insiderIdentifiers.addCustomIdentifier(key, [identifiers objectForKey:key]);
            }
        }

        if (call.arguments[@"insiderID"]) {
            [[Insider getCurrentUser] login:insiderIdentifiers insiderIDResult:^(NSString *insiderID) {
                result(insiderID);
            }];
            return;
        }

        [[Insider getCurrentUser] login:insiderIdentifiers];
        result(@[]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)logout:(FlutterMethodCall *)call withResult:(FlutterResult)result{
    @try {
        [[Insider getCurrentUser] logout];
        result(@[]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)putException:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"exception"]) return;
        NSException *e = [NSException exceptionWithName:@"[Dart Error]" reason:call.arguments[@"exception"] userInfo:nil];
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    } @catch (NSException *e) {
    }
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    @try {
        mEventSink = events;
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
    return nil;
}

-(void)registerCallback:(NSDictionary*)dict {
    @try {
        mEventSink([InsiderHybrid dictToJson:dict]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)setWhatsappOptin:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"value"]) return;
        [Insider getCurrentUser].setWhatsappOptin([call.arguments[@"value"] boolValue]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)signUpConfirmation:(FlutterMethodCall *)call {
    @try {
        [Insider signUpConfirmation];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)setActiveForegroundPushView:(FlutterMethodCall *)call {
    @try {
        [Insider setActiveForegroundPushView];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)setForegroundPushCallback:(FlutterMethodCall *) call {
    @try {
        [Insider setForegroundPushCallback:@selector(foregroundPushCallback:) sender:self];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)reinitWithPartnerName:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"newPartnerName"]) return;
        [Insider reinitWithPartnerName:call.arguments[@"newPartnerName"]];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)getInsiderID:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        result([Insider getInsiderID]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)disableInAppMessages:(FlutterMethodCall *)call {
    @try {
        [Insider disableInAppMessages];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)enableInAppMessages:(FlutterMethodCall *)call {
    @try {
        [Insider enableInAppMessages];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)foregroundPushCallback:(UNNotification *) notification {
    @try {
        mEventSink([InsiderHybrid dictToJson:notification.request.content.userInfo]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)registerInsiderIDListener:(FlutterMethodCall *) call {
    @try {
        [Insider registerInsiderIDListenerWithSelector:@selector(insiderIDChangeListener:) sender:self];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)insiderIDChangeListener:(NSString *) insiderID {
    @try {
        [InsiderIDStreamHandler triggerEvent:insiderID];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)handleUniversalLink:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"universalLink"]) return;

        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:call.arguments[@"universalLink"]];

        [Insider handleUniversalLink:activity];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

@end
