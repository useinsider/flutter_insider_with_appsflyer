import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_insider/flutter_insider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  const MethodChannel channel = MethodChannel('flutter_insider');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('Date Handling Tests', () {
    test('setBirthday converts DateTime to epoch milliseconds string', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      final DateTime testDate = DateTime(2024, 1, 1, 12, 0, 0);
      final int expectedEpoch = testDate.millisecondsSinceEpoch;

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      final user = FlutterInsider.Instance.getCurrentUser();
      expect(user, isNotNull, reason: 'User should be initialized after initFlutterBase');
      user!.setBirthday(testDate);

      expect(methodCalls.length, greaterThan(0));
      final birthdayCall = methodCalls.firstWhere(
        (call) => call.method == 'setBirthday',
        orElse: () => throw Exception('setBirthday method not called'),
      );

      expect(birthdayCall.arguments, isA<Map>());
      final args = Map<String, dynamic>.from(birthdayCall.arguments as Map);
      expect(args['key'], equals('setBirthday'));
      expect(args['value'], equals(expectedEpoch.toString()));
    });

    test('setCustomAttributeWithDate converts DateTime to epoch milliseconds string', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      final DateTime testDate = DateTime(2024, 6, 15, 10, 30, 0);
      final int expectedEpoch = testDate.millisecondsSinceEpoch;
      const String customKey = 'custom_date_attribute';

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      final user = FlutterInsider.Instance.getCurrentUser();
      expect(user, isNotNull, reason: 'User should be initialized after initFlutterBase');
      user!.setCustomAttributeWithDate(customKey, testDate);

      expect(methodCalls.length, greaterThan(0));
      final customDateCall = methodCalls.firstWhere(
        (call) => call.method == 'setCustomAttributeWithDate',
        orElse: () => throw Exception('setCustomAttributeWithDate method not called'),
      );

      expect(customDateCall.arguments, isA<Map>());
      final args = Map<String, dynamic>.from(customDateCall.arguments as Map);
      expect(args['key'], equals(customKey));
      expect(args['value'], equals(expectedEpoch.toString()));
    });

    test('setBirthday handles different DateTime values correctly', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      final testDates = [
        DateTime(1970, 1, 1),
        DateTime(2000, 1, 1),
        DateTime(2024, 12, 31, 23, 59, 59),
        DateTime.now(),
      ];

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      final user = FlutterInsider.Instance.getCurrentUser();
      expect(user, isNotNull, reason: 'User should be initialized after initFlutterBase');

      for (final date in testDates) {
        user!.setBirthday(date);
        final expectedEpoch = date.millisecondsSinceEpoch;

        final birthdayCall = methodCalls.firstWhere(
          (call) {
            if (call.method != 'setBirthday') return false;
            final args = Map<String, dynamic>.from(call.arguments as Map);
            return args['value'] == expectedEpoch.toString();
          },
          orElse: () => throw Exception('setBirthday not called with correct epoch for ${date.toIso8601String()}'),
        );

        final args = Map<String, dynamic>.from(birthdayCall.arguments as Map);
        expect(args['value'], equals(expectedEpoch.toString()));
      }
    });
  });

  group('Cart Events saleID Tests', () {
    test('visitCartPage sends saleID in args when provided', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);

      final product = FlutterInsider.Instance.createNewProduct(
        'PROD1', 'Test Product', ['cat'], 'https://img.url', 9.99, 'USD');
      await FlutterInsider.Instance.visitCartPage([product], saleID: 'SALE-123');

      final call = methodCalls.firstWhere(
        (c) => c.method == 'visitCartPage',
        orElse: () => throw Exception('visitCartPage method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args['saleID'], equals('SALE-123'));
    });

    test('visitCartPage does NOT send saleID key when saleID is null', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);

      final product = FlutterInsider.Instance.createNewProduct(
        'PROD1', 'Test Product', ['cat'], 'https://img.url', 9.99, 'USD');
      await FlutterInsider.Instance.visitCartPage([product]);

      final call = methodCalls.firstWhere(
        (c) => c.method == 'visitCartPage',
        orElse: () => throw Exception('visitCartPage method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args.containsKey('saleID'), isFalse);
    });

    test('visitCartPage does NOT send saleID key when saleID is empty string', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);

      final product = FlutterInsider.Instance.createNewProduct(
        'PROD1', 'Test Product', ['cat'], 'https://img.url', 9.99, 'USD');
      await FlutterInsider.Instance.visitCartPage([product], saleID: '');

      final call = methodCalls.firstWhere(
        (c) => c.method == 'visitCartPage',
        orElse: () => throw Exception('visitCartPage method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args.containsKey('saleID'), isFalse);
    });

    test('itemRemovedFromCart sends saleID in args when provided', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      await FlutterInsider.Instance.itemRemovedFromCart('PROD1', saleID: 'SALE-456');

      final call = methodCalls.firstWhere(
        (c) => c.method == 'itemRemovedFromCart',
        orElse: () => throw Exception('itemRemovedFromCart method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args['productID'], equals('PROD1'));
      expect(args['saleID'], equals('SALE-456'));
    });

    test('itemRemovedFromCart does NOT send saleID key when saleID is null', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      await FlutterInsider.Instance.itemRemovedFromCart('PROD1');

      final call = methodCalls.firstWhere(
        (c) => c.method == 'itemRemovedFromCart',
        orElse: () => throw Exception('itemRemovedFromCart method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args.containsKey('saleID'), isFalse);
    });

    test('itemRemovedFromCart does NOT send saleID key when saleID is empty string', () async {
      final List<MethodCall> methodCalls = [];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      await FlutterInsider.Instance.initFlutterBase('test_partner', 'test_group', null);
      await FlutterInsider.Instance.itemRemovedFromCart('PROD1', saleID: '');

      final call = methodCalls.firstWhere(
        (c) => c.method == 'itemRemovedFromCart',
        orElse: () => throw Exception('itemRemovedFromCart method not called'),
      );
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args.containsKey('saleID'), isFalse);
    });
  });
}
