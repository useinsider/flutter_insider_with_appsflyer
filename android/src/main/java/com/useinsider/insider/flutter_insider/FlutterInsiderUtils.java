package com.useinsider.insider.flutter_insider;

import com.useinsider.insider.AppCardsException;
import com.useinsider.insider.ContentOptimizerDataType;
import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderAppFramesError;
import com.useinsider.insider.InsiderAppFramesErrorCode;
import com.useinsider.insider.InsiderAppFramesViewStatus;
import com.useinsider.insider.InsiderEvent;
import com.useinsider.insider.InsiderGender;
import com.useinsider.insider.InsiderProduct;
import com.useinsider.insider.MessageCenterData;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

public class FlutterInsiderUtils {
    public static InsiderEvent parseEvent(
            String eventName,
            List<Map<String, Object>> parameters
    ) {
        InsiderEvent event = Insider.Instance.tagEvent(eventName);

        if (parameters == null) return event;

        for (Map<String, Object> parameter : parameters) {
            if (parameter == null) continue;

            String type = parameter.get("type") != null
                    ? parameter.get("type").toString()
                    : null;
            String key = parameter.get("key") != null
                    ? parameter.get("key").toString()
                    : null;

            if (type == null || key == null) continue;

            Object value = parameter.get("value");
            if (value == null) continue;

            try {
                switch (type) {
                    case "string":
                        event.addParameterWithString(key, value.toString());
                        break;

                    case "integer":
                        if (!isWholeNumber(value)) break;
                        event.addParameterWithInt(key, toInt(value));
                        break;

                    case "double":
                        event.addParameterWithDouble(key, toDouble(value));
                        break;

                    case "boolean":
                        event.addParameterWithBoolean(key, toBoolean(value));
                        break;

                    case "date":
                        if (!isSendableDate(value)) break;
                        event.addParameterWithDate(
                                key,
                                new Date(toLong(value))
                        );
                        break;

                    case "strings":
                        if (value instanceof List) {
                            List<?> list = (List<?>) value;
                            String[] array = new String[list.size()];
                            for (int i = 0; i < list.size(); i++) {
                                array[i] = list.get(i).toString();
                            }
                            event.addParameterWithStringArray(key, array);
                        }
                        break;

                    case "numbers":
                        if (value instanceof List) {
                            List<?> list = (List<?>) value;
                            Number[] array = new Number[list.size()];
                            for (int i = 0; i < list.size(); i++) {
                                Object item = list.get(i);
                                array[i] = item instanceof Number
                                        ? (Number) item
                                        : Double.parseDouble(item.toString());
                            }
                            event.addParameterWithNumericArray(key, array);
                        }
                        break;

                    case "objects":
                        if (value instanceof List) {
                            event.addParameterWithObjectArray(key, convertCustomParametersList((List<?>) value));
                        }
                        break;

                    default:
                        throw new IllegalArgumentException(
                                "parseEvent skipped an entry tagged '" + type + "': the tag is unknown, or its value is not of the type the tag names."
                        );
                }
            } catch (Exception e) {
                Insider.Instance.putException(e);
            }
        }

        return event;
    }

