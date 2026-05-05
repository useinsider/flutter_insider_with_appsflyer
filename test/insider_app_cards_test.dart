import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_insider/src/insider_app_cards.dart';
import 'package:flutter_insider/src/app_cards_models.dart';
import 'package:flutter_insider/src/app_cards_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_insider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('FlutterInsiderAppCards', () {
    group('getCampaigns', () {
      test('should return campaigns on success', () async {
        final mockCampaignsData = {
          'items': [
            {
              'id': 'card-1',
              'type': 'message',
              'read': false,
              'content': {
                'title': 'Test Card',
                'description': 'Test Description',
              },
            },
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            return mockCampaignsData;
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final campaigns = await appCards.getCampaigns();

        expect(campaigns, isNotNull);
        expect(campaigns!.appCards, hasLength(1));
        expect(campaigns.appCards[0].id, equals('card-1'));
        expect(campaigns.appCards[0].type, equals('message'));
        expect(campaigns.appCards[0].isRead, equals(false));
        expect(campaigns.appCards[0].content!.title, equals('Test Card'));
      });

      test('should return campaigns with images', () async {
        final mockCampaignsData = {
          'items': [
            {
              'id': 'card-2',
              'type': 'image',
              'read': true,
              'images': [
                {'url': 'https://example.com/image.jpg'},
              ],
            },
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            return mockCampaignsData;
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final campaigns = await appCards.getCampaigns();

        expect(campaigns, isNotNull);
        expect(campaigns!.appCards, hasLength(1));
        expect(campaigns.appCards[0].id, equals('card-2'));
        expect(campaigns.appCards[0].type, equals('image'));
        expect(campaigns.appCards[0].isRead, equals(true));
        expect(campaigns.appCards[0].images, hasLength(1));
        expect(campaigns.appCards[0].images![0].url,
            equals('https://example.com/image.jpg'));
      });

      test('should handle cards with buttons and actions', () async {
        final mockCampaignsData = {
          'items': [
            {
              'id': 'card-3',
              'type': 'message',
              'read': false,
              'content': {
                'title': 'Promotional Card',
                'description': 'Check out our new products!',
              },
              'buttons': [
                {
                  'id': 'btn-1',
                  'text': 'Shop Now',
                  'action': {
                    'type': 'deep_link',
                    'url_scheme': 'app://shop',
                  },
                },
              ],
              'action': {
                'type': 'deep_link',
                'keysAndValues': {'url': 'app://promo'},
              },
            },
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            return mockCampaignsData;
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final campaigns = await appCards.getCampaigns();

        expect(campaigns, isNotNull);
        expect(campaigns!.appCards[0].buttons, hasLength(1));
        expect(campaigns.appCards[0].buttons![0].id, equals('btn-1'));
        expect(campaigns.appCards[0].buttons![0].text, equals('Shop Now'));
        expect(campaigns.appCards[0].action, isNotNull);
        expect(campaigns.appCards[0].action!.actionType, equals('deep_link'));
      });

      test('should handle empty campaigns', () async {
        final mockCampaignsData = {'items': []};

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            return mockCampaignsData;
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final campaigns = await appCards.getCampaigns();

        expect(campaigns, isNotNull);
        expect(campaigns!.appCards, hasLength(0));
      });

      test('should throw InsiderAppCardsException on error without details', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            throw PlatformException(code: 'APP_CARDS_ERROR', message: 'Network error');
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        expect(
          () => appCards.getCampaigns(),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });

      test('should throw InsiderAppCardsException with networkError code from details', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            throw PlatformException(
              code: 'APP_CARDS_ERROR',
              message: 'A network error occurred.',
              details: {'code': 'networkError', 'message': 'A network error occurred.'},
            );
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        await expectLater(
          appCards.getCampaigns(),
          throwsA(
            isA<InsiderAppCardsException>().having(
              (e) => e.error.code,
              'errorCode',
              InsiderAppCardsErrorCode.networkError,
            ),
          ),
        );
      });

      test('should throw InsiderAppCardsException with sdkNotInitialized code from details', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAppCardsCampaigns') {
            throw PlatformException(
              code: 'APP_CARDS_ERROR',
              message: 'Insider SDK is not initialized.',
              details: {'code': 'sdkNotInitialized', 'message': 'Insider SDK is not initialized.'},
            );
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        await expectLater(
          appCards.getCampaigns(),
          throwsA(
            isA<InsiderAppCardsException>().having(
              (e) => e.error.code,
              'errorCode',
              InsiderAppCardsErrorCode.sdkNotInitialized,
            ),
          ),
        );
      });
    });

    group('view', () {
      test('should invoke platform method with correct arguments', () async {
        MethodCall? capturedCall;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          capturedCall = methodCall;
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
        );

        appCards.view(card);

        expect(capturedCall, isNotNull);
        final call = capturedCall!;
        expect(call.method, equals('viewAppCard'));
        expect(call.arguments, isA<Map>());
        expect(call.arguments['appCard'], isA<Map>());
        expect(call.arguments['appCard']['id'], equals('card-1'));
        expect(call.arguments['appCard']['type'], equals('message'));
      });
    });

    group('click', () {
      test('should invoke platform method with correct arguments', () async {
        MethodCall? capturedCall;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          capturedCall = methodCall;
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
        );

        appCards.click(card);

        expect(capturedCall, isNotNull);
        final call = capturedCall!;
        expect(call.method, equals('clickAppCard'));
        expect(call.arguments, isA<Map>());
        expect(call.arguments['appCard'], isA<Map>());
        expect(call.arguments['appCard']['id'], equals('card-1'));
        expect(call.arguments['appCard']['type'], equals('message'));
      });
    });

    group('markAsRead', () {
      test('should call native method with appCardIds on success', () async {
        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsRead') {
            capturedMethod = methodCall.method;
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.markAsRead(['card-1', 'card-2']);

        expect(capturedMethod, equals('appCardsMarkAsRead'));
        expect(capturedAppCardIds, equals(['card-1', 'card-2']));
      });

      test('should throw InsiderAppCardsException when native method fails', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsRead') {
            throw PlatformException(
              code: 'APP_CARDS_ERROR',
              message: 'Failed to mark as read',
            );
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        expect(
          () => appCards.markAsRead(['card-1']),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });

      test('should handle single appCardId', () async {
        List<String>? capturedAppCardIds;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsRead') {
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.markAsRead(['card-1']);

        expect(capturedAppCardIds, equals(['card-1']));
      });
    });

    group('markAsUnread', () {
      test('should call native method with appCardIds on success', () async {
        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsUnread') {
            capturedMethod = methodCall.method;
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.markAsUnread(['card-1', 'card-2']);

        expect(capturedMethod, equals('appCardsMarkAsUnread'));
        expect(capturedAppCardIds, equals(['card-1', 'card-2']));
      });

      test('should throw InsiderAppCardsException when native method fails', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsUnread') {
            throw PlatformException(
              code: 'APP_CARDS_ERROR',
              message: 'Failed to mark as unread',
            );
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        expect(
          () => appCards.markAsUnread(['card-1']),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });

      test('should handle single appCardId', () async {
        List<String>? capturedAppCardIds;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsMarkAsUnread') {
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.markAsUnread(['card-1']);

        expect(capturedAppCardIds, equals(['card-1']));
      });
    });

    group('delete', () {
      test('should call native method with appCardIds on success', () async {
        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsDelete') {
            capturedMethod = methodCall.method;
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.delete(['card-1', 'card-2']);

        expect(capturedMethod, equals('appCardsDelete'));
        expect(capturedAppCardIds, equals(['card-1', 'card-2']));
      });

      test('should throw InsiderAppCardsException when native method fails', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsDelete') {
            throw PlatformException(
              code: 'APP_CARDS_ERROR',
              message: 'Failed to delete card',
            );
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);

        expect(
          () => appCards.delete(['card-1']),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });

      test('should handle single appCardId', () async {
        List<String>? capturedAppCardIds;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'appCardsDelete') {
            capturedAppCardIds = List<String>.from(methodCall.arguments['appCardIds']);
            return '';
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        await appCards.delete(['card-1']);

        expect(capturedAppCardIds, equals(['card-1']));
      });
    });

    group('clickButton', () {
      test('should call native module with button appCardId and data', () async {
        String? capturedAppCardId;
        Map<String, dynamic>? capturedData;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'clickAppCardButton') {
            capturedAppCardId = methodCall.arguments['appCardId'];
            capturedData = Map<String, dynamic>.from(methodCall.arguments['data']);
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final button = InsiderAppCardButton(
          id: '262bf03d44f0c6b3cff4d821c2a473885562c8f7c60c51603783ed1f98a6bf506a26c1ee9a85c7ef9b90a35cd6f9fb80',
          text: 'Demo',
          appCardId: 'card-1',
          action: InsiderAppCardDeeplinkAction(
            externalBrowserUrl: 'https://insiderone.com/request-a-demo/',
          ),
        );

        appCards.clickButton(button);

        expect(capturedAppCardId, equals('card-1'));
        expect(capturedData, isNotNull);
        expect(capturedData!['id'], equals('262bf03d44f0c6b3cff4d821c2a473885562c8f7c60c51603783ed1f98a6bf506a26c1ee9a85c7ef9b90a35cd6f9fb80'));
        expect(capturedData!['text'], equals('Demo'));
        expect(capturedData!['action'], isNotNull);
        expect(capturedData!['action']['type'], equals('deep_link'));
        expect(capturedData!['action']['external_browser_url'], equals('https://insiderone.com/request-a-demo/'));
      });

      test('should call native module with button without action', () async {
        String? capturedAppCardId;
        Map<String, dynamic>? capturedData;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'clickAppCardButton') {
            capturedAppCardId = methodCall.arguments['appCardId'];
            capturedData = Map<String, dynamic>.from(methodCall.arguments['data']);
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final button = InsiderAppCardButton(
          id: 'btn-2',
          text: 'Learn More',
          appCardId: 'card-2',
        );

        appCards.clickButton(button);

        expect(capturedAppCardId, equals('card-2'));
        expect(capturedData, isNotNull);
        expect(capturedData!['id'], equals('btn-2'));
        expect(capturedData!['text'], equals('Learn More'));
        expect(capturedData!['action'], isNull);
      });

      test('should call native module with button that has internal browser URL', () async {
        String? capturedAppCardId;
        Map<String, dynamic>? capturedData;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'clickAppCardButton') {
            capturedAppCardId = methodCall.arguments['appCardId'];
            capturedData = Map<String, dynamic>.from(methodCall.arguments['data']);
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final button = InsiderAppCardButton(
          id: 'btn-3',
          text: 'Shop Now',
          appCardId: 'card-3',
          action: InsiderAppCardDeeplinkAction(
            internalBrowserUrl: 'https://insiderone.com/shop',
          ),
        );

        appCards.clickButton(button);

        expect(capturedAppCardId, equals('card-3'));
        expect(capturedData, isNotNull);
        expect(capturedData!['id'], equals('btn-3'));
        expect(capturedData!['text'], equals('Shop Now'));
        expect(capturedData!['action'], isNotNull);
        expect(capturedData!['action']['type'], equals('deep_link'));
        expect(capturedData!['action']['internal_browser_url'], equals('https://insiderone.com/shop'));
      });

      test('should handle button with empty appCardId', () async {
        String? capturedAppCardId;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'clickAppCardButton') {
            capturedAppCardId = methodCall.arguments['appCardId'];
            return null;
          }
          return null;
        });

        final appCards = FlutterInsiderAppCards(channel);
        final button = InsiderAppCardButton(
          id: 'btn-4',
          text: 'Test',
        );

        appCards.clickButton(button);

        expect(capturedAppCardId, equals(''));
      });
    });
  });
}
