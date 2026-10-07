#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// Must match `Constants.APP_FRAMES_VIEW_TYPE` on the Dart side.
extern NSString *const InsiderAppFramesViewType;

/// Creates the platform view backing the Dart `InsiderAppFramesView` widget.
@interface InsiderAppFramesViewFactory : NSObject <FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

NS_ASSUME_NONNULL_END
