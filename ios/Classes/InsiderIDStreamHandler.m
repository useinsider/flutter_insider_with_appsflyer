#import "InsiderIDStreamHandler.h"

@implementation InsiderIDStreamHandler

static FlutterEventSink _eventSink = nil;

+ (FlutterEventSink)eventSink {
    @synchronized(self) {
        return _eventSink;
    }
}

+ (void)setEventSink:(FlutterEventSink)eventSink {
    @synchronized(self) {
        _eventSink = eventSink;
    }
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    InsiderIDStreamHandler.eventSink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    InsiderIDStreamHandler.eventSink = nil;
    return nil;
}

+ (void)triggerEvent:(NSString*)data {
    if (InsiderIDStreamHandler.eventSink != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            InsiderIDStreamHandler.eventSink(data);
        });
    }
}

@end
