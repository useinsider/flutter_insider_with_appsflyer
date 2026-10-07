import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../utils.dart';
import 'insider_app_frames_error.dart';
import 'insider_app_frames_status.dart';

/// Channel used only to report wrapper-level exceptions back to the SDK,
/// mirroring the fire-and-forget policy used across the plugin.
const MethodChannel _pluginChannel = MethodChannel(Constants.CHANNEL_NAME);

/// Inline Insider App Frames content, embedded as a platform view.
///
/// The native `InsiderAppFramesView` subscribes to its placement as soon as it
/// is attached to a window and unsubscribes when detached, so simply mounting
/// and unmounting this widget drives the whole lifecycle. There is no imperative
/// load/refresh API to call.
///
/// Sizing: native self-sizing (`intrinsicContentSize` on iOS, `onMeasure` on
/// Android) has no effect inside a Flutter platform view, because Flutter
/// imposes a fixed size on it. This widget therefore owns the height. It starts
/// at a 1-logical-pixel bootstrap height rather than at zero — Flutter never
/// creates a platform view that lays out to zero size, so a frame that started
/// collapsed would never get a native view and therefore never report a height
/// to grow into. It expands as soon as the template reports its optimal height.
/// Pass [height] to take that over yourself.
///
/// Visibility: the SDK never hides or removes the view. By default this widget
/// collapses to zero when the template requests a dismissal; set
/// [collapseOnDismiss] to false and handle [onDismissRequested] yourself if you
/// want different behaviour. A dismissal that arrives while [collapseOnDismiss]
/// is true is terminal for this widget instance: the dismissed state is cleared
/// only when [placementId] changes, so bringing a frame back requires a new
/// [placementId] or a new widget [Key]. Flipping [collapseOnDismiss] to false
/// afterwards does not restore the frame. With [collapseOnDismiss] false from
/// the start nothing is latched at all.
///
/// Only [placementId] recreates the native view. Later changes to [height],
/// [collapseOnDismiss] and the callbacks take effect on the next build without
/// resetting any state.
///
/// The widget must be mounted after `FlutterInsider.Instance.init(...)`. A
/// native view created before the SDK is initialised never subscribes and does
/// not retry.
///
/// If the native side has not registered the App Frames platform view — an old
/// native SDK, for instance — the frame collapses and the failure is reported to
/// Insider rather than surfacing to the end user. That safety net exists on
/// **Android only**: `UiKitView` gives Flutter no hook for a failed creation, so
/// on iOS the failure surfaces as a platform exception in the host app's console
/// instead, the frame stays at its 1px bootstrap height rather than collapsing,
/// and nothing about it reaches Insider's telemetry. Diagnosing an iOS frame
/// that never appears therefore means asking the customer for a console log —
/// there is no server-side trace to look up.
class InsiderAppFramesView extends StatefulWidget {
  /// The placement this view renders.
  final String placementId;

  /// Fixed height in logical pixels. When null (the default) the widget sizes
  /// itself from the template's reported height.
  final double? height;

  /// The frame's content-lifecycle status changed.
  ///
  /// This is the single entry point for observing the load. A successful load
  /// walks [InsiderAppFramesViewStatus.resolving] →
  /// [InsiderAppFramesViewStatus.downloading] →
  /// [InsiderAppFramesViewStatus.rendering] →
  /// [InsiderAppFramesViewStatus.ready], and `ready` is the only status in which
  /// content is on screen. Use [InsiderAppFramesViewStatus.isLoading] and
  /// [InsiderAppFramesViewStatus.isError] rather than matching each case.
  ///
  /// App Frames fail silently by contract: treat
  /// [InsiderAppFramesViewStatus.unavailable],
  /// [InsiderAppFramesViewStatus.disabled] and the `error*` statuses as "the
  /// slot collapsed", not as something to surface to the end user.
  final void Function(
    InsiderAppFramesViewStatus status,
    InsiderAppFramesViewStatus previousStatus,
  )? onStatusChanged;

