#import <Flutter/Flutter.h>

#if __has_include(<InsiderMobile/Insider.h>)
#import <InsiderMobile/Insider.h>
#elif __has_include("Insider.h")
#import "Insider.h"
#endif

/**
 * EventChannel stream handler for the `insider_event_listener` channel.
 *
 * Also implements `InsiderEventListener` itself. The Insider SDK holds
 * registered observers WEAKLY, so the shared instance is retained in a
 * file-static strong reference (see `+sharedInstance`) — registering a
 * transient object would silently stop delivering events once it deallocated.
 *
 * Single-engine assumption: the sink and the observer are process-global, matching
 * `InsiderIDStreamHandler`. With more than one FlutterEngine (add-to-app hosting)
 * the most recently attached engine wins the sink, and a detach from any engine
 * removes the observer for all of them, so listeners must be re-created after a
 * detach. Single-engine is the supported mode for this plugin.
 */
@interface InsiderEventStreamHandler : NSObject <FlutterStreamHandler, InsiderEventListener>

/// `strong` rather than `copy`, matching `InsiderIDStreamHandler`. A block property
/// would normally want `copy`, but Flutter heap-copies the sink before handing it to
/// `onListenWithArguments:`, so there is nothing on the stack to capture. Changing it
/// here alone would split the two handlers; if it is worth tightening, both should
/// move together.
@property (class, nonatomic, strong) FlutterEventSink eventSink;

/// The single strongly-retained handler instance registered with the SDK.
+ (instancetype)sharedInstance;

/// Registers `sharedInstance` as an SDK observer, if not registered already.
+ (void)addObserver;

/// Removes `sharedInstance` from the SDK's observers, if registered.
+ (void)removeObserver;

@end
