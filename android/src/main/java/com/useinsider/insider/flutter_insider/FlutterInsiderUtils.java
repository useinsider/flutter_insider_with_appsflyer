package com.useinsider.insider.flutter_insider;

import com.useinsider.insider.AppCardsException;
import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderAppFramesError;
import com.useinsider.insider.InsiderAppFramesErrorCode;
import com.useinsider.insider.InsiderAppFramesViewStatus;
import com.useinsider.insider.InsiderEvent;
import com.useinsider.insider.InsiderProduct;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
                        event.addParameterWithInt(key, toInt(value));
                        break;

                    case "double":
                        event.addParameterWithDouble(key, toDouble(value));
                        break;

                    case "boolean":
                        event.addParameterWithBoolean(key, toBoolean(value));
                        break;

                    case "date":
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

                    default:
                        throw new IllegalArgumentException(
                                "Unknown event parameter type: " + type
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
                                    "Unknown custom parameter type: " + type
                            );
                    }
                } catch (Exception e) {
                    Insider.Instance.putException(e);
                }
            }
        }

        return product;
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
