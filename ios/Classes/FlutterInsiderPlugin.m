#import "FlutterInsiderPlugin.h"
#import "InsiderIDStreamHandler.h"
#import "FlutterInsiderUtils.h"
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

- (NSDictionary *)convertCustomParameters:(NSArray *)params {
    if (!params) return nil;
    NSMutableDictionary *converted = [NSMutableDictionary dictionary];
    for (id item in params) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *parameter = (NSDictionary *)item;
        NSString *type = parameter[@"type"];
        NSString *key  = parameter[@"key"];
        if (![type isKindOfClass:[NSString class]] || ![key isKindOfClass:[NSString class]]) continue;
        id value = parameter[@"value"];
        if ([type isEqualToString:@"string"] && [value isKindOfClass:[NSString class]]) {
            converted[key] = value;
        } else if (([type isEqualToString:@"integer"] || [type isEqualToString:@"double"] || [type isEqualToString:@"boolean"]) && [value isKindOfClass:[NSNumber class]]) {
            converted[key] = value;
        } else if ([type isEqualToString:@"date"] && [value isKindOfClass:[NSNumber class]]) {
            long long epochMillis = [(NSNumber *)value longLongValue];
            NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)epochMillis / 1000.0];
            converted[key] = dateValue;
        } else if (([type isEqualToString:@"string_array"] || [type isEqualToString:@"numeric_array"]) && [value isKindOfClass:[NSArray class]]) {
            converted[key] = value;
        }
    }
    return converted;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:INIT_WITH_LAUNCH_OPTIONS]) {
        [self initWithLaunchOptions:call withResult:result];
    } else if ([call.method isEqualToString:INIT_WITH_CUSTOM_ENDPOINT]) {
        [self initWithCustomEndpoint:call withResult:result];
    } else if ([call.method isEqualToString:START_TRACKING_GEOFENCE]){
        [self startTrackingGeofence:call];
    } else if ([call.method isEqualToString:SET_ALLOWS_BACKGROUND_LOCATION_UPDATES]) {
        [self setAllowsBackgroundLocationUpdates:call];
    } else if ([call.method isEqualToString:REGISTER_WITH_QUIET_PERMISSION]) {
        [self registerWithQuietPermission:call];
    } else if ([call.method isEqualToString:HANDLE_NOTIFICATION] || [call.method isEqualToString:@"triggerPushProcessWithNotificationData"]) {
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
    } else if ([call.method isEqualToString:@"getMessageCenterDataWithIdentifiers"]) {
        [self getMessageCenterWithIdentifiers:call withResult:result];
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
    } else if ([call.method isEqualToString:@"logoutResettingInsiderID"]) {
        [self logoutResettingInsiderID:call withResult:result];
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
    } else if ([call.method isEqualToString:@"setInternalBrowserCloseButtonPosition"]) {
        result(nil);
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

- (void)setAllowsBackgroundLocationUpdates:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"allowsBackgroundLocationUpdates"]) return;
        [InsiderGeofence setAllowsBackgroundLocationUpdates:[call.arguments[@"allowsBackgroundLocationUpdates"] boolValue]];
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
        if (call.arguments[@"customParameters"]) {
            [Insider visitHomepageWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitHomepage];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitListingPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"taxonomy"]) return;
        if (call.arguments[@"customParameters"]) {
            [Insider visitListingPageWithTaxonomy:call.arguments[@"taxonomy"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitListingPageWithTaxonomy:call.arguments[@"taxonomy"]];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitProductDetailPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider visitProductDetailPageWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitProductDetailPageWithProduct:product];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitCartPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"products"]) return;
        NSArray *productsList = call.arguments[@"products"];
        NSMutableArray *cartProducts = [NSMutableArray arrayWithCapacity:productsList.count];
        for (NSDictionary *productMap in productsList) {
            NSDictionary *requiredFields = productMap[@"requiredFields"];
            NSDictionary *optionalFields = productMap[@"optionalFields"];
            NSArray *productCustomParameters = productMap[@"productCustomParameters"];
            InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
            [cartProducts addObject:product];
        }
        NSString *saleID = call.arguments[@"saleID"];
        if (saleID.length > 0) {
            [Insider visitCartPageWithProducts:cartProducts saleID:saleID customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else if (call.arguments[@"customParameters"]) {
            [Insider visitCartPageWithProducts:cartProducts customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitCartPageWithProducts:cartProducts];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemPurchased:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"uniqueSaleID"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemPurchasedWithSaleID:call.arguments[@"uniqueSaleID"] product:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemPurchasedWithSaleID:call.arguments[@"uniqueSaleID"] product:product];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemAddedToCart:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemAddedToCartWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemAddedToCartWithProduct:product];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemRemovedFromCart:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"productID"]) return;
        NSString *saleID = call.arguments[@"saleID"];
        if (saleID.length > 0) {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"] saleID:saleID customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else if (call.arguments[@"customParameters"]) {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"]];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)cartCleared:(FlutterMethodCall *)call {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider cartClearedWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider cartCleared];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)visitWishlistPage:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"products"]) return;
        NSArray *productsList = call.arguments[@"products"];
        NSMutableArray *wishlistProducts = [NSMutableArray arrayWithCapacity:productsList.count];
        for (NSDictionary *productMap in productsList) {
            NSDictionary *requiredFields = productMap[@"requiredFields"];
            NSDictionary *optionalFields = productMap[@"optionalFields"];
            NSArray *productCustomParameters = productMap[@"productCustomParameters"];
            InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
            [wishlistProducts addObject:product];
        }
        if (call.arguments[@"customParameters"]) {
            [Insider visitWishlistWithProducts:wishlistProducts customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitWishlistWithProducts:wishlistProducts];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemAddedToWishlist:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemAddedToWishlistWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemAddedToWishlistWithProduct:product];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)itemRemovedFromWishlist:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"productID"]) return;

        if (call.arguments[@"customParameters"]) {
            [Insider itemRemovedFromWishlistWithProductID:call.arguments[@"productID"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemRemovedFromWishlistWithProductID:call.arguments[@"productID"]];
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)wishlistCleared:(FlutterMethodCall *)call {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider wishlistClearedWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider wishlistCleared];
        }
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
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"customParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *customParameters = call.arguments[@"customParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:customParameters];
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
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"customParameters"]) return;
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *customParameters = call.arguments[@"customParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:customParameters];
        [Insider clickSmartRecommendationProductWithID:[call.arguments[@"recommendationID"] intValue] product:product];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getMessageCenter:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"startDate"] || !call.arguments[@"endDate"] || !call.arguments[@"limit"]) {
            result([FlutterError errorWithCode:@"MESSAGE_CENTER_LOG" message:@"Missing arguments" details:nil]);
            return;
        }
        [InsiderHybrid getMessageCenterDataWithLimit:[call.arguments[@"limit"] integerValue]
                                           startDate:[call.arguments[@"startDate"] integerValue]
                                             endDate:[call.arguments[@"endDate"] integerValue]
                                             success:^(NSArray *messageCenterData) {
                                                 result(messageCenterData);
                                             }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)getMessageCenterWithIdentifiers:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"startDate"] || !call.arguments[@"endDate"] || !call.arguments[@"limit"] || !call.arguments[@"identifiers"]) {
            result([FlutterError errorWithCode:@"MESSAGE_CENTER_LOG" message:@"Missing arguments" details:nil]);
            return;
        }
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[call.arguments[@"startDate"] doubleValue] / 1000.0];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[call.arguments[@"endDate"] doubleValue] / 1000.0];
        InsiderIdentifiers *identifiers = [self buildInsiderIdentifiersFromMap:call.arguments[@"identifiers"]];
        [Insider getMessageCenterDataWithLimit:[call.arguments[@"limit"] integerValue]
                                     startDate:startDate
                                       endDate:endDate
                                   identifiers:identifiers
                                       success:^(NSArray *messageCenterData) {
                                           result(messageCenterData);
                                       }];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (void)tagEvent:(FlutterMethodCall *)call {
    @try {
        if (!call.arguments[@"name"] || !call.arguments[@"parameters"]) return;
        NSString *eventName = call.arguments[@"name"];
        NSArray *parameters = call.arguments[@"parameters"];
        [[FlutterInsiderUtils parseEventFromEventName:eventName andParameters:parameters] build];
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
        NSString *epochString = [call.arguments[@"value"] description];
        long long epochMillis = epochString.longLongValue;
        NSTimeInterval epochSeconds = ((NSTimeInterval)epochMillis) / 1000.0;
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:epochSeconds];
        [Insider getCurrentUser].setBirthday(dateValue);
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
        NSString *key = call.arguments[@"key"];
        NSString *value = [call.arguments[@"value"] description];
        long long epochMillis = value.longLongValue;
        NSTimeInterval epochSeconds = ((NSTimeInterval)epochMillis) / 1000.0;
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:epochSeconds];
        [Insider getCurrentUser].setCustomAttributeWithDate(key, dateValue);
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

