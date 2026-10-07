import 'dart:async';

import 'package:flutter/services.dart';

import 'constants.dart';
import 'utils.dart';

/// A single event recorded by the native Insider SDK, delivered to
/// [FlutterInsiderEvents.addObserver] subscribers.
class InsiderRecordedEvent {
  /// The event name, as passed to `tagEvent`.
  final String name;

  /// The event's parameters.
  ///
  /// Values are decoded by the platform's standard message codec, so they are
  /// Dart primitives (`String`, `int`, `double`, `bool`), `List`s, or nested
  /// `Map<Object?, Object?>`s. Array parameters added natively via
  /// `addParameterWithStringArray` / `addParameterWithNumericArray` arrive as
  /// `List`s.
  ///
  /// Parameters added natively via `addParameterWithDate` arrive as a
  /// **formatted date `String`**, not a number: both SDKs stringify the date
  /// when it is recorded (Android `StaticUtils.formatDate`, iOS an RFC-format
  /// string), so no native date object ever reaches this map. Parse it as a
  /// `String` — casting to `int` throws at runtime.
  ///
  /// Unmodifiable: the same event instance reaches every listener, so mutating
  /// it would change what the others see. The guarantee is shallow — a nested
  /// `Map` or `List` can still be changed in place — so copy out rather than
  /// editing anything you receive here.
  final Map<String, dynamic> parameters;

  /// The moment the event was recorded, **in WHOLE SECONDS since the Unix
  /// epoch** — NOT milliseconds.
  ///
  /// > ⚠️ **This is seconds, not milliseconds.** This mirrors the native
  /// > Android and iOS SDKs exactly, rather than silently rescaling. Passing
  /// > this value straight into [DateTime.fromMillisecondsSinceEpoch] yields a
  /// > date in January 1970 and is the single most common integration mistake
  /// > with this API.
  ///
  /// To convert, multiply by 1000 first — or just use [recordedAt], which does
  /// it for you:
  ///
  /// ```dart
  /// // WRONG — interprets seconds as milliseconds:
  /// DateTime.fromMillisecondsSinceEpoch(event.timestamp);
  ///
  /// // Right:
  /// DateTime.fromMillisecondsSinceEpoch(event.timestamp * 1000);
  ///
  /// // Simplest:
  /// event.recordedAt;
  /// ```
  final int timestamp;

  InsiderRecordedEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  /// [timestamp] converted to a [DateTime], handling the seconds → milliseconds
  /// scaling for you. Prefer this over converting [timestamp] by hand.
  DateTime get recordedAt =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  /// Builds an event from the raw platform channel payload.
  ///
  /// Returns `null` if the payload is malformed, so a single bad message
  /// cannot tear down the subscriber's stream.
  static InsiderRecordedEvent? fromPlatform(dynamic payload) {
    if (payload is! Map) return null;

    final name = payload['name'];
    final timestamp = payload['timestamp'];

    if (name is! String || timestamp is! int) return null;

    final rawParameters = payload['parameters'];
    final parameters = <String, dynamic>{};

    if (rawParameters is Map) {
      rawParameters.forEach((key, value) {
        if (key != null) parameters[key.toString()] = value;
      });
    }

    return InsiderRecordedEvent(
      name: name,
      // Unmodifiable because the same event instance is fanned out to every
      // listener: without it one could mutate parameters and the next would
      // observe the mutation instead of what the SDK recorded. Note this is
      // shallow — a nested Map or List can still be changed in place — so copy
      // out rather than editing anything you receive.
      parameters: Map<String, dynamic>.unmodifiable(parameters),
      timestamp: timestamp,
    );
  }

  @override
  String toString() =>
      'InsiderRecordedEvent(name: $name, parameters: $parameters, '
      'timestamp: $timestamp)';
}

/// A cancellable handle on an Insider event listener registration.
///
/// Returned by [FlutterInsiderEvents.addObserver]. Call [cancel] when the
/// listener is no longer needed — typically from a `State.dispose()`.
///
/// > **Deviation from [FlutterInsider.registerInsiderIDListener]:** that older
/// > API takes a bare `Function` and returns `Future<void>`, giving callers no
/// > way to stop listening. That is tolerable for Insider ID changes, which
/// > are rare. This listener fires on *every* recorded event, so an
/// > un-cancellable registration would leak the callback (and keep the native
/// > observer registered) for the process lifetime. Hence the cancellable
/// > handle.
class InsiderEventSubscription {
  final StreamSubscription<dynamic> _subscription;
  final Future<void> Function() _onCancel;
  bool _isCancelled = false;

