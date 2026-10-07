#import "FlutterInsiderPlugin.h"
#import "InsiderIDStreamHandler.h"
#import "InsiderEventStreamHandler.h"
#import "FlutterInsiderUtils.h"
#import "AppFrames/InsiderAppFramesViewFactory.h"
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

    // Uses the shared instance rather than a fresh object: the SDK holds the
    // observer weakly, so the handler must be strongly retained elsewhere.
    FlutterEventChannel* insiderEventListenerChannel = [FlutterEventChannel
                                                        eventChannelWithName:@"insider_event_listener"
                                                        binaryMessenger:[registrar messenger]];
    [insiderEventListenerChannel setStreamHandler:[InsiderEventStreamHandler sharedInstance]];

    InsiderAppFramesViewFactory* appFramesViewFactory =
        [[InsiderAppFramesViewFactory alloc] initWithMessenger:[registrar messenger]];
    [registrar registerViewFactory:appFramesViewFactory withId:InsiderAppFramesViewType];
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

- (void)returnInvalidArgs:(FlutterResult)result {
    result([FlutterError errorWithCode:@"INVALID_ARGS" message:@"Missing required arguments" details:nil]);
}

- (void)returnInvalidArgs:(FlutterResult)result withCode:(NSString *)code message:(NSString *)message {
    NSDictionary *details = @{
        @"code": @"invalidParameter",
        @"message": message
    };
    result([FlutterError errorWithCode:code message:message details:details]);
}