    public static InsiderProduct parseProduct(
            Map<String, Object> requiredFields,
            Map<String, Object> optionalFields,
            List<Map<String, Object>> customParameters
    ) {

        String productId = requiredFields.get("product_id").toString();
        String name = requiredFields.get("name").toString();
        String imageURL = requiredFields.get("image_url").toString();
        String currency = requiredFields.get("currency").toString();
        double price = toDouble(requiredFields.get("price"));

        List<?> taxonomyList = (List<?>) requiredFields.get("taxonomy");
        String[] taxonomy = new String[taxonomyList.size()];
        for (int i = 0; i < taxonomyList.size(); i++) {
            taxonomy[i] = taxonomyList.get(i).toString();
        }

        InsiderProduct product = Insider.Instance.createNewProduct(
                productId,
                name,
                taxonomy,
                imageURL,
                price,
                currency
        );

        if (optionalFields != null) {
            for (Map.Entry<String, Object> entry : optionalFields.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();
                if (value == null) continue;

                try {
                    switch (key) {
                        case "color":
                            product.setColor(value.toString());
                            break;
                        case "voucher_name":
                            product.setVoucherName(value.toString());
                            break;
                        case "promotion_name":
                            product.setPromotionName(value.toString());
                            break;
                        case "size":
                            product.setSize(value.toString());
                            break;
                        case "sale_price":
                            product.setSalePrice(toDouble(value));
                            break;
                        case "shipping_cost":
                            product.setShippingCost(toDouble(value));
                            break;
                        case "voucher_discount":
                            product.setVoucherDiscount(toDouble(value));
                            break;
                        case "promotion_discount":
                            product.setPromotionDiscount(toDouble(value));
                            break;
                        case "stock":
                            product.setStock(toInt(value));
                            break;
                        case "quantity":
                            product.setQuantity(toInt(value));
                            break;
                        case "group_code":
                            product.setGroupCode(value.toString());
                            break;
                        case "brand":
                            product.setBrand(value.toString());
                            break;
                        case "sku":
                            product.setSku(value.toString());
                            break;
                        case "gender":
                            product.setGender(value.toString());
                            break;
                        case "multipack":
                            product.setMultipack(value.toString());
                            break;
                        case "product_type":
                            product.setProductType(value.toString());
                            break;
                        case "gtin":
                            product.setGtin(value.toString());
                            break;
                        case "description":
                            product.setDescription(value.toString());
                            break;
                        case "tags":
                            if (value instanceof List) {
                                List<?> list = (List<?>) value;
                                String[] tags = new String[list.size()];
                                for (int i = 0; i < list.size(); i++) {
                                    tags[i] = list.get(i).toString();
                                }
                                product.setTags(tags);
                            }
                            break;
                        case "in_stock":
                            product.setInStock(toBoolean(value));
                            break;
                        case "product_url":
                            product.setProductURL(value.toString());
                            break;
                    }
                } catch (Exception e) {
                    Insider.Instance.putException(e);
                }
            }
        }

        if (customParameters != null) {
            for (Map<String, Object> parameter : customParameters) {
                if (parameter == null) continue;

                String type = parameter.get("type") != null
                        ? parameter.get("type").toString()
                        : null;
                String key = parameter.get("key") != null
                        ? parameter.get("key").toString()
                        : null;

                if (type == null || key == null) continue;

                Object value = parameter.get("value");
                if (value == null) continue;

                try {
                    switch (type) {
                        case "string":
                            product.setCustomAttributeWithString(
                                    key, value.toString());
                            break;
                        case "integer":
                            if (!isWholeNumber(value)) break;
                            product.setCustomAttributeWithInt(
                                    key, toInt(value));
                            break;
                        case "double":
                            product.setCustomAttributeWithDouble(
                                    key, toDouble(value));
                            break;
                        case "boolean":
                            product.setCustomAttributeWithBoolean(
                                    key, toBoolean(value));
                            break;
                        case "date":
                            if (!isSendableDate(value)) break;
                            product.setCustomAttributeWithDate(
                                    key, new Date(toLong(value)));
                            break;
                        case "strings":
                            if (value instanceof List) {
                                List<?> list = (List<?>) value;
                                String[] array = new String[list.size()];
                                for (int i = 0; i < list.size(); i++) {
                                    array[i] = list.get(i).toString();
                                }
                                product.setCustomAttributeWithStringArray(
                                        key, array);
                            }
                            break;
                        case "numbers":
                            if (value instanceof List) {
                                List<?> list = (List<?>) value;
                                Number[] array = new Number[list.size()];
                                for (int i = 0; i < list.size(); i++) {
                                    Object item = list.get(i);
                                    array[i] = item instanceof Number
                                            ? (Number) item
                                            : Double.parseDouble(item.toString());
                                }
                                product.setCustomAttributeWithNumericArray(
                                        key, array);
                            }
                            break;
                        default:
                            throw new IllegalArgumentException(
                                    "parseProduct skipped an entry tagged '" + type + "': the tag is unknown, or its value is not of the type the tag names."
                            );
                    }
                } catch (Exception e) {
                    Insider.Instance.putException(e);
                }
            }
        }

        return product;
    }

