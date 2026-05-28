import 'dart:convert';

import '../../domain/entities/chat_app_settings.dart';

class ChatAppSettingsCodec {
  const ChatAppSettingsCodec._();

  static String encode(ChatAppSettings settings) {
    return jsonEncode(toJson(settings));
  }

  static ChatAppSettings decode(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('应用设置格式无效');
    }

    return fromJson(value);
  }

  static Map<String, dynamic> toJson(ChatAppSettings settings) {
    return <String, dynamic>{
      'version': 1,
      'voice': _voiceToJson(settings.voice),
      'quickPhrases': settings.quickPhrases.map(_quickPhraseToJson).toList(),
      'networkProxy': _networkProxyToJson(settings.networkProxy),
      'worldBook': _worldBookToJson(settings.worldBook),
      'promptInjection': _promptInjectionToJson(settings.promptInjection),
      'storage': _storageToJson(settings.storage),
    };
  }

  static ChatAppSettings fromJson(Map<String, dynamic> value) {
    const defaults = ChatAppSettings();
    return defaults.copyWith(
      voice: _voiceFromJson(value['voice'], defaults.voice),
      quickPhrases: _listValue(value['quickPhrases'])
          .map(_quickPhraseFromJson)
          .whereType<ChatQuickPhrase>()
          .toList(growable: false),
      networkProxy: _networkProxyFromJson(
        value['networkProxy'],
        defaults.networkProxy,
      ),
      worldBook: _worldBookFromJson(value['worldBook'], defaults.worldBook),
      promptInjection: _promptInjectionFromJson(
        value['promptInjection'],
        defaults.promptInjection,
      ),
      storage: _storageFromJson(value['storage'], defaults.storage),
    );
  }

  static Map<String, dynamic> _voiceToJson(ChatVoiceSettings settings) {
    return <String, dynamic>{
      'enabled': settings.enabled,
      'provider': settings.provider.name,
      'endpoint': settings.endpoint,
      'speaker': settings.speaker,
      'streaming': settings.streaming,
      'timeoutMs': settings.timeout.inMilliseconds,
    };
  }

  static ChatVoiceSettings _voiceFromJson(
    Object? source,
    ChatVoiceSettings fallback,
  ) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }

    return fallback.copyWith(
      enabled: _boolValue(source['enabled'], fallback.enabled),
      provider: _enumValue(
        ChatVoiceProvider.values,
        source['provider'],
        fallback.provider,
      ),
      endpoint: _trimmedStringValue(source['endpoint'], fallback.endpoint),
      speaker: _nonBlankStringValue(source['speaker'], fallback.speaker),
      streaming: _boolValue(source['streaming'], fallback.streaming),
      timeout: Duration(
        milliseconds: _intValue(
          source['timeoutMs'],
          fallback.timeout.inMilliseconds,
        ),
      ),
    );
  }

  static Map<String, dynamic> _quickPhraseToJson(ChatQuickPhrase phrase) {
    return <String, dynamic>{
      'id': phrase.id,
      'title': phrase.title,
      'content': phrase.content,
      'enabled': phrase.enabled,
    };
  }

  static ChatQuickPhrase? _quickPhraseFromJson(Object? source) {
    if (source is! Map<String, dynamic>) {
      return null;
    }

    final id = _requiredString(source['id']);
    final title = _requiredString(source['title']);
    final content = _requiredString(source['content']);
    if (id == null || title == null || content == null) {
      return null;
    }

    return ChatQuickPhrase(
      id: id,
      title: title,
      content: content,
      enabled: _boolValue(source['enabled'], true),
    );
  }

  static Map<String, dynamic> _networkProxyToJson(
    ChatNetworkProxySettings settings,
  ) {
    return <String, dynamic>{
      'enabled': settings.enabled,
      'type': settings.type.name,
      'server': settings.server,
      'port': settings.port,
      'username': settings.username,
      'password': settings.password,
      'bypassRules': settings.bypassRules,
      'testUrl': settings.testUrl,
    };
  }

  static ChatNetworkProxySettings _networkProxyFromJson(
    Object? source,
    ChatNetworkProxySettings fallback,
  ) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }

    return fallback.copyWith(
      enabled: _boolValue(source['enabled'], fallback.enabled),
      type: _enumValue(
        ChatNetworkProxyType.values,
        source['type'],
        fallback.type,
      ),
      server: _stringValue(source['server'], fallback.server),
      port: _intValue(source['port'], fallback.port),
      username: _trimmedStringValue(source['username'], fallback.username),
      password: _stringValue(source['password'], fallback.password),
      bypassRules:
          _stringListValueOrNull(source['bypassRules']) ?? fallback.bypassRules,
      testUrl: _nonBlankStringValue(source['testUrl'], fallback.testUrl),
    );
  }

  static Map<String, dynamic> _worldBookToJson(
    ChatWorldBookSettings settings,
  ) {
    return <String, dynamic>{
      'enabled': settings.enabled,
      'maxActiveEntries': settings.maxActiveEntries,
      'entries': settings.entries.map(_worldBookEntryToJson).toList(),
    };
  }

  static ChatWorldBookSettings _worldBookFromJson(
    Object? source,
    ChatWorldBookSettings fallback,
  ) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }

    return fallback.copyWith(
      enabled: _boolValue(source['enabled'], fallback.enabled),
      maxActiveEntries: _intValue(
        source['maxActiveEntries'],
        fallback.maxActiveEntries,
      ),
      entries: _listValue(source['entries'])
          .map(_worldBookEntryFromJson)
          .whereType<ChatWorldBookEntry>()
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _worldBookEntryToJson(
    ChatWorldBookEntry entry,
  ) {
    return <String, dynamic>{
      'id': entry.id,
      'title': entry.title,
      'content': entry.content,
      'keywords': entry.keywords,
      'enabled': entry.enabled,
    };
  }

  static ChatWorldBookEntry? _worldBookEntryFromJson(Object? source) {
    if (source is! Map<String, dynamic>) {
      return null;
    }

    final id = _requiredString(source['id']);
    final title = _requiredString(source['title']);
    final content = _requiredString(source['content']);
    if (id == null || title == null || content == null) {
      return null;
    }

    return ChatWorldBookEntry(
      id: id,
      title: title,
      content: content,
      keywords: _stringListValue(source['keywords']),
      enabled: _boolValue(source['enabled'], true),
    );
  }

  static Map<String, dynamic> _promptInjectionToJson(
    ChatPromptInjectionSettings settings,
  ) {
    return <String, dynamic>{
      'enabled': settings.enabled,
      'rules': settings.rules.map(_promptRuleToJson).toList(),
    };
  }

  static ChatPromptInjectionSettings _promptInjectionFromJson(
    Object? source,
    ChatPromptInjectionSettings fallback,
  ) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }

    return fallback.copyWith(
      enabled: _boolValue(source['enabled'], fallback.enabled),
      rules: _listValue(source['rules'])
          .map(_promptRuleFromJson)
          .whereType<ChatPromptInjectionRule>()
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _promptRuleToJson(
    ChatPromptInjectionRule rule,
  ) {
    return <String, dynamic>{
      'id': rule.id,
      'title': rule.title,
      'content': rule.content,
      'position': rule.position.name,
      'enabled': rule.enabled,
    };
  }

  static ChatPromptInjectionRule? _promptRuleFromJson(Object? source) {
    if (source is! Map<String, dynamic>) {
      return null;
    }

    final id = _requiredString(source['id']);
    final title = _requiredString(source['title']);
    final content = _requiredString(source['content']);
    if (id == null || title == null || content == null) {
      return null;
    }

    return ChatPromptInjectionRule(
      id: id,
      title: title,
      content: content,
      position: _enumValue(
        ChatPromptInjectionPosition.values,
        source['position'],
        ChatPromptInjectionPosition.systemPrefix,
      ),
      enabled: _boolValue(source['enabled'], true),
    );
  }

  static Map<String, dynamic> _storageToJson(ChatStorageSettings settings) {
    return <String, dynamic>{
      'autoSaveConversations': settings.autoSaveConversations,
      'saveDrafts': settings.saveDrafts,
      'retentionPolicy': settings.retentionPolicy.name,
      'maxLocalConversations': settings.maxLocalConversations,
    };
  }

  static ChatStorageSettings _storageFromJson(
    Object? source,
    ChatStorageSettings fallback,
  ) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }

    return fallback.copyWith(
      autoSaveConversations: _boolValue(
        source['autoSaveConversations'],
        fallback.autoSaveConversations,
      ),
      saveDrafts: _boolValue(source['saveDrafts'], fallback.saveDrafts),
      retentionPolicy: _enumValue(
        ChatStorageRetentionPolicy.values,
        source['retentionPolicy'],
        fallback.retentionPolicy,
      ),
      maxLocalConversations: _intValue(
        source['maxLocalConversations'],
        fallback.maxLocalConversations,
      ),
    );
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    Object? source,
    T fallback,
  ) {
    if (source is! String) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == source) {
        return value;
      }
    }

    return fallback;
  }

  static bool _boolValue(Object? source, bool fallback) {
    return source is bool ? source : fallback;
  }

  static int _intValue(Object? source, int fallback) {
    return source is int ? source : fallback;
  }

  static String _stringValue(Object? source, String fallback) {
    return source is String ? source : fallback;
  }

  static String _trimmedStringValue(Object? source, String fallback) {
    return source is String ? source.trim() : fallback;
  }

  static String _nonBlankStringValue(Object? source, String fallback) {
    final value = _trimmedStringValue(source, fallback);
    return value.isEmpty ? fallback : value;
  }

  static String? _requiredString(Object? source) {
    if (source is! String) {
      return null;
    }

    final trimmed = source.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<Object?> _listValue(Object? source) {
    return source is List ? source : const <Object?>[];
  }

  static List<String> _stringListValue(Object? source) {
    return _stringListValueOrNull(source) ?? const <String>[];
  }

  static List<String>? _stringListValueOrNull(Object? source) {
    if (source is! List) {
      return null;
    }

    return source
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
}
