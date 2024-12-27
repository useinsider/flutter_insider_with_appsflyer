package com.useinsider.insider.flutter_insider;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.AsyncTask;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.RemoteMessage;
import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderCallback;
import com.useinsider.insider.InsiderCallbackType;
import com.useinsider.insider.InsiderIdentifiers;
import com.useinsider.insider.InsiderProduct;
import com.useinsider.insider.InsiderUser;
import com.useinsider.insider.MessageCenterData;
import com.useinsider.insider.RecommendationEngine;
import com.useinsider.insiderhybrid.InsiderHybrid;
import com.useinsider.insiderhybrid.InsiderHybridUtils;
import com.useinsider.insiderhybrid.constants.InsiderHybridMethods;
import com.useinsider.insider.InsiderIDListener;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.content.Intent;

import com.appsflyer.AppsFlyerLib;
import android.os.Bundle;

import java.util.Iterator;

public class FlutterInsiderPlugin implements MethodCallHandler, EventChannel.StreamHandler, 
    FlutterPlugin, ActivityAware {

    private Activity activity;
    private Context context;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink mEventSink;
    private InsiderIDListener insiderIDListener;

    private boolean isCoreInited = false;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.context = applicationContext;
        methodChannel = new MethodChannel(messenger, "flutter_insider");
        eventChannel = new EventChannel(messenger, "flutter_insider_event");
        eventChannel.setStreamHandler(this);
        methodChannel.setMethodCallHandler(this);

        EventChannel insiderIDListenerEventChannel =
                new EventChannel(messenger, "insider_id_listener");
        insiderIDListenerEventChannel.setStreamHandler(new InsiderIDStreamHandler());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        eventChannel.setStreamHandler(null);
        eventChannel = null;
    }

    private void initSDK(MethodCall call, Result result) {
        try {
            String partnerName = call.argument("partnerName").toString();
            Insider.Instance.init((Application) context.getApplicationContext(), partnerName);
            Insider.Instance.setSDKType("flutter");
            Insider.Instance.setHybridSDKVersion(call.argument("sdkVersion").toString());
            Insider.Instance.resumeSessionHybridConfig(activity);

            if (isCoreInited) {
                Insider.Instance.resumeSessionHybridRequestConfig();
            }

            isCoreInited = true;

            Insider.Instance.registerInsiderCallback(new InsiderCallback() {
                @Override
                public void doAction(JSONObject data, InsiderCallbackType type) {
                    try {
                        if (data != null) {
                            data.put("type", type.ordinal());
                            mEventSink.success(data.toString());

                            handlePushDataForAppsFlyer(data.getJSONObject("data"));
                        }
                    } catch (Exception e) {
                        mEventSink.error("[INSIDER][registerInsiderCallback]", "Callback exception", data);
                        Insider.Instance.putException(e);
                    }
                }
            });

            FirebaseMessaging.getInstance().getToken()
                    .addOnCompleteListener(new OnCompleteListener<String>() {
                        @Override
                        public void onComplete(@NonNull Task<String> task) {
                            if (!task.isSuccessful()) {
                                return;
                            }

                            Insider.Instance.setHybridPushToken(task.getResult());
                        }
                    });

            Insider.Instance.storePartnerName(partnerName);
            result.success("");
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    public static void handleFCMNotification(Context context, RemoteMessage remoteMessage) {
        try {
            Insider.Instance.handleFCMNotification(context, remoteMessage);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    @SuppressLint("StaticFieldLeak")
    @Override
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {
        try {
            if (call.method == null || call.method.length() == 0)
                return;
            switch (call.method) {
                case InsiderHybridMethods.INIT_WITH_CUSTOM_ENDPOINT:
                    if (!call.hasArgument("partnerName") || !call.hasArgument("sdkVersion")
                            || !call.hasArgument("customEndpoint")) {
                        result.error(Constants.ERROR, "SDK failed to init", null);
                        return;
                    }
                    if (Insider.Instance.isSDKInitialized()) {
                        result.success("");
                        return;
                    }
                    Insider.Instance.setCustomEndpoint(call.argument("customEndpoint").toString());
                    initSDK(call, result);
                    break;
                case InsiderHybridMethods.INIT_WITH_LAUNCH_OPTIONS:
                    if (!call.hasArgument("partnerName") || !call.hasArgument("sdkVersion")) {
                        result.error(Constants.ERROR, "SDK failed to init", null);
                        return;
                    }
                    if (Insider.Instance.isSDKInitialized()) {
                        result.success("");
                        return;
                    }
                    initSDK(call, result);
                    break;
                case InsiderHybridMethods.HANDLE_NOTIFICATION:
                    if (!call.hasArgument("notification")) {
                        return;
                    }

                    Map<String, Object> notification = call.argument("notification");
                    Map<String, String> notificationStringified = new HashMap<>();
                    for (String key : notification.keySet()) {
                        notificationStringified.put(key, String.valueOf(notification.get(key)));
                    }

                    final Map<String, String> finalNotificationStringified = notificationStringified;

                    new AsyncTask<Void, Void, String>() {
                        @Override
                        protected String doInBackground(Void... params) {

                            String provider = Insider.Instance.getCurrentProvider(context);
                            switch (provider) {
                                case "other":
                                case "google":
                                    RemoteMessage fcmRemoteMessage = new RemoteMessage.Builder("insider").setData(finalNotificationStringified).build();
                                    Insider.Instance.handleFCMNotification(context, fcmRemoteMessage);
                                    break;
                                default:
                                    break;
                            }
                            return "";
                        }
                    }.execute();
                    break;
                case InsiderHybridMethods.START_TRACKING_GEOFENCE:
                    Insider.Instance.startTrackingGeofence();
                    break;
                case InsiderHybridMethods.SET_GDPR_CONSENT:
                    if (!call.hasArgument("consent"))
                        return;
                    Insider.Instance.setGDPRConsent((boolean) call.argument("consent"));
                    break;
                case "enableIDFACollection":
                    if (!call.hasArgument("enableIDFACollection"))
                        return;
                    // Depracated only Android
                    // Insider.Instance.enableIDFACollection((boolean) call.argument("enableIDFACollection"));
                    break;
                case "enableCarrierCollection":
                    if (!call.hasArgument("enableCarrierCollection"))
                        return;
                    Insider.Instance.enableCarrierCollection((boolean) call.argument("enableCarrierCollection"));
                    break;
                case "enableIpCollection":
                    if (!call.hasArgument("enableIpCollection"))
                        return;
                    Insider.Instance.enableIpCollection((boolean) call.argument("enableIpCollection"));
                    break;
                case "enableLocationCollection":
                    if (!call.hasArgument("enableLocationCollection"))
                        return;
                    Insider.Instance.enableLocationCollection((boolean) call.argument("enableLocationCollection"));
                    break;
                case InsiderHybridMethods.GET_CONTENT_STRING_WITH_NAME:
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(
                            InsiderHybrid.getContentStringWithName(call.argument(Constants.VARIABLE_NAME).toString(),
                                    call.argument(Constants.DEFAULT_VALUE).toString(),
                                    (int) call.argument(Constants.DATA_TYPE)));
                    break;
                case InsiderHybridMethods.GET_CONTENT_INT_WITH_NAME:
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(InsiderHybrid.getContentIntWithName(
                            call.argument(Constants.VARIABLE_NAME).toString(),
                            (int) call.argument(Constants.DEFAULT_VALUE), (int) call.argument(Constants.DATA_TYPE)));
                    break;
                case InsiderHybridMethods.GET_CONTENT_BOOL_WITH_NAME:
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(
                            InsiderHybrid.getContentBoolWithName(call.argument(Constants.VARIABLE_NAME).toString(),
                                    (boolean) call.argument(Constants.DEFAULT_VALUE),
                                    (int) call.argument(Constants.DATA_TYPE)));
                    break;
                case InsiderHybridMethods.GET_SMART_RECOMMENDATION:
                    if (!call.hasArgument(Constants.RECOMMENDATION_ID) || !call.hasArgument(Constants.LOCALE)
                            || !call.hasArgument(Constants.CURRENCY)) {
                        result.error(Constants.RECOMMENDATION_LOG, "Missing arguments", null);
                        return;
                    }
                    Insider.Instance.getSmartRecommendation((int) call.argument(Constants.RECOMMENDATION_ID),
                            call.argument(Constants.LOCALE).toString(), call.argument(Constants.CURRENCY).toString(),
                            getRecommendationCallback(result));
                    break;
                case InsiderHybridMethods.GET_SMART_RECOMMENDATION_WITH_PRODUCT:
                    if (!call.hasArgument(Constants.RECOMMENDATION_ID) || !call.hasArgument(Constants.LOCALE)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP)) {
                        result.error(Constants.RECOMMENDATION_LOG, "Missing arguments", null);
                        return;
                    }
                    InsiderProduct product = InsiderHybrid.createProduct(
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP));
                    Insider.Instance.getSmartRecommendationWithProduct(product,
                            (int) call.argument(Constants.RECOMMENDATION_ID),
                            call.argument(Constants.LOCALE).toString(), getRecommendationCallback(result));
                    break;
                case "getSmartRecommendationWithProductIDs":
                    if (!call.hasArgument(Constants.RECOMMENDATION_ID) || !call.hasArgument(Constants.LOCALE) || !call.hasArgument("productIDs") || !call.hasArgument(Constants.CURRENCY)) {
                        result.error(Constants.RECOMMENDATION_LOG, "Missing arguments", null);
                        return;
                    }

                    String[] productIDs = ((ArrayList<String>) call.argument("productIDs")).toArray(new String[0]);

                    Insider.Instance.getSmartRecommendationWithProductIDs(productIDs,
                            (int) call.argument(Constants.RECOMMENDATION_ID),
                            call.argument(Constants.LOCALE).toString(),
                            call.argument(Constants.CURRENCY).toString(),
                            getRecommendationCallback(result));
                    break;
                case InsiderHybridMethods.CLICK_SMART_RECOMMENDATION_PRODUCT:
                    if (!call.hasArgument(Constants.RECOMMENDATION_ID) ||
                            !call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP) ||
                            !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP)
                    ) {
                        return;
                    }
                    InsiderProduct recommendationLogProduct = InsiderHybrid.createProduct(
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP));
                    Insider.Instance.clickSmartRecommendationProduct((int) call.argument(Constants.RECOMMENDATION_ID), recommendationLogProduct);
                    break;
                case InsiderHybridMethods.GET_MESSAGE_CENTER_DATA:
                    if (!call.hasArgument(Constants.START_DATE) || !call.hasArgument(Constants.END_DATE)
                            || !call.hasArgument(Constants.LIMIT)) {
                        result.error(Constants.MESSAGE_CENTER_LOG, "Missing arguments", null);
                        return;
                    }
                    InsiderHybrid.getMessageCenterData((int) call.argument(Constants.LIMIT),
                            call.argument(Constants.START_DATE).toString(),
                            call.argument(Constants.END_DATE).toString(), getMessageCenterCallback(result));
                    break;
                case InsiderHybridMethods.REMOVE_INAPP:
                    Insider.Instance.removeInapp(activity);
                    break;
                case InsiderHybridMethods.PUT_EXCEPTION:
                    if (!call.hasArgument(Constants.EXCEPTION))
                        return;
                    String exception = call.argument(Constants.EXCEPTION);
                    Insider.Instance.putException(new Exception(exception));
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ENDPOINT:
                    if (!call.hasArgument(Constants.ENDPOINT))
                        return;
                    String endpoint = call.argument(Constants.ENDPOINT);
                    Insider.Instance.setCustomEndpoint(endpoint);
                    break;
                case InsiderHybridMethods.SET_GENDER:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    InsiderHybrid.setGender((int) call.argument(Constants.VALUE));
                    break;
                case InsiderHybridMethods.SET_BIRTHDAY:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    InsiderHybrid.setBirthday(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_NAME:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setName(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_SURNAME:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setSurname(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_AGE:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setAge(Integer.parseInt(call.argument(Constants.VALUE).toString()));
                    break;
                case "setPhoneNumber":
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setPhoneNumber(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_SMS_OPTIN:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setSMSOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case "setEmail":
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setEmail(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_EMAIL_OPTIN:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setEmailOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_PUSH_OPTIN:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setPushOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_LOCATION_OPTIN:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setLocationOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_LANGUAGE:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setLanguage(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_LOCALE:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setLocale(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_FACEBOOK_ID:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setFacebookID(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_TWITTER_ID:
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setTwitterID(call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_STRING:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setCustomAttributeWithString(
                            call.argument(Constants.KEY).toString(), call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setCustomAttributeWithDouble(
                            call.argument(Constants.KEY).toString(),
                            Double.parseDouble(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_INT:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setCustomAttributeWithInt(call.argument(Constants.KEY).toString(),
                            Integer.parseInt(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser().setCustomAttributeWithBoolean(
                            call.argument(Constants.KEY).toString(),
                            Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_DATE:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    InsiderHybrid.setCustomAttributeWithDate(call.argument(Constants.KEY).toString(),
                            call.argument(Constants.VALUE).toString());
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE))
                        return;
                    ArrayList<?> arrayList = call.argument(Constants.VALUE);
                    Insider.Instance.getCurrentUser().setCustomAttributeWithArray(
                            call.argument(Constants.KEY).toString(), arrayList.toArray(new String[arrayList.size()]));
                    break;
                case InsiderHybridMethods.UNSET_CUSTOM_ATTRIBUTE:
                    if (!call.hasArgument(Constants.KEY))
                        return;
                    Insider.Instance.getCurrentUser().unsetCustomAttribute(call.argument(Constants.KEY).toString());
                    break;
                case InsiderHybridMethods.LOGIN:
                    if (!call.hasArgument("identifiers")) {
                        return;
                    }
                    Map<String, Object> identifiers = call.argument("identifiers");
                    InsiderIdentifiers insiderIdentifiers = new InsiderIdentifiers();
                    for (String key : identifiers.keySet()) {
                        switch (key) {
                            case InsiderHybridMethods.ADD_EMAIL:
                                insiderIdentifiers.addEmail(String.valueOf(identifiers.get(key)));
                                break;
                            case InsiderHybridMethods.ADD_PHONE_NUMBER:
                                insiderIdentifiers.addPhoneNumber(String.valueOf(identifiers.get(key)));
                                break;
                            case InsiderHybridMethods.ADD_USER_ID:
                                insiderIdentifiers.addUserID(String.valueOf(identifiers.get(key)));
                                break;
                            default:
                                insiderIdentifiers.addCustomIdentifier(key, String.valueOf(identifiers.get(key)));
                                break;
                        }
                    }

                    if (call.hasArgument("insiderID")) {
                        Insider.Instance.getCurrentUser().login(insiderIdentifiers, new InsiderUser.InsiderIDResult() {
                            @Override
                            public void insiderIDResult(String insiderID) {
                                MethodResultWrapper resultWrapper = new MethodResultWrapper(result);

                                if (insiderID != null) {
                                    resultWrapper.success(insiderID);

                                    return;
                                }

                                resultWrapper.success("");
                            }
                        });

                        return;
                    }

                    Insider.Instance.getCurrentUser().login(insiderIdentifiers);
                    result.success("");
                    break;
                case InsiderHybridMethods.LOGOUT:
                    Insider.Instance.getCurrentUser().logout();
                    result.success("");
                    break;
                case InsiderHybridMethods.ITEM_PURCHASED:
                    if (!call.hasArgument("uniqueSaleID") || !call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP))
                        return;
                    Insider.Instance.itemPurchased(call.argument("uniqueSaleID").toString(),
                            InsiderHybrid.createProduct(
                                    (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                                    (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP)));
                    break;
                case InsiderHybridMethods.ITEM_ADDED_TO_CART:
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP))
                        return;
                    Insider.Instance.itemAddedToCart(InsiderHybrid.createProduct(
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP)));
                    break;
                case InsiderHybridMethods.ITEM_REMOVED_FROM_CART:
                    if (!call.hasArgument("productID"))
                        return;
                    Insider.Instance.itemRemovedFromCart(call.argument("productID").toString());
                    break;
                case InsiderHybridMethods.CART_CLEARED:
                    Insider.Instance.cartCleared();
                    break;
                case InsiderHybridMethods.TAG_EVENT:
                    if (!call.hasArgument("name") || !call.hasArgument("parameters"))
                        return;
                    InsiderHybrid.tagEvent(call.argument("name").toString(),
                            (Map<String, Object>) call.argument("parameters"));
                    break;
                case InsiderHybridMethods.VISIT_HOME_PAGE:
                    Insider.Instance.visitHomePage();
                    break;
                case InsiderHybridMethods.VISIT_LISTING_PAGE:
                    if (!call.hasArgument("taxonomy"))
                        return;
                    String[] taxonomy = ((ArrayList<String>) call.argument("taxonomy")).toArray(new String[0]);
                    Insider.Instance.visitListingPage(taxonomy);
                    break;
                case InsiderHybridMethods.VISIT_PRODUCT_DETAIL_PAGE:
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP))
                        return;
                    InsiderProduct recommendationProduct = InsiderHybrid.createProduct(
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                            (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP));
                    Insider.Instance.visitProductDetailPage(recommendationProduct);
                    break;
                case InsiderHybridMethods.VISIT_CART_PAGE:
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCTS))
                        return;
                    InsiderHybrid.visitCartPage(
                            (ArrayList<Map<String, Object>>) call.argument(InsiderHybridMethods.PRODUCTS));
                    break;
                case InsiderHybridMethods.REGISTER_WITH_QUIET_PERMISSION:
                case "setForegroundPushCallback":
                case "setActiveForegroundPushView":
                    break;
                case "setWhatsappOptin":
                    if (!call.hasArgument(Constants.VALUE))
                        return;
                    Insider.Instance.getCurrentUser()
                            .setWhatsappOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    break;
                case "signUpConfirmation":
                    Insider.Instance.signUpConfirmation();
                    break;
                case "reinitWithPartnerName":
                    Insider.Instance.reinitWithPartnerName(call.argument("newPartnerName"));
                    break;
                case "getInsiderID":
                    result.success(Insider.Instance.getInsiderID());
                    break;
                case "registerInsiderIDListener":
                    if (insiderIDListener == null) {
                        insiderIDListener = new InsiderIDListener() {
                            @Override
                            public void onUpdated(String insiderID) {
                                InsiderIDStreamHandler.triggerEvent(insiderID);
                            }
                        };

                        Insider.Instance.registerInsiderIDListener(insiderIDListener);
                    }
                    break;
                case "setPushToken":
                    if (!call.hasArgument("pushToken"))
                        return;
                    Insider.Instance.setPushToken(call.argument("pushToken").toString());
                    break;
                case "disableInAppMessages":
                    Insider.Instance.disableInAppMessages();
                    break;
                case "enableInAppMessages":
                    Insider.Instance.enableInAppMessages();
                    break;
                case "visitWishlistPage":
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCTS))
                        return;

                    Insider.Instance.visitWishlistPage(
                            InsiderHybrid.convertArrayToInsiderProductArray(
                                    (ArrayList<Map<String, Object>>) call.argument(InsiderHybridMethods.PRODUCTS)
                            )
                    );
                    break;
                case "itemAddedToWishlist":
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCT_MUST_MAP)
                            || !call.hasArgument(InsiderHybridMethods.PRODUCT_OPT_MAP))
                        return;

                    Insider.Instance.itemAddedToWishlist(
                            InsiderHybrid.createProduct(
                                    (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_MUST_MAP),
                                    (Map<String, Object>) call.argument(InsiderHybridMethods.PRODUCT_OPT_MAP))
                    );
                    break;
                case "itemRemovedFromWishlist":
                    if (!call.hasArgument("productID"))
                        return;

                    Insider.Instance.itemRemovedFromWishlist(call.argument("productID").toString());
                    break;
                case "wishlistCleared":
                    Insider.Instance.wishlistCleared();
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    private void handlePushDataForAppsFlyer(JSONObject pushPayload) {
        try {
            if (pushPayload == null) { return; }

            Bundle bundle = this.createAFBundleObject(pushPayload);

            if (activity != null && bundle != null) {
                Intent intent = activity.getIntent();

                if (intent != null) {
                    intent.putExtras(bundle);

                    activity.setIntent(intent);

                    AppsFlyerLib.getInstance().sendPushNotificationData(activity);
                }
            }
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    private Bundle createAFBundleObject(JSONObject jsonObject) {
        try {
            String campaignName = jsonObject.getString("c");
            String isRetargeting = jsonObject.getString("is_retargeting");
            String pushID = jsonObject.getString("pid");

            if (campaignName != null && isRetargeting != null && pushID != null) {
                Bundle bundle = new Bundle();
                JSONObject afObject = new JSONObject();

                afObject.put("c", campaignName)
                        .put("is_retargeting", Boolean.parseBoolean(isRetargeting.toLowerCase()))
                        .put("pid", pushID);

                bundle.putString("af", afObject.toString());

                return bundle;
            }
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }

        return null;
    }

    private MessageCenterData getMessageCenterCallback(final Result result) {
        return new MessageCenterData() {
            @Override
            public void loadMessageCenterData(JSONArray jsonArray) {
                MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                try {
                    ArrayList<Object> messages = InsiderHybridUtils.convertJSONArrayToArrayList(jsonArray);
                    if (messages == null) {
                        resultWrapper.error(Constants.MESSAGE_CENTER_LOG, "Message Center returned null.", null);
                    }
                    resultWrapper.success(messages);
                } catch (Exception e) {
                    resultWrapper.error(Constants.MESSAGE_CENTER_LOG, "Message Center exception.", null);
                    Insider.Instance.putException(e);
                }
            }
        };
    }

    private RecommendationEngine.SmartRecommendation getRecommendationCallback(final Result result) {
        return new RecommendationEngine.SmartRecommendation() {
            @Override
            public void loadRecommendationData(JSONObject jsonObject) {
                MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                try {
                    HashMap<String, Object> map = InsiderHybridUtils.convertJSONObjectToMap(jsonObject);
                    if (map == null) {
                        resultWrapper.error(Constants.RECOMMENDATION_LOG, "Recommendation returned null.", null);
                    }
                    resultWrapper.success(map);
                } catch (Exception e) {
                    resultWrapper.error(Constants.RECOMMENDATION_LOG, "Recommendation exception.", null);
                    Insider.Instance.putException(e);
                }
            }
        };
    }

    private boolean isContentOptimizerCallValid(MethodCall call) {
        return !(!call.hasArgument(Constants.VARIABLE_NAME) || !call.hasArgument(Constants.DEFAULT_VALUE)
                || !call.hasArgument(Constants.DATA_TYPE));
    }

    @Override
    public void onListen(Object o, final EventChannel.EventSink eventSink) {
        try {
            mEventSink = eventSink;
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    @Override
    public void onCancel(Object o) {
        // We are not listening on cancel.
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
