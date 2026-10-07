import '../constants.dart';

/// The phase an [InsiderAppFramesView] is in as it loads and displays its
/// placement content.
///
/// Both native SDKs report these as the same lowerCamelCase strings, matching
/// these enum names.
///
/// During a successful load a frame moves forward through the loading phases —
/// [resolving] → [downloading] → [rendering] → [ready]. It can come to rest at
/// any point: [unavailable] when no campaign targets the placement, [dismissed]
/// when the content closes itself, or one of the `error*` states when a step
/// fails. None of these are latched — the frame moves forward again when fresh
/// content arrives. [detached] and [noPlacement] are the idle states a frame
/// sits in before it starts loading.
///
/// [ready] is the only status in which content is on screen. App Frames fail
/// silently by contract, so treat [unavailable] and the `error*` states as
/// "collapse the slot", not "show an error". [unknown] is the catch-all for a
/// status a newer native SDK reports that this plugin cannot name.
///
/// This enum is additive: new statuses are appended as the native SDKs grow.
/// Always give a `switch` over it a `default` (or `_`) clause, and treat
/// anything you do not recognise the way you treat [unknown].
enum InsiderAppFramesViewStatus {
  /// Idle: the native view is not attached to a window, so it is not
  /// subscribed. The initial status.
  detached,

  /// Idle: attached to a window but no placement id to load.
  noPlacement,

  /// App Frames is switched off for the app, so the SDK never resolves
  /// placements. Not an error — the frame renders nothing.
  ///
  /// Both platforms gate the feature on a manifest flag, and neither reports
  /// anything beyond this status when the flag is wrong:
  ///
  /// - **iOS** — set an `App Frames Enabled` boolean inside the top-level
  ///   `Insider` dictionary in `Info.plist`.
  /// - **Android** — set `com.useinsider.insider.APP_FRAMES_ENABLED` meta-data
  ///   in `AndroidManifest.xml`, as a literal `android:value="true"`.
  ///
  /// Distinct from [unavailable], which means the feature is on but no campaign
  /// targets this placement.
  disabled,

  /// Fetching which campaign currently targets the placement.
  resolving,

  /// Downloading the campaign's content.
  downloading,

  /// The content downloaded and is rendering, but is not on screen yet — the
  /// frame stays collapsed until it becomes [ready].
  rendering,

  /// No campaign targets this placement. Not an error; let the frame collapse
  /// rather than showing an empty box.
  unavailable,

  /// The content rendered correctly. The only status in which the frame is
  /// visible and occupies its content height.
  ready,

  /// The content closed itself, usually through a close control in the
  /// template. Not latched: fresh content returns the frame to the loading
  /// phases.
  dismissed,

  /// The placements resolution failed, so no campaign could be resolved.
  errorResolving,

  /// A campaign was resolved but its content failed to download, or its render
  /// URL failed trust validation.
  errorDownloading,

  /// The content downloaded but the frame failed to render it — the content could
  /// not be displayed, or the template reported an error.
  errorRendering,

  /// A status this build of the plugin does not know — a native SDK newer than
  /// this plugin reported something outside the vocabulary above.
  ///
  /// Not a Dart-only invention — the string arrives over the wire. iOS's
  /// `InsiderAppFramesViewStatusStringValue` returns `"unknown"` for a raw value
  /// outside its enum, and this plugin's Android bridge
  /// (`FlutterInsiderUtils.mapAppFramesStatus`) returns it for a null or
  /// unmapped `InsiderAppFramesViewStatus`. Neither native enum has an `unknown`
  /// member today; this is what a native SDK newer than this plugin surfaces as.
  ///
  /// Treat it as "the slot's content cannot be accounted for": the widget
  /// collapses the frame on it, because keeping a stale template's height on
  /// screen is the worse of the two failure modes.
  ///
  /// Declared last to keep this list aligned with
  /// [kInsiderAppFramesStatusWireNames], which is order-dependent.
  unknown,
}

