#import "InsiderAppFramesViewFactory.h"
#import "InsiderAppFramesPlatformView.h"

NSString *const InsiderAppFramesViewType =
    @"com.useinsider.insider.flutter_insider/app_frames_view";

@interface InsiderAppFramesViewFactory ()
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger> *messenger;
@end

@implementation InsiderAppFramesViewFactory

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    // The Dart widget encodes its creation params with the standard codec.
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
    return [[InsiderAppFramesPlatformView alloc] initWithFrame:frame
                                                viewIdentifier:viewId
                                                     arguments:args
                                               binaryMessenger:self.messenger];
}

@end
