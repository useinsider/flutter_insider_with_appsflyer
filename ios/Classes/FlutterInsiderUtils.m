#import "FlutterInsiderUtils.h"

@implementation FlutterInsiderUtils

+ (InsiderEvent *)parseEventFromEventName:(NSString *)eventName
                            andParameters:(NSArray *)parameters {

    InsiderEvent *event = [Insider tagEvent:eventName];

    if (![parameters isKindOfClass:[NSArray class]]) {
        return event;
    }

    for (id item in parameters) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;

        NSDictionary *parameter = (NSDictionary *)item;

        NSString *type = parameter[@"type"];
        NSString *key  = parameter[@"key"];
        if (![type isKindOfClass:[NSString class]] || ![key isKindOfClass:[NSString class]]) continue;

        id value = parameter[@"value"];

        if ([type isEqualToString:@"string"] && [value isKindOfClass:[NSString class]]) {
            NSString *stringValue = value;
            event.addParameterWithString(key, stringValue);
        }
        else if ([type isEqualToString:@"integer"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = value;
            int integerValue = (int)(numberValue != nil ? numberValue.integerValue : 0);
            event.addParameterWithInt(key, integerValue);
        }
        else if ([type isEqualToString:@"double"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = value;
            double doubleValue = (numberValue != nil ? numberValue.doubleValue : 0.0);
            event.addParameterWithDouble(key, doubleValue);
        }
        else if ([type isEqualToString:@"boolean"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = value;
            BOOL booleanValue = (numberValue != nil ? numberValue.boolValue : NO);
            event.addParameterWithBoolean(key, booleanValue);
        }
        else if ([type isEqualToString:@"date"] && [value isKindOfClass:[NSString class]]) {
            long long epochMillis = [(NSString *)value longLongValue];
            NSTimeInterval seconds = ((NSTimeInterval)epochMillis) / 1000.0;
            NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:seconds];
            event.addParameterWithDate(key, dateValue);
        }
        else if ([type isEqualToString:@"strings"] && [value isKindOfClass:[NSArray class]]) {
            NSArray * stringsValue = value;
            event.addParameterWithStringArray(key, stringsValue);
        }
        else if ([type isEqualToString:@"numbers"] && [value isKindOfClass:[NSArray class]]) {
            NSArray * numbersValue = value;
            event.addParameterWithNumericArray(key, numbersValue);
        }
    }

    return event;
}

+ (nonnull InsiderProduct *)parseProductFromRequiredFields:(nonnull NSDictionary *)requiredFields
                                         andOptionalFields:(nullable NSDictionary *)optionalFields
                                       andCustomParameters:(nullable NSArray *)customParameters {

    /// Apply required fields
    NSString *productId = requiredFields[@"product_id"];
    NSString *name = requiredFields[@"name"];
    NSArray *taxonomy = requiredFields[@"taxonomy"];
    NSString *imageURL = requiredFields[@"image_url"];
    NSNumber *priceNumber = requiredFields[@"price"];
    double price = [priceNumber isKindOfClass:[NSNumber class]] ? priceNumber.doubleValue : 0.0;
    NSString *currency = requiredFields[@"currency"];

    InsiderProduct *product = [Insider createNewProductWithID:productId name:name taxonomy:taxonomy imageURL:imageURL price:price currency:currency];

    /// Apply optional fields
    for (NSString *key in optionalFields) {
        id value = optionalFields[key];

        if ([key isEqualToString:@"color"]) {
            NSString *color = (NSString *)value;
            product.setColor(color);
        }
        else if ([key isEqualToString:@"voucher_name"]) {
            NSString *voucherName = (NSString *)value;
            product.setVoucherName(voucherName);
        }
        else if ([key isEqualToString:@"promotion_name"]) {
            NSString *promotionName = (NSString *)value;
            product.setPromotionName(promotionName);
        }
        else if ([key isEqualToString:@"size"]) {
            NSString *size = (NSString *)value;
            product.setSize(size);
        }
        else if ([key isEqualToString:@"sale_price"]) {
            NSNumber *salePriceNumber = (NSNumber *)value;
            double salePrice = salePriceNumber.doubleValue;
            product.setSalePrice(salePrice);
        }
        else if ([key isEqualToString:@"shipping_cost"]) {
            NSNumber *shippingCostNumber = (NSNumber *)value;
            double shippingCost = shippingCostNumber.doubleValue;
            product.setShippingCost(shippingCost);
        }
        else if ([key isEqualToString:@"voucher_discount"]) {
            NSNumber *voucherDiscountNumber = (NSNumber *)value;
            double voucherDiscount = voucherDiscountNumber.doubleValue;
            product.setVoucherDiscount(voucherDiscount);
        }
        else if ([key isEqualToString:@"promotion_discount"]) {
            NSNumber *promotionDiscountNumber = (NSNumber *)value;
            double promotionDiscount = promotionDiscountNumber.doubleValue;
            product.setPromotionDiscount(promotionDiscount);
        }
        else if ([key isEqualToString:@"stock"]) {
            NSNumber *stockNumber = (NSNumber *)value;
            int stock = stockNumber.intValue;
            product.setStock(stock);
        }
        else if ([key isEqualToString:@"quantity"]) {
            NSNumber *quantityNumber = (NSNumber *)value;
            int quantity = quantityNumber.intValue;
            product.setQuantity(quantity);
        }
        else if ([key isEqualToString:@"group_code"]) {
            NSString *groupCode = (NSString *)value;
            product.setGroupCode(groupCode);
        }
        else if ([key isEqualToString:@"brand"]) {
            NSString *brand = (NSString *)value;
            product.setBrand(brand);
        }
        else if ([key isEqualToString:@"sku"]) {
            NSString *sku = (NSString *)value;
            product.setSku(sku);
        }
        else if ([key isEqualToString:@"gender"]) {
            NSString *gender = (NSString *)value;
            product.setGender(gender);
        }
        else if ([key isEqualToString:@"multipack"]) {
            NSString *multipack = (NSString *)value;
            product.setMultipack(multipack);
        }
        else if ([key isEqualToString:@"product_type"]) {
            NSString *productType = (NSString *)value;
            product.setProductType(productType);
        }
        else if ([key isEqualToString:@"gtin"]) {
            NSString *gtin = (NSString *)value;
            product.setGtin(gtin);
        }
        else if ([key isEqualToString:@"description"]) {
            NSString *desc = (NSString *)value;
            product.setDescription(desc);
        }
        else if ([key isEqualToString:@"tags"]) {
            NSArray *tagsArray = (NSArray *)value;
            product.setTags(tagsArray);
        }
        else if ([key isEqualToString:@"in_stock"]) {
            NSNumber *inStockNumber = (NSNumber *)value;
            BOOL inStock = inStockNumber.boolValue;
            product.setInStock(inStock);
        }
        else if ([key isEqualToString:@"product_url"]) {
            NSString *productURL = (NSString *)value;
            product.setProductURL(productURL);
        }
    }

    /// Apply custom parameters
    for (id item in customParameters) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;

        NSDictionary *parameter = (NSDictionary *)item;

        NSString *type = parameter[@"type"];
        NSString *key  = parameter[@"key"];
        if (![type isKindOfClass:[NSString class]] || ![key isKindOfClass:[NSString class]]) continue;

        id value = parameter[@"value"];

        if ([type isEqualToString:@"string"] && [value isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)value;
            product.setCustomAttributeWithString(key, stringValue);
        }
        else if ([type isEqualToString:@"integer"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = (NSNumber *)value;
            int intValue = (int)numberValue.integerValue;
            product.setCustomAttributeWithInt(key, intValue);
        }
        else if ([type isEqualToString:@"double"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = (NSNumber *)value;
            double doubleValue = numberValue.doubleValue;
            product.setCustomAttributeWithDouble(key, doubleValue);
        }
        else if ([type isEqualToString:@"boolean"] && [value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = (NSNumber *)value;
            BOOL booleanValue = numberValue.boolValue;
            product.setCustomAttributeWithBoolean(key, booleanValue);
        }
        else if ([type isEqualToString:@"date"] && [value isKindOfClass:[NSString class]]) {
            // Epoch millis passed as string from RN
            NSString *epochString = (NSString *)value;
            long long epochMillis = epochString.longLongValue;
            NSTimeInterval seconds = ((NSTimeInterval)epochMillis) / 1000.0;
            NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:seconds];
            product.setCustomAttributeWithDate(key, dateValue);
        }
        else if ([type isEqualToString:@"strings"] && [value isKindOfClass:[NSArray class]]) {
            NSArray *stringsValue = (NSArray *)value;
            product.setCustomAttributeWithStringArray(key, stringsValue);
        }
        else if ([type isEqualToString:@"numbers"] && [value isKindOfClass:[NSArray class]]) {
            NSArray *numbersValue = (NSArray *)value;
            product.setCustomAttributeWithNumericArray(key, numbersValue);
        }
    }

    return product;
}

@end