- (void)returnException:(NSException *)exception withResult:(FlutterResult)result {
    [Insider sendError:exception desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    result([FlutterError errorWithCode:@"INSIDER_EXCEPTION" message:exception.reason details:nil]);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:INIT_WITH_LAUNCH_OPTIONS]) {
        [self initWithLaunchOptions:call withResult:result];
    } else if ([call.method isEqualToString:INIT_WITH_CUSTOM_ENDPOINT]) {
        [self initWithCustomEndpoint:call withResult:result];
    } else if ([call.method isEqualToString:START_TRACKING_GEOFENCE]){
        [self startTrackingGeofence:call withResult:result];
    } else if ([call.method isEqualToString:SET_ALLOWS_BACKGROUND_LOCATION_UPDATES]) {
        [self setAllowsBackgroundLocationUpdates:call withResult:result];
    } else if ([call.method isEqualToString:REGISTER_WITH_QUIET_PERMISSION]) {
        [self registerWithQuietPermission:call withResult:result];
    } else if ([call.method isEqualToString:HANDLE_NOTIFICATION] || [call.method isEqualToString:@"triggerPushProcessWithNotificationData"]) {
        [self handleNotification:call withResult:result];
    } else if ([call.method isEqualToString:SET_GDPR_CONSENT]) {
        [self setGDPRConsent:call withResult:result];
    } else if ([call.method isEqualToString:@"setMobileAppAccess"]) {
        [self setMobileAppAccess:call withResult:result];
    } else if ([call.method isEqualToString:ENABLE_IDFA_COLLECTION]) {
        [self enableIDFACollection:call withResult:result];
    } else if ([call.method isEqualToString:@"enableCarrierCollection"]) {
        [self enableCarrierCollection:call withResult:result];
    } else if ([call.method isEqualToString:@"enableIpCollection"]) {
        [self enableIpCollection:call withResult:result];
    } else if ([call.method isEqualToString:@"enableLocationCollection"]) {
        [self enableLocationCollection:call withResult:result];
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
    } else if ([call.method isEqualToString:@"markContentOptimizerAsSeen"]) {
        [self markContentOptimizerAsSeen:call withResult:result];
    } else if ([call.method isEqualToString:REMOVE_INAPP]) {
        [self removeInapp:call withResult:result];
    } else if ([call.method isEqualToString:VISIT_HOME_PAGE]) {
        [self visitHomePage:call withResult:result];
    } else if ([call.method isEqualToString:VISIT_LISTING_PAGE]) {
        [self visitListingPage:call withResult:result];
    } else if ([call.method isEqualToString:VISIT_PRODUCT_DETAIL_PAGE]) {
        [self visitProductDetailPage:call withResult:result];
    } else if ([call.method isEqualToString:VISIT_CART_PAGE]) {
        [self visitCartPage:call withResult:result];
    } else if ([call.method isEqualToString:ITEM_PURCHASED]) {
        [self itemPurchased:call withResult:result];
    } else if ([call.method isEqualToString:ITEM_ADDED_TO_CART]) {
        [self itemAddedToCart:call withResult:result];
    } else if ([call.method isEqualToString:ITEM_REMOVED_FROM_CART]) {
        [self itemRemovedFromCart:call withResult:result];
    } else if ([call.method isEqualToString:CART_CLEARED]) {
        [self cartCleared:call withResult:result];
    } else if ([call.method isEqualToString:TAG_EVENT]) {
        [self tagEvent:call withResult:result];
    } else if ([call.method isEqualToString:GET_SMART_RECOMMENDATION]) {
        [self getSmartRecommendation:call withResult:result];
    } else if ([call.method isEqualToString:GET_SMART_RECOMMENDATION_WITH_PRODUCT]) {
        [self getSmartRecommendationWithProduct:call withResult:result];
    } else if ([call.method isEqualToString:@"getSmartRecommendationWithProductIDs"]) {
        [self getSmartRecommendationWithProductIDs:call withResult:result];
    } else if ([call.method isEqualToString:CLICK_SMART_RECOMMENDATION_PRODUCT]) {
        [self clickSmartRecommendationProduct:call withResult:result];
    } else if ([call.method isEqualToString:GET_MESSAGE_CENTER_DATA]) {
        [self getMessageCenter:call withResult:result];
    } else if ([call.method isEqualToString:@"getAppCardsCampaigns"]) {
        [self getAppCardsCampaigns:call withResult:result];
    } else if ([call.method isEqualToString:@"viewAppCard"]) {
        [self viewAppCard:call withResult:result];
    } else if ([call.method isEqualToString:@"clickAppCard"]) {
        [self clickAppCard:call withResult:result];
    } else if ([call.method isEqualToString:@"appCardsMarkAsRead"]) {
        [self appCardsMarkAsRead:call withResult:result];
    } else if ([call.method isEqualToString:@"appCardsMarkAsUnread"]) {
        [self appCardsMarkAsUnread:call withResult:result];
    } else if ([call.method isEqualToString:@"appCardsDelete"]) {
        [self appCardsDelete:call withResult:result];
    } else if ([call.method isEqualToString:@"clickAppCardButton"]) {
        [self clickAppCardButton:call withResult:result];
    } else if ([call.method isEqualToString:@"getMessageCenterDataWithIdentifiers"]) {
        [self getMessageCenterWithIdentifiers:call withResult:result];
    } else if ([call.method isEqualToString:SET_GENDER]) {
        [self setGender:call withResult:result];
    } else if ([call.method isEqualToString:SET_BIRTHDAY]) {
        [self setBirthday:call withResult:result];
    } else if ([call.method isEqualToString:SET_NAME]) {
        [self setName:call withResult:result];
    } else if ([call.method isEqualToString:SET_SURNAME]) {
        [self setSurname:call withResult:result];
    } else if ([call.method isEqualToString:SET_AGE]) {
        [self setAge:call withResult:result];
    } else if ([call.method isEqualToString:SET_SMS_OPTIN]) {
        [self setSMSOptin:call withResult:result];
    } else if ([call.method isEqualToString:@"setEmail"]) {
        [self setEmail:call withResult:result];
    } else if ([call.method isEqualToString:SET_EMAIL_OPTIN]) {
        [self setEmailOptin:call withResult:result];
    } else if ([call.method isEqualToString:@"setPhoneNumber"]) {
        [self setPhoneNumber:call withResult:result];
    } else if ([call.method isEqualToString:SET_PUSH_OPTIN]) {
        [self setPushOptin:call withResult:result];
    } else if ([call.method isEqualToString:SET_LOCATION_OPTIN]) {
        [self setLocationOptin:call withResult:result];
    } else if ([call.method isEqualToString:SET_LANGUAGE]) {
        [self setLanguage:call withResult:result];
    } else if ([call.method isEqualToString:SET_LOCALE]) {
        [self setLocale:call withResult:result];
    } else if ([call.method isEqualToString:SET_FACEBOOK_ID]) {
        [self setFacebookID:call withResult:result];
    } else if ([call.method isEqualToString:SET_TWITTER_ID]) {
        [self setTwitterID:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_STRING]) {
        [self setCustomAttributeWithString:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_INT]) {
        [self setCustomAttributeWithInt:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE]) {
        [self setCustomAttributeWithDouble:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN]) {
        [self setCustomAttributeWithBoolean:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_DATE]) {
        [self setCustomAttributeWithDate:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ATTRIBUTE_WITH_ARRAY]) {
        [self setCustomAttributeWithArray:call withResult:result];
    } else if ([call.method isEqualToString:UNSET_CUSTOM_ATTRIBUTE]) {
        [self unsetCustomAttribute:call withResult:result];
    } else if ([call.method isEqualToString:LOGIN]) {
        [self login:call withResult:result];
    } else if ([call.method isEqualToString:LOGOUT]) {
        [self logout:call withResult:result];
    } else if ([call.method isEqualToString:@"logoutResettingInsiderID"]) {
        [self logoutResettingInsiderID:call withResult:result];
    } else if ([call.method isEqualToString:PUT_EXCEPTION]) {
        [self putException:call withResult:result];
    } else if ([call.method isEqualToString:SET_CUSTOM_ENDPOINT]) {
        result(nil);
    } else if ([call.method isEqualToString:@"setWhatsappOptin"]) {
        [self setWhatsappOptin:call withResult:result];
    } else if ([call.method isEqualToString:@"setPromotionalOptin"]) {
        [self setPromotionalOptin:call withResult:result];
    } else if ([call.method isEqualToString:@"signUpConfirmation"]) {
        [self signUpConfirmation:call withResult:result];
    } else if ([call.method isEqualToString:@"setForegroundPushCallback"]) {
        [self setForegroundPushCallback:call withResult:result];
    } else if ([call.method isEqualToString:@"setActiveForegroundPushView"]) {
        [self setActiveForegroundPushView:call withResult:result];
    } else if ([call.method isEqualToString:@"reinitWithPartnerName"]) {
        [self reinitWithPartnerName:call withResult:result];
    } else if ([call.method isEqualToString:@"getInsiderID"]) {
        [self getInsiderID:call withResult:result];
    } else if ([call.method isEqualToString:@"registerInsiderIDListener"]) {
        [self registerInsiderIDListener:call withResult:result];
    } else if ([call.method isEqualToString:@"registerEventListener"]) {
        [self registerEventListener:call withResult:result];
    } else if ([call.method isEqualToString:@"unregisterEventListener"]) {
        [self unregisterEventListener:call withResult:result];
    } else if ([call.method isEqualToString:@"setPushToken"]) {
        [self setPushToken:call withResult:result];
    } else if ([call.method isEqualToString:@"disableInAppMessages"]) {
        [self disableInAppMessages:call withResult:result];
    } else if ([call.method isEqualToString:@"enableInAppMessages"]) {
        [self enableInAppMessages:call withResult:result];
    } else if ([call.method isEqualToString:@"visitWishlistPage"]) {
        [self visitWishlistPage:call withResult:result];
    } else if ([call.method isEqualToString:@"itemAddedToWishlist"]) {
        [self itemAddedToWishlist:call withResult:result];
    } else if ([call.method isEqualToString:@"itemRemovedFromWishlist"]) {
        [self itemRemovedFromWishlist:call withResult:result];
    } else if ([call.method isEqualToString:@"wishlistCleared"]) {
        [self wishlistCleared:call withResult:result];
    } else if ([call.method isEqualToString:@"handleUniversalLink"]) {
        [self handleUniversalLink:call withResult:result];
    } else if ([call.method isEqualToString:@"setInternalBrowserCloseButtonPosition"]) {
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSString *)resolveAppIdentifier:(FlutterMethodCall *)call {
    id appIdentifier = call.arguments[@"appIdentifier"];
    return [appIdentifier isKindOfClass:[NSString class]] && [appIdentifier length] > 0 ? appIdentifier : nil;
}