/// Groupings over [InsiderAppFramesViewStatus], mirroring the `isError` and
/// `isLoading` helpers both native SDKs expose.
///
/// These live in an extension rather than on the enum itself because the plugin
/// still supports Dart 2.15, which predates enhanced enums.
extension InsiderAppFramesViewStatusX on InsiderAppFramesViewStatus {
  /// Whether this is one of the failure states.
  ///
  /// True for [InsiderAppFramesViewStatus.errorResolving],
  /// [InsiderAppFramesViewStatus.errorDownloading] and
  /// [InsiderAppFramesViewStatus.errorRendering] — exactly the statuses that
  /// carry an error. [InsiderAppFramesViewStatus.unavailable] is **not** an
  /// error: it means no campaign targets the placement.
  bool get isError =>
      this == InsiderAppFramesViewStatus.errorResolving ||
      this == InsiderAppFramesViewStatus.errorDownloading ||
      this == InsiderAppFramesViewStatus.errorRendering;

  /// Whether this is one of the in-flight loading phases.
  ///
  /// True for [InsiderAppFramesViewStatus.resolving],
  /// [InsiderAppFramesViewStatus.downloading] and
  /// [InsiderAppFramesViewStatus.rendering] — the frame is working towards
  /// content but nothing is on screen yet.
  bool get isLoading =>
      this == InsiderAppFramesViewStatus.resolving ||
      this == InsiderAppFramesViewStatus.downloading ||
      this == InsiderAppFramesViewStatus.rendering;
}

/// Parses the status wire string both native bridges send.
///
/// An unrecognised or absent value falls back to
/// [InsiderAppFramesViewStatus.unknown] rather than throwing: a native SDK
/// newer than this plugin may report a status this enum does not know, and
/// losing the callback entirely would be worse than reporting that it could not
/// be represented.
///
/// The fallback is deliberately **not** [InsiderAppFramesViewStatus.detached].
/// `detached` means "off-window, content intact", which is the one idle status
/// the widget must not collapse on — so an unrepresentable status landing there
/// would leave a dead frame holding its old height, with [isError] reading
/// false and nothing anywhere reporting it.
InsiderAppFramesViewStatus insiderAppFramesStatusFromWire(Object? raw) {
  if (raw is! String) return InsiderAppFramesViewStatus.unknown;
  for (final status in InsiderAppFramesViewStatus.values) {
    if (status.name == raw) return status;
  }
  return InsiderAppFramesViewStatus.unknown;
}

/// Wire names in enum order.
///
/// Scope: this pins the **Dart** enum's member names against [Constants], so a
/// rename on one of the two Dart sides without the other fails a test. It says
/// nothing about the native bridges — no test in this repo reads a Java or
/// Objective-C string, and a rename there still falls back silently at runtime
/// (see [insiderAppFramesStatusFromWire]). Keeping the native constants in step
/// is a review-time obligation, not something CI catches.
const List<String> kInsiderAppFramesStatusWireNames = <String>[
  Constants.APP_FRAMES_STATUS_DETACHED,
  Constants.APP_FRAMES_STATUS_NO_PLACEMENT,
  Constants.APP_FRAMES_STATUS_DISABLED,
  Constants.APP_FRAMES_STATUS_RESOLVING,
  Constants.APP_FRAMES_STATUS_DOWNLOADING,
  Constants.APP_FRAMES_STATUS_RENDERING,
  Constants.APP_FRAMES_STATUS_UNAVAILABLE,
  Constants.APP_FRAMES_STATUS_READY,
  Constants.APP_FRAMES_STATUS_DISMISSED,
  Constants.APP_FRAMES_STATUS_ERROR_RESOLVING,
  Constants.APP_FRAMES_STATUS_ERROR_DOWNLOADING,
  Constants.APP_FRAMES_STATUS_ERROR_RENDERING,
  Constants.APP_FRAMES_STATUS_UNKNOWN,
];