  /// The frame failed to load. App Frames are designed to fail silently — this
  /// is diagnostic information, not something to surface to the end user.
  final ValueChanged<InsiderAppFramesError>? onLoadFailed;

  /// The template requested a new height, in logical pixels.
  ///
  /// Fires on every reported height, including a repeat of the current one and
  /// including when [height] overrides it.
  final ValueChanged<double>? onHeightChanged;

  /// The user dismissed the frame.
  final VoidCallback? onDismissRequested;

  /// The template triggered an action carrying campaign-defined data.
  ///
  /// The SDK has already performed any deep-link navigation by the time this
  /// fires; this is a notification, not an interception hook.
  final ValueChanged<Map<String, dynamic>>? onActionTriggered;

  /// Whether to collapse the widget to zero height on a dismiss request.
  final bool collapseOnDismiss;

  /// Gestures the frame is allowed to claim from the surrounding widgets.
  ///
  /// Defaults to taps only, so buttons and the template's close control work
  /// while a surrounding scrollable keeps handling drags. Pass an empty set to
  /// make the frame inert, or add recognisers for a template that needs them.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const InsiderAppFramesView({
    Key? key,
    required this.placementId,
    this.height,
    this.onStatusChanged,
    this.onLoadFailed,
    this.onHeightChanged,
    this.onDismissRequested,
    this.onActionTriggered,
    this.collapseOnDismiss = true,
    this.gestureRecognizers,
  }) : super(key: key);

  @override
  State<InsiderAppFramesView> createState() => _InsiderAppFramesViewState();
}

class _InsiderAppFramesViewState extends State<InsiderAppFramesView> {
  MethodChannel? _viewChannel;
  double _reportedHeight = 0;
  bool _dismissed = false;
  bool _creationFailed = false;