  InsiderEventSubscription(this._subscription, this._onCancel);

  /// Whether [cancel] has already been called.
  bool get isCancelled => _isCancelled;

  /// Stops delivering events and unregisters the native observer once no
  /// listeners remain. Safe to call more than once.
  Future<void> cancel() async {
    if (_isCancelled) return;
    _isCancelled = true;

    await _subscription.cancel();
    await _onCancel();
  }
}

/// Public API surface for the recorded-event listener feature.
///
/// Access via [FlutterInsider.events], mirroring how the native SDKs namespace
/// this API (`[[Insider events] addObserver:]` on iOS,
/// `Insider.Instance.events().addObserver(...)` on Android).
///
/// ```dart
/// final subscription = await FlutterInsider.Instance.events.addObserver(
///   (event) => print('${event.name} at ${event.recordedAt}'),
/// );
/// ```
///
/// > **Why the state below is `static`.** Unlike [FlutterInsiderAppCards],
/// > which holds nothing but its channel, this class owns state that mirrors a
/// > *process-global* resource: one native observer and one platform-channel
/// > subscription, shared by every listener. [FlutterInsider.events] caches a
/// > single instance, but nothing prevents a second one being constructed —
/// > `FlutterInsider.Instance` is a mutable static, and the tests construct
/// > namespace classes directly. Per-instance fields would let a stray second
/// > instance register the native observer twice and keep its own refcount, so
/// > the last `cancel()` on one would tear the stream out from under the
/// > other's live listeners. Keeping them static makes the accounting correct
/// > no matter how many instances exist.
class FlutterInsiderEvents {
  final MethodChannel _channel;

  FlutterInsiderEvents(this._channel);

  static const EventChannel _eventChannel = const EventChannel(
    'insider_event_listener',
  );

  /// Broadcast controller fanning the single platform subscription out to
  /// every [addObserver] caller.
  ///
  /// [EventChannel.receiveBroadcastStream] returns a NEW stream on each call,
  /// and each subscription re-installs the channel's message handler, so the
  /// most recent subscriber would be the only one to receive messages. One
  /// shared platform subscription avoids that.
  static StreamController<InsiderRecordedEvent>? _eventController;
  static StreamSubscription<dynamic>? _eventChannelSubscription;

  /// Number of live [addObserver] subscriptions. The native observer is
  /// unregistered only when this drops back to zero.
  static int _eventListenerCount = 0;

  /// Lazily opens the single platform-channel subscription shared by all
  /// [addObserver] callers.
  Stream<InsiderRecordedEvent> _eventStream() {
    final controller = _eventController ??=
        StreamController<InsiderRecordedEvent>.broadcast();

    _eventChannelSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      (dynamic payload) {
        final event = InsiderRecordedEvent.fromPlatform(payload);
        if (event != null) controller.add(event);
      },
      onError: (dynamic error) {
        FlutterInsiderUtils.putException(_channel, error);
      },
    );

