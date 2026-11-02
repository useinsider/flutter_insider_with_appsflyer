#import <Foundation/Foundation.h>

#if __has_include(<InsiderMobile/Insider.h>)
#import <InsiderMobile/Insider.h>
#elif __has_include("Insider.h")
#import "Insider.h"
#endif

@interface FlutterInsiderUtils : NSObject

+ (nonnull InsiderEvent *)parseEventFromEventName:(nonnull NSString *)eventName
                                    andParameters:(nullable NSArray *)parameters;

+ (nonnull InsiderProduct *)parseProductFromRequiredFields:(nonnull NSDictionary *)requiredFields
                                         andOptionalFields:(nullable NSDictionary *)optionalFields
                                       andCustomParameters:(nullable NSArray *)customParameters;

/// Converts the Dart typed parameter list `[{type, key, value}]` into a native dictionary.
/// A nested `object` entry is converted recursively.
+ (nullable NSDictionary<NSString *, id> *)convertCustomParameters:(nullable NSArray *)params;

/// Converts a merge/remove match, or returns nil when it is not a list or loses an entry during
/// conversion. A narrowed match selects more objects than requested, so the call must be refused.
+ (nullable NSDictionary<NSString *, id> *)convertMatch:(nullable id)match;

/// Converts a list of Dart typed parameter lists, skipping any item that is not a list.
+ (nonnull NSArray<NSDictionary<NSString *, id> *> *)convertCustomParametersList:(nullable NSArray *)list;

+ (nonnull NSString *)mapAppCardsErrorCode:(nonnull NSError *)error;
+ (nonnull NSDictionary *)appCardsErrorToDictionary:(nonnull NSError *)error;

+ (nonnull NSString *)mapAppFramesErrorCode:(nonnull NSError *)error;
+ (nonnull NSDictionary *)appFramesErrorToDictionary:(nonnull NSError *)error;
+ (nonnull NSString *)mapAppFramesStatus:(InsiderAppFramesViewStatus)status;

+ (void)setGender:(int)gender;
+ (void)getMessageCenterDataWithLimit:(NSInteger)limit
                      startDateMillis:(NSInteger)startDateEpoch
                        endDateMillis:(NSInteger)endDateEpoch
                              success:(nonnull void (^)(NSArray * _Nonnull result))completionBlock;
+ (nullable NSString *)dictToJson:(nonnull NSDictionary *)dict;
/// Sends `dict` to `sink` as JSON; skips it when there is no listener yet or the payload does not serialize.
+ (void)sendDict:(nonnull NSDictionary *)dict toSink:(nullable void (^)(id _Nullable event))sink;

@end

