/// Layout variants delivered by App Card campaigns.
///
/// Use [InsiderAppCard.type] to branch UI rendering between the message-only
/// and image-led layouts.
class InsiderAppCardType {
  /// Text-only card: title + description, no hero image.
  static const String MESSAGE = "message";

  /// Image-led card: hero image is the primary visual element.
  static const String IMAGE = "image";
}
