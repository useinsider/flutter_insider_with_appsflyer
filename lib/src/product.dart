import 'utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Builder describing a product for the Insider catalog and shopping events.
///
/// Construct via [FlutterInsider.createNewProduct] (which supplies all
/// required fields) and chain `set*` calls to attach optional metadata or
/// custom attributes:
///
/// ```dart
/// final product = FlutterInsider.Instance.createNewProduct(
///   'sku-123',
///   'Running Shoes',
///   ['Sport', 'Footwear'],
///   'https://cdn.example.com/sku-123.jpg',
///   59.90,
///   'EUR',
/// )
///   ..setBrand('Acme')
///   ..setSize('42')
///   ..setStock(120);
/// ```
///
/// Pass the resulting instance to APIs such as
/// [FlutterInsider.visitProductDetailPage] or
/// [FlutterInsider.itemAddedToCart].
class FlutterInsiderProduct {
  /// Catalog-required fields (id, name, taxonomy, image URL, price, currency)
  /// populated by the constructor.
  Map<String, dynamic> requiredFields = <String, dynamic>{};

  /// Optional fields attached via builder methods (color, brand, stock, ...).
  Map<String, dynamic> optionalFields = <String, dynamic>{};

  /// Typed custom parameters attached via `setCustomAttributeWith*`.
  List<Map<String, dynamic>> customParameters = <Map<String, dynamic>>[];

  /// Returns the required-fields map. Used internally when serialising the
  /// product for the platform channel.
  Map<String, dynamic> get productMustMap => requiredFields;

  /// Returns optional fields merged with custom parameters.
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

