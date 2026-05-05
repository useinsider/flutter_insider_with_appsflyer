import 'package:flutter/services.dart';
import 'constants.dart';
import 'app_cards_models.dart';
import 'app_cards_error.dart';
import 'utils.dart';

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

  void view(InsiderAppCard appCard) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCard'] = appCard.toMap();

      _channel.invokeMethod('viewAppCard', args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

  void click(InsiderAppCard appCard) {
    try {
      Map<String, dynamic> args = <String, dynamic>{};
      args['appCard'] = appCard.toMap();

      _channel.invokeMethod('clickAppCard', args);
    } catch (e) {
      FlutterInsiderUtils.putException(_channel, e);
    }
  }

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
