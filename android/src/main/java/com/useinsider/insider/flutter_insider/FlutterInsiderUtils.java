package com.useinsider.insider.flutter_insider;

import com.useinsider.insider.Insider;
import com.useinsider.insider.InsiderEvent;
import com.useinsider.insider.InsiderProduct;

import java.util.Date;
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
}