- (void)initWithLaunchOptions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try{
        if (!call.arguments[@"partnerName"] || !call.arguments[@"sdkVersion"] || !call.arguments[@"appGroup"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider registerInsiderCallbackWithSelector:@selector(registerCallback:) sender:self];
        [Insider setHybridSDKVersion:call.arguments[@"sdkVersion"]];
        NSString *appIdentifier = [self resolveAppIdentifier:call];
        if (appIdentifier) {
            [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"] appIdentifier:appIdentifier];
        } else {
            [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"]];
        }
        result(@[]);
    } @catch (NSException *exception){
        [self returnException:exception withResult:result];
    }
}

- (void)initWithCustomEndpoint:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try{
        if (!call.arguments[@"partnerName"] || !call.arguments[@"sdkVersion"] || !call.arguments[@"appGroup"] || !call.arguments[@"customEndpoint"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider registerInsiderCallbackWithSelector:@selector(registerCallback:) sender:self];
        [Insider setHybridSDKVersion:call.arguments[@"sdkVersion"]];
        NSString *appIdentifier = [self resolveAppIdentifier:call];
        if (appIdentifier) {
            [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"] customEndpoint:call.arguments[@"customEndpoint"] appIdentifier:appIdentifier];
        } else {
            [Insider initWithLaunchOptions:nil partnerName:call.arguments[@"partnerName"] appGroup:call.arguments[@"appGroup"] customEndpoint:call.arguments[@"customEndpoint"]];
        }
        result(@[]);
    } @catch (NSException *exception){
        [self returnException:exception withResult:result];
    }
}

- (void)hybridIntent:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        //[Insider resumeSession];
        result(@[]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)registerWithQuietPermission:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"permission"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider registerWithQuietPermission:[call.arguments[@"permission"] boolValue]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)handleNotification:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try{
        if (!call.arguments[@"notification"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *notificationPayload = call.arguments[@"notification"];
        [Insider handlePushLogWithUserInfo:notificationPayload];
        [Insider trackInteractiveLogWithUserInfo:notificationPayload];
        result(nil);
    } @catch (NSException *e){
        [self returnException:e withResult:result];
    }
}

- (void)startTrackingGeofence:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [InsiderGeofence startTracking];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setAllowsBackgroundLocationUpdates:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"allowsBackgroundLocationUpdates"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [InsiderGeofence setAllowsBackgroundLocationUpdates:[call.arguments[@"allowsBackgroundLocationUpdates"] boolValue]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)enableIDFACollection:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"enableIDFACollection"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider enableIDFACollection:[call.arguments[@"enableIDFACollection"] boolValue]];
        result(nil);
    } @catch (NSException *e){
        [self returnException:e withResult:result];
    }
}

- (void)enableCarrierCollection:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"enableCarrierCollection"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider enableCarrierCollection:[call.arguments[@"enableCarrierCollection"] boolValue]];
        result(nil);
    } @catch (NSException *e){
        [self returnException:e withResult:result];
    }
}

- (void)enableIpCollection:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"enableIpCollection"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider enableIpCollection:[call.arguments[@"enableIpCollection"] boolValue]];
        result(nil);
    } @catch (NSException *e){
        [self returnException:e withResult:result];
    }
}

- (void)enableLocationCollection:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"enableLocationCollection"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider enableLocationCollection:[call.arguments[@"enableLocationCollection"] boolValue]];
        result(nil);
    } @catch (NSException *e){
        [self returnException:e withResult:result];
    }
}

- (void)setGDPRConsent:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"consent"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider setGDPRConsent:[call.arguments[@"consent"] boolValue]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setMobileAppAccess:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"mobileAppAccess"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider setMobileAppAccess:[call.arguments[@"mobileAppAccess"] boolValue]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentStringWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *coResult = [Insider getContentStringWithName:call.arguments[@"variableName"] defaultString:call.arguments[@"defaultValue"] dataType:[call.arguments[@"dataType"] intValue]];
        result(coResult);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentIntWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        int coResult = [Insider getContentIntWithName:call.arguments[@"variableName"] defaultInt:[call.arguments[@"defaultValue"] intValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithInt:coResult]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentBoolWithName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        bool coResult = [Insider getContentBoolWithName:call.arguments[@"variableName"] defaultBool:[call.arguments[@"defaultValue"] boolValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithBool:coResult]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentStringWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *coResult = [Insider getContentStringWithoutCache:call.arguments[@"variableName"] defaultString:call.arguments[@"defaultValue"] dataType:[call.arguments[@"dataType"] intValue]];
        result(coResult);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentBoolWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        bool coResult = [Insider getContentBoolWithoutCache:call.arguments[@"variableName"] defaultBool:[call.arguments[@"defaultValue"] boolValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithBool:coResult]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getContentIntWithoutCache:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"] || !call.arguments[@"defaultValue"] || !call.arguments[@"dataType"]) {
            [self returnInvalidArgs:result];
            return;
        }
        int coResult = [Insider getContentIntWithoutCache:call.arguments[@"variableName"] defaultInt:[call.arguments[@"defaultValue"] intValue] dataType:[call.arguments[@"dataType"] intValue]];
        result([NSNumber numberWithInt:coResult]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)markContentOptimizerAsSeen:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"variableName"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider markContentOptimizerAsSeen:call.arguments[@"variableName"]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)removeInapp:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [Insider removeInapp];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)visitHomePage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider visitHomepageWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitHomepage];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)visitListingPage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"taxonomy"]) {
            [self returnInvalidArgs:result];
            return;
        }
        if (call.arguments[@"customParameters"]) {
            [Insider visitListingPageWithTaxonomy:call.arguments[@"taxonomy"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitListingPageWithTaxonomy:call.arguments[@"taxonomy"]];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)visitProductDetailPage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider visitProductDetailPageWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider visitProductDetailPageWithProduct:product];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)visitCartPage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"products"]) {
            [self returnInvalidArgs:result];
            return;
        }
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
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)itemPurchased:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"uniqueSaleID"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemPurchasedWithSaleID:call.arguments[@"uniqueSaleID"] product:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemPurchasedWithSaleID:call.arguments[@"uniqueSaleID"] product:product];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)itemAddedToCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemAddedToCartWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemAddedToCartWithProduct:product];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)itemRemovedFromCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"productID"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *saleID = call.arguments[@"saleID"];
        if (saleID.length > 0) {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"] saleID:saleID customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else if (call.arguments[@"customParameters"]) {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemRemovedFromCartWithProductID:call.arguments[@"productID"]];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)cartCleared:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider cartClearedWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider cartCleared];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)visitWishlistPage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"products"]) {
            [self returnInvalidArgs:result];
            return;
        }
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
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)itemAddedToWishlist:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"productCustomParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *productCustomParameters = call.arguments[@"productCustomParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:productCustomParameters];
        if (call.arguments[@"customParameters"]) {
            [Insider itemAddedToWishlistWithProduct:product customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemAddedToWishlistWithProduct:product];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)itemRemovedFromWishlist:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"productID"]) {
            [self returnInvalidArgs:result];
            return;
        }

        if (call.arguments[@"customParameters"]) {
            [Insider itemRemovedFromWishlistWithProductID:call.arguments[@"productID"] customParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider itemRemovedFromWishlistWithProductID:call.arguments[@"productID"]];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)wishlistCleared:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider wishlistClearedWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider wishlistCleared];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getSmartRecommendation:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"currency"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getSmartRecommendationWithID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] currency:call.arguments[@"currency"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getSmartRecommendationWithProduct:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"customParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *customParameters = call.arguments[@"customParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:customParameters];
        [Insider getSmartRecommendationWithProduct:product recommendationID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)getSmartRecommendationWithProductIDs:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"locale"] || !call.arguments[@"productIDs"] || !call.arguments[@"currency"]) {
            [self returnInvalidArgs:result];
            return;
        }

        [Insider getSmartRecommendationWithProductIDs:call.arguments[@"productIDs"] recommendationID:[call.arguments[@"recommendationID"] intValue] locale:call.arguments[@"locale"] currency:call.arguments[@"currency"] smartRecommendation:^(NSDictionary *recommendation) {
            result(recommendation);
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)clickSmartRecommendationProduct:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"recommendationID"] || !call.arguments[@"requiredFields"] || !call.arguments[@"optionalFields"] || !call.arguments[@"customParameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSDictionary *requiredFields = call.arguments[@"requiredFields"];
        NSDictionary *optionalFields = call.arguments[@"optionalFields"];
        NSArray *customParameters = call.arguments[@"customParameters"];
        InsiderProduct *product = [FlutterInsiderUtils parseProductFromRequiredFields:requiredFields andOptionalFields:optionalFields andCustomParameters:customParameters];
        [Insider clickSmartRecommendationProductWithID:[call.arguments[@"recommendationID"] intValue] product:product];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
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
        [self returnException:e withResult:result];
    }
}

