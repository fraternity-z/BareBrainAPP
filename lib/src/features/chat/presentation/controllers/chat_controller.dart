import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/entities/chat_conversation_summary.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/repositories/chat_conversation_catalog_store.dart';
import '../../domain/repositories/chat_session_store.dart';
import '../../domain/repositories/chat_voice_output.dart';
import '../../domain/services/chat_conversation_title_builder.dart';
import '../../domain/services/chat_connection_settings_parser.dart';
import '../../domain/services/chat_route_id_builder.dart';
import '../../domain/usecases/check_chat_connection.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../data/models/chat_conversation_catalog_codec.dart';
import '../../data/models/chat_session_snapshot_codec.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required SendChatMessage sendChatMessage,
    required ChatConnectionSettings initialSettings,
    CheckChatConnection? checkConnection,
    ChatSessionStore? sessionStore,
    ChatSessionStoreFactory? sessionStoreFactory,
    ChatConversationCatalogStore? catalogStore,
    ChatStorageSettings storageSettings = const ChatStorageSettings(),
    ChatVoiceSettings voiceSettings = const ChatVoiceSettings(),
    ChatVoiceOutput? voiceOutput,
    String conversationId = 'default',
    String conversationTitle = 'BareBrain',
  })  : _sendChatMessage = sendChatMessage,
        _checkConnection = checkConnection,
        _settings = initialSettings,
        _fixedSessionStore = sessionStore,
        _sessionStoreFactory = sessionStoreFactory,
        _sessionStore = sessionStoreFactory?.forConversation(conversationId) ??
            sessionStore,
        _catalogStore = catalogStore,
        _storageSettings = storageSettings,
        _voiceSettings = voiceSettings,
        _voiceOutput = voiceOutput,
        _conversationId = conversationId,
        _conversationTitle = conversationTitle;

  final SendChatMessage _sendChatMessage;
  final CheckChatConnection? _checkConnection;
  final ChatSessionStore? _fixedSessionStore;
  final ChatSessionStoreFactory? _sessionStoreFactory;
  final ChatSessionStore? _sessionStore;
  final ChatConversationCatalogStore? _catalogStore;
  ChatStorageSettings _storageSettings;
  ChatVoiceSettings _voiceSettings;
  final ChatVoiceOutput? _voiceOutput;
  String _conversationId;
  String _conversationTitle;
  ChatConnectionSettings _settings;
  ChatSessionStore? _activeSessionStore;
  final List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatConversationSummary> _conversations = <ChatConversationSummary>[];
  String _draft = '';
  bool _isSending = false;
  bool _isDisposed = false;
  String? _errorMessage;

  ChatConnectionSettings get settings => _settings;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get draft => _draft;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String get conversationId => _conversationId;
  bool get canRetryLastMessage {
    return !_isSending && _lastRetryableUserMessageIndex() != null;
  }

  String? get lastRetryableUserMessageContent {
    final index = _lastRetryableUserMessageIndex();
    return index == null ? null : _messages[index].content;
  }

  String get bareBrainChatId {
    return ChatRouteIdBuilder.build(
      clientId: _settings.clientId,
      conversationId: _conversationId,
    );
  }

  List<ChatConversationSummary> get conversations {
    return List<ChatConversationSummary>.unmodifiable(_conversations);
  }

  Future<ChatStorageUsage> loadStorageUsage() async {
    await _saveSnapshot();
    await _saveCatalogSummary();

    final storedCatalog = await _catalogStore?.load();
    final catalog = storedCatalog ??
        ChatConversationCatalog(
          activeConversationId: _conversationId,
          conversations: _conversations,
        );

    final seenConversationIds = <String>{};
    var messageCount = 0;
    var draftCount = 0;
    var snapshotBytes = 0;
    DateTime? lastUpdated;

    for (final conversation in catalog.conversations) {
      if (!seenConversationIds.add(conversation.id)) {
        continue;
      }

      final updatedAt = conversation.updatedAt;
      if (lastUpdated == null || updatedAt.isAfter(lastUpdated)) {
        lastUpdated = updatedAt;
      }

      final snapshot = await _storeForConversation(conversation.id)?.load();
      if (snapshot == null) {
        messageCount += conversation.messageCount;
        continue;
      }

      messageCount += snapshot.messages.length;
      if (snapshot.draft.trim().isNotEmpty) {
        draftCount++;
      }
      snapshotBytes += utf8
          .encode(
            ChatSessionSnapshotCodec.encode(snapshot),
          )
          .length;
    }

    final catalogBytes = catalog.conversations.isEmpty
        ? 0
        : utf8.encode(ChatConversationCatalogCodec.encode(catalog)).length;

    return ChatStorageUsage(
      conversationCount: seenConversationIds.length,
      messageCount: messageCount,
      draftCount: draftCount,
      catalogBytes: catalogBytes,
      snapshotBytes: snapshotBytes,
      lastUpdated: lastUpdated,
    );
  }

  Future<void> restore() async {
    try {
      await _restoreCatalog();
      await _restoreActiveSnapshot();
      _errorMessage = null;
      unawaited(_saveCatalogSummary());
      _notify();
    } catch (error) {
      _errorMessage = '恢复会话失败：$error';
      _notify();
    }
  }

  void updateSettings(ChatConnectionSettings settings) {
    _settings = settings;
    _errorMessage = null;
    unawaited(_saveSnapshot());
    unawaited(_saveCatalogSummary());
    _notify();
  }

  Future<void> testConnection(ChatConnectionSettings settings) async {
    final checkConnection = _checkConnection;
    if (checkConnection == null) {
      ChatConnectionSettingsParser.normalize(settings);
      return;
    }

    await checkConnection(settings);
  }

  void reportError(String message) {
    _errorMessage = message;
    _notify();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    _notify();
  }

  void updateStorageSettings(
    ChatStorageSettings settings, {
    bool persistImmediately = true,
  }) {
    if (settings == _storageSettings) {
      return;
    }

    _storageSettings = settings;
    if (!persistImmediately || !settings.autoSaveConversations) {
      return;
    }

    unawaited(_saveSnapshot());
    unawaited(_saveCatalogSummary());
  }

  void updateVoiceSettings(ChatVoiceSettings settings) {
    _voiceSettings = settings;
  }

  Future<void> createConversation({String? title}) async {
    await _saveSnapshot();
    await _saveCatalogSummary();

    final id = _newId('conversation');
    _conversationId = id;
    _conversationTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'BareBrain ${_conversations.length + 1}';
    _activeSessionStore = _storeForConversation(id);
    _messages.clear();
    _draft = '';
    _errorMessage = null;

    await _saveSnapshot();
    await _saveCatalogSummary();
    _notify();
  }

  Future<void> selectConversation(String conversationId) async {
    if (conversationId == _conversationId) {
      return;
    }

    await _saveSnapshot();
    await _saveCatalogSummary();

    final summary = _findConversation(conversationId);
    if (summary == null) {
      _errorMessage = '会话不存在';
      _notify();
      return;
    }

    _conversationId = summary.id;
    _conversationTitle = summary.title;
    _settings = summary.settings;
    _activeSessionStore = _storeForConversation(summary.id);
    _messages.clear();
    _draft = '';
    _errorMessage = null;

    await _restoreActiveSnapshot();
    await _saveCatalogSummary();
    _notify();
  }

  Future<void> deleteConversation(String conversationId) async {
    if (conversationId == _conversationId) {
      _errorMessage = '不能删除当前会话';
      _notify();
      return;
    }

    final summary = _findConversation(conversationId);
    if (summary == null) {
      _errorMessage = '会话不存在';
      _notify();
      return;
    }

    try {
      await _sessionStoreFactory?.forConversation(conversationId).clear();
      final store = _catalogStore;
      final current = store == null
          ? ChatConversationCatalog(
              activeConversationId: _conversationId,
              conversations: _conversations,
            )
          : await store.load();
      final next = (current ??
              ChatConversationCatalog(
                activeConversationId: _conversationId,
                conversations: _conversations,
              ))
          .remove(conversationId);
      _conversations = next.conversations;
      await store?.save(next);
      _errorMessage = null;
      _notify();
    } catch (error) {
      _errorMessage = '删除会话失败：$error';
      _notify();
    }
  }

  Future<void> renameConversation(String conversationId, String title) async {
    final nextTitle = title.trim();
    if (nextTitle.isEmpty) {
      _errorMessage = '会话标题不能为空';
      _notify();
      return;
    }

    final summary = _findConversation(conversationId);
    if (summary == null) {
      _errorMessage = '会话不存在';
      _notify();
      return;
    }

    try {
      final store = _catalogStore;
      final current = store == null
          ? ChatConversationCatalog(
              activeConversationId: _conversationId,
              conversations: _conversations,
            )
          : await store.load();
      final next = (current ??
              ChatConversationCatalog(
                activeConversationId: _conversationId,
                conversations: _conversations,
              ))
          .rename(conversationId, nextTitle);
      _conversations = next.conversations;
      if (conversationId == _conversationId) {
        _conversationTitle = nextTitle;
      }
      await store?.save(next);
      _errorMessage = null;
      _notify();
    } catch (error) {
      _errorMessage = '重命名会话失败：$error';
      _notify();
    }
  }

  Future<void> send(String content, {String? transportContent}) async {
    if (_isSending) {
      return;
    }

    final normalized = content.trim();
    if (normalized.isEmpty) {
      _errorMessage = '消息不能为空';
      _notify();
      return;
    }

    await _sendNormalized(
      normalized,
      transportContent: transportContent?.trim(),
    );
  }

  void updateDraft(String draft) {
    if (draft == _draft) {
      return;
    }

    _draft = draft;
    unawaited(_saveSnapshot());
  }

  Future<void> retryLastUserMessage({String? transportContent}) async {
    if (_isSending) {
      return;
    }

    final retryIndex = _lastRetryableUserMessageIndex();
    if (retryIndex == null) {
      _errorMessage = '没有可重试的消息';
      _notify();
      return;
    }

    final content = _messages[retryIndex].content.trim();
    if (content.isEmpty) {
      _errorMessage = '没有可重试的消息';
      _notify();
      return;
    }

    _messages.removeRange(retryIndex + 1, _messages.length);
    await _sendNormalized(
      content,
      existingUserMessageIndex: retryIndex,
      transportContent: transportContent?.trim(),
    );
  }

  Future<void> _sendNormalized(
    String normalized, {
    int? existingUserMessageIndex,
    String? transportContent,
  }) async {
    final shouldAutoTitle = existingUserMessageIndex == null &&
        _messages.isEmpty &&
        _hasGeneratedConversationTitle();
    _isSending = true;
    _errorMessage = null;
    _draft = '';
    if (shouldAutoTitle) {
      _conversationTitle = ChatConversationTitleBuilder.fromMessage(normalized);
    }
    final userMessageIndex = existingUserMessageIndex ?? _messages.length;
    if (existingUserMessageIndex == null) {
      _messages.add(
        ChatMessage(
          id: _newId('user'),
          author: ChatMessageAuthor.user,
          content: normalized,
          createdAt: DateTime.now(),
          isPending: true,
        ),
      );
    } else {
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: true,
      );
    }
    _notify();
    await _saveSnapshot();
    await _saveCatalogSummary();

    try {
      final response = await _sendChatMessage(
        transportContent?.isNotEmpty == true ? transportContent! : normalized,
        _settings,
        chatId: bareBrainChatId,
      );
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      _messages.add(
        ChatMessage(
          id: _newId('assistant'),
          author: ChatMessageAuthor.assistant,
          content: response,
          createdAt: DateTime.now(),
        ),
      );
      await _saveSnapshot();
      await _saveCatalogSummary();
      unawaited(_speakAssistantResponse(response));
    } on ChatException catch (error) {
      _errorMessage = error.message;
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      _messages.add(
        ChatMessage(
          id: _newId('system'),
          author: ChatMessageAuthor.system,
          content: error.message,
          createdAt: DateTime.now(),
          error: error.message,
        ),
      );
      await _saveSnapshot();
      await _saveCatalogSummary();
    } catch (error) {
      _errorMessage = '发送失败：$error';
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      _messages.add(
        ChatMessage(
          id: _newId('system'),
          author: ChatMessageAuthor.system,
          content: _errorMessage!,
          createdAt: DateTime.now(),
          error: _errorMessage,
        ),
      );
      await _saveSnapshot();
      await _saveCatalogSummary();
    } finally {
      _isSending = false;
      _notify();
    }
  }

  void clear() {
    _messages.clear();
    _errorMessage = null;
    unawaited(_saveSnapshot());
    unawaited(_saveCatalogSummary());
    _notify();
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _saveSnapshot() async {
    if (!_storageSettings.autoSaveConversations) {
      return;
    }

    final store = _currentSessionStore();
    if (store == null) {
      return;
    }

    try {
      await store.save(
        ChatSessionSnapshot(
          settings: _settings,
          messages: List<ChatMessage>.unmodifiable(_messages),
          draft: _storageSettings.saveDrafts ? _draft : '',
        ),
      );
    } catch (error) {
      _errorMessage = '保存会话失败：$error';
    }
  }

  Future<void> _saveCatalogSummary() async {
    try {
      final summary = ChatConversationSummary(
        id: _conversationId,
        title: _conversationTitle,
        settings: _settings,
        updatedAt: _lastMessageTime(),
        messageCount: _messages.length,
        lastMessagePreview: _lastMessagePreview(),
      );
      final store = _catalogStore;
      final shouldPersist = _storageSettings.autoSaveConversations;
      final current =
          store == null || !shouldPersist ? null : await store.load();
      final catalog = current ??
          ChatConversationCatalog(
            activeConversationId: _conversationId,
            conversations: _conversations,
          );
      final next = _applyStoragePolicy(catalog.upsertActive(summary));
      _conversations = next.conversations;
      if (shouldPersist) {
        await _clearPrunedConversationSnapshots(catalog, next);
        await store?.save(next);
      }
    } catch (error) {
      _errorMessage = '保存会话目录失败：$error';
    }
  }

  Future<void> _restoreCatalog() async {
    final store = _catalogStore;
    if (store == null) {
      return;
    }

    final catalog = await store.load();
    if (catalog == null || catalog.conversations.isEmpty) {
      return;
    }

    _conversations = List<ChatConversationSummary>.unmodifiable(
      catalog.conversations,
    );
    final active = catalog.activeConversation;
    if (active == null) {
      return;
    }

    _conversationId = active.id;
    _conversationTitle = active.title;
    _settings = active.settings;
    _activeSessionStore = _storeForConversation(active.id);
  }

  Future<void> _restoreActiveSnapshot() async {
    final store = _currentSessionStore();
    if (store == null) {
      return;
    }

    final snapshot = await store.load();
    if (snapshot == null) {
      return;
    }

    _settings = snapshot.settings;
    _draft = _storageSettings.saveDrafts ? snapshot.draft : '';
    _messages
      ..clear()
      ..addAll(
        snapshot.messages.map((message) {
          if (!message.isPending) {
            return message;
          }
          return message.copyWith(isPending: false);
        }),
      );
  }

  ChatSessionStore? _currentSessionStore() {
    _activeSessionStore ??= _storeForConversation(_conversationId);
    return _activeSessionStore;
  }

  ChatSessionStore? _storeForConversation(String conversationId) {
    return _sessionStoreFactory?.forConversation(conversationId) ??
        _fixedSessionStore ??
        _sessionStore;
  }

  ChatConversationSummary? _findConversation(String conversationId) {
    for (final conversation in _conversations) {
      if (conversation.id == conversationId) {
        return conversation;
      }
    }

    return null;
  }

  int? _lastRetryableUserMessageIndex() {
    if (_messages.length < 2) {
      return null;
    }

    final last = _messages.last;
    if (last.author != ChatMessageAuthor.system || last.error == null) {
      return null;
    }

    for (var index = _messages.length - 2; index >= 0; index--) {
      final message = _messages[index];
      if (message.author == ChatMessageAuthor.user) {
        return index;
      }
      if (message.author == ChatMessageAuthor.assistant) {
        return null;
      }
    }

    return null;
  }

  bool _hasGeneratedConversationTitle() {
    if (_conversationTitle == 'BareBrain') {
      return true;
    }

    return RegExp(r'^BareBrain \d+$').hasMatch(_conversationTitle);
  }

  DateTime _lastMessageTime() {
    if (_messages.isEmpty) {
      return DateTime.now();
    }

    return _messages.last.createdAt;
  }

  String _lastMessagePreview() {
    if (_messages.isEmpty) {
      return '';
    }

    final normalized = _messages.last.content.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
    if (normalized.length <= 80) {
      return normalized;
    }

    return '${normalized.substring(0, 80)}...';
  }

  ChatConversationCatalog _applyStoragePolicy(
    ChatConversationCatalog catalog,
  ) {
    final retentionCutoff = _retentionCutoff();
    final filtered = catalog.conversations.where((conversation) {
      if (conversation.id == catalog.activeConversationId) {
        return true;
      }

      return retentionCutoff == null ||
          conversation.updatedAt.isAfter(retentionCutoff);
    }).toList(growable: false);

    final limited = filtered
        .take(_storageSettings.maxLocalConversations)
        .toList(growable: false);
    ChatConversationSummary? activeConversation;
    for (final conversation in filtered) {
      if (conversation.id == catalog.activeConversationId) {
        activeConversation = conversation;
        break;
      }
    }
    if (activeConversation != null) {
      final activeConversationId = activeConversation.id;
      final hasActiveConversation = limited.any((conversation) {
        return conversation.id == activeConversationId;
      });
      if (!hasActiveConversation) {
        if (limited.length >= _storageSettings.maxLocalConversations) {
          limited.removeLast();
        }
        limited.add(activeConversation);
      }
    }

    return ChatConversationCatalog(
      activeConversationId: catalog.activeConversationId,
      conversations: List<ChatConversationSummary>.unmodifiable(limited),
    );
  }

  Future<void> _clearPrunedConversationSnapshots(
    ChatConversationCatalog previous,
    ChatConversationCatalog next,
  ) async {
    final remainingIds = next.conversations.map((conversation) {
      return conversation.id;
    }).toSet();

    for (final conversation in previous.conversations) {
      if (remainingIds.contains(conversation.id) ||
          conversation.id == _conversationId) {
        continue;
      }

      await _sessionStoreFactory?.forConversation(conversation.id).clear();
    }
  }

  DateTime? _retentionCutoff() {
    return switch (_storageSettings.retentionPolicy) {
      ChatStorageRetentionPolicy.forever => null,
      ChatStorageRetentionPolicy.thirtyDays =>
        DateTime.now().subtract(const Duration(days: 30)),
      ChatStorageRetentionPolicy.ninetyDays =>
        DateTime.now().subtract(const Duration(days: 90)),
    };
  }

  Future<void> _speakAssistantResponse(String response) async {
    final voiceOutput = _voiceOutput;
    if (voiceOutput == null ||
        !_voiceSettings.enabled ||
        response.trim().isEmpty) {
      return;
    }

    try {
      await voiceOutput.speak(response, _voiceSettings);
    } on ChatException catch (error) {
      _errorMessage = error.message.startsWith('语音服务')
          ? error.message
          : '语音服务失败：${error.message}';
      _notify();
    } catch (error) {
      _errorMessage = '语音服务失败：$error';
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class ChatStorageUsage {
  const ChatStorageUsage({
    required this.conversationCount,
    required this.messageCount,
    required this.draftCount,
    required this.catalogBytes,
    required this.snapshotBytes,
    this.lastUpdated,
  });

  const ChatStorageUsage.empty()
      : conversationCount = 0,
        messageCount = 0,
        draftCount = 0,
        catalogBytes = 0,
        snapshotBytes = 0,
        lastUpdated = null;

  final int conversationCount;
  final int messageCount;
  final int draftCount;
  final int catalogBytes;
  final int snapshotBytes;
  final DateTime? lastUpdated;

  int get totalBytes => catalogBytes + snapshotBytes;
}
