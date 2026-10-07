#import "InsiderEventStreamHandler.h"

/// Internal to the handler — events reach the sink through the SDK observer
/// callback, never through a direct call. Kept out of the header so nothing can
/// bypass that flow, matching the private `triggerEvent` on the Android side.
@interface InsiderEventStreamHandler ()

+ (void)triggerEventWithName:(NSString *)name
                  parameters:(NSDictionary *)parameters
                   timestamp:(NSTimeInterval)timestamp;

@end

@implementation InsiderEventStreamHandler

static FlutterEventSink _eventSink = nil;

/// Strong reference keeping the observer alive — the SDK holds it weakly.
static InsiderEventStreamHandler *_sharedInstance = nil;
static BOOL _isObserving = NO;

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

+ (instancetype)sharedInstance {
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[InsiderEventStreamHandler alloc] init];
        }
        return _sharedInstance;
    }
}

+ (void)addObserver {
    @try {
        @synchronized(self) {
            if (_isObserving) return;

            // The flag is set only AFTER the SDK call returns. Setting it first
            // would permanently wedge the bridge if `addObserver:` threw: every
            // later call would early-return believing an observer exists, and
            // no event would ever arrive.
            [[Insider events] addObserver:[InsiderEventStreamHandler sharedInstance]];
            _isObserving = YES;
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];

        // Rethrown so the plugin reports the failure to Dart, which rolls its
        // subscribe back. Swallowing it here would answer success and hand the
        // caller a subscription with no observer behind it — and it left the
        // plugin's own @catch unreachable, which is how this was missed.
        // Android's addObserver() rethrows for the same reason.
        @throw;
    }
}

+ (void)removeObserver {
    @try {
        @synchronized(self) {
            if (!_isObserving) return;

            // Symmetrically, the flag is cleared only after the SDK accepted the
            // removal, so a throwing `removeObserver:` cannot leave the bridge
            // believing it is unregistered while the SDK still holds it.
            [[Insider events] removeObserver:[InsiderEventStreamHandler sharedInstance]];
            _isObserving = NO;
        }
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    InsiderEventStreamHandler.eventSink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    InsiderEventStreamHandler.eventSink = nil;
    [InsiderEventStreamHandler removeObserver];
    return nil;
}

#pragma mark - InsiderEventListener

- (void)onEventRecorded:(NSString *)name
             parameters:(NSDictionary<NSString *, id> *)parameters
              timestamp:(NSTimeInterval)timestamp {
    @try {
        [InsiderEventStreamHandler triggerEventWithName:name
                                             parameters:parameters
                                              timestamp:timestamp];
    } @catch (NSException *e) {
        [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
    }
}

+ (void)triggerEventWithName:(NSString *)name
                  parameters:(NSDictionary *)parameters
                   timestamp:(NSTimeInterval)timestamp {
    if (InsiderEventStreamHandler.eventSink == nil) return;

    // `timestamp` is whole seconds since 1970. Boxed as a long long so Dart
    // receives an int, matching the Android bridge.
    NSDictionary *payload = @{
        @"name": name ?: @"",
        @"parameters": [self encodeParameters:parameters] ?: @{},
        @"timestamp": @((long long) timestamp)
    };

    // The SDK delivers on a background thread; FlutterEventSink must only be
    // touched on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Re-read: the sink may have been cleared by onCancel between the
        // check above and this block running.
        FlutterEventSink sink = InsiderEventStreamHandler.eventSink;
        if (sink != nil) {
            sink(payload);
        }
    });
}

#pragma mark - Codec-safe parameter conversion

/**
 * Copies the SDK's parameter dictionary into a codec-safe dictionary,
 * recursing through nested dictionaries and arrays.
 *
 * A `FlutterStandardMessageCodec` encoding failure takes down the WHOLE event,
 * not just the offending value, so anything the codec cannot represent
 * degrades to its `description` rather than being passed through.
 *
 * Dates need no special case here: `addParameterWithDate` stores an
 * RFC-format `NSString`, so no `NSDate` ever reaches this method.
 */
+ (NSDictionary *)encodeParameters:(NSDictionary *)parameters {
    if (![parameters isKindOfClass:[NSDictionary class]]) return @{};

    NSMutableDictionary *encoded =
        [NSMutableDictionary dictionaryWithCapacity:parameters.count];

    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if (key == nil) return;

        NSString *encodedKey = [key isKindOfClass:[NSString class]]
            ? key
            : [key description];
        if (encodedKey == nil) return;

        encoded[encodedKey] = [self encodeValue:value];
    }];

    return encoded;
}

+ (id)encodeValue:(id)value {
    if (value == nil || value == [NSNull null]) return [NSNull null];

    if ([value isKindOfClass:[NSDictionary class]]) {
        return [self encodeParameters:value];
    }

    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *source = (NSArray *) value;
        NSMutableArray *list = [NSMutableArray arrayWithCapacity:source.count];
        for (id item in source) {
            [list addObject:[self encodeValue:item]];
        }
        return list;
    }

    // Types the standard codec handles natively.
    if ([value isKindOfClass:[NSString class]] ||
        [value isKindOfClass:[NSNumber class]] ||
        [value isKindOfClass:[NSData class]]) {
        return value;
    }

    // Unknown type — degrade to a string so a single unsupported value cannot
    // fail encoding and drop the whole event.
    NSString *described = [value description];
    return described ?: [NSNull null];
}

@end
