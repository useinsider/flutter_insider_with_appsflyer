import 'constants.dart';
import 'utils.dart';
import 'package:flutter/services.dart';

class FlutterInsiderProduct {
  Map<String, dynamic> productMustMap = new Map();
  Map<String, dynamic> productOptMap = new Map();
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

    productMustMap[Constants.PRODUCT_ID] = productID;
    productMustMap[Constants.PRODUCT_NAME] = name;
    productMustMap[Constants.TAXONOMY] = taxonomy;
    productMustMap[Constants.IMAGE_URL] = imageURL;
    productMustMap[Constants.UNIT_PRICE] = unitPrice;
    productMustMap[Constants.CURRENCY] = currency;
  }

  FlutterInsiderProduct setColor(String color) {
    try {
      this.productOptMap[Constants.COLOR] = color;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setVoucherName(String voucherName) {
    try {
      this.productOptMap[Constants.VOUCHER_NAME] = voucherName;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setPromotionName(String promotionName) {
    try {
      this.productOptMap[Constants.PROMOTION_NAME] = promotionName;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setSalePrice(double salePrice) {
    try {
      this.productOptMap[Constants.SALE_PRICE] = salePrice;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setShippingCost(double shippingCost) {
    try {
      this.productOptMap[Constants.SHIPPING_COST] = shippingCost;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setVoucherDiscount(double voucherDiscount) {
    try {
      this.productOptMap[Constants.VOUCHER_DISCOUNT] = voucherDiscount;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setPromotionDiscount(double promotionDiscount) {
    try {
      this.productOptMap[Constants.PROMOTION_DISCOUNT] = promotionDiscount;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setStock(int stock) {
    try {
      this.productOptMap[Constants.STOCK] = stock;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setQuantity(int quantity) {
    try {
      this.productOptMap[Constants.QUANTITY] = quantity;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setSize(String size) {
    try {
      this.productOptMap[Constants.SIZE] = size;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithString(String key, String value) {
    try {
      this.productOptMap[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDouble(String key, double value) {
    try {
      this.productOptMap[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithInt(String key, int value) {
    try {
      this.productOptMap[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithBoolean(String key, bool value) {
    try {
      this.productOptMap[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDate(String key, DateTime value) {
    try {
      this.productOptMap[key] = FlutterInsiderUtils.getDateForParsing(value);
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  @Deprecated('Use setCustomAttributeWithStringArray instead')
  FlutterInsiderProduct setCustomAttributeWithArray(
      String key, List<String> value) {
    try {
      this.productOptMap[key] = value;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setGroupCode(String groupCode) {
    try {
      this.productOptMap[Constants.GROUP_CODE] = groupCode;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }

  FlutterInsiderProduct setBrand(String brand) {
    try {
      if (brand.isNotEmpty) {
        this.productOptMap[Constants.BRAND] = brand;
      }
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setGender(String gender) {
    try {
      if (gender.isNotEmpty) {
        this.productOptMap[Constants.PRODUCT_GENDER] = gender;
      }
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setDescription(String description) {
    try {
      this.productOptMap[Constants.DESCRIPTION] = description;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setSku(String sku) {
    try {
      this.productOptMap[Constants.SKU] = sku;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setMultipack(String multipack) {
    try {
      this.productOptMap[Constants.MULTIPACK] = multipack;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setProductType(String productType) {
    try {
      this.productOptMap[Constants.PRODUCT_TYPE] = productType;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setGtin(String gtin) {
    try {
      this.productOptMap[Constants.GTIN] = gtin;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setTags(List<String> tags) {
    try {
      this.productOptMap[Constants.TAGS] = tags;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setInStock(bool isInStock) {
    try {
      this.productOptMap[Constants.IS_IN_STOCK] = isInStock;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  FlutterInsiderProduct setProductURL(String productURL) {
    try {
      if (productURL.isNotEmpty) {
        this.productOptMap[Constants.PRODUCT_URL] = productURL;
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

      bool allIntegers = validArray
          .every((num e) => e is int || (e is double && e == e.toInt()));

      if (allIntegers) {
        List<int> intArray = validArray.map((num e) => e.toInt()).toList();
        this.productOptMap[key] = intArray;
      } else {
        List<double> doubleArray =
            validArray.map((num e) => e.toDouble()).toList();
        this.productOptMap[key] = doubleArray;
      }
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
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
      this.productOptMap[key] = validArray;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    return this;
  }
}
