enum ChatVoiceProvider {
  custom('HTTP 服务');

  const ChatVoiceProvider(this.label);

  final String label;
}

enum ChatNetworkProxyType {
  http('HTTP');

  const ChatNetworkProxyType(this.label);

  final String label;
}

enum ChatPromptInjectionPosition {
  systemPrefix('系统前置'),
  userPrefix('用户前置'),
  messageSuffix('消息后置');

  const ChatPromptInjectionPosition(this.label);

  final String label;
}

enum ChatStorageRetentionPolicy {
  forever('永久保留'),
  thirtyDays('30 天'),
  ninetyDays('90 天');

  const ChatStorageRetentionPolicy(this.label);

  final String label;
}

class ChatVoiceSettings {
  const ChatVoiceSettings({
    this.enabled = false,
    this.provider = ChatVoiceProvider.custom,
    this.endpoint = '',
    this.speaker = '默认',
    this.streaming = true,
    this.timeout = const Duration(seconds: 8),
  });

  final bool enabled;
  final ChatVoiceProvider provider;
  final String endpoint;
  final String speaker;
  final bool streaming;
  final Duration timeout;

  String get summary {
    if (!enabled) {
      return '关闭';
    }

    return provider.label;
  }

  ChatVoiceSettings copyWith({
    bool? enabled,
    ChatVoiceProvider? provider,
    String? endpoint,
    String? speaker,
    bool? streaming,
    Duration? timeout,
  }) {
    return ChatVoiceSettings(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      endpoint: endpoint ?? this.endpoint,
      speaker: speaker ?? this.speaker,
      streaming: streaming ?? this.streaming,
      timeout: _clampTimeout(timeout ?? this.timeout),
    );
  }

  static Duration _clampTimeout(Duration value) {
    if (value < const Duration(seconds: 1)) {
      return const Duration(seconds: 1);
    }

    if (value > const Duration(seconds: 60)) {
      return const Duration(seconds: 60);
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatVoiceSettings &&
            other.enabled == enabled &&
            other.provider == provider &&
            other.endpoint == endpoint &&
            other.speaker == speaker &&
            other.streaming == streaming &&
            other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      provider,
      endpoint,
      speaker,
      streaming,
      timeout,
    );
  }
}

class ChatNetworkProxySettings {
  const ChatNetworkProxySettings({
    this.enabled = false,
    this.type = ChatNetworkProxyType.http,
    this.server = '127.0.0.1',
    this.port = 8080,
    this.username = '',
    this.password = '',
    this.bypassRules = const <String>[
      'localhost',
      '127.0.0.1',
      '10.0.0.0/8',
      '172.16.0.0/12',
      '192.168.0.0/16',
      '::1',
    ],
    this.testUrl = 'https://example.com',
  })  : assert(port > 0),
        assert(port <= 65535);

  final bool enabled;
  final ChatNetworkProxyType type;
  final String server;
  final int port;
  final String username;
  final String password;
  final List<String> bypassRules;
  final String testUrl;

  String get summary {
    if (!enabled) {
      return '直连';
    }

    return '${type.label} $server:$port';
  }

  ChatNetworkProxySettings copyWith({
    bool? enabled,
    ChatNetworkProxyType? type,
    String? server,
    int? port,
    String? username,
    String? password,
    List<String>? bypassRules,
    String? testUrl,
  }) {
    return ChatNetworkProxySettings(
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      server: _normalizeServer(server ?? this.server),
      port: _clampPort(port ?? this.port),
      username: username ?? this.username,
      password: password ?? this.password,
      bypassRules: List<String>.unmodifiable(
        (bypassRules ?? this.bypassRules)
            .map((rule) => rule.trim())
            .where((rule) => rule.isNotEmpty),
      ),
      testUrl: testUrl ?? this.testUrl,
    );
  }

  static String _normalizeServer(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '127.0.0.1' : trimmed;
  }

