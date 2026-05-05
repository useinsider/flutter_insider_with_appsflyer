import 'dart:convert';
import '../enum/InsiderAppCardActionType.dart';
import '../flutter_insider.dart' show FlutterInsider;

class InsiderAppCardContent {
  String title;
  String description;

  InsiderAppCardContent({
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
    };
  }

  static InsiderAppCardContent? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['title'] == null || map['description'] == null) {
      return null;
    }

    return InsiderAppCardContent(
      title: map['title'] as String,
      description: map['description'] as String,
    );
  }
}

class InsiderAppCardImage {
  String url;

  InsiderAppCardImage({required this.url});

  Map<String, dynamic> toMap() {
    return {
      'url': url,
    };
  }

  static InsiderAppCardImage? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['url'] == null) {
      return null;
    }

    return InsiderAppCardImage(
      url: map['url'] as String,
    );
  }
}

abstract class InsiderAppCardAction {
  String actionType;

  InsiderAppCardAction({required this.actionType});

  Map<String, dynamic> toMap();
}

class InsiderAppCardDeeplinkAction extends InsiderAppCardAction {
  final String? _urlScheme;
  final String? _internalBrowserUrl;
  final String? _externalBrowserUrl;
  final Map<String, dynamic>? _json;
  final List<Map<String, String>>? _keysAndValues;

  InsiderAppCardDeeplinkAction({
    String? urlScheme,
    String? internalBrowserUrl,
    String? externalBrowserUrl,
    Map<String, dynamic>? json,
    List<Map<String, String>>? keysAndValues,
  })  : _urlScheme = urlScheme,
        _internalBrowserUrl = internalBrowserUrl,
        _externalBrowserUrl = externalBrowserUrl,
        _json = json,
        _keysAndValues = keysAndValues,
        super(actionType: InsiderAppCardActionType.DEEP_LINK);

  String get url {
    return _urlScheme ?? _internalBrowserUrl ?? _externalBrowserUrl ?? '';
  }

  Map<String, dynamic>? get json => _json;

  List<Map<String, String>>? get keysAndValues => _keysAndValues;

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': actionType,
    };

    if (_urlScheme != null) {
      map['url_scheme'] = _urlScheme;
    }
    if (_internalBrowserUrl != null) {
      map['internal_browser_url'] = _internalBrowserUrl;
    }
    if (_externalBrowserUrl != null) {
      map['external_browser_url'] = _externalBrowserUrl;
    }
    if (_json != null) {
      map['json'] = jsonEncode(_json);
    }
    if (_keysAndValues != null) {
      map['key_value'] = _keysAndValues;
    }

    return map;
  }

  static InsiderAppCardDeeplinkAction? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['type'] != InsiderAppCardActionType.DEEP_LINK) {
      return null;
    }

    Map<String, dynamic>? jsonMap;
    final rawJson = map['json'];
    if (rawJson is String && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          jsonMap = decoded;
        }
      } catch (_) {
        jsonMap = null;
      }
    } else if (rawJson is Map) {
      jsonMap = Map<String, dynamic>.from(rawJson);
    }

    List<Map<String, String>>? keysAndValuesList;
    if (map['key_value'] != null && map['key_value'] is List) {
      keysAndValuesList = (map['key_value'] as List)
          .map((item) {
            if (item is Map) {
              return Map<String, String>.from(
                item.map((k, v) => MapEntry(k.toString(), v.toString()))
              );
            }
            return null;
          })
          .whereType<Map<String, String>>()
          .toList();
    }

    return InsiderAppCardDeeplinkAction(
      urlScheme: map['url_scheme'] as String?,
      internalBrowserUrl: map['internal_browser_url'] as String?,
      externalBrowserUrl: map['external_browser_url'] as String?,
      json: jsonMap,
      keysAndValues: keysAndValuesList,
    );
  }
}

class InsiderAppCardOpenSettingsAction
    extends InsiderAppCardAction {
  InsiderAppCardOpenSettingsAction()
      : super(actionType: InsiderAppCardActionType.OPEN_SETTINGS);

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': actionType,
    };
  }

  static InsiderAppCardOpenSettingsAction? fromMap(
      Map<String, dynamic>? map) {
    if (map == null || map['type'] != InsiderAppCardActionType.OPEN_SETTINGS) {
      return null;
    }
    return InsiderAppCardOpenSettingsAction();
  }
}

class InsiderAppCardFeedbackAction extends InsiderAppCardAction {
  InsiderAppCardFeedbackAction()
      : super(actionType: InsiderAppCardActionType.FEEDBACK);

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': actionType,
    };
  }

  static InsiderAppCardFeedbackAction? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['type'] != InsiderAppCardActionType.FEEDBACK) {
      return null;
    }
    return InsiderAppCardFeedbackAction();
  }
}

class InsiderAppCardButton {
  String id;
  String text;
  String? appCardId;
  InsiderAppCardAction? action;

  InsiderAppCardButton({
    required this.id,
    required this.text,
    this.appCardId,
    this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'action': action?.toMap(),
    };
  }

