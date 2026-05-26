import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/entities/chat_conversation_summary.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/repositories/chat_conversation_catalog_store.dart';
import '../../domain/repositories/chat_session_store.dart';
import '../../domain/services/chat_conversation_title_builder.dart';
import '../../domain/services/chat_connection_settings_parser.dart';
import '../../domain/services/chat_route_id_builder.dart';
import '../../domain/usecases/check_chat_connection.dart';
import '../../domain/usecases/send_chat_message.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required SendChatMessage sendChatMessage,
    required ChatConnectionSettings initialSettings,
    CheckChatConnection? checkConnection,
    ChatSessionStore? sessionStore,
    ChatSessionStoreFactory? sessionStoreFactory,
    ChatConversationCatalogStore? catalogStore,
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
        _conversationId = conversationId,
        _conversationTitle = conversationTitle;

  final SendChatMessage _sendChatMessage;
  final CheckChatConnection? _checkConnection;
  final ChatSessionStore? _fixedSessionStore;
  final ChatSessionStoreFactory? _sessionStoreFactory;
  final ChatSessionStore? _sessionStore;
  final ChatConversationCatalogStore? _catalogStore;
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

  String get bareBrainChatId {
    return ChatRouteIdBuilder.build(
      clientId: _settings.clientId,
      conversationId: _conversationId,
    );
  }

  List<ChatConversationSummary> get conversations {
    return List<ChatConversationSummary>.unmodifiable(_conversations);
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

  Future<void> send(String content) async {
    if (_isSending) {
      return;
    }

    final normalized = content.trim();
    if (normalized.isEmpty) {
      _errorMessage = '消息不能为空';
      _notify();
      return;
    }

    await _sendNormalized(normalized);
  }

  void updateDraft(String draft) {
    if (draft == _draft) {
      return;
    }

    _draft = draft;
    unawaited(_saveSnapshot());
  }

  Future<void> retryLastUserMessage() async {
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
    await _sendNormalized(content, existingUserMessageIndex: retryIndex);
  }

  Future<void> _sendNormalized(
    String normalized, {
    int? existingUserMessageIndex,
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
        normalized,
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
    final store = _currentSessionStore();
    if (store == null) {
      return;
    }

    try {
      await store.save(
        ChatSessionSnapshot(
          settings: _settings,
          messages: List<ChatMessage>.unmodifiable(_messages),
          draft: _draft,
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
      final current = store == null ? null : await store.load();
      final catalog = current ??
          ChatConversationCatalog(
            activeConversationId: _conversationId,
            conversations: _conversations,
          );
      final next = catalog.upsertActive(summary);
      _conversations = next.conversations;
      await store?.save(next);
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
    _draft = snapshot.draft;
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
