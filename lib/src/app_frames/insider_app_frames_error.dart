import '../constants.dart';

/// Error codes reported by an [InsiderAppFramesView].
///
/// Both Android and iOS bridges send error codes as camelCase strings matching
/// these enum names (e.g. 'resolutionFailed', 'contentDisplayFailed').
///
/// App Frames are designed to fail silently: when a placement has no content
/// the view simply renders nothing and reports a zero height. Prefer letting
/// the frame collapse over showing an error to the end user.
enum InsiderAppFramesErrorCode {
  /// An unclassified failure. Also the fallback for a code this plugin does not
  /// recognise, so a native SDK newer than the plugin degrades instead of
  /// throwing.
  unknown,

  /// The request that fetches the set of App Frames placements failed — a
  /// network or server error. No placement can load until it recovers.
  resolutionFailed,

  /// The placements request succeeded but its body could not be reconciled
  /// (for example the `placements` key is missing), so no placement was routed.
  responseMalformed,

  /// The placement's content failed to download.
  downloadingFailed,

  /// The placement's render URL failed trust validation — it is not an absolute
  /// http(s) URL with a host — so its content was never fetched.
  placementUntrusted,

  /// The placement's content was downloaded but could not be displayed.
  contentDisplayFailed,

  /// The rendered template itself reported an error while running.
  renderingFailed,
}

/// Structured error delivered to [InsiderAppFramesView.onLoadFailed].
class InsiderAppFramesError {
  final InsiderAppFramesErrorCode code;
  final String message;

  /// Raw template dismiss code, present only when the frame's template reported
  /// a non-default dismissal. Null otherwise.
  ///
  /// **Currently populated on Android only.** The iOS SDK does carry the dismiss
  /// code in the error's `userInfo["dismiss_code"]`, but this plugin's iOS bridge
  /// does not forward it yet, so it stays null there. Until it does, a
  /// cross-platform host must read null as "no information", not as "a default
  /// dismissal".
  final int? dismissCode;

  /// The originating failure underneath this one, when the SDK wrapped one.
  ///
  /// Comes from the native error's cause chain — Android's `Throwable.getCause`
  /// and iOS's `NSUnderlyingErrorKey`. Null when the failure has no deeper
  /// cause. Diagnostic only; its text is not a stable contract.
  final String? cause;

  const InsiderAppFramesError({
    required this.code,
    required this.message,
    this.dismissCode,
    this.cause,
  });

  factory InsiderAppFramesError.fromMap(Map<dynamic, dynamic> map) {
    // Match on the type rather than casting: a `as String?` throws on a payload
    // that carries the code or message as anything else, and that exception
    // would cost the host its `onLoadFailed` callback entirely — the one place
    // it learns the frame failed. An unusable field falls back instead.
    final rawCode = map[Constants.APP_FRAMES_ERROR_CODE];
    final code = rawCode is String ? rawCode : 'unknown';
    final rawMessage = map[Constants.APP_FRAMES_ERROR_MESSAGE];
    final message = rawMessage is String
        ? rawMessage
        : 'An unexpected error occurred.';
    final rawDismissCode = map[Constants.APP_FRAMES_DISMISS_CODE];
    final rawCause = map[Constants.APP_FRAMES_ERROR_CAUSE];
    return InsiderAppFramesError(
      code: InsiderAppFramesErrorCode.values.asNameMap()[code] ??
          InsiderAppFramesErrorCode.unknown,
      message: message,
      // Any number, not just an int: a native side may hand the dismiss code
      // over as a double. Narrowing to `int` alone would silently drop a code
      // that arrived as 96.0.
      dismissCode: rawDismissCode is num ? rawDismissCode.toInt() : null,
      cause: rawCause is String && rawCause.isNotEmpty ? rawCause : null,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer(
      'InsiderAppFramesError(code: $code, message: $message',
    );
    if (dismissCode != null) buffer.write(', dismissCode: $dismissCode');
    if (cause != null) buffer.write(', cause: $cause');
    buffer.write(')');
    return buffer.toString();
  }
}
