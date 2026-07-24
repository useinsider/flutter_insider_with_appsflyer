/// Data type identifiers for the Content Optimizer API.
///
/// Pass one of these constants as the `dataType` argument to
/// [FlutterInsider.getContentStringWithName],
/// [FlutterInsider.getContentIntWithName], or
/// [FlutterInsider.getContentBoolWithName] to choose which Insider variable
/// pool to read from.
class ContentOptimizerDataType {
  /// Variable defined as a Content Optimizer **content** variable in the
  /// Insider panel.
  static const int CONTENT = 0;

  /// Variable defined as a Content Optimizer **element** variable in the
  /// Insider panel.
  static const int ELEMENT = 1;
}
