package com.useinsider.insider.flutter_insider;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.AsyncTask;
import android.net.Uri;
import android.content.Intent;

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
import com.useinsider.insider.AppCardsCampaignsCallback;
import com.useinsider.insider.AppCardsDeleteCallback;
import com.useinsider.insider.AppCardsMarkAsReadCallback;
import com.useinsider.insider.AppCardsException;
import com.useinsider.insider.InsiderAppCard;
import com.useinsider.insider.InsiderAppCardButton;
import com.useinsider.insider.InsiderAppCardCampaignsResponse;
import com.useinsider.insider.InsiderAppCards;
import com.useinsider.insider.RecommendationEngine;
import com.useinsider.insiderhybrid.InsiderHybrid;
import com.useinsider.insiderhybrid.InsiderHybridUtils;
import com.useinsider.insiderhybrid.constants.InsiderHybridMethods;
import com.useinsider.insider.CloseButtonPosition;
import com.useinsider.insider.InsiderIDListener;
import com.useinsider.insider.flutter_insider.FlutterInsiderUtils;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
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

    private Map<String, Object> convertCustomParameters(ArrayList<Map<String, Object>> params) {
        if (params == null) return null;
        Map<String, Object> converted = new HashMap<>();
        for (Map<String, Object> entry : params) {
            String key = (String) entry.get("key");
            String type = (String) entry.get("type");
            Object value = entry.get("value");
            if (key == null || type == null || value == null) continue;
            switch (type) {
                case "string":
                    converted.put(key, value.toString());
                    break;
                case "integer":
                    converted.put(key, ((Number) value).intValue());
                    break;
                case "double":
                    converted.put(key, ((Number) value).doubleValue());
                    break;
                case "boolean":
                    converted.put(key, value);
                    break;
                case "date":
                    converted.put(key, new Date(((Number) value).longValue()));
                    break;
                case "string_array":
                    if (value instanceof ArrayList) {
                        converted.put(key, ((ArrayList<String>) value).toArray(new String[0]));
                    }
                    break;
                case "numeric_array":
                    if (value instanceof ArrayList) {
                        converted.put(key, ((ArrayList<?>) value).toArray(new Number[0]));
                    }
                    break;
                default:
                    converted.put(key, value);
                    break;
            }
        }
        return converted;
    }

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

    private void returnInvalidArgs(Result result) {
        result.error("INVALID_ARGS", "Missing required arguments", null);
    }

    private void returnInvalidArgs(Result result, String code, String message) {
        HashMap<String, Object> details = new HashMap<>();
        details.put("code", "invalidParameter");
        details.put("message", message);
        result.error(code, message, details);
    }


    private void initSDK(MethodCall call, Result result) {
        try {
            String partnerName = call.argument("partnerName").toString();

            Insider.Instance.registerInsiderCallback(new InsiderCallback() {
                @Override
                public void doAction(JSONObject data, InsiderCallbackType type) {
                    try {
                        if (data != null) {
                            data.put("type", type.ordinal());
                            mEventSink.success(data.toString());

                            if (data.has("data")) {
                                handlePushDataForAppsFlyer(data.getJSONObject("data"));
                            }
                        }
                    } catch (Exception e) {
                        mEventSink.error("[INSIDER][registerInsiderCallback]", "Callback exception", data);
                        Insider.Instance.putException(e);
                    }
                }
            });

            Insider.Instance.init((Application) context.getApplicationContext(), partnerName);
            Insider.Instance.setSDKType("flutter");
            Insider.Instance.setHybridSDKVersion(call.argument("sdkVersion").toString());
            Insider.Instance.resumeSessionHybridConfig(activity);

            if (isCoreInited) {
                Insider.Instance.resumeSessionHybridRequestConfig();
            }

            isCoreInited = true;

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
            result.error("SDK_INIT_ERROR", e.getMessage(), null);
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
            if (call.method == null || call.method.length() == 0) {
                result.error("INVALID_METHOD", "Method name is null or empty", null);
                return;
            }
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
                        returnInvalidArgs(result);
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
                    result.success(null);
                    break;
                case "triggerPushProcessWithNotificationData":
                    if (!call.hasArgument("notification")) {
                        returnInvalidArgs(result);
                        return;
                    }

                    Map<String, String> triggerNotificationData = call.argument("notification");
                    Insider.Instance.triggerPushProcessWithNotificationData(context, triggerNotificationData);
                    result.success(null);
                    break;
                case InsiderHybridMethods.START_TRACKING_GEOFENCE:
                    Insider.Instance.startTrackingGeofence();
                    result.success(null);
                    break;
                case "setAllowsBackgroundLocationUpdates":
                    if (!call.hasArgument("allowsBackgroundLocationUpdates")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_GDPR_CONSENT:
                    if (!call.hasArgument("consent")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.setGDPRConsent((boolean) call.argument("consent"));
                    result.success(null);
                    break;
                case "enableIDFACollection":
                    if (!call.hasArgument("enableIDFACollection")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    // Depracated only Android
                    // Insider.Instance.enableIDFACollection((boolean) call.argument("enableIDFACollection"));
                    result.success(null);
                    break;
                case "enableCarrierCollection":
                    if (!call.hasArgument("enableCarrierCollection")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.enableCarrierCollection((boolean) call.argument("enableCarrierCollection"));
                    result.success(null);
                    break;
                case "enableIpCollection":
                    if (!call.hasArgument("enableIpCollection")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.enableIpCollection((boolean) call.argument("enableIpCollection"));
                    result.success(null);
                    break;
                case "enableLocationCollection":
                    if (!call.hasArgument("enableLocationCollection")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.enableLocationCollection((boolean) call.argument("enableLocationCollection"));
                    result.success(null);
                    break;
                case "setInternalBrowserCloseButtonPosition":
                    if (!call.hasArgument("position")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    String positionStr = call.argument("position");
                    if (positionStr == null) {
                        returnInvalidArgs(result);
                        return;
                    }
                    CloseButtonPosition closeButtonPosition;
                    switch (positionStr) {
                        case "LEFT":
                            closeButtonPosition = CloseButtonPosition.LEFT;
                            break;
                        case "NONE":
                            closeButtonPosition = CloseButtonPosition.NONE;
                            break;
                        default:
                            closeButtonPosition = CloseButtonPosition.RIGHT;
                            break;
                    }
                    Insider.Instance.setInternalBrowserCloseButtonPosition(closeButtonPosition);
                    result.success(null);
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
                            || !call.hasArgument("requiredFields")
                            || !call.hasArgument("optionalFields") || !call.hasArgument("customParameters")) {
                        result.error(Constants.RECOMMENDATION_LOG, "Missing arguments", null);
                        return;
                    }
                    Map<String, Object> recRequiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> recOptionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> recCustomParameters = (List<Map<String, Object>>) call.argument("customParameters");
                    InsiderProduct recProduct = FlutterInsiderUtils.parseProduct(recRequiredFields, recOptionalFields, recCustomParameters);
                    Insider.Instance.getSmartRecommendationWithProduct(recProduct,
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
                            !call.hasArgument("requiredFields") ||
                            !call.hasArgument("optionalFields") || !call.hasArgument("customParameters")
                    ) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Map<String, Object> clickRecRequiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> clickRecOptionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> clickRecCustomParameters = (List<Map<String, Object>>) call.argument("customParameters");
                    InsiderProduct clickRecProduct = FlutterInsiderUtils.parseProduct(clickRecRequiredFields, clickRecOptionalFields, clickRecCustomParameters);
                    Insider.Instance.clickSmartRecommendationProduct((int) call.argument(Constants.RECOMMENDATION_ID), clickRecProduct);
                    result.success(null);
                    break;
                case InsiderHybridMethods.GET_MESSAGE_CENTER_DATA:
                    if (!call.hasArgument(Constants.START_DATE) || !call.hasArgument(Constants.END_DATE)
                            || !call.hasArgument(Constants.LIMIT)) {
                        result.error(Constants.MESSAGE_CENTER_LOG, "Missing arguments", null);
                        return;
                    }
                    InsiderHybrid.getMessageCenterData((int) call.argument(Constants.LIMIT),
                            (long) call.argument(Constants.START_DATE),
                            (long) call.argument(Constants.END_DATE), getMessageCenterCallback(result));
                    break;
                case "getAppCardsCampaigns":
                    Insider.Instance.appCards().getCampaigns(new AppCardsCampaignsCallback() {
                        @Override
                        public void onComplete(InsiderAppCardCampaignsResponse responseObject, AppCardsException error) {
                            MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                            if (error != null || responseObject == null) {
                                HashMap<String, Object> errorDetails = FlutterInsiderUtils.appCardsErrorToMap(error);
                                resultWrapper.error(Constants.APP_CARDS_LOG, (String) errorDetails.get("message"), errorDetails);
                            } else {
                                try {
                                    JSONObject jsonObject = responseObject.toJSONObject();
                                    HashMap<String, Object> map = InsiderHybridUtils.convertJSONObjectToMap(jsonObject);
                                    resultWrapper.success(map);
                                } catch (Exception e) {
                                    resultWrapper.error(Constants.APP_CARDS_LOG, "App Cards campaigns exception.", null);
                                    Insider.Instance.putException(e);
                                }
                            }
                        }
                    });
                    break;
                case "viewAppCard":
                    try {
                        if (!call.hasArgument("appCard")) {
                            returnInvalidArgs(result);
                            return;
                        }

                        new InsiderAppCard(
                            new JSONObject(
                                (Map<String, Object>) call.argument("appCard")
                            )
                        ).view();
                        result.success(null);
                    } catch (Exception e) {
                        Insider.Instance.putException(e);
                        result.error(Constants.APP_CARDS_LOG, "viewAppCard exception.", null);
                    }
                    break;
                case "clickAppCard":
                    try {
                        if (!call.hasArgument("appCard")) {
                            returnInvalidArgs(result);
                            return;
                        }

                        new InsiderAppCard(
                            new JSONObject(
                                (Map<String, Object>) call.argument("appCard")
                            )
                        ).click();
                        result.success(null);
                    } catch (Exception e) {
                        Insider.Instance.putException(e);
                        result.error(Constants.APP_CARDS_LOG, "clickAppCard exception.", null);
                    }
                    break;
                case "clickAppCardButton":
                    try {
                        if (!call.hasArgument("appCardId") || !call.hasArgument("data")) {
                            returnInvalidArgs(result);
                            return;
                        }

                        String appCardId = call.argument("appCardId");
                        Map<String, Object> dataMap = call.argument("data");

                        if (appCardId == null || dataMap == null) {
                            returnInvalidArgs(result);
                            return;
                        }

                        JSONObject jsonObject = new JSONObject(new HashMap<>(dataMap));
                        InsiderAppCardButton button =
                                new InsiderAppCardButton(appCardId, jsonObject);
                        button.click();
                        result.success(null);
                    } catch (Exception e) {
                        Insider.Instance.putException(e);
                        result.error(Constants.APP_CARDS_LOG, "clickAppCardButton exception.", null);
                    }
                    break;
                case "appCardsMarkAsRead":
                    if (!call.hasArgument("appCardIds")) {
                        returnInvalidArgs(result, Constants.APP_CARDS_LOG, "Missing appCardIds argument");
                        return;
                    }
                    ArrayList<String> readAppCardIdsList = call.argument("appCardIds");
                    String[] readAppCardIdsArray = readAppCardIdsList.toArray(new String[readAppCardIdsList.size()]);
                    Insider.Instance.appCards().markAsRead(readAppCardIdsArray, error -> {
                        MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                        if (error != null) {
                            HashMap<String, Object> errorDetails = FlutterInsiderUtils.appCardsErrorToMap(error);
                            resultWrapper.error(Constants.APP_CARDS_LOG, (String) errorDetails.get("message"), errorDetails);
                        } else {
                            resultWrapper.success("");
                        }
                    });
                    break;
                case "appCardsMarkAsUnread":
                    if (!call.hasArgument("appCardIds")) {
                        returnInvalidArgs(result, Constants.APP_CARDS_LOG, "Missing appCardIds argument");
                        return;
                    }
                    ArrayList<String> unreadAppCardIdsList = call.argument("appCardIds");
                    String[] unreadAppCardIdsArray = unreadAppCardIdsList.toArray(new String[unreadAppCardIdsList.size()]);
                    Insider.Instance.appCards().markAsUnread(unreadAppCardIdsArray, error -> {
                        MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                        if (error != null) {
                            HashMap<String, Object> errorDetails = FlutterInsiderUtils.appCardsErrorToMap(error);
                            resultWrapper.error(Constants.APP_CARDS_LOG, (String) errorDetails.get("message"), errorDetails);
                        } else {
                            resultWrapper.success("");
                        }
                    });
                    break;
                case "appCardsDelete":
                    if (!call.hasArgument("appCardIds")) {
                        returnInvalidArgs(result, Constants.APP_CARDS_LOG, "Missing appCardIds argument");
                        return;
                    }
                    ArrayList<String> deleteAppCardIdsList = call.argument("appCardIds");
                    String[] deleteAppCardIdsArray = deleteAppCardIdsList.toArray(new String[deleteAppCardIdsList.size()]);
                    Insider.Instance.appCards().delete(deleteAppCardIdsArray, error -> {
                        MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
                        if (error != null) {
                            HashMap<String, Object> errorDetails = FlutterInsiderUtils.appCardsErrorToMap(error);
                            resultWrapper.error(Constants.APP_CARDS_LOG, (String) errorDetails.get("message"), errorDetails);
                        } else {
                            resultWrapper.success("");
                        }
                    });
                    break;
                case "getMessageCenterDataWithIdentifiers":
                    if (!call.hasArgument(Constants.START_DATE) || !call.hasArgument(Constants.END_DATE)
                            || !call.hasArgument(Constants.LIMIT) || !call.hasArgument("identifiers")) {
                        result.error(Constants.MESSAGE_CENTER_LOG, "Missing arguments", null);
                        return;
                    }
                    Insider.Instance.getMessageCenterData(
                            (int) call.argument(Constants.LIMIT),
                            new Date((long) call.argument(Constants.START_DATE)),
                            new Date((long) call.argument(Constants.END_DATE)),
                            buildInsiderIdentifiers(call.argument("identifiers")),
                            getMessageCenterCallback(result));
                    break;
                case InsiderHybridMethods.REMOVE_INAPP:
                    Insider.Instance.removeInapp(activity);
                    result.success(null);
                    break;
                case InsiderHybridMethods.PUT_EXCEPTION:
                    if (!call.hasArgument(Constants.EXCEPTION)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    String exception = call.argument(Constants.EXCEPTION);
                    Insider.Instance.putException(new Exception(exception));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ENDPOINT:
                    if (!call.hasArgument(Constants.ENDPOINT)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    String endpoint = call.argument(Constants.ENDPOINT);
                    Insider.Instance.setCustomEndpoint(endpoint);
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_GENDER:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    InsiderHybrid.setGender((int) call.argument(Constants.VALUE));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_BIRTHDAY:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    long birthdayEpoch = Long.parseLong(call.argument(Constants.VALUE).toString());
                    Date birthdayDate = new Date(birthdayEpoch);
                    Insider.Instance.getCurrentUser().setBirthday(birthdayDate);
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_NAME:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setName(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_SURNAME:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setSurname(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_AGE:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setAge(Integer.parseInt(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case "setPhoneNumber":
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setPhoneNumber(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_SMS_OPTIN:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setSMSOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case "setEmail":
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setEmail(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_EMAIL_OPTIN:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setEmailOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_PUSH_OPTIN:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setPushOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_LOCATION_OPTIN:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setLocationOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_LANGUAGE:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setLanguage(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_LOCALE:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setLocale(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_FACEBOOK_ID:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setFacebookID(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_TWITTER_ID:
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setTwitterID(call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_STRING:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setCustomAttributeWithString(
                            call.argument(Constants.KEY).toString(), call.argument(Constants.VALUE).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_DOUBLE:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setCustomAttributeWithDouble(
                            call.argument(Constants.KEY).toString(),
                            Double.parseDouble(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_INT:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setCustomAttributeWithInt(call.argument(Constants.KEY).toString(),
                            Integer.parseInt(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_BOOLEAN:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().setCustomAttributeWithBoolean(
                            call.argument(Constants.KEY).toString(),
                            Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_DATE:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    // Flutter: epoch milliseconds as String
                    String customKey = call.argument(Constants.KEY).toString();
                    long valueEpoch = Long.parseLong(call.argument(Constants.VALUE).toString());
                    Date valueDate = new Date(valueEpoch);
                    Insider.Instance.getCurrentUser().setCustomAttributeWithDate(customKey, valueDate);
                    result.success(null);
                    break;
                case InsiderHybridMethods.SET_CUSTOM_ATTRIBUTE_WITH_ARRAY:
                    if (!call.hasArgument(Constants.KEY) || !call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    ArrayList<?> arrayList = call.argument(Constants.VALUE);
                    Insider.Instance.getCurrentUser().setCustomAttributeWithArray(
                            call.argument(Constants.KEY).toString(), arrayList.toArray(new String[arrayList.size()]));
                    result.success(null);
                    break;
                case InsiderHybridMethods.UNSET_CUSTOM_ATTRIBUTE:
                    if (!call.hasArgument(Constants.KEY)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser().unsetCustomAttribute(call.argument(Constants.KEY).toString());
                    result.success(null);
                    break;
                case InsiderHybridMethods.LOGIN:
                    if (!call.hasArgument("identifiers")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    InsiderIdentifiers insiderIdentifiers = buildInsiderIdentifiers(call.argument("identifiers"));

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
                case "logoutResettingInsiderID":
                    InsiderIdentifiers[] logoutIdentifiersArray = null;
                    if (call.hasArgument("additionalIdentifiers")) {
                        ArrayList<Map<String, Object>> logoutIdentifiersList = call.argument("additionalIdentifiers");
                        if (logoutIdentifiersList != null && !logoutIdentifiersList.isEmpty()) {
                            logoutIdentifiersArray = new InsiderIdentifiers[logoutIdentifiersList.size()];
                            for (int i = 0; i < logoutIdentifiersList.size(); i++) {
                                logoutIdentifiersArray[i] = buildInsiderIdentifiers(logoutIdentifiersList.get(i));
                            }
                        }
                    }

                    if (call.hasArgument("insiderIDResult")) {
                        Insider.Instance.getCurrentUser().logoutResettingInsiderID(logoutIdentifiersArray, new InsiderUser.InsiderIDResult() {
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

                    Insider.Instance.getCurrentUser().logoutResettingInsiderID(logoutIdentifiersArray);
                    result.success("");
                    break;
                case InsiderHybridMethods.ITEM_PURCHASED:
                    if (!call.hasArgument("uniqueSaleID") || !call.hasArgument("requiredFields")
                            || !call.hasArgument("optionalFields") || !call.hasArgument("productCustomParameters")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Map<String, Object> requiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> optionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> productCustomParameters = (List<Map<String, Object>>) call.argument("productCustomParameters");
                    InsiderProduct product = FlutterInsiderUtils.parseProduct(requiredFields, optionalFields, productCustomParameters);
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.itemPurchased(call.argument("uniqueSaleID").toString(), product, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.itemPurchased(call.argument("uniqueSaleID").toString(), product);
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.ITEM_ADDED_TO_CART:
                    if (!call.hasArgument("requiredFields")
                            || !call.hasArgument("optionalFields") || !call.hasArgument("productCustomParameters")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Map<String, Object> cartRequiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> cartOptionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> cartCustomParameters = (List<Map<String, Object>>) call.argument("productCustomParameters");
                    InsiderProduct cartProduct = FlutterInsiderUtils.parseProduct(cartRequiredFields, cartOptionalFields, cartCustomParameters);
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.itemAddedToCart(cartProduct, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.itemAddedToCart(cartProduct);
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.ITEM_REMOVED_FROM_CART:
                    if (!call.hasArgument("productID")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    if (call.hasArgument("saleID")) {
                        String removeSaleID = (String) call.argument("saleID");
                        if (call.hasArgument("customParameters")) {
                            Insider.Instance.itemRemovedFromCart(call.argument("productID").toString(), removeSaleID, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                        } else {
                            Insider.Instance.itemRemovedFromCart(call.argument("productID").toString(), removeSaleID);
                        }
                    } else if (call.hasArgument("customParameters")) {
                        Insider.Instance.itemRemovedFromCart(call.argument("productID").toString(), convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.itemRemovedFromCart(call.argument("productID").toString());
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.CART_CLEARED:
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.cartCleared(convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.cartCleared();
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.TAG_EVENT:
                    if (!call.hasArgument("name") || !call.hasArgument("parameters")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    String eventName = call.argument("name").toString();
                    List<Map<String, Object>> parameters = (List<Map<String, Object>>) call.argument("parameters");
                    FlutterInsiderUtils.parseEvent(eventName, parameters).build();
                    result.success(null);
                    break;
                case InsiderHybridMethods.VISIT_HOME_PAGE:
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.visitHomePage(convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.visitHomePage();
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.VISIT_LISTING_PAGE:
                    if (!call.hasArgument("taxonomy")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    String[] taxonomy = ((ArrayList<String>) call.argument("taxonomy")).toArray(new String[0]);
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.visitListingPage(taxonomy, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.visitListingPage(taxonomy);
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.VISIT_PRODUCT_DETAIL_PAGE:
                    if (!call.hasArgument("requiredFields")
                            || !call.hasArgument("optionalFields") || !call.hasArgument("productCustomParameters")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Map<String, Object> detailRequiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> detailOptionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> detailCustomParameters = (List<Map<String, Object>>) call.argument("productCustomParameters");
                    InsiderProduct detailProduct = FlutterInsiderUtils.parseProduct(detailRequiredFields, detailOptionalFields, detailCustomParameters);
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.visitProductDetailPage(detailProduct, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.visitProductDetailPage(detailProduct);
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.VISIT_CART_PAGE:
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCTS)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    ArrayList<Map<String, Object>> cartProductsList = (ArrayList<Map<String, Object>>) call.argument(InsiderHybridMethods.PRODUCTS);
                    InsiderProduct[] cartProducts = new InsiderProduct[cartProductsList.size()];
                    for (int i = 0; i < cartProductsList.size(); i++) {
                        Map<String, Object> productMap = cartProductsList.get(i);
                        Map<String, Object> cartReqFields = (Map<String, Object>) productMap.get("requiredFields");
                        Map<String, Object> cartOptFields = (Map<String, Object>) productMap.get("optionalFields");
                        List<Map<String, Object>> cartCustomParams = (List<Map<String, Object>>) productMap.get("productCustomParameters");
                        cartProducts[i] = FlutterInsiderUtils.parseProduct(cartReqFields, cartOptFields, cartCustomParams);
                    }
                    if (call.hasArgument("saleID")) {
                        String cartSaleID = (String) call.argument("saleID");
                        if (call.hasArgument("customParameters")) {
                            Insider.Instance.visitCartPage(cartProducts, cartSaleID, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                        } else {
                            Insider.Instance.visitCartPage(cartProducts, cartSaleID);
                        }
                    } else if (call.hasArgument("customParameters")) {
                        Insider.Instance.visitCartPage(cartProducts, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.visitCartPage(cartProducts);
                    }
                    result.success(null);
                    break;
                case InsiderHybridMethods.REGISTER_WITH_QUIET_PERMISSION:
                case "setForegroundPushCallback":
                case "setActiveForegroundPushView":
                    result.success(null);
                    break;
                case "setWhatsappOptin":
                    if (!call.hasArgument(Constants.VALUE)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.getCurrentUser()
                            .setWhatsappOptin(Boolean.parseBoolean(call.argument(Constants.VALUE).toString()));
                    result.success(null);
                    break;
                case "signUpConfirmation":
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.signUpConfirmation(convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.signUpConfirmation();
                    }
                    result.success(null);
                    break;
                case "reinitWithPartnerName":
                    Insider.Instance.reinitWithPartnerName(call.argument("newPartnerName"));
                    result.success(null);
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
                    result.success(null);
                    break;
                case "setPushToken":
                    if (!call.hasArgument("pushToken")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.setPushToken(call.argument("pushToken").toString());
                    result.success(null);
                    break;
                case "disableInAppMessages":
                    Insider.Instance.disableInAppMessages();
                    result.success(null);
                    break;
                case "enableInAppMessages":
                    Insider.Instance.enableInAppMessages();
                    result.success(null);
                    break;
                case "visitWishlistPage":
                    if (!call.hasArgument(InsiderHybridMethods.PRODUCTS)) {
                        returnInvalidArgs(result);
                        return;
                    }
                    ArrayList<Map<String, Object>> wishlistProductsList = (ArrayList<Map<String, Object>>) call.argument(InsiderHybridMethods.PRODUCTS);
                    InsiderProduct[] wishlistProducts = new InsiderProduct[wishlistProductsList.size()];
                    for (int i = 0; i < wishlistProductsList.size(); i++) {
                        Map<String, Object> productMap = wishlistProductsList.get(i);
                        Map<String, Object> reqFields = (Map<String, Object>) productMap.get("requiredFields");
                        Map<String, Object> optFields = (Map<String, Object>) productMap.get("optionalFields");
                        List<Map<String, Object>> customParams = (List<Map<String, Object>>) productMap.get("productCustomParameters");
                        wishlistProducts[i] = FlutterInsiderUtils.parseProduct(reqFields, optFields, customParams);
                    }
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.visitWishlistPage(wishlistProducts, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.visitWishlistPage(wishlistProducts);
                    }
                    result.success(null);
                    break;
                case "itemAddedToWishlist":
                    if (!call.hasArgument("requiredFields")
                            || !call.hasArgument("optionalFields") || !call.hasArgument("productCustomParameters")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Map<String, Object> wishlistRequiredFields = (Map<String, Object>) call.argument("requiredFields");
                    Map<String, Object> wishlistOptionalFields = (Map<String, Object>) call.argument("optionalFields");
                    List<Map<String, Object>> wishlistCustomParameters = (List<Map<String, Object>>) call.argument("productCustomParameters");
                    InsiderProduct wishlistProduct = FlutterInsiderUtils.parseProduct(wishlistRequiredFields, wishlistOptionalFields, wishlistCustomParameters);
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.itemAddedToWishlist(wishlistProduct, convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.itemAddedToWishlist(wishlistProduct);
                    }
                    result.success(null);
                    break;
                case "itemRemovedFromWishlist":
                    if (!call.hasArgument("productID")) {
                        returnInvalidArgs(result);
                        return;
                    }

                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.itemRemovedFromWishlist(call.argument("productID").toString(), convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.itemRemovedFromWishlist(call.argument("productID").toString());
                    }
                    result.success(null);
                    break;
                case "wishlistCleared":
                    if (call.hasArgument("customParameters")) {
                        Insider.Instance.wishlistCleared(convertCustomParameters((ArrayList<Map<String, Object>>) call.argument("customParameters")));
                    } else {
                        Insider.Instance.wishlistCleared();
                    }
                    result.success(null);
                    break;
                case "handleUniversalLink":
                    if (!call.hasArgument("universalLink")) {
                        returnInvalidArgs(result);
                        return;
                    }

                    Intent intent = new Intent();
                    intent.setData(Uri.parse(call.argument("universalLink")));

                    Insider.Instance.handleUniversalLink(intent);
                    result.success(null);
                    break;
                case "setMobileAppAccess":
                    if (!call.hasArgument("mobileAppAccess")) {
                        returnInvalidArgs(result);
                        return;
                    }
                    Insider.Instance.setMobileAppAccess((boolean) call.argument("mobileAppAccess"));
                    result.success(null);
                    break;
                case "getContentStringWithoutCache":
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(
                            InsiderHybrid.getContentStringWithoutCache(call.argument(Constants.VARIABLE_NAME).toString(),
                                    call.argument(Constants.DEFAULT_VALUE).toString(),
                                    (int) call.argument(Constants.DATA_TYPE)));
                    break;
                case "getContentIntWithoutCache":
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(InsiderHybrid.getContentIntWithoutCache(
                            call.argument(Constants.VARIABLE_NAME).toString(),
                            (int) call.argument(Constants.DEFAULT_VALUE), (int) call.argument(Constants.DATA_TYPE)));
                    break;
                case "getContentBoolWithoutCache":
                    if (!isContentOptimizerCallValid(call)) {
                        result.error(Constants.ERROR, null, null);
                        return;
                    }
                    result.success(
                            InsiderHybrid.getContentBoolWithoutCache(call.argument(Constants.VARIABLE_NAME).toString(),
                                    (boolean) call.argument(Constants.DEFAULT_VALUE),
                                    (int) call.argument(Constants.DATA_TYPE)));
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            Insider.Instance.putException(e);

            try {
                result.error("INSIDER_EXCEPTION", e.getMessage(), null);
            } catch (Exception ignored) {
                // result may have already been consumed
            }
        }
    }

    private InsiderIdentifiers buildInsiderIdentifiers(Map<String, Object> identifiersMap) {
        InsiderIdentifiers identifiers = new InsiderIdentifiers();
        for (String key : identifiersMap.keySet()) {
            switch (key) {
                case InsiderHybridMethods.ADD_EMAIL:
                    identifiers.addEmail(String.valueOf(identifiersMap.get(key)));
                    break;
                case InsiderHybridMethods.ADD_PHONE_NUMBER:
                    identifiers.addPhoneNumber(String.valueOf(identifiersMap.get(key)));
                    break;
                case InsiderHybridMethods.ADD_USER_ID:
                    identifiers.addUserID(String.valueOf(identifiersMap.get(key)));
                    break;
                default:
                    identifiers.addCustomIdentifier(key, String.valueOf(identifiersMap.get(key)));
                    break;
            }
        }
        return identifiers;
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
                        return;
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
                        return;
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