  static InsiderAppCardButton? fromMap(
      Map<String, dynamic>? map) {
    if (map == null ||
        map['id'] == null ||
        map['text'] == null) {
      return null;
    }

    InsiderAppCardAction? action;
    if (map['action'] != null) {
      final actionMap = Map<String, dynamic>.from(map['action']);
      final actionType = actionMap['type'] as String?;

      if (actionType == InsiderAppCardActionType.DEEP_LINK) {
        action = InsiderAppCardDeeplinkAction.fromMap(actionMap);
      } else if (actionType == InsiderAppCardActionType.OPEN_SETTINGS) {
        action = InsiderAppCardOpenSettingsAction.fromMap(actionMap);
      } else if (actionType == InsiderAppCardActionType.FEEDBACK) {
        action = InsiderAppCardFeedbackAction.fromMap(actionMap);
      }
    }

    return InsiderAppCardButton(
      id: map['id'] as String,
      text: map['text'] as String,
      appCardId: map['appCardId'] as String?,
      action: action,
    );
  }

  void click() {
    FlutterInsider.Instance.appCards.clickButton(this);
  }
}

class InsiderAppCard {
  String id;
  String type;
  bool isRead;
  List<InsiderAppCardImage>? images;
  InsiderAppCardContent? content;
  List<InsiderAppCardButton>? buttons;
  InsiderAppCardAction? action;

  InsiderAppCard({
    required this.id,
    required this.type,
    this.isRead = false,
    this.images,
    this.content,
    this.buttons,
    this.action,
  });

  Future<void> markAsRead() async {
    try {
      await FlutterInsider.Instance.appCards.markAsRead([id]);
      isRead = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsUnread() async {
    try {
      await FlutterInsider.Instance.appCards.markAsUnread([id]);
      isRead = false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete() async {
    try {
      await FlutterInsider.Instance.appCards.delete([id]);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'read': isRead,
      'images': images?.map((img) => img.toMap()).toList(),
      'content': content?.toMap(),
      'buttons': buttons?.map((btn) => btn.toMap()).toList(),
      'action': action?.toMap(),
    };
  }

  void view() {
    FlutterInsider.Instance.appCards.view(this);
  }

  void click() {
    FlutterInsider.Instance.appCards.click(this);
  }

  static InsiderAppCard? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }

    final id = map['id'];
    final type = map['type'];
    final isRead = map['read'] ?? false;

    if (id == null || type == null) {
      return null;
    }

    List<InsiderAppCardImage>? images;
    if (map['images'] != null && map['images'] is List) {
      images = (map['images'] as List)
          .map((img) => InsiderAppCardImage.fromMap(
          Map<String, dynamic>.from(img)))
          .whereType<InsiderAppCardImage>()
          .toList();
    }

    InsiderAppCardContent? content;
    if (map['content'] != null) {
      content = InsiderAppCardContent.fromMap(
          Map<String, dynamic>.from(map['content']));
    }

    List<InsiderAppCardButton>? buttons;
    if (map['buttons'] != null && map['buttons'] is List) {
      buttons = (map['buttons'] as List)
          .map((btn) {
            final btnMap = Map<String, dynamic>.from(btn);
            if (btnMap['appCardId'] == null) {
              btnMap['appCardId'] = id;
            }
            return InsiderAppCardButton.fromMap(btnMap);
          })
          .whereType<InsiderAppCardButton>()
          .toList();
    }

    InsiderAppCardAction? action;
    if (map['action'] != null) {
      final actionMap = Map<String, dynamic>.from(map['action']);
      final actionType = actionMap['type'] as String?;

      if (actionType == InsiderAppCardActionType.DEEP_LINK) {
        action = InsiderAppCardDeeplinkAction.fromMap(actionMap);
      } else if (actionType == InsiderAppCardActionType.OPEN_SETTINGS) {
        action = InsiderAppCardOpenSettingsAction.fromMap(actionMap);
      } else if (actionType == InsiderAppCardActionType.FEEDBACK) {
        action = InsiderAppCardFeedbackAction.fromMap(actionMap);
      }
    }

    return InsiderAppCard(
      id: id as String,
      type: type as String,
      isRead: isRead as bool,
      images: images,
      content: content,
      buttons: buttons,
      action: action,
    );
  }
}

class InsiderAppCardCampaignsResponse {
  List<InsiderAppCard> appCards;

  InsiderAppCardCampaignsResponse({required this.appCards});

  Map<String, dynamic> toMap() {
    return {
      'appCards': appCards.map((card) => card.toMap()).toList(),
    };
  }

  static InsiderAppCardCampaignsResponse? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }

    final cardsList = map['items'] ;

    if (cardsList == null || cardsList is! List) {
      return InsiderAppCardCampaignsResponse(appCards: []);
    }

    final cards = (cardsList)
        .map((card) => InsiderAppCard.fromMap(
        Map<String, dynamic>.from(card)))
        .whereType<InsiderAppCard>()
        .toList();

    return InsiderAppCardCampaignsResponse(appCards: cards);
  }
}
