#import "InsiderAppFramesPlatformView.h"
#import "FlutterInsiderUtils.h"

/// Must match `Constants.APP_FRAMES_CHANNEL_PREFIX` on the Dart side.
static NSString *const kChannelPrefix = @"flutter_insider_app_frames_";

// native -> Dart
static NSString *const kMethodOnStatusChanged = @"onStatusChanged";
static NSString *const kMethodOnLoadFailed = @"onLoadFailed";
static NSString *const kMethodOnHeightChangeRequested = @"onHeightChangeRequested";
static NSString *const kMethodOnDismissRequested = @"onDismissRequested";
static NSString *const kMethodOnActionTriggered = @"onActionTriggered";

// Argument keys
static NSString *const kArgPlacementId = @"placementId";
static NSString *const kArgHeight = @"height";
static NSString *const kArgActionData = @"actionData";
static NSString *const kArgStatus = @"status";
static NSString *const kArgPreviousStatus = @"previousStatus";

@interface InsiderAppFramesPlatformView ()
@property (nonatomic, strong) InsiderAppFramesView *appFramesView;
@property (nonatomic, strong) FlutterMethodChannel *channel;
@end

@implementation InsiderAppFramesPlatformView

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        _appFramesView = [[InsiderAppFramesView alloc] initWithFrame:frame];

        NSString *channelName = [NSString stringWithFormat:@"%@%lld", kChannelPrefix, viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName
                                               binaryMessenger:messenger];

        // The SDK holds the delegate weakly. Flutter retains this platform view object for the
        // lifetime of the view, which is what keeps the callbacks alive.
        _appFramesView.delegate = self;

        NSString *placementId = nil;
        if ([args isKindOfClass:[NSDictionary class]]) {
            id rawPlacementId = ((NSDictionary *)args)[kArgPlacementId];
            if ([rawPlacementId isKindOfClass:[NSString class]]) {
                placementId = rawPlacementId;
            }
        }

        if (placementId.length > 0) {
            _appFramesView.placementId = placementId;
        } else {
            // The Dart widget requires a non-empty placement id, so an absent one means the
            // creation params did not survive the channel. The view is still returned — Flutter
            // has already committed to it — but it subscribes to nothing and the frame collapses,
            // which is the documented silent-failure behaviour for App Frames.
            NSException *e = [NSException
                exceptionWithName:@"[App Frames]"
                           reason:@"InsiderAppFramesView created without a placement id; "
                                  @"the frame will not load."
                         userInfo:nil];
            [Insider sendError:e desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
        }
    }
    return self;
}

- (UIView *)view {
    return self.appFramesView;
}

- (void)dealloc {
    _appFramesView.delegate = nil;
}

/**
 Delivers a callback to Dart on the main thread.

 InsiderAppFramesViewDelegate is @c NS_SWIFT_UI_ACTOR, so the SDK already promises main-actor
 delivery and the fast path below is what actually runs. The hop stays as a guard: a Flutter channel
 may only be touched from the platform thread, and every other native-to-Dart path in this plugin
 takes the same precaution — see @c InsiderIDStreamHandler.triggerEvent.

 The block captures @c self weakly so a callback queued just before teardown cannot keep the
 platform view — and the native view it owns — alive past its disposal.
 */
- (void)invokeOnDart:(NSString *)method arguments:(id)arguments {
    if (NSThread.isMainThread) {
        [self.channel invokeMethod:method arguments:arguments];
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.channel invokeMethod:method arguments:arguments];
    });
}

#pragma mark - InsiderAppFramesViewDelegate

- (void)appFramesView:(InsiderAppFramesView *)view
    didChangeStatusTo:(InsiderAppFramesViewStatus)status
                 from:(InsiderAppFramesViewStatus)previousStatus {
    [self invokeOnDart:kMethodOnStatusChanged
             arguments:@{
                 kArgStatus: [FlutterInsiderUtils mapAppFramesStatus:status],
                 kArgPreviousStatus: [FlutterInsiderUtils mapAppFramesStatus:previousStatus]
             }];
}

- (void)appFramesView:(InsiderAppFramesView *)view didFailLoadingWithError:(NSError *)error {
    [self invokeOnDart:kMethodOnLoadFailed
             arguments:[FlutterInsiderUtils appFramesErrorToDictionary:error]];
}

- (void)appFramesView:(InsiderAppFramesView *)view didRequestHeightChangeTo:(CGFloat)optimalHeight {
    // The iOS SDK reports points, which are already Flutter's logical pixels — no conversion.
    // (The Android bridge divides by the display density for the same reason.)
    [self invokeOnDart:kMethodOnHeightChangeRequested arguments:@{kArgHeight: @(optimalHeight)}];
}

- (void)appFramesViewDidRequestDismiss:(InsiderAppFramesView *)view {
    [self invokeOnDart:kMethodOnDismissRequested arguments:nil];
}

- (void)appFramesView:(InsiderAppFramesView *)view
    didTriggerActionWithData:(NSDictionary<NSString *, id> *)actionData {
    // Keys and value types are campaign-defined and arbitrarily nested, so the payload crosses the
    // channel as JSON rather than as a converted map. A campaign can therefore carry a value JSON
    // cannot represent — a JS `Date` reaching the bridge as an `NSDate`, for instance.
    // `dataWithJSONObject:` RAISES for those rather than returning an error, so the validity check
    // is what keeps a malformed campaign from taking the host app down.
    //
    // Every bail-out below is reported. An action the user actually tapped evaporating with no
    // trace is not what "App Frames fail silently" covers — that contract is about frame content
    // collapsing, not about a host callback going missing. Android's `JSONObject.toString()` never
    // fails, so without this the same campaign works there and is silently inert here, with
    // nothing in any telemetry to explain it.
    if (![NSJSONSerialization isValidJSONObject:actionData]) {
        [self reportActionDataFailure:@"payload is not a valid JSON object"
                             withData:actionData];
        return;
    }

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:actionData options:0 error:&error];
    if (error != nil || data == nil) {
        [self reportActionDataFailure:@"payload could not be serialised to JSON"
                             withData:actionData];
        return;
    }

    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (json == nil) {
        [self reportActionDataFailure:@"serialised payload is not valid UTF-8"
                             withData:actionData];
        return;
    }

    [self invokeOnDart:kMethodOnActionTriggered arguments:@{kArgActionData: json}];
}

/// Reports an action payload the bridge could not deliver.
///
/// Names the placement and the payload's *shape* only — the top-level keys and their classes. The
/// values are campaign data (coupon codes, customer identifiers) and do not belong in an error
/// report, which is the same rule the Dart side applies in `_reportUnusableActionData`.
- (void)reportActionDataFailure:(NSString *)reason withData:(NSDictionary<NSString *, id> *)data {
    NSMutableArray<NSString *> *shape = [NSMutableArray array];
    for (id key in data) {
        [shape addObject:[NSString stringWithFormat:@"%@:%@", key, NSStringFromClass([data[key] class])]];
    }

    NSString *description =
        [NSString stringWithFormat:@"InsiderAppFramesView[%@] dropped an action callback: %@ {%@}",
                                   self.appFramesView.placementId ?: @"<none>", reason,
                                   [shape componentsJoinedByString:@", "]];

    [Insider sendError:[NSException exceptionWithName:@"InsiderAppFramesActionDataError"
                                              reason:description
                                            userInfo:nil]
                  desc:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__]];
}

@end
