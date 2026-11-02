#import "FlutterInsiderUtils.h"

@implementation FlutterInsiderUtils

// The JavaScript Date range, mirrored from the WebView SDK so a date that no
// wrapper can represent is dropped instead of becoming a bogus timestamp.
static const double kMaxDateMillis = 8640000000000000.0;

/// Returns YES when the value can become a date both platforms can carry.
static BOOL isSendableDateMillis(double millis) {
    return !isnan(millis) && !isinf(millis) && fabs(millis) <= kMaxDateMillis;
}

/// Returns YES when an "integer" entry really holds a whole number.
static BOOL isWholeNumber(NSNumber *value) {
    double number = value.doubleValue;

    return !isnan(number) && !isinf(number) && number == rint(number);
}

/// Reports a bridge-side skip. The bridge cannot reach the developer's
/// console, so the SDK's own error channel is the only report it can make.
static void reportSkippedEntry(NSString *where, NSString *type) {
    // The entry may have been skipped because the tag is unknown OR because a
    // known tag carried the wrong value class, so the message must not claim
    // the tag itself is unsupported.
    NSString *reason = [NSString stringWithFormat:@"%@ skipped an entry tagged '%@': the tag is unknown, or its value is not of the type the tag names.", where, type ?: @"(null)"];
    [Insider sendError:[NSException exceptionWithName:@"[Flutter Bridge]" reason:reason userInfo:nil]
                  desc:@"FlutterInsiderUtils"];
}

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
            if (!isWholeNumber(numberValue)) continue;
            int integerValue = (int)numberValue.integerValue;
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
            double epochMillis = [(NSString *)value doubleValue];
            if (!isSendableDateMillis(epochMillis)) continue;
            NSTimeInterval seconds = ((NSTimeInterval)[(NSString *)value longLongValue]) / 1000.0;
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
        else if ([type isEqualToString:@"objects"] && [value isKindOfClass:[NSArray class]]) {
            event.addParameterWithObjectArray(key, [self convertCustomParametersList:(NSArray *)value]);
        }
        else {
            // The Android bridge reports an unmatched entry through
            // putException; do the same instead of dropping it silently.
            reportSkippedEntry(@"parseEvent", type);
        }
    }

    return event;
}

+ (nullable NSDictionary<NSString *, id> *)convertCustomParameters:(nullable NSArray *)params {
    if (![params isKindOfClass:[NSArray class]]) return nil;
    NSMutableDictionary *converted = [NSMutableDictionary dictionary];
    for (id item in params) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *parameter = (NSDictionary *)item;
        NSString *type = parameter[@"type"];
        NSString *key  = parameter[@"key"];
        if (![type isKindOfClass:[NSString class]] || ![key isKindOfClass:[NSString class]]) continue;
        id value = parameter[@"value"];
        if ([type isEqualToString:@"string"] && [value isKindOfClass:[NSString class]]) {
            converted[key] = value;
        } else if (([type isEqualToString:@"integer"] || [type isEqualToString:@"double"] || [type isEqualToString:@"boolean"]) && [value isKindOfClass:[NSNumber class]]) {
            // An "integer" entry carrying a fractional value is dropped, as the
            // Android bridge and the WebView SDK do.
            if ([type isEqualToString:@"integer"] && !isWholeNumber((NSNumber *)value)) continue;
            converted[key] = value;
        } else if ([type isEqualToString:@"date"] && [value isKindOfClass:[NSNumber class]]) {
            if (!isSendableDateMillis([(NSNumber *)value doubleValue])) continue;
            long long epochMillis = [(NSNumber *)value longLongValue];
            NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)epochMillis / 1000.0];
            converted[key] = dateValue;
        } else if (([type isEqualToString:@"string_array"] || [type isEqualToString:@"numeric_array"]) && [value isKindOfClass:[NSArray class]]) {
            converted[key] = value;
        } else if ([type isEqualToString:@"object"] && [value isKindOfClass:[NSArray class]]) {
            converted[key] = [self convertCustomParameters:(NSArray *)value];
        }
    }
    return converted;
}

+ (nullable NSDictionary<NSString *, id> *)convertMatch:(nullable id)match {
    if (![match isKindOfClass:[NSArray class]]) return nil;
    NSDictionary<NSString *, id> *converted = [self convertCustomParameters:(NSArray *)match];
    return converted.count == [(NSArray *)match count] ? converted : nil;
}

+ (nonnull NSArray<NSDictionary<NSString *, id> *> *)convertCustomParametersList:(nullable NSArray *)list {
    NSMutableArray<NSDictionary<NSString *, id> *> *objects = [NSMutableArray array];
    if (![list isKindOfClass:[NSArray class]]) return objects;
    for (id item in list) {
        if (![item isKindOfClass:[NSArray class]]) continue;
        [objects addObject:[self convertCustomParameters:(NSArray *)item]];
    }
    return objects;
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
            if (!isWholeNumber(numberValue)) continue;
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
            // Epoch millis passed as string from Dart
            NSString *epochString = (NSString *)value;
            if (!isSendableDateMillis(epochString.doubleValue)) continue;
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
        else {
            reportSkippedEntry(@"parseProduct", type);
        }
    }

    return product;
}

