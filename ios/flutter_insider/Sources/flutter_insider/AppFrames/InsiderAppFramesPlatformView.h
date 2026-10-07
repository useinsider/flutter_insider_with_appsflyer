#import <Flutter/Flutter.h>

// Same resolution dance as FlutterInsiderUtils.h: the SDK lands as a framework or as plain
// headers on the search path, depending on the distribution channel.
#if __has_include(<InsiderMobile/Insider.h>)
#import <InsiderMobile/Insider.h>
#elif __has_include("Insider.h")
#import "Insider.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Hosts a native @c InsiderAppFramesView inside the Flutter view hierarchy and relays every
 @c InsiderAppFramesViewDelegate callback to Dart over a per-view @c FlutterMethodChannel.

 The native view subscribes to its placement on window attach and unsubscribes on detach, so
 mounting and unmounting the Flutter widget drives the whole lifecycle. The placement is fixed for
 the life of the view — the Dart widget recreates the platform view when its @c placementId changes
 rather than mutating this one.

 The channel is one-way (native to Dart). Dart never invokes anything on it, so no method call
 handler is installed.
 */
@interface InsiderAppFramesPlatformView : NSObject <FlutterPlatformView, InsiderAppFramesViewDelegate>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(nullable id)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

NS_ASSUME_NONNULL_END