  static int _clampPort(int value) {
    return value.clamp(1, 65535).toInt();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatNetworkProxySettings &&
            other.enabled == enabled &&
            other.type == type &&
            other.server == server &&
            other.port == port &&
            other.username == username &&
            other.password == password &&
            _listEquals(other.bypassRules, bypassRules) &&
            other.testUrl == testUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      type,
      server,
      port,
      username,
      password,
      Object.hashAll(bypassRules),
      testUrl,
    );
  }
}

class ChatQuickPhrase {
  const ChatQuickPhrase({
    required this.id,
    required this.title,
    required this.content,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String content;
  final bool enabled;

  ChatQuickPhrase copyWith({
    String? id,
    String? title,
    String? content,
    bool? enabled,
  }) {
    return ChatQuickPhrase(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatQuickPhrase &&
            other.id == id &&
            other.title == title &&
            other.content == content &&
            other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(id, title, content, enabled);
}

class ChatWorldBookEntry {
  const ChatWorldBookEntry({
    required this.id,
    required this.title,
    required this.content,
    this.keywords = const <String>[],
    this.enabled = true,
  });

  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final bool enabled;

  ChatWorldBookEntry copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? keywords,
    bool? enabled,
  }) {
    return ChatWorldBookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      keywords: List<String>.unmodifiable(
        (keywords ?? this.keywords)
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty),
      ),
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatWorldBookEntry &&
            other.id == id &&
            other.title == title &&
            other.content == content &&
            _listEquals(other.keywords, keywords) &&
            other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, Object.hashAll(keywords), enabled);
  }
}

class ChatWorldBookSettings {
  const ChatWorldBookSettings({
    this.enabled = true,
    this.maxActiveEntries = 4,
    this.entries = const <ChatWorldBookEntry>[],
  });

  final bool enabled;
  final int maxActiveEntries;
  final List<ChatWorldBookEntry> entries;

  String get summary {
    if (!enabled) {
      return '关闭';
    }

    final enabledCount = entries.where((entry) => entry.enabled).length;
    return '$enabledCount 条启用';
  }

