import 'package:flutter/services.dart';
import 'constants.dart';
import 'app_cards_models.dart';
import 'app_cards_error.dart';
import 'utils.dart';

/// Public API surface for the App Cards feature.
///
/// Access via [FlutterInsider.appCards]. Methods that fail with a recoverable
/// platform error throw an [InsiderAppCardsException]; non-platform errors are
/// reported to the native SDK and swallowed.
///
/// ```dart
/// final response = await FlutterInsider.Instance.appCards.getCampaigns();
/// for (final card in response?.appCards ?? []) {
///   card.view();
/// }
/// ```
class FlutterInsiderAppCards {
  final MethodChannel _channel;

  FlutterInsiderAppCards(this._channel);

  InsiderAppCardsException _toAppCardsException(PlatformException e) {
    final details = e.details;
    if (details is Map) {
      return InsiderAppCardsException(InsiderAppCardsError.fromMap(details));
    }
    return InsiderAppCardsException(
      InsiderAppCardsError(
        code: InsiderAppCardsErrorCode.unknown,
        message: e.message ?? 'An unexpected error occurred.',
      ),
    );
  }

  /// Fetches the active App Card campaigns for the current user.
  ///
  /// Returns `null` when the native side reports no data. Throws
  /// [InsiderAppCardsException] when the native bridge surfaces a structured
  /// error.
  Future<InsiderAppCardCampaignsResponse?> getCampaigns() async {
    try {
      final result = await _channel.invokeMethod<Map>(
        Constants.GET_APP_CARDS_CAMPAIGNS,
      );

      if (result == null) return null;

      return InsiderAppCardCampaignsResponse.fromMap(
        Map<String, dynamic>.from(result),
      );
    } on PlatformException catch (e) {
      throw _toAppCardsException(e);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      return null;
    }
  }

  /// Marks the given [appCardIds] as read.
  ///
  /// Throws [InsiderAppCardsException] on a structured native error.
  Future<void> markAsRead(List<String> appCardIds) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCardIds'] = appCardIds;
      await _channel.invokeMethod('appCardsMarkAsRead', args);
    } on PlatformException catch (e) {
      throw _toAppCardsException(e);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      rethrow;
    }
  }

  /// Marks the given [appCardIds] as unread.
  ///
  /// Throws [InsiderAppCardsException] on a structured native error.
  Future<void> markAsUnread(List<String> appCardIds) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCardIds'] = appCardIds;
      await _channel.invokeMethod('appCardsMarkAsUnread', args);
    } on PlatformException catch (e) {
      throw _toAppCardsException(e);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      rethrow;
    }
  }

  /// Deletes the given [appCardIds].
  ///
  /// Throws [InsiderAppCardsException] on a structured native error.
  Future<void> delete(List<String> appCardIds) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCardIds'] = appCardIds;
      await _channel.invokeMethod('appCardsDelete', args);
    } on PlatformException catch (e) {
      throw _toAppCardsException(e);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
      rethrow;
    }
  }

  /// Records a view (impression) for the given [appCard].
  void view(InsiderAppCard appCard) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCard'] = appCard.toMap();

      _channel.invokeMethod('viewAppCard', args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records a tap on the given [appCard].
  void click(InsiderAppCard appCard) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCard'] = appCard.toMap();

      _channel.invokeMethod('clickAppCard', args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  /// Records a tap on a [button] inside an App Card.
  void clickButton(InsiderAppCardButton button) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};

      args['appCardId'] = button.appCardId ?? '';
      args['data'] = button.toMap();

      _channel.invokeMethod('clickAppCardButton', args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }
}