- (InsiderIdentifiers *)buildInsiderIdentifiersFromMap:(NSDictionary *)identifiersMap {
    InsiderIdentifiers *identifiers = [[InsiderIdentifiers alloc] init];
    for (NSString *key in identifiersMap.allKeys) {
        if ([key isEqualToString:ADD_EMAIL]) {
            identifiers.addEmail([identifiersMap objectForKey:key]);
        } else if ([key isEqualToString:ADD_PHONE_NUMBER]) {
            identifiers.addPhoneNumber([identifiersMap objectForKey:key]);
        } else if ([key isEqualToString:ADD_USER_ID]) {
            identifiers.addUserID([identifiersMap objectForKey:key]);
        } else {
            identifiers.addCustomIdentifier(key, [identifiersMap objectForKey:key]);
        }
    }
    return identifiers;
}

- (void)login:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"identifiers"]) return;
        InsiderIdentifiers *insiderIdentifiers = [self buildInsiderIdentifiersFromMap:call.arguments[@"identifiers"]];

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

- (void)logoutResettingInsiderID:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        NSArray<InsiderIdentifiers *> *additionalIdentifiers = @[];
        if (call.arguments[@"additionalIdentifiers"]) {
            NSArray *identifiersList = call.arguments[@"additionalIdentifiers"];
            if (identifiersList && identifiersList.count > 0) {
                NSMutableArray<InsiderIdentifiers *> *identifiersArray = [NSMutableArray array];
                for (NSDictionary *identifiersMap in identifiersList) {
                    [identifiersArray addObject:[self buildInsiderIdentifiersFromMap:identifiersMap]];
                }
                additionalIdentifiers = identifiersArray;
            }
        }

        if (call.arguments[@"insiderIDResult"]) {
            [[Insider getCurrentUser] logoutResettingInsiderID:additionalIdentifiers insiderIDResult:^(NSString *insiderID) {
                result(insiderID);
            }];
            return;
        }

        [[Insider getCurrentUser] logoutResettingInsiderID:additionalIdentifiers];
        result(@"");
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
        if (call.arguments[@"customParameters"]) {
            [Insider signUpConfirmationWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider signUpConfirmation];
        }
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
