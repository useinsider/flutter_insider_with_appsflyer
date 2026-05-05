import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_insider/src/app_cards_models.dart';
import 'package:flutter_insider/src/app_cards_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('InsiderAppCardContent', () {
    test('should create content with title and description', () {
      final content = InsiderAppCardContent(
        title: 'Welcome',
        description: 'Welcome to our app!',
      );

      expect(content.title, equals('Welcome'));
      expect(content.description, equals('Welcome to our app!'));
    });
  });

  group('InsiderAppCardImage', () {
    test('should create image with url', () {
      final image = InsiderAppCardImage(
        url: 'https://example.com/image.jpg',
      );

      expect(image.url, equals('https://example.com/image.jpg'));
    });
  });

  group('InsiderAppCardButton', () {
    const MethodChannel channel = MethodChannel('flutter_insider');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should create button with all properties', () {
      final button = InsiderAppCardButton(
        id: 'btn-1',
        text: 'Click Me',
        appCardId: 'card-1',
        action: null,
      );

      expect(button.id, equals('btn-1'));
      expect(button.text, equals('Click Me'));
      expect(button.appCardId, equals('card-1'));
      expect(button.action, isNull);
    });

    test('should expose toMap method with original structure', () {
      final button = InsiderAppCardButton(
        id: '262bf03d44f0c6b3cff4d821c2a473885562c8f7c60c51603783ed1f98a6bf506a26c1ee9a85c7ef9b90a35cd6f9fb80',
        text: 'Demo',
        appCardId: 'card-1',
        action: InsiderAppCardDeeplinkAction(
          externalBrowserUrl: 'https://insiderone.com/request-a-demo/',
        ),
      );

      final data = button.toMap();
      expect(data['id'], equals('262bf03d44f0c6b3cff4d821c2a473885562c8f7c60c51603783ed1f98a6bf506a26c1ee9a85c7ef9b90a35cd6f9fb80'));
      expect(data['text'], equals('Demo'));
      expect(data['action'], isNotNull);
      expect(data['action']['type'], equals('deep_link'));
      expect(data['action']['external_browser_url'], equals('https://insiderone.com/request-a-demo/'));
    });

    test('should have correct properties for button click', () {
      final button = InsiderAppCardButton(
        id: 'btn-1',
        text: 'Click Me',
        appCardId: 'card-1',
        action: InsiderAppCardDeeplinkAction(
          externalBrowserUrl: 'https://example.com',
        ),
      );

      final data = button.toMap();
      expect(data['id'], equals('btn-1'));
      expect(data['text'], equals('Click Me'));
      expect(data['action'], isNotNull);
      expect(data['action']['type'], equals('deep_link'));
      expect(button.appCardId, equals('card-1'));
    });
  });

  group('InsiderAppCardDeeplinkAction', () {
    test('should create deeplink action with urlScheme', () {
      final action = InsiderAppCardDeeplinkAction(
        urlScheme: 'app://home',
      );

      expect(action.actionType, equals('deep_link'));
      expect(action.url, equals('app://home'));
    });

    test('should return url with priority order', () {
      final action = InsiderAppCardDeeplinkAction(
        urlScheme: 'app://scheme',
        internalBrowserUrl: 'https://internal.com',
        externalBrowserUrl: 'https://external.com',
      );

      expect(action.url, equals('app://scheme'));
    });

    test('should expose json as a map', () {
      final action = InsiderAppCardDeeplinkAction(
        json: {'url': 'app://home', 'param': 'value'},
      );

      expect(action.json!['url'], equals('app://home'));
      expect(action.json!['param'], equals('value'));
    });

    test('should return null json when json string is missing', () {
      final action = InsiderAppCardDeeplinkAction();

      expect(action.json, isNull);
    });

    test('should expose keysAndValues as raw list', () {
      final action = InsiderAppCardDeeplinkAction(
        keysAndValues: [
          {'key': 'url', 'value': 'app://home'},
          {'key': 'param', 'value': 'value'},
        ],
      );

      expect(action.keysAndValues, hasLength(2));
      expect(action.keysAndValues![0]['key'], equals('url'));
      expect(action.keysAndValues![0]['value'], equals('app://home'));
      expect(action.keysAndValues![1]['key'], equals('param'));
      expect(action.keysAndValues![1]['value'], equals('value'));
    });
  });

  group('InsiderAppCardOpenSettingsAction', () {
    test('should create open settings action', () {
      final action = InsiderAppCardOpenSettingsAction();

      expect(action.actionType, equals('open_settings'));
    });
  });

  group('InsiderAppCardFeedbackAction', () {
    test('should create feedback action', () {
      final action = InsiderAppCardFeedbackAction();

      expect(action.actionType, equals('feedback'));
    });
  });

  group('InsiderAppCard', () {
    test('should create card with basic properties', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
      });

      expect(card, isNotNull);
      expect(card!.id, equals('card-1'));
      expect(card.type, equals('message'));
      expect(card.isRead, equals(false));
      expect(card.images, isNull);
      expect(card.content, isNull);
      expect(card.buttons, isNull);
      expect(card.action, isNull);
    });

    test('should create card with content', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'content': {
          'title': 'Test Title',
          'description': 'Test Description',
        },
      });

      expect(card!.content, isNotNull);
      expect(card.content!.title, equals('Test Title'));
      expect(card.content!.description, equals('Test Description'));
    });

    test('should create card with images', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'image',
        'read': true,
        'images': [
          {'url': 'https://example.com/img1.jpg'},
          {'url': 'https://example.com/img2.jpg'},
        ],
      });

      expect(card!.images, hasLength(2));
      expect(card.images![0].url, equals('https://example.com/img1.jpg'));
      expect(card.images![1].url, equals('https://example.com/img2.jpg'));
    });

    test('should create card with buttons', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'buttons': [
          {
            'id': 'btn-1',
            'text': 'Action 1',
          },
          {
            'id': 'btn-2',
            'text': 'Action 2',
          },
        ],
      });

      expect(card!.buttons, hasLength(2));
      expect(card.buttons![0].id, equals('btn-1'));
      expect(card.buttons![0].text, equals('Action 1'));
      expect(card.buttons![0].appCardId, equals('card-1'));
      expect(card.buttons![1].id, equals('btn-2'));
      expect(card.buttons![1].text, equals('Action 2'));
      expect(card.buttons![1].appCardId, equals('card-1'));
    });

    test('should create card with deeplink action', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'action': {
          'type': 'deep_link',
          'url_scheme': 'app://promo',
        },
      });

      expect(card!.action, isA<InsiderAppCardDeeplinkAction>());
      expect(card.action!.actionType, equals('deep_link'));
      expect(
        (card.action as InsiderAppCardDeeplinkAction).url,
        equals('app://promo'),
      );
    });

    test('should create card with open settings action', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'action': {
          'type': 'open_settings',
        },
      });

      expect(card!.action, isA<InsiderAppCardOpenSettingsAction>());
      expect(card.action!.actionType, equals('open_settings'));
    });

    test('should create card with feedback action', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'action': {
          'type': 'feedback',
        },
      });

      expect(card!.action, isA<InsiderAppCardFeedbackAction>());
      expect(card.action!.actionType, equals('feedback'));
    });

    test('should handle unknown action type', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-1',
        'type': 'message',
        'read': false,
        'action': {
          'type': 'unknown_type',
        },
      });

      expect(card!.action, isNull);
    });

    test('should create complete card with all properties', () {
      final card = InsiderAppCard.fromMap({
        'id': 'card-complete',
        'type': 'message',
        'read': false,
        'content': {
          'title': 'Complete Card',
          'description': 'This card has everything',
        },
        'images': [
          {'url': 'https://example.com/image.jpg'}
        ],
        'buttons': [
          {
            'id': 'btn-1',
            'text': 'Click Here',
          },
        ],
        'action': {
          'type': 'deep_link',
          'url_scheme': 'app://details',
        },
      });

      expect(card!.id, equals('card-complete'));
      expect(card.type, equals('message'));
      expect(card.isRead, equals(false));
      expect(card.content, isNotNull);
      expect(card.images, hasLength(1));
      expect(card.buttons, hasLength(1));
      expect(card.action, isA<InsiderAppCardDeeplinkAction>());
    });

    group('markAsRead', () {
      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          null,
        );
      });

      test('should call markAsRead with card ID and update isRead on success',
          () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: false,
        );

        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsRead') {
              capturedMethod = methodCall.method;
              capturedAppCardIds =
                  List<String>.from(methodCall.arguments['appCardIds']);
              return '';
            }
            return null;
          },
        );

        await card.markAsRead();

        expect(capturedMethod, equals('appCardsMarkAsRead'));
        expect(capturedAppCardIds, equals(['card-1']));
        expect(card.isRead, equals(true));
      });

      test('should not update isRead when markAsRead fails', () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsRead') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Failed to mark as read',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.markAsRead(),
          throwsA(isA<InsiderAppCardsException>()),
        );
        expect(card.isRead, equals(false));
      });

      test('should return a promise that resolves and updates isRead on success',
          () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsRead') {
              return '';
            }
            return null;
          },
        );

        await expectLater(card.markAsRead(), completes);
        expect(card.isRead, equals(true));
      });

      test('should return a promise that rejects and keeps isRead unchanged on failure',
          () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsRead') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Network error',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.markAsRead(),
          throwsA(isA<InsiderAppCardsException>()),
        );
        expect(card.isRead, equals(false));
      });
    });

    group('markAsUnread', () {
      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          null,
        );
      });

      test('should call markAsUnread with card ID and update isRead on success',
          () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: true,
        );

        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsUnread') {
              capturedMethod = methodCall.method;
              capturedAppCardIds =
                  List<String>.from(methodCall.arguments['appCardIds']);
              return '';
            }
            return null;
          },
        );

        await card.markAsUnread();

        expect(capturedMethod, equals('appCardsMarkAsUnread'));
        expect(capturedAppCardIds, equals(['card-1']));
        expect(card.isRead, equals(false));
      });

      test('should not update isRead when markAsUnread fails', () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: true,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsUnread') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Failed to mark as unread',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.markAsUnread(),
          throwsA(isA<InsiderAppCardsException>()),
        );
        expect(card.isRead, equals(true));
      });

      test('should return a promise that resolves and updates isRead on success',
          () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: true,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsUnread') {
              return '';
            }
            return null;
          },
        );

        await expectLater(card.markAsUnread(), completes);
        expect(card.isRead, equals(false));
      });

      test('should return a promise that rejects and keeps isRead unchanged on failure',
          () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: true,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsMarkAsUnread') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Network error',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.markAsUnread(),
          throwsA(isA<InsiderAppCardsException>()),
        );
        expect(card.isRead, equals(true));
      });
    });

    group('delete', () {
      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          null,
        );
      });

      test('should call delete with card ID on success', () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: false,
        );

        List<String>? capturedAppCardIds;
        String? capturedMethod;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsDelete') {
              capturedMethod = methodCall.method;
              capturedAppCardIds =
                  List<String>.from(methodCall.arguments['appCardIds']);
              return '';
            }
            return null;
          },
        );

        await card.delete();

        expect(capturedMethod, equals('appCardsDelete'));
        expect(capturedAppCardIds, equals(['card-1']));
      });

      test('should throw error when delete fails', () async {
        final card = InsiderAppCard(
          id: 'card-1',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsDelete') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Failed to delete card',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.delete(),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });

      test('should return a promise that resolves on success', () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsDelete') {
              return '';
            }
            return null;
          },
        );

        await expectLater(card.delete(), completes);
      });

      test('should return a promise that rejects on failure', () async {
        final card = InsiderAppCard(
          id: 'card-2',
          type: 'message',
          isRead: false,
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter_insider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'appCardsDelete') {
              throw PlatformException(
                code: 'APP_CARDS_ERROR',
                message: 'Network error',
              );
            }
            return null;
          },
        );

        await expectLater(
          card.delete(),
          throwsA(isA<InsiderAppCardsException>()),
        );
      });
    });
  });

  group('InsiderAppCardCampaignsResponse', () {
    test('should create response with cards', () {
      final response = InsiderAppCardCampaignsResponse.fromMap({
        'items': [
          {
            'id': 'card-1',
            'type': 'message',
            'read': false,
          },
          {
            'id': 'card-2',
            'type': 'image',
            'read': true,
          },
        ],
      });

      expect(response!.appCards, hasLength(2));
      expect(response.appCards[0].id, equals('card-1'));
      expect(response.appCards[1].id, equals('card-2'));
    });

    test('should create empty response when items is empty array', () {
      final response = InsiderAppCardCampaignsResponse.fromMap({'items': []});

      expect(response!.appCards, hasLength(0));
    });

    test('should handle undefined items', () {
      final response = InsiderAppCardCampaignsResponse.fromMap({});

      expect(response!.appCards, hasLength(0));
    });
  });

  group('InsiderAppCard convenience methods', () {
    test('view() method exists and can be called', () {
      final card = InsiderAppCard(
        id: 'card-1',
        type: 'message',
      );

      expect(card.view, isA<Function>());
    });

    test('click() method exists and can be called', () {
      final card = InsiderAppCard(
        id: 'card-1',
        type: 'message',
      );

      expect(card.click, isA<Function>());
    });
  });
}