    // The JavaScript Date range, mirrored from the WebView SDK so a date that no
    // wrapper can represent is dropped instead of becoming a bogus timestamp.
    private static final long MAX_DATE_MILLIS = 8640000000000000L;

    /** Returns true when the value can become a Date both platforms can carry. */
    private static boolean isSendableDate(Object value) {
        if (value instanceof Number) {
            double millis = ((Number) value).doubleValue();

            return !Double.isNaN(millis) && !Double.isInfinite(millis)
                    && Math.abs(millis) <= MAX_DATE_MILLIS;
        }

        try {
            return Math.abs(Long.parseLong(value.toString())) <= MAX_DATE_MILLIS;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    /** Returns true when an "integer" entry really holds a whole number. */
    private static boolean isWholeNumber(Object value) {
        double number;

        if (value instanceof Number) {
            number = ((Number) value).doubleValue();
        } else {
            try {
                number = Double.parseDouble(value.toString());
            } catch (NumberFormatException e) {
                return false;
            }
        }

        return !Double.isNaN(number) && !Double.isInfinite(number)
                && number == Math.rint(number);
    }

    /**
     * Converts the Dart typed parameter list {@code [{type, key, value}]} into a native map.
     * A nested {@code object} entry is converted recursively.
     */
    public static Map<String, Object> convertCustomParameters(List<Map<String, Object>> params) {
        if (params == null) return null;
        Map<String, Object> converted = new HashMap<>();
        for (Map<String, Object> entry : params) {
            // One malformed entry must not take the whole call with it: the
            // event and product converters already guard per entry.
            try {
                convertCustomParameter(converted, entry);
            } catch (Exception e) {
                Insider.Instance.putException(e);
            }
        }

        return converted;
    }

    /** Converts one typed entry into {@code converted}; skips what native would. */
    @SuppressWarnings("unchecked")
    private static void convertCustomParameter(
            Map<String, Object> converted, Map<String, Object> entry) {
        String key = (String) entry.get("key");
        String type = (String) entry.get("type");
        Object value = entry.get("value");
        if (key == null || type == null || value == null) return;
        switch (type) {
            case "string":
                converted.put(key, value.toString());
                break;
            case "integer":
                // The codec sends a Dart int beyond 32 bits as a Long; keep it intact.
                if (!isWholeNumber(value)) break;
                converted.put(key, value instanceof Long ? value : ((Number) value).intValue());
                break;
            case "double":
                converted.put(key, ((Number) value).doubleValue());
                break;
            case "boolean":
                converted.put(key, value);
                break;
            case "date":
                if (!isSendableDate(value)) break;
                converted.put(key, new Date(((Number) value).longValue()));
                break;
            case "string_array":
                if (value instanceof List) {
                    converted.put(key, ((List<String>) value).toArray(new String[0]));
                }
                break;
            case "numeric_array":
                if (value instanceof List) {
                    converted.put(key, ((List<?>) value).toArray(new Number[0]));
                }
                break;
            case "object":
                if (value instanceof List) {
                    converted.put(key, convertCustomParameters((List<Map<String, Object>>) value));
                }
                break;
            default:
                // An unknown type tag is skipped, as the React Native and
                // WebView bridges do; it never reaches native.
                break;
        }
    }

    /**
     * Converts a merge/remove match, or returns null when it is not a list or loses an entry during
     * conversion. A narrowed match selects more objects than requested and both actions are
     * irreversible, so the caller must refuse the call rather than send what is left.
     */
    @SuppressWarnings("unchecked")
    public static Map<String, Object> convertMatch(Object match) {
        if (!(match instanceof List)) return null;
        List<Map<String, Object>> entries = (List<Map<String, Object>>) match;
        Map<String, Object> converted = convertCustomParameters(entries);
        return converted != null && converted.size() == entries.size() ? converted : null;
    }

    /**
     * Converts a list of Dart typed parameter lists into a list of native maps, skipping any item
     * that is not a list.
     */
    @SuppressWarnings("unchecked")
    public static List<Map<String, Object>> convertCustomParametersList(List<?> list) {
        List<Map<String, Object>> objects = new ArrayList<>();
        if (list == null) return objects;
        for (Object item : list) {
            if (!(item instanceof List)) continue;
            objects.add(convertCustomParameters((List<Map<String, Object>>) item));
        }
        return objects;
    }

    private static int toInt(Object value) {
        return value instanceof Number
                ? ((Number) value).intValue()
                : Integer.parseInt(value.toString());
    }

    private static double toDouble(Object value) {
        return value instanceof Number
                ? ((Number) value).doubleValue()
                : Double.parseDouble(value.toString());
    }

    private static long toLong(Object value) {
        return value instanceof Number
                ? ((Number) value).longValue()
                : Long.parseLong(value.toString());
    }

    private static boolean toBoolean(Object value) {
        return value instanceof Boolean
                ? (Boolean) value
                : Boolean.parseBoolean(value.toString());
    }

    public static ArrayList<Object> convertJSONArrayToArrayList(JSONArray jsonArray) {
        try {
            ArrayList<Object> list = new ArrayList<>();
            for (int i = 0; i < jsonArray.length(); i++) {
                list.add(convertJSONValue(jsonArray.get(i)));
            }
            return list;
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return null;
    }

    public static HashMap<String, Object> convertJSONObjectToMap(JSONObject jsonObject) {
        try {
            HashMap<String, Object> map = new HashMap<>();
            Iterator<String> iterator = jsonObject.keys();
            while (iterator.hasNext()) {
                String key = iterator.next();
                map.put(key, convertJSONValue(jsonObject.get(key)));
            }
            return map;
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return null;
    }

    private static Object convertJSONValue(Object value) {
        if (value instanceof JSONObject) return convertJSONObjectToMap((JSONObject) value);
        if (value instanceof JSONArray) return convertJSONArrayToArrayList((JSONArray) value);
        if (value instanceof Boolean || value instanceof Integer || value instanceof Double || value instanceof String) {
            return value;
        }
        return String.valueOf(value);
    }

    public static void setGender(int gender) {
        try {
            Insider.Instance.getCurrentUser().setGender(toInsiderGender(gender));
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
    }

    public static String getContentStringWithName(String variableName, String defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentStringWithName(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    public static int getContentIntWithName(String variableName, int defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentIntWithName(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    public static boolean getContentBoolWithName(String variableName, boolean defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentBoolWithName(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    public static String getContentStringWithoutCache(String variableName, String defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentStringWithoutCache(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    public static int getContentIntWithoutCache(String variableName, int defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentIntWithoutCache(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    public static boolean getContentBoolWithoutCache(String variableName, boolean defaultValue, int dataType) {
        try {
            ContentOptimizerDataType type = toContentOptimizerDataType(dataType);
            if (type == null) return defaultValue;
            return Insider.Instance.getContentBoolWithoutCache(variableName, defaultValue, type);
        } catch (Exception e) {
            Insider.Instance.putException(e);
        }
        return defaultValue;
    }

    // The SDK can answer and throw in either order; a Flutter result must be answered once.
    public static void getMessageCenterData(int limit, long startDateEpochMillis, long endDateEpochMillis, MessageCenterData callback) {
        AtomicBoolean answered = new AtomicBoolean(false);
        MessageCenterData answerOnce = messageCenterData -> {
            if (answered.compareAndSet(false, true)) {
                callback.loadMessageCenterData(messageCenterData);
            }
        };
        try {
            Insider.Instance.getMessageCenterData(limit, new Date(startDateEpochMillis), new Date(endDateEpochMillis), answerOnce);
        } catch (Exception e) {
            answerOnce.loadMessageCenterData(new JSONArray());
            Insider.Instance.putException(e);
        }
    }

    private static InsiderGender toInsiderGender(int gender) {
        switch (gender) {
            case 0:
                return InsiderGender.MALE;
            case 1:
                return InsiderGender.FEMALE;
            default:
                return InsiderGender.OTHER;
        }
    }

    private static ContentOptimizerDataType toContentOptimizerDataType(int dataType) {
        switch (dataType) {
            case 0:
                return ContentOptimizerDataType.CONTENT;
            case 1:
                return ContentOptimizerDataType.ELEMENT;
            default:
                Insider.Instance.putException(new ArrayIndexOutOfBoundsException(dataType));
                return null;
        }
    }

    public static String mapAppCardsExceptionCode(AppCardsException exception) {
        switch (exception.getCode()) {
            case SDK_NOT_INITIALIZED: return "sdkNotInitialized";
            case INVALID_PARAMETER: return "invalidParameter";
            case NETWORK_ERROR: return "networkError";
            case SERVER_ERROR: return "serverError";
            case PARSE_ERROR: return "parseError";
            default: return "unknown";
        }
    }

    public static HashMap<String, Object> appCardsErrorToMap(AppCardsException error) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("code", error != null ? mapAppCardsExceptionCode(error) : "unknown");
        map.put("message", error != null && error.getMessage() != null ? error.getMessage() : "An unexpected error occurred.");
        return map;
    }

    /**
     * Maps an App Frames error code onto the camelCase wire vocabulary shared with the iOS bridge
     * and the Dart {@code InsiderAppFramesErrorCode} enum.
     */
    public static String mapAppFramesErrorCode(InsiderAppFramesErrorCode code) {
        if (code == null) return "unknown";
        switch (code) {
            case RESOLUTION_FAILED: return "resolutionFailed";
            case RESPONSE_MALFORMED: return "responseMalformed";
            case DOWNLOADING_FAILED: return "downloadingFailed";
            case PLACEMENT_UNTRUSTED: return "placementUntrusted";
            case CONTENT_DISPLAY_FAILED: return "contentDisplayFailed";
            case RENDERING_FAILED: return "renderingFailed";
            default: return "unknown";
        }
    }

    /**
     * Maps an App Frames view status onto the lowerCamelCase wire vocabulary shared with the iOS
     * bridge (its {@code InsiderAppFramesViewStatusStringValue}) and the Dart
     * {@code InsiderAppFramesViewStatus} enum.
     */
    public static String mapAppFramesStatus(InsiderAppFramesViewStatus status) {
        // A null or unrecognised status maps to "unknown", never to "detached". `detached` has a
        // specific meaning on the Dart side — off-window with its content intact — and is the one
        // status the widget does not collapse on, so using it as the catch-all would park an
        // unaccountable frame on screen at its last height with nothing reporting it.
        if (status == null) return "unknown";
        switch (status) {
            case DETACHED: return "detached";
            case NO_PLACEMENT: return "noPlacement";
            case DISABLED: return "disabled";
            case RESOLVING: return "resolving";
            case DOWNLOADING: return "downloading";
            case RENDERING: return "rendering";
            case UNAVAILABLE: return "unavailable";
            case READY: return "ready";
            case DISMISSED: return "dismissed";
            case ERROR_RESOLVING: return "errorResolving";
            case ERROR_DOWNLOADING: return "errorDownloading";
            case ERROR_RENDERING: return "errorRendering";
            default: return "unknown";
        }
    }

    public static HashMap<String, Object> appFramesErrorToMap(InsiderAppFramesError error) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("code", error != null ? mapAppFramesErrorCode(error.getCode()) : "unknown");
        map.put("message", error != null && error.getMessage() != null ? error.getMessage() : "An unexpected error occurred.");
        // Only a template-reported dismissal carries a dismiss code; omit the key otherwise so the
        // Dart model can leave it null.
        if (error != null && error.getDismissCode() != InsiderAppFramesError.NO_DISMISS_CODE) {
            map.put("dismissCode", error.getDismissCode());
        }
        // The SDK wraps the originating failure, which is the only thing that says *why* a load
        // failed. Omit the key when there is no deeper cause so the Dart model leaves it null.
        Throwable cause = error != null ? error.getCause() : null;
        if (cause != null) {
            map.put("cause", cause.toString());
        }
        return map;
    }
}
