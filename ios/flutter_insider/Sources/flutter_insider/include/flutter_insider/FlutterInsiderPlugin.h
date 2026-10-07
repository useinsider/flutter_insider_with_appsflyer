#import <Flutter/Flutter.h>
#import <UserNotifications/UserNotifications.h>

@interface FlutterInsiderPlugin : NSObject<FlutterPlugin, FlutterStreamHandler>
+(instancetype)Instance;
@end