  ChatWorldBookSettings copyWith({
    bool? enabled,
    int? maxActiveEntries,
    List<ChatWorldBookEntry>? entries,
  }) {
    return ChatWorldBookSettings(
      enabled: enabled ?? this.enabled,
      maxActiveEntries:
          (maxActiveEntries ?? this.maxActiveEntries).clamp(1, 20).toInt(),
      entries: List<ChatWorldBookEntry>.unmodifiable(entries ?? this.entries),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatWorldBookSettings &&
            other.enabled == enabled &&
            other.maxActiveEntries == maxActiveEntries &&
            _listEquals(other.entries, entries);
  }

  @override
  int get hashCode {
    return Object.hash(enabled, maxActiveEntries, Object.hashAll(entries));
  }
}

class ChatPromptInjectionRule {
  const ChatPromptInjectionRule({
    required this.id,
    required this.title,
    required this.content,
    this.position = ChatPromptInjectionPosition.systemPrefix,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String content;
  final ChatPromptInjectionPosition position;
  final bool enabled;

  ChatPromptInjectionRule copyWith({
    String? id,
    String? title,
    String? content,
    ChatPromptInjectionPosition? position,
    bool? enabled,
  }) {
    return ChatPromptInjectionRule(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      position: position ?? this.position,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatPromptInjectionRule &&
            other.id == id &&
            other.title == title &&
            other.content == content &&
            other.position == position &&
            other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, position, enabled);
  }
}

class ChatPromptInjectionSettings {
  const ChatPromptInjectionSettings({
    this.enabled = true,
    this.rules = const <ChatPromptInjectionRule>[],
  });

  final bool enabled;
  final List<ChatPromptInjectionRule> rules;

  String get summary {
    if (!enabled) {
      return '关闭';
    }

    final enabledCount = rules.where((rule) => rule.enabled).length;
    return '$enabledCount 条启用';
  }

  ChatPromptInjectionSettings copyWith({
    bool? enabled,
    List<ChatPromptInjectionRule>? rules,
  }) {
    return ChatPromptInjectionSettings(
      enabled: enabled ?? this.enabled,
      rules: List<ChatPromptInjectionRule>.unmodifiable(rules ?? this.rules),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatPromptInjectionSettings &&
            other.enabled == enabled &&
            _listEquals(other.rules, rules);
  }

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(rules));
}

class ChatStorageSettings {
  const ChatStorageSettings({
    this.autoSaveConversations = true,
    this.saveDrafts = true,
    this.retentionPolicy = ChatStorageRetentionPolicy.forever,
    this.maxLocalConversations = 100,
  });

  final bool autoSaveConversations;
  final bool saveDrafts;
  final ChatStorageRetentionPolicy retentionPolicy;
  final int maxLocalConversations;

  String get summary {
    if (!autoSaveConversations) {
      return '不保存';
    }

    return retentionPolicy.label;
  }

  ChatStorageSettings copyWith({
    bool? autoSaveConversations,
    bool? saveDrafts,
    ChatStorageRetentionPolicy? retentionPolicy,
    int? maxLocalConversations,
  }) {
    return ChatStorageSettings(
      autoSaveConversations:
          autoSaveConversations ?? this.autoSaveConversations,
      saveDrafts: saveDrafts ?? this.saveDrafts,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      maxLocalConversations:
          (maxLocalConversations ?? this.maxLocalConversations)
              .clamp(1, 500)
              .toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatStorageSettings &&
            other.autoSaveConversations == autoSaveConversations &&
            other.saveDrafts == saveDrafts &&
            other.retentionPolicy == retentionPolicy &&
            other.maxLocalConversations == maxLocalConversations;
  }

  @override
  int get hashCode {
    return Object.hash(
      autoSaveConversations,
      saveDrafts,
      retentionPolicy,
      maxLocalConversations,
    );
  }
}

class ChatAppSettings {
  const ChatAppSettings({
    this.voice = const ChatVoiceSettings(),
    this.quickPhrases = const <ChatQuickPhrase>[],
    this.networkProxy = const ChatNetworkProxySettings(),
    this.worldBook = const ChatWorldBookSettings(),
    this.promptInjection = const ChatPromptInjectionSettings(),
    this.storage = const ChatStorageSettings(),
  });

  final ChatVoiceSettings voice;
  final List<ChatQuickPhrase> quickPhrases;
  final ChatNetworkProxySettings networkProxy;
  final ChatWorldBookSettings worldBook;
  final ChatPromptInjectionSettings promptInjection;
  final ChatStorageSettings storage;

  ChatAppSettings copyWith({
    ChatVoiceSettings? voice,
    List<ChatQuickPhrase>? quickPhrases,
    ChatNetworkProxySettings? networkProxy,
    ChatWorldBookSettings? worldBook,
    ChatPromptInjectionSettings? promptInjection,
    ChatStorageSettings? storage,
  }) {
    return ChatAppSettings(
      voice: voice ?? this.voice,
      quickPhrases:
          List<ChatQuickPhrase>.unmodifiable(quickPhrases ?? this.quickPhrases),
      networkProxy: networkProxy ?? this.networkProxy,
      worldBook: worldBook ?? this.worldBook,
      promptInjection: promptInjection ?? this.promptInjection,
      storage: storage ?? this.storage,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatAppSettings &&
            other.voice == voice &&
            _listEquals(other.quickPhrases, quickPhrases) &&
            other.networkProxy == networkProxy &&
            other.worldBook == worldBook &&
            other.promptInjection == promptInjection &&
            other.storage == storage;
  }

  @override
  int get hashCode {
    return Object.hash(
      voice,
      Object.hashAll(quickPhrases),
      networkProxy,
      worldBook,
      promptInjection,
      storage,
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }

  return true;
}