  @override
  void didUpdateWidget(covariant InsiderAppFramesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placementId != widget.placementId) {
      // The platform view is keyed on placementId, so Flutter tears down the
      // native view and builds a fresh one. That is deliberate: the native
      // views never reset their reported height, so reusing one across
      // placements would keep the previous placement's height until the new
      // template happens to report a different one.
      _viewChannel?.setMethodCallHandler(null);
      _viewChannel = null;
      _reportedHeight = 0;
      _dismissed = false;
      _creationFailed = false;
    }
  }

  @override
  void dispose() {
    _viewChannel?.setMethodCallHandler(null);
    _viewChannel = null;
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    // Nothing awaits the native creation, so this can land after the widget is
    // gone — a fast scroll or a `Navigator.pop` while `create()` is in flight.
    // `dispose` has already cleared `_viewChannel` by then, so installing a
    // handler here would leave it on the binary messenger with nothing left to
    // remove it, holding the disposed State and the host's closures alive.
    if (!mounted) return;
    // Clear any channel this overwrites before losing the reference to it.
    // `dispose` can only ever clean up the latest, so an earlier one would keep
    // its handler on the binary messenger with nothing left to remove it.
    _viewChannel?.setMethodCallHandler(null);
    final channel =
        MethodChannel('${Constants.APP_FRAMES_CHANNEL_PREFIX}$id');
    channel.setMethodCallHandler(_handleNativeCall);
    _viewChannel = channel;
  }

  /// The native side could not create the platform view — most often because it
  /// never registered the view type. App Frames fail silently: collapse the
  /// widget and report the failure to Insider instead of letting an unhandled
  /// error reach the host app.
  void _onPlatformViewCreationFailed(Object error) {
    FlutterInsiderUtils.putException(_pluginChannel, error);
    if (!mounted || _creationFailed) return;
    setState(() => _creationFailed = true);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    // Payload handling only. A malformed payload must never take the host app
    // down: the plugin's policy is to report it to Insider and swallow it. Host
    // callbacks are invoked through [_notifyHost], which keeps a bug in the host
    // app's own callback out of Insider's error stream.
    try {
      switch (call.method) {
        case Constants.APP_FRAMES_ON_STATUS_CHANGED:
          final args = call.arguments;
          final map = args is Map ? args : const <dynamic, dynamic>{};
          final status =
              insiderAppFramesStatusFromWire(map[Constants.APP_FRAMES_STATUS]);
          final previous = insiderAppFramesStatusFromWire(
            map[Constants.APP_FRAMES_PREVIOUS_STATUS],
          );
          _collapseIfContentGone(status);
          _notifyHost(
            () => widget.onStatusChanged?.call(status, previous),
            'onStatusChanged',
          );
          break;
        case Constants.APP_FRAMES_ON_LOAD_FAILED:
          final args = call.arguments;
          final error = InsiderAppFramesError.fromMap(
            args is Map ? args : const <dynamic, dynamic>{},
          );
          _notifyHost(() => widget.onLoadFailed?.call(error), 'onLoadFailed');
          break;
        case Constants.APP_FRAMES_ON_HEIGHT_CHANGE_REQUESTED:
          final args = call.arguments;
          final rawHeight =
              args is Map ? args[Constants.APP_FRAMES_HEIGHT] : null;
          if (rawHeight is num) {
            _setHeight(rawHeight.toDouble());
          }
          break;
        case Constants.APP_FRAMES_ON_DISMISS_REQUESTED:
          if (widget.collapseOnDismiss && mounted) {
            setState(() => _dismissed = true);
          }
          _notifyHost(
            () => widget.onDismissRequested?.call(),
            'onDismissRequested',
          );
          break;
        case Constants.APP_FRAMES_ON_ACTION_TRIGGERED:
          final args = call.arguments;
          final raw =
              args is Map ? args[Constants.APP_FRAMES_ACTION_DATA] : null;
          // Absent or empty action data is a legitimate no-op: an action need
          // not carry a payload. Data that is PRESENT but unusable is not —
          // dropping it silently would lose the host's callback with nothing
          // left to diagnose it by, so it takes the plugin's ignore-AND-report
          // path rather than ignore alone.
          if (raw == null) break;
          if (raw is! String) {
            _reportUnusableActionData('a ${raw.runtimeType}');
            break;
          }
          if (raw.isEmpty) break;
          // `jsonDecode` is deliberately isolated from the outer catch. Its
          // FormatException stringifies with the offending source inline, so
          // letting it reach `putException` below would ship the raw campaign
          // payload — coupon codes, customer e-mail addresses — to Insider's
          // error backend. Route it to the type-only report instead.
          final Object? decoded;
          try {
            decoded = jsonDecode(raw);
          } on FormatException {
            _reportUnusableActionData('a String that is not valid JSON');
            break;
          }
          if (decoded is! Map) {
            _reportUnusableActionData('JSON that decoded to a '
                '${decoded.runtimeType}');
            break;
          }
          final actionData = Map<String, dynamic>.from(decoded);
          _notifyHost(
            () => widget.onActionTriggered?.call(actionData),
            'onActionTriggered',
          );
          break;
      }
    } catch (e) {
      // Name the placement and the callback. Every plugin surface funnels into
      // one `putException` stream, so a bare exception string lands there with
      // nothing to filter on and cannot answer the only question support is
      // ever asked about it: which placement broke.
      FlutterInsiderUtils.putException(
        _pluginChannel,
        'InsiderAppFramesView[${widget.placementId}] failed while handling '
        '${call.method}: $e',
      );
    }
    return null;
  }

  /// Statuses in which the native view has dropped its content and zeroed its
  /// own intrinsic height.
  ///
  /// Both SDKs zero themselves silently in these states — they do **not** fire a
  /// height callback for the collapse. Because this widget drives the height
  /// itself, it has to mirror that, or a frame that once reached
  /// [InsiderAppFramesViewStatus.ready] keeps the old content's height as an
  /// empty gap in the layout.
  ///
  /// Intended to match the states in which each native view zeroes its own
  /// intrinsic height. That correspondence cannot be checked from this repo —
  /// the native collapse logic is internal to both SDKs — so keeping the two in
  /// step is a review obligation at every native SDK bump, not something CI
  /// catches.
  ///
  /// [InsiderAppFramesViewStatus.detached] is the one status deliberately
  /// absent: the view is only off-window (scrolled away, for instance) and its
  /// content survives, so collapsing the slot there would make it flicker on
  /// the way back. [InsiderAppFramesViewStatus.unknown] is included for exactly
  /// the opposite reason — a status this build cannot account for is no reason
  /// to keep a possibly-dead template's height reserved on screen.
  static const Set<InsiderAppFramesViewStatus> _contentGoneStatuses =
      <InsiderAppFramesViewStatus>{
    InsiderAppFramesViewStatus.noPlacement,
    InsiderAppFramesViewStatus.disabled,
    InsiderAppFramesViewStatus.unavailable,
    InsiderAppFramesViewStatus.dismissed,
    InsiderAppFramesViewStatus.errorResolving,
    InsiderAppFramesViewStatus.errorDownloading,
    InsiderAppFramesViewStatus.errorRendering,
    InsiderAppFramesViewStatus.unknown,
  };

  /// Drops back to the bootstrap height when the native view has silently
  /// zeroed itself.
  ///
  /// The host's [InsiderAppFramesView.onHeightChanged] is intentionally **not**
  /// invoked: no height was reported, and synthesising one would announce an
  /// event neither SDK sent. This collapse latches nothing by itself, so the
  /// frame grows again from the height the next template reports — except for
  /// [InsiderAppFramesViewStatus.dismissed], which the dismiss callback latches
  /// separately (see the class doc).
  void _collapseIfContentGone(InsiderAppFramesViewStatus status) {
    if (!_contentGoneStatuses.contains(status)) return;
    if (!mounted || _reportedHeight == 0) return;
    setState(() => _reportedHeight = 0);
  }

  /// Reports action data that arrived in a shape the widget cannot deliver.
  ///
  /// The contract is a JSON object encoded as a string; anything else means the
  /// native bridge and this widget disagree, which is an SDK-side fault and so
  /// goes to Insider rather than to the host's console. Only the payload's type
  /// is reported — the value itself is campaign data and does not belong in an
  /// error report. The host callback is skipped either way.
  void _reportUnusableActionData(String describedShape) {
    FlutterInsiderUtils.putException(
      _pluginChannel,
      FormatException(
        'InsiderAppFramesView[${widget.placementId}] received '
        '${Constants.APP_FRAMES_ACTION_DATA} as $describedShape; expected a '
        'JSON object encoded as a String.',
      ),
    );
  }

  /// Runs a host-app callback without ever letting it escape.
  ///
  /// A throwing callback is the host developer's bug, not an SDK failure, so it
  /// goes to [FlutterError.reportError] — the host's own console — rather than
  /// to Insider's `putException`. It is still never rethrown at the caller: the
  /// plugin must not take the host app down.
  void _notifyHost(VoidCallback callback, String callbackName) {
    // Defence only, with no reachable path today: `_handleNativeCall` contains
    // no `await`, so `mounted` cannot flip mid-body, and every route that
    // installs the handler removes it again. It stands so that adding an
    // `await` upstream cannot quietly start firing callbacks at a dead widget.
    if (!mounted) return;
    try {
      callback();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_insider',
          context: ErrorDescription(
            'while delivering InsiderAppFramesView.$callbackName '
            'to the host app',
          ),
        ),
      );
    }
  }

  void _setHeight(double height) {
    if (!mounted) return;
    _notifyHost(
      () => widget.onHeightChanged?.call(height),
      'onHeightChanged',
    );
    if (height == _reportedHeight) return;
    setState(() => _reportedHeight = height);
  }

  /// Flutter never creates a platform view that lays out to zero size, so a
  /// frame that started collapsed would never get a native view — and therefore
  /// never load, never report a height, and never expand. The widget keeps this
  /// sliver of height until the template reports its own, which is what lets the
  /// native view attach to a window and subscribe to its placement.
  static const double _bootstrapHeight = 1;

  double get _effectiveHeight {
    if (widget.height != null) return widget.height!;
    return _reportedHeight > 0 ? _reportedHeight : _bootstrapHeight;
  }

  /// App Frames only exists on the two platforms the plugin bridges.
  ///
  /// [kIsWeb] is checked first because on Flutter web [defaultTargetPlatform]
  /// reports the *browser's* platform — `TargetPlatform.iOS` in Safari on iOS —
  /// which would otherwise send the web build down the `UiKitView` path.
  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    // Take up no space at all where there is no native view to host — otherwise
    // the bootstrap height below would reserve a sliver for nothing.
    if (!_isSupportedPlatform) return const SizedBox.shrink();

    // Same reasoning when the native view could not be created at all.
    if (_creationFailed) return const SizedBox.shrink();

    // A dismissal is the one case where the frame goes away entirely: dropping the
    // platform view detaches the native view from the window, which unsubscribes it
    // so a later campaign cannot silently bring the frame back.
    //
    // Latched on `_dismissed` alone, never re-reading `collapseOnDismiss`: the
    // flag decides whether a dismissal collapses the frame *at the moment it
    // arrives*, and flipping it to false afterwards must not undo that. Reading
    // it here instead would rebuild the platform view from scratch and hold it
    // at the previous template's height, which is the class doc's stated
    // guarantee inverted.
    if (_dismissed) return const SizedBox.shrink();

    // Otherwise the platform view stays mounted even at the bootstrap height. The
    // native view only subscribes to its placement while attached to a window, so
    // unmounting it while it is still collapsed would stop the content — and
    // therefore the height — from ever arriving.
    return SizedBox(
      height: _effectiveHeight,
      width: double.infinity,
      child: _buildPlatformView(),
    );
  }

  /// Taps only by default: an App Frame is usually hosted inside a scrollable,
  /// and claiming drags too would stop the list from scrolling over the frame.
  /// With no recogniser at all the surrounding scrollable wins every gesture and
  /// the template's buttons never receive a touch.
  Set<Factory<OneSequenceGestureRecognizer>> get _gestureRecognizers =>
      widget.gestureRecognizers ??
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => TapGestureRecognizer()),
      };

  Widget _buildPlatformView() {
    final creationParams = <String, dynamic>{
      Constants.APP_FRAMES_PLACEMENT_ID: widget.placementId,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Hybrid composition: the native view hosts a WebView with a JavaScript
        // bridge, which virtual display embedding renders unreliably (keyboard
        // input, accessibility and hardware-accelerated content).
        return PlatformViewLink(
          key: ValueKey<String>(widget.placementId),
          viewType: Constants.APP_FRAMES_VIEW_TYPE,
          surfaceFactory: (context, controller) {
            // AndroidViewSurface, not the generic PlatformViewSurface: only the
            // Android one forwards touches to the embedded view through the
            // controller. With the generic surface the frame renders but its
            // buttons and close control never receive a tap.
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: _gestureRecognizers,
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (params) {
            // Full hybrid composition, not the cheaper texture-layer variant.
            // Under `initSurfaceAndroidView` the engine starts the frame as a
            // texture and later re-hosts it in the view hierarchy; that
            // transition re-initialises a view that already has a parent and
            // aborts the process with
            // "The Android view returned from PlatformView#getView() was
            // already added to a parent view."
            final controller = PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: Constants.APP_FRAMES_VIEW_TYPE,
              layoutDirection: Directionality.of(context),
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            );
            controller.addOnPlatformViewCreatedListener(
              params.onPlatformViewCreated,
            );
            controller.addOnPlatformViewCreatedListener(
              _onPlatformViewCreated,
            );
            // Nothing awaits `create()`, so without this handler a rejection —
            // an unregistered view type, for instance — would reach the host app
            // as an unhandled zone error.
            controller.create().catchError(_onPlatformViewCreationFailed);
            return controller;
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          key: ValueKey<String>(widget.placementId),
          viewType: Constants.APP_FRAMES_VIEW_TYPE,
          layoutDirection: Directionality.of(context),
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: _gestureRecognizers,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