- (void)getAppCardsCampaigns:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [[Insider appCards] getCampaigns:^(InsiderAppCardCampaignsResponseModel *response, NSError *error) {
            if (error) {
                NSDictionary *errorDetails = [FlutterInsiderUtils appCardsErrorToDictionary:error];
                result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                           message:errorDetails[@"message"]
                                           details:errorDetails]);
            } else {
                NSDictionary *dict = [response toDictionary];
                result(dict ?: @{});
            }
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)viewAppCard:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCard"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCard argument"];
            return;
        }

        InsiderAppCardModel *model = [[InsiderAppCardModel alloc] initWithDictionary:call.arguments[@"appCard"] error:nil];

        if (model) {
            [model view];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)clickAppCard:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCard"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCard argument"];
            return;
        }

        InsiderAppCardModel *model = [[InsiderAppCardModel alloc] initWithDictionary:call.arguments[@"appCard"] error:nil];

        if (model) {
            [model click];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)appCardsMarkAsRead:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCardIds"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCardIds argument"];
            return;
        }
        NSArray<NSString *> *appCardIds = call.arguments[@"appCardIds"];
        [[Insider appCards] markAsRead:[NSSet setWithArray:appCardIds] completion:^(NSError *error) {
            if (error) {
                NSDictionary *errorDetails = [FlutterInsiderUtils appCardsErrorToDictionary:error];
                result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                           message:errorDetails[@"message"]
                                           details:errorDetails]);
            } else {
                result(@[]);
            }
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)appCardsMarkAsUnread:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCardIds"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCardIds argument"];
            return;
        }
        NSArray<NSString *> *appCardIds = call.arguments[@"appCardIds"];
        [[Insider appCards] markAsUnread:[NSSet setWithArray:appCardIds] completion:^(NSError *error) {
            if (error) {
                NSDictionary *errorDetails = [FlutterInsiderUtils appCardsErrorToDictionary:error];
                result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                           message:errorDetails[@"message"]
                                           details:errorDetails]);
            } else {
                result(@[]);
            }
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)appCardsDelete:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCardIds"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCardIds argument"];
            return;
        }
        NSArray<NSString *> *appCardIds = call.arguments[@"appCardIds"];
        [[Insider appCards] deleteAppCards:[NSSet setWithArray:appCardIds] completion:^(NSError *error) {
            if (error) {
                NSDictionary *errorDetails = [FlutterInsiderUtils appCardsErrorToDictionary:error];
                result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                           message:errorDetails[@"message"]
                                           details:errorDetails]);
            } else {
                result(@[]);
            }
        }];
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)clickAppCardButton:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"appCardId"] || !call.arguments[@"data"]) {
            [self returnInvalidArgs:result withCode:@"APP_CARDS_ERROR" message:@"Missing appCardId or data argument"];
            return;
        }

        NSString *appCardId = call.arguments[@"appCardId"];
        NSDictionary *data = call.arguments[@"data"];

        InsiderAppCardButtonModel *model =
        [[InsiderAppCardButtonModel alloc] initWithDictionary:data error:nil];

        if (model) {
            [model setAppCardId:appCardId];
            [model click];
            result(@[]);
        } else {
            result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                       message:@"Failed to create button model"
                                       details:@{@"code": @"parseError", @"message": @"Failed to create button model"}]);
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
        result([FlutterError errorWithCode:@"APP_CARDS_ERROR"
                                   message:[NSString stringWithFormat:@"Exception: %@", e.reason]
                                   details:nil]);
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
        [self returnException:e withResult:result];
    }
}