    return controller.stream;
  }

  /// Closes the shared platform subscription once no listeners remain.
  ///
  /// The statics are detached synchronously, before either await. Awaiting
  /// first would leave them visible across the suspension, so an
  /// [addObserver] arriving in that window would latch onto the controller
  /// this call is about to close via the `??=` in [_eventStream] and receive
  /// `onDone` instead of events.
  static Future<void> _closeEventStream() async {
    final subscription = _eventChannelSubscription;
    final controller = _eventController;

    _eventChannelSubscription = null;
    _eventController = null;

    await subscription?.cancel();
    await controller?.close();
  }

  /// Registers [callback] to be invoked for every event recorded by the
  /// native Insider SDK, including events tagged natively rather than through
  /// this plugin.
  ///
  /// Returns an [InsiderEventSubscription]; call
  /// [InsiderEventSubscription.cancel] to stop listening. The native observer
  /// is torn down once the last subscription is cancelled.
  ///
  /// > ⚠️ **[InsiderRecordedEvent.timestamp] is in WHOLE SECONDS since the
  /// > Unix epoch, NOT milliseconds.** This matches the native SDKs exactly.
  /// > `DateTime.fromMillisecondsSinceEpoch(event.timestamp)` is WRONG and
  /// > gives you January 1970 — you need
  /// > `DateTime.fromMillisecondsSinceEpoch(event.timestamp * 1000)`, or just
  /// > use [InsiderRecordedEvent.recordedAt].
  ///
  /// ```dart
  /// final subscription = await FlutterInsider.Instance.events.addObserver(
  ///   (event) {
  ///     print('${event.name} at ${event.recordedAt}');
  ///     print('parameters: ${event.parameters}');
  ///   },
  /// );
  ///
  /// // Later, e.g. in State.dispose():
  /// await subscription.cancel();
  /// ```
  ///
  /// ## Forwarding to a third-party analytics SDK
  ///
  /// The common use of this API is mirroring Insider's event stream into
  /// another analytics tool. Note that every mainstream analytics SDK expects
  /// timestamps in **milliseconds**, while [InsiderRecordedEvent.timestamp] is
  /// in **seconds** — so the conversion below is required, not optional.
  ///
  /// ```dart
  /// final subscription = await FlutterInsider.Instance.events.addObserver(
  ///   (event) {
  ///     // Analytics SDKs want epoch MILLISECONDS; Insider gives you seconds.
  ///     final millis = event.timestamp * 1000;
  ///     // Equivalently: event.recordedAt.millisecondsSinceEpoch
  ///
  ///     // Parameter values are codec primitives (String, int, double, bool),
  ///     // Lists, or nested Maps. Date parameters arrive as a formatted
  ///     // String. Most SDKs only accept a flat Map<String, Object>,
  ///     // so drop anything nested rather than letting the call throw.
  ///     final properties = <String, Object>{
  ///       for (final entry in event.parameters.entries)
  ///         if (entry.value is String ||
  ///             entry.value is num ||
  ///             entry.value is bool)
  ///           entry.key: entry.value as Object,
  ///       'insider_recorded_at_ms': millis,
  ///     };
  ///
  ///     // Firebase Analytics:
  ///     // FirebaseAnalytics.instance.logEvent(
  ///     //   name: event.name,
  ///     //   parameters: properties,
  ///     // );
  ///
  ///     // Mixpanel:
  ///     // mixpanel.track(event.name, properties: {
  ///     //   ...properties,
  ///     //   'time': millis,
  ///     // });
  ///
  ///     // Amplitude:
  ///     // amplitude.track(BaseEvent(
  ///     //   event.name,
  ///     //   eventProperties: properties,
  ///     //   timestamp: millis,
  ///     // ));
  ///   },
  /// );
  /// ```
  ///
  /// > Keep [callback] cheap and non-throwing. It runs for *every* recorded
  /// > event, and a throwing callback breaks delivery for that subscription.
  /// > Queue or batch instead of doing network I/O inline.
  ///
  /// Events are delivered on a background thread natively and hopped onto the
  /// platform main thread before reaching Dart, so [callback] always runs on
  /// the Dart isolate's event loop.
  ///
  /// > Single-engine only. The native observer and its sink are process-global,
  /// > matching the existing Insider ID listener. In an add-to-app host running
  /// > more than one `FlutterEngine`, the most recently attached engine wins the
  /// > stream. Detaching an engine tears the native observer down while this
  /// > subscription still looks live, so re-create listeners after a detach.
  ///
  /// Throws if the native registration fails. The subscribe is rolled back
  /// first, so a later call can retry cleanly — rather than returning a
  /// subscription that looks live while native holds no observer and no event
  /// ever arrives.
  Future<InsiderEventSubscription> addObserver(
    void Function(InsiderRecordedEvent event) callback,
  ) async {
    // Subscribe BEFORE invoking the method channel so the native onListen has
    // installed the EventSink before the SDK starts emitting.
    final subscription = _eventStream().listen(callback);

    _eventListenerCount++;

    try {
      await _channel.invokeMethod(Constants.REGISTER_EVENT_LISTENER);
    } catch (error) {
      // Roll the subscribe back rather than handing out a subscription that
      // looks live but can never deliver: native holds no observer, so the
      // caller would wait forever with no signal that anything went wrong.
      // Reporting the failure is what lets them retry.
      await subscription.cancel();

      if (_eventListenerCount > 0) _eventListenerCount--;
      if (_eventListenerCount == 0) await _closeEventStream();

      await FlutterInsiderUtils.putException(_channel, error);

      rethrow;
    }

    return InsiderEventSubscription(subscription, () async {
      if (_eventListenerCount > 0) _eventListenerCount--;
      if (_eventListenerCount > 0) return;

      await _closeEventStream();

      try {
        await _channel.invokeMethod(Constants.UNREGISTER_EVENT_LISTENER);
      } catch (error) {
        // Unlike the register path this does not rethrow: the caller is
        // tearing down and has nothing left to retry, and the stream is
        // already closed above either way.
        await FlutterInsiderUtils.putException(_channel, error);
      }
    });
  }
}
