import 'constants.dart';
import 'utils.dart';
import 'package:flutter/services.dart';

class FlutterInsiderProduct {
  Map<String, dynamic> requiredFields = <String, dynamic>{};
  Map<String, dynamic> optionalFields = <String, dynamic>{};
  List<Map<String, dynamic>> customParameters = <Map<String, dynamic>>[];

  Map<String, dynamic> get productMustMap => requiredFields;
  Map<String, dynamic> get productOptMap {
    final Map<String, dynamic> combined = Map.from(optionalFields);
    for (final param in customParameters) {
      final key = param['key'] as String?;
      if (key != null) {
        final value = param['value'];
        combined[key] = value;
      }
    }
    return combined;
  }
  late MethodChannel _channel;

  FlutterInsiderProduct(
      MethodChannel methodChannel,
      String productID,
      name,
      List<String> taxonomy,
      String imageURL,
      double unitPrice,
      String currency) {
    this._channel = methodChannel;

    requiredFields['product_id'] = productID;
    requiredFields['name'] = name;
    requiredFields['taxonomy'] = taxonomy;
    requiredFields['image_url'] = imageURL;
    requiredFields['price'] = unitPrice;
    requiredFields['currency'] = currency;
  }

  FlutterInsiderProduct setColor(String color) {
    try {
      this.optionalFields["color"] = color;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setVoucherName(String voucherName) {
    try {
      this.optionalFields["voucher_name"] = voucherName;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setPromotionName(String promotionName) {
    try {
      this.optionalFields["promotion_name"] = promotionName;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setSalePrice(double salePrice) {
    try {
      this.optionalFields["sale_price"] = salePrice;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setShippingCost(double shippingCost) {
    try {
      this.optionalFields["shipping_cost"] = shippingCost;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setVoucherDiscount(double voucherDiscount) {
    try {
      this.optionalFields["voucher_discount"] = voucherDiscount;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setPromotionDiscount(double promotionDiscount) {
    try {
      this.optionalFields["promotion_discount"] = promotionDiscount;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setStock(int stock) {
    try {
      this.optionalFields["stock"] = stock;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setQuantity(int quantity) {
    try {
      this.optionalFields["quantity"] = quantity;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setSize(String size) {
    try {
      this.optionalFields["size"] = size;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithString(String key, String value) {
    try {
      this.customParameters.add({
        'type': 'string',
        'key': key,
        'value': value,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDouble(String key, double value) {
    try {
      this.customParameters.add({
        'type': 'double',
        'key': key,
        'value': value,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithInt(String key, int value) {
    try {
      this.customParameters.add({
        'type': 'integer',
        'key': key,
        'value': value,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithBoolean(String key, bool value) {
    try {
      this.customParameters.add({
        'type': 'boolean',
        'key': key,
        'value': value,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDate(String key, DateTime value) {
    try {
      final int epochMilliseconds = value.millisecondsSinceEpoch;
      this.customParameters.add({
        'type': 'date',
        'key': key,
        'value': epochMilliseconds.toString(),
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  @Deprecated('Use setCustomAttributeWithStringArray instead')
  FlutterInsiderProduct setCustomAttributeWithArray(
      String key, List<String> value) {
    try {
      this.customParameters.add({
        'type': 'strings',
        'key': key,
        'value': value,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setGroupCode(String groupCode) {
    try {
      this.optionalFields["group_code"] = groupCode;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setBrand(String brand) {
    try {
      if (brand.isNotEmpty) {
        this.optionalFields["brand"] = brand;
      }
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setGender(String gender) {
    try {
      if (gender.isNotEmpty) {
        this.optionalFields["gender"] = gender;
      }
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setDescription(String description) {
    try {
      this.optionalFields["description"] = description;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setSku(String sku) {
    try {
      this.optionalFields["sku"] = sku;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setMultipack(String multipack) {
    try {
      this.optionalFields["multipack"] = multipack;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setProductType(String productType) {
    try {
      this.optionalFields["product_type"] = productType;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setGtin(String gtin) {
    try {
      this.optionalFields["gtin"] = gtin;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setTags(List<String> tags) {
    try {
      this.optionalFields["tags"] = tags;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setInStock(bool isInStock) {
    try {
      this.optionalFields["in_stock"] = isInStock;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setProductURL(String productURL) {
    try {
      if (productURL.isNotEmpty) {
        this.optionalFields["product_url"] = productURL;
      }
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithNumericArray(
      String key, List<num> values) {
    try {
      List<num>? validArray = FlutterInsiderUtils.validateNumericArray(values);
      if (validArray == null) return this;

      this.customParameters.add({
        'type': 'numbers',
        'key': key,
        'value': validArray,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithStringArray(
      String key, List<String> values) {
    try {
      List<String>? validArray =
          FlutterInsiderUtils.validateStringArray(values);
      if (validArray == null) {
        validArray = [];
      }
      this.customParameters.add({
        'type': 'strings',
        'key': key,
        'value': validArray,
      });
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }
}