+ (NSString *)mapAppCardsErrorCode:(NSError *)error {
    if ([error.domain isEqualToString:InsiderAppCardsErrorDomain]) {
        switch (error.code) {
            case InsiderAppCardsErrorCodeSdkNotInitialized: return @"sdkNotInitialized";
            case InsiderAppCardsErrorCodeInvalidParameter: return @"invalidParameter";
            case InsiderAppCardsErrorCodeNetworkError: return @"networkError";
            case InsiderAppCardsErrorCodeServerError: return @"serverError";
            case InsiderAppCardsErrorCodeParseError: return @"parseError";
            default: return @"unknown";
        }
    }
    return @"unknown";
}

+ (NSDictionary *)appCardsErrorToDictionary:(NSError *)error {
    NSString *code = [self mapAppCardsErrorCode:error];
    NSString *message = error.localizedDescription ?: @"An unexpected error occurred.";
    return @{@"code": code, @"message": message};
}

/// Maps an App Frames error onto the camelCase wire vocabulary shared with the Android bridge and
/// the Dart `InsiderAppFramesErrorCode` enum. The six strings below must stay identical to
/// `FlutterInsiderUtils.mapAppFramesErrorCode` on Android.
+ (NSString *)mapAppFramesErrorCode:(NSError *)error {
    if ([error.domain isEqualToString:InsiderAppFramesErrorDomain]) {
        switch (error.code) {
            case InsiderAppFramesErrorCodeResolutionFailed: return @"resolutionFailed";
            case InsiderAppFramesErrorCodeResponseMalformed: return @"responseMalformed";
            case InsiderAppFramesErrorCodeDownloadingFailed: return @"downloadingFailed";
            case InsiderAppFramesErrorCodePlacementUntrusted: return @"placementUntrusted";
            case InsiderAppFramesErrorCodeContentDisplayFailed: return @"contentDisplayFailed";
            case InsiderAppFramesErrorCodeRenderingFailed: return @"renderingFailed";
            default: return @"unknown";
        }
    }
    return @"unknown";
}

/// Maps an App Frames view status onto the lowerCamelCase wire vocabulary shared with the Android
/// bridge and the Dart `InsiderAppFramesViewStatus` enum. The SDK already provides exactly this
/// vocabulary, so this defers to it rather than restating the mapping.
+ (NSString *)mapAppFramesStatus:(InsiderAppFramesViewStatus)status {
    // Passed through verbatim, @"unknown" included: the Dart enum has a matching `unknown` member,
    // and remapping it to @"detached" here would tell the widget the frame is merely off-window
    // with its content intact — the one status it deliberately does not collapse on.
    return InsiderAppFramesViewStatusStringValue(status);
}

+ (NSDictionary *)appFramesErrorToDictionary:(NSError *)error {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        @"code": [self mapAppFramesErrorCode:error],
        @"message": error.localizedDescription ?: @"An unexpected error occurred."
    }];

    // No `dismissCode` here — but not because the SDK lacks one: InsiderAppFramesView.m passes
    // @{@"dismiss_code": ...} to InsiderAppFramesErrorMake on a non-default template dismissal,
    // so it is available under error.userInfo. This bridge simply does not forward it yet, and
    // the Dart model documents the field as populated on Android only for that reason.

    // The SDK stores the originating failure under NSUnderlyingErrorKey, which is the only thing
    // that says *why* a load failed. Omit the key when there is no deeper cause.
    id underlying = error.userInfo[NSUnderlyingErrorKey];
    if ([underlying isKindOfClass:[NSError class]]) {
        dictionary[@"cause"] = ((NSError *)underlying).localizedDescription;
    }

    return dictionary;
}

+ (void)setGender:(int)gender {
    @try {
        [Insider getCurrentUser].setGender([self insiderGenderFromInt:gender]);
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

// The SDK can answer and throw in either order; a FlutterResult must be answered once.
+ (void)getMessageCenterDataWithLimit:(NSInteger)limit
                      startDateMillis:(NSInteger)startDateEpoch
                        endDateMillis:(NSInteger)endDateEpoch
                              success:(void (^)(NSArray *))completionBlock {
    __block BOOL answered = NO;
    NSObject *answerLock = [NSObject new];
    void (^answerOnce)(NSArray *) = ^(NSArray *messageCenterData) {
        @synchronized (answerLock) {
            if (answered) return;
            answered = YES;
        }
        completionBlock(@[@{@"data": messageCenterData ?: @[]}]);
    };
    @try {
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startDateEpoch / 1000.0];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endDateEpoch / 1000.0];
        [Insider getMessageCenterDataWithLimit:limit
                                     startDate:startDate
                                       endDate:endDate
                                       success:^(NSArray *messageCenterData) {
            answerOnce(messageCenterData);
        }];
    } @catch (NSException *e) {
        answerOnce(@[]);
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

+ (NSString *)dictToJson:(NSDictionary *)dict {
    @try {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        if (!jsonData) {
            NSException *failure = [NSException exceptionWithName:NSInvalidArgumentException
                                                            reason:@"NSJSONSerialization returned nil"
                                                          userInfo:nil];
            [Insider sendError:failure desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
            return nil;
        }
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
        return nil;
    }
}

+ (void)sendDict:(NSDictionary *)dict toSink:(void (^)(id _Nullable))sink {
    NSString *json = [self dictToJson:dict];
    if (json && sink) sink(json);
}

+ (InsiderGender)insiderGenderFromInt:(int)gender {
    switch (gender) {
        case 0:
            return InsiderGenderMale;
        case 1:
            return InsiderGenderFemale;
        default:
            return InsiderGenderOther;
    }
}

@end