- (void)tagEvent:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"name"] || !call.arguments[@"parameters"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *eventName = call.arguments[@"name"];
        NSArray *parameters = call.arguments[@"parameters"];
        [[FlutterInsiderUtils parseEventFromEventName:eventName andParameters:parameters] build];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setGender:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [InsiderHybrid setGender:[call.arguments[@"value"] intValue]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setBirthday:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *epochString = [call.arguments[@"value"] description];
        long long epochMillis = epochString.longLongValue;
        NSTimeInterval epochSeconds = ((NSTimeInterval)epochMillis) / 1000.0;
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:epochSeconds];
        [Insider getCurrentUser].setBirthday(dateValue);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setName(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setSurname:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setSurname(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setAge:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setAge([call.arguments[@"value"] intValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setPhoneNumber:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setPhoneNumber(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setSMSOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setSMSOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setEmail:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setEmail(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setEmailOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setEmailOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setPushOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setPushOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setLocationOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setLocationOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setLanguage:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setLanguage(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setLocale:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setLocale(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setFacebookID:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setFacebookID(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setTwitterID:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setTwitterID(call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithString:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setCustomAttributeWithString(call.arguments[@"key"], call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithInt:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setCustomAttributeWithInt(call.arguments[@"key"], [call.arguments[@"value"] intValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithDouble:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setCustomAttributeWithDouble(call.arguments[@"key"], [call.arguments[@"value"] doubleValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithBoolean:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setCustomAttributeWithBoolean(call.arguments[@"key"], [call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithDate:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSString *key = call.arguments[@"key"];
        NSString *value = [call.arguments[@"value"] description];
        long long epochMillis = value.longLongValue;
        NSTimeInterval epochSeconds = ((NSTimeInterval)epochMillis) / 1000.0;
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:epochSeconds];
        [Insider getCurrentUser].setCustomAttributeWithDate(key, dateValue);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)setCustomAttributeWithArray:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"] || !call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setCustomAttributeWithArray(call.arguments[@"key"], call.arguments[@"value"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

- (void)unsetCustomAttribute:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"key"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].unsetCustomAttribute(call.arguments[@"key"]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
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
        if (!call.arguments[@"identifiers"]) {
            [self returnInvalidArgs:result];
            return;
        }
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
        [self returnException:e withResult:result];
    }
}

- (void)logout:(FlutterMethodCall *)call withResult:(FlutterResult)result{
    @try {
        [[Insider getCurrentUser] logout];
        result(@[]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
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
        [self returnException:e withResult:result];
    }
}

- (void)putException:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"exception"]) {
            [self returnInvalidArgs:result];
            return;
        }
        NSException *e = [NSException exceptionWithName:@"[Dart Error]" reason:call.arguments[@"exception"] userInfo:nil];
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
        result(nil);
    } @catch (NSException *e) {
        result([FlutterError errorWithCode:@"INSIDER_EXCEPTION" message:e.reason details:nil]);
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

-(void)setWhatsappOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setWhatsappOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)setPromotionalOptin:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"value"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider getCurrentUser].setPromotionalOptin([call.arguments[@"value"] boolValue]);
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)signUpConfirmation:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (call.arguments[@"customParameters"]) {
            [Insider signUpConfirmationWithCustomParameters:[self convertCustomParameters:call.arguments[@"customParameters"]]];
        } else {
            [Insider signUpConfirmation];
        }
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)setActiveForegroundPushView:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [Insider setActiveForegroundPushView];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)setForegroundPushCallback:(FlutterMethodCall *) call withResult:(FlutterResult)result {
    @try {
        [Insider setForegroundPushCallback:@selector(foregroundPushCallback:) sender:self];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)reinitWithPartnerName:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"newPartnerName"]) {
            [self returnInvalidArgs:result];
            return;
        }
        [Insider reinitWithPartnerName:call.arguments[@"newPartnerName"]];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)getInsiderID:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        result([Insider getInsiderID]);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)disableInAppMessages:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [Insider disableInAppMessages];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)enableInAppMessages:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        [Insider enableInAppMessages];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)foregroundPushCallback:(UNNotification *) notification {
    @try {
        mEventSink([InsiderHybrid dictToJson:notification.request.content.userInfo]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)registerInsiderIDListener:(FlutterMethodCall *) call withResult:(FlutterResult)result {
    @try {
        [Insider registerInsiderIDListenerWithSelector:@selector(insiderIDChangeListener:) sender:self];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)registerEventListener:(FlutterMethodCall *) call withResult:(FlutterResult)result {
    @try {
        [InsiderEventStreamHandler addObserver];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)unregisterEventListener:(FlutterMethodCall *) call withResult:(FlutterResult)result {
    @try {
        [InsiderEventStreamHandler removeObserver];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)setPushToken:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        // iOS does not support setting push token manually - no-op
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

-(void)insiderIDChangeListener:(NSString *) insiderID {
    @try {
        [InsiderIDStreamHandler triggerEvent:insiderID];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

-(void)handleUniversalLink:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    @try {
        if (!call.arguments[@"universalLink"]) {
            [self returnInvalidArgs:result];
            return;
        }

        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:call.arguments[@"universalLink"]];

        [Insider handleUniversalLink:activity];
        result(nil);
    } @catch (NSException *e) {
        [self returnException:e withResult:result];
    }
}

@end
