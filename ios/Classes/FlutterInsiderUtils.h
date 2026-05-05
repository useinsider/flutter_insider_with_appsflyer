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

+ (nonnull NSString *)mapAppCardsErrorCode:(nonnull NSError *)error;
+ (nonnull NSDictionary *)appCardsErrorToDictionary:(nonnull NSError *)error;

@end

