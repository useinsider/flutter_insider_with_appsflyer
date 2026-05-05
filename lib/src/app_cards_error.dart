/// Error codes for App Cards operations.
/// Both Android and iOS bridges send error codes as camelCase strings
/// matching these enum names (e.g. 'networkError', 'serverError').
enum InsiderAppCardsErrorCode {
  unknown,
  sdkNotInitialized,
  invalidParameter,
  networkError,
  serverError,
  parseError,
}

/// Structured error returned by App Cards operations.
class InsiderAppCardsError {
  final InsiderAppCardsErrorCode code;
  final String message;

  const InsiderAppCardsError({
    required this.code,
    required this.message,
  });

  factory InsiderAppCardsError.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['code'] as String? ?? 'unknown';
    final message = map['message'] as String? ?? 'An unexpected error occurred.';
    return InsiderAppCardsError(
      code: InsiderAppCardsErrorCode.values.asNameMap()[rawCode] ??
          InsiderAppCardsErrorCode.unknown,
      message: message,
    );
  }

  @override
  String toString() =>
      'InsiderAppCardsError(code: $code, message: $message)';
}

/// Exception thrown by App Cards operations when a native error occurs.
class InsiderAppCardsException implements Exception {
  final InsiderAppCardsError error;

  const InsiderAppCardsException(this.error);

  @override
  String toString() => 'InsiderAppCardsException: ${error.message}';
}
