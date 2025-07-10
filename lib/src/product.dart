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
      if (color == null) return this;
      
      this.productOptMap[Constants.COLOR] = color;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setVoucherName(String voucherName) {
    try {
      if (voucherName == null) return this;

      this.productOptMap[Constants.VOUCHER_NAME] = voucherName;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setPromotionName(String promotionName) {
    try {
      if (promotionName == null) return this;

      this.productOptMap[Constants.PROMOTION_NAME] = promotionName;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setSalePrice(double salePrice) {
    try {
      if (salePrice == null) return this;

      this.productOptMap[Constants.SALE_PRICE] = salePrice;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setShippingCost(double shippingCost) {
    try {
      if (shippingCost == null) return this;

      this.productOptMap[Constants.SHIPPING_COST] = shippingCost;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setVoucherDiscount(double voucherDiscount) {
    try {
      if (voucherDiscount == null) return this;

      this.productOptMap[Constants.VOUCHER_DISCOUNT] = voucherDiscount;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setPromotionDiscount(double promotionDiscount) {
    try {
      if (promotionDiscount == null) return this;

      this.productOptMap[Constants.PROMOTION_DISCOUNT] = promotionDiscount;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setStock(int stock) {
    try {
      if (stock == null) return this;

      this.productOptMap[Constants.STOCK] = stock;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setQuantity(int quantity) {
    try {
      if (quantity == null) return this;

      this.productOptMap[Constants.QUANTITY] = quantity;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setSize(String size) {
    try {
      if (size == null) return this;

      this.productOptMap[Constants.SIZE] = size;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithString(String key, String value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDouble(String key, double value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithInt(String key, int value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithBoolean(String key, bool value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithDate(String key, DateTime value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = FlutterInsiderUtils.getDateForParsing(value);

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setCustomAttributeWithArray(String key, List<String> value) {
    try {
      if (key == null || value == null) return this;

      this.productOptMap[key] = value;

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }
    
    return this;
  }

  FlutterInsiderProduct setGroupCode(String groupCode) {
    try {
      if (groupCode != null) {
        this.productOptMap[Constants.GROUP_CODE] = groupCode;
      };

      return this;
    } catch (Exception) {
      FlutterInsiderUtils.putException(_channel, Exception);
    }

    return this;
  }

  FlutterInsiderProduct setBrand(String brand) {
    try {
      if (brand != null && brand.isNotEmpty) {
        this.productOptMap[Constants.BRAND] = brand;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setGender(String gender) {
    try {
      if (gender != null && gender.isNotEmpty) {
        this.productOptMap[Constants.PRODUCT_GENDER] = gender;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setDescription(String description) {
    try {
      if (description != null) {
        this.productOptMap[Constants.DESCRIPTION] = description;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setSku(String sku) {
    try {
      if (sku != null) {
        this.productOptMap[Constants.SKU] = sku;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setMultipack(String multipack) {
    try {
      if (multipack != null) {
        this.productOptMap[Constants.MULTIPACK] = multipack;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setProductType(String productType) {
    try {
      if (productType != null) {
        this.productOptMap[Constants.PRODUCT_TYPE] = productType;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setGtin(String gtin) {
    try {
      if (gtin != null) {
        this.productOptMap[Constants.GTIN] = gtin;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setTags(List<String> tags) {
    try {
      if (tags != null) {
        this.productOptMap[Constants.TAGS] = tags;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }

  FlutterInsiderProduct setInStock(bool isInStock) {
    try {
      if (isInStock != null) {
        this.productOptMap[Constants.IS_IN_STOCK] = isInStock;
      }
      return this;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return this;
    }
  }
}