  /// Creates a product. Prefer [FlutterInsider.createNewProduct] over calling
  /// this constructor directly.
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
    if (!unitPrice.isFinite) {
      debugPrint('[Insider] createNewProduct: the price of $productID is NaN '
          'or infinite, so this product will be left out of every call that carries it.');
    }
  }

  /// Whether the required price is finite. A product without one is left out
  /// of every call that carries it, because a NaN or infinite price breaks
  /// the native payload.
  bool get hasSendablePrice =>
      requiredFields['price'] is double &&
      (requiredFields['price'] as double).isFinite;

  /// Sets the product color.
  FlutterInsiderProduct setColor(String color) {
    try {
      this.optionalFields["color"] = color;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the voucher name applied to the product.
  FlutterInsiderProduct setVoucherName(String voucherName) {
    try {
      this.optionalFields["voucher_name"] = voucherName;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the promotion name applied to the product.
  FlutterInsiderProduct setPromotionName(String promotionName) {
    try {
      this.optionalFields["promotion_name"] = promotionName;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the discounted sale price (use the original price as the
  /// constructor's `unitPrice`).
  FlutterInsiderProduct setSalePrice(double salePrice) {
    try {
      if (!FlutterInsiderUtils.isSendableDouble(
          'setSalePrice', 'sale_price', salePrice)) {
        return this;
      }
      this.optionalFields["sale_price"] = salePrice;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the shipping cost for the product.
  FlutterInsiderProduct setShippingCost(double shippingCost) {
    try {
      if (!FlutterInsiderUtils.isSendableDouble(
          'setShippingCost', 'shipping_cost', shippingCost)) {
        return this;
      }
      this.optionalFields["shipping_cost"] = shippingCost;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the discount amount provided by the voucher.
  FlutterInsiderProduct setVoucherDiscount(double voucherDiscount) {
    try {
      if (!FlutterInsiderUtils.isSendableDouble(
          'setVoucherDiscount', 'voucher_discount', voucherDiscount)) {
        return this;
      }
      this.optionalFields["voucher_discount"] = voucherDiscount;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the discount amount provided by the promotion.
  FlutterInsiderProduct setPromotionDiscount(double promotionDiscount) {
    try {
      if (!FlutterInsiderUtils.isSendableDouble(
          'setPromotionDiscount', 'promotion_discount', promotionDiscount)) {
        return this;
      }
      this.optionalFields["promotion_discount"] = promotionDiscount;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the available stock count.
  FlutterInsiderProduct setStock(int stock) {
    try {
      // Both bridges narrow to a 32-bit `int` (`toInt`, `intValue`), so a
      // wider value is stored as a different wrong number, not refused.
      if (!FlutterInsiderUtils.isSendableInteger('setStock', 'stock', stock)) {
        return this;
      }
      this.optionalFields["stock"] = stock;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the quantity for cart / purchase events.
  FlutterInsiderProduct setQuantity(int quantity) {
    try {
      // Same 32-bit narrowing as setStock.
      if (!FlutterInsiderUtils.isSendableInteger(
          'setQuantity', 'quantity', quantity)) {
        return this;
      }
      this.optionalFields["quantity"] = quantity;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the product size (e.g. apparel size).
  FlutterInsiderProduct setSize(String size) {
    try {
      this.optionalFields["size"] = size;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Attaches a string-typed custom attribute.
  FlutterInsiderProduct setCustomAttributeWithString(String key, String value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithString', key)) {
        return this;
      }
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

  /// Attaches a double-typed custom attribute.
  FlutterInsiderProduct setCustomAttributeWithDouble(String key, double value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithDouble', key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableDouble(
          'setCustomAttributeWithDouble', key, value)) {
        return this;
      }
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

  /// Attaches an integer-typed custom attribute.
  FlutterInsiderProduct setCustomAttributeWithInt(String key, int value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithInt', key)) {
        return this;
      }
      if (!FlutterInsiderUtils.isSendableInteger(
          'setCustomAttributeWithInt', key, value)) {
        return this;
      }
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

  /// Attaches a boolean-typed custom attribute.
  FlutterInsiderProduct setCustomAttributeWithBoolean(String key, bool value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithBoolean', key)) {
        return this;
      }
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

  /// Attaches a date-typed custom attribute. Stored as epoch milliseconds.
  FlutterInsiderProduct setCustomAttributeWithDate(String key, DateTime value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithDate', key)) {
        return this;
      }
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

  /// Attaches a string-array custom attribute without validation.
  ///
  /// Prefer [setCustomAttributeWithStringArray], which filters invalid
  /// entries.
  @Deprecated('Use setCustomAttributeWithStringArray instead')
  FlutterInsiderProduct setCustomAttributeWithArray(
      String key, List<String> value) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithArray', key)) {
        return this;
      }
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

  /// Sets a group code linking this product to its variant group.
  FlutterInsiderProduct setGroupCode(String groupCode) {
    try {
      this.optionalFields["group_code"] = groupCode;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the product brand. Empty values are ignored.
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

  /// Sets the target gender for the product. Empty values are ignored.
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

  /// Sets a free-form product description.
  FlutterInsiderProduct setDescription(String description) {
    try {
      this.optionalFields["description"] = description;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the SKU identifier.
  FlutterInsiderProduct setSku(String sku) {
    try {
      this.optionalFields["sku"] = sku;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets multipack metadata (e.g. `2x`, `3x`).
  FlutterInsiderProduct setMultipack(String multipack) {
    try {
      this.optionalFields["multipack"] = multipack;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the product type / sub-category.
  FlutterInsiderProduct setProductType(String productType) {
    try {
      this.optionalFields["product_type"] = productType;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the GTIN / EAN / UPC barcode.
  FlutterInsiderProduct setGtin(String gtin) {
    try {
      this.optionalFields["gtin"] = gtin;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets product tags.
  FlutterInsiderProduct setTags(List<String> tags) {
    try {
      this.optionalFields["tags"] = tags;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets in-stock status.
  FlutterInsiderProduct setInStock(bool isInStock) {
    try {
      this.optionalFields["in_stock"] = isInStock;
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
    return this;
  }

  /// Sets the canonical product URL. Empty values are ignored.
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

  /// Attaches a numeric-array custom attribute, dropping any non-finite
  /// entries. An array left empty is still attached, as native does.
  FlutterInsiderProduct setCustomAttributeWithNumericArray(
      String key, List<num> values) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithNumericArray', key)) {
        return this;
      }
      List<num> validArray =
          FlutterInsiderUtils.validateNumericArray(values) ?? <num>[];

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

  /// Attaches a string-array custom attribute.
  FlutterInsiderProduct setCustomAttributeWithStringArray(
      String key, List<String> values) {
    try {
      if (!FlutterInsiderUtils.isSendableKey(
          'setCustomAttributeWithStringArray', key)) {
        return this;
      }
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
