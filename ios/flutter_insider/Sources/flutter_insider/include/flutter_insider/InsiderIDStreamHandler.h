#import <Flutter/Flutter.h>

@interface InsiderIDStreamHandler : NSObject <FlutterStreamHandler>
@property (class, nonatomic, strong) FlutterEventSink eventSink;

+ (void)triggerEvent:(NSString *)data;
@end