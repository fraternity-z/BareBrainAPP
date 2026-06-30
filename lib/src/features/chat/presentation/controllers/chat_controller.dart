import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/entities/chat_conversation_summary.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/entities/incoming_chat_message.dart';
import '../../domain/repositories/chat_conversation_catalog_store.dart';
import '../../domain/repositories/chat_session_store.dart';
import '../../domain/services/chat_conversation_title_builder.dart';
import '../../domain/services/chat_connection_settings_parser.dart';
import '../../domain/services/chat_route_id_builder.dart';
import '../../domain/services/bare_brain_board_command_parser.dart';
import '../../domain/usecases/run_bare_brain_board_command.dart';
import '../../domain/usecases/check_chat_connection.dart';
import '../../domain/usecases/receive_chat_messages.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../data/models/chat_conversation_catalog_codec.dart';
import '../../data/models/chat_session_snapshot_codec.dart';

enum ChatConversationRestoreMode {
  overwrite,
  merge,
}

class ChatConversationBackup {
  const ChatConversationBackup({
    this.catalog,
    this.snapshots = const <String, ChatSessionSnapshot>{},
  });

  final ChatConversationCatalog? catalog;
  final Map<String, ChatSessionSnapshot> snapshots;

  bool get isEmpty {
    return (catalog == null || catalog!.conversations.isEmpty) &&
        snapshots.isEmpty;
  }

  int get conversationCount {
    final catalogCount = catalog?.conversations.length ?? 0;
    return catalogCount > snapshots.length ? catalogCount : snapshots.length;
  }

  int get messageCount {
    if (snapshots.isNotEmpty) {
      return snapshots.values.fold<int>(
        0,
        (total, snapshot) => total + snapshot.messages.length,
      );
    }

    return catalog?.conversations.fold<int>(
          0,
          (total, conversation) => total + conversation.messageCount,
        ) ??
        0;
  }

  int get draftCount {
    return snapshots.values.where((snapshot) {
      return snapshot.draft.trim().isNotEmpty;
    }).length;
  }
}

class ChatController extends ChangeNotifier {
  ChatController({
    required SendChatMessage sendChatMessage,
    required ChatConnectionSettings initialSettings,
    ReceiveChatMessages? receiveChatMessages,
    RunBareBrainBoardCommand? runBoardCommand,
    CheckChatConnection? checkConnection,
    ChatSessionStore? sessionStore,
    ChatSessionStoreFactory? sessionStoreFactory,
    ChatConversationCatalogStore? catalogStore,
    ChatStorageSettings storageSettings = const ChatStorageSettings(),
    String conversationId = 'default',
    String conversationTitle = 'BareBrain',
  })  : _sendChatMessage = sendChatMessage,
        _receiveChatMessages = receiveChatMessages,
        _runBoardCommand = runBoardCommand,
        _checkConnection = checkConnection,
        _settings = initialSettings,
        _fixedSessionStore = sessionStore,
        _sessionStoreFactory = sessionStoreFactory,
        _sessionStore = sessionStoreFactory?.forConversation(conversationId) ??
            sessionStore,
        _catalogStore = catalogStore,
        _storageSettings = storageSettings,
        _conversationId = conversationId,
        _conversationTitle = conversationTitle;

  final SendChatMessage _sendChatMessage;
  final ReceiveChatMessages? _receiveChatMessages;
  final RunBareBrainBoardCommand? _runBoardCommand;
  final CheckChatConnection? _checkConnection;
  final ChatSessionStore? _fixedSessionStore;
  final ChatSessionStoreFactory? _sessionStoreFactory;
  final ChatSessionStore? _sessionStore;
  final ChatConversationCatalogStore? _catalogStore;
  ChatStorageSettings _storageSettings;
  String _conversationId;
  String _conversationTitle;
  ChatConnectionSettings _settings;
  ChatSessionStore? _activeSessionStore;
  final List<ChatMessage> _messages = <ChatMessage>[];
  late final UnmodifiableListView<ChatMessage> _messageView =
      UnmodifiableListView<ChatMessage>(_messages);
  final List<IncomingChatMessage> _deferredIncomingMessages =
      <IncomingChatMessage>[];
  final List<ChatConversationSummary> _conversations =
      <ChatConversationSummary>[];
  late final UnmodifiableListView<ChatConversationSummary> _conversationView =
      UnmodifiableListView<ChatConversationSummary>(_conversations);
  String _draft = '';
  bool _isSending = false;
  bool _isDisposed = false;
  Timer? _draftSaveTimer;
  StreamSubscription<IncomingChatMessage>? _incomingMessageSubscription;
  Future<void>? _snapshotSaveFuture;
  String? _incomingMessageRouteKey;
  String? _lastIncomingMessageSignature;
  DateTime? _lastIncomingMessageAt;
  int _incomingMessageGeneration = 0;
  bool _saveSnapshotAgain = false;
  String? _errorMessage;

  static const Duration _draftSaveDebounce = Duration(milliseconds: 450);
  static const Duration _incomingDuplicateWindow = Duration(seconds: 3);
  static const int _maxDeferredIncomingMessages = 20;
  static const String _incomingErrorPrefix = '主动接收失败：';

  ChatConnectionSettings get settings => _settings;
  List<ChatMessage> get messages => _messageView;
  String get draft => _draft;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String get conversationId => _conversationId;
  String get conversationTitle => _conversationTitle;
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

  List<ChatConversationSummary> get conversations => _conversationView;

  Future<ChatStorageUsage> loadStorageUsage() async {
    await _saveSnapshotImmediately();
    await _saveCatalogSummary();

    final storedCatalog = await _catalogStore?.load();
    final catalog = _mergeCatalogBackups(
      storedCatalog ??
          ChatConversationCatalog(
            activeConversationId: _conversationId,
            conversations: const <ChatConversationSummary>[],
          ),
      ChatConversationCatalog(
        activeConversationId: _conversationId,
        conversations: _conversations,
      ),
      preferBackup: true,
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

  Future<ChatConversationBackup> exportConversationBackup() async {
    await _saveSnapshotImmediately();
    await _saveCatalogSummary();

    final storedCatalog = await _catalogStore?.load();
    final catalog = storedCatalog ??
        ChatConversationCatalog(
          activeConversationId: _conversationId,
          conversations: _conversations,
        );
    final snapshots = <String, ChatSessionSnapshot>{};
    final seenConversationIds = <String>{};

    for (final conversation in catalog.conversations) {
      if (!seenConversationIds.add(conversation.id)) {
        continue;
      }

      final snapshot = conversation.id == _conversationId
          ? _currentSnapshot()
          : await _storeForConversation(conversation.id)?.load();
      if (snapshot != null) {
        snapshots[conversation.id] = snapshot;
      }
    }

    return ChatConversationBackup(
      catalog: catalog,
      snapshots: Map<String, ChatSessionSnapshot>.unmodifiable(snapshots),
    );
  }

  Future<void> restoreConversationBackup(
    ChatConversationBackup backup, {
    ChatConversationRestoreMode mode = ChatConversationRestoreMode.overwrite,
  }) async {
    if (backup.isEmpty) {
      return;
    }

    try {
      await _saveSnapshotImmediately();
      await _saveCatalogSummary();

      final currentCatalog = await _catalogStore?.load() ??
          ChatConversationCatalog(
            activeConversationId: _conversationId,
            conversations: _conversations,
          );
      final backupCatalog = backup.catalog ??
          ChatConversationCatalog(
            activeConversationId: backup.snapshots.keys.first,
            conversations: const <ChatConversationSummary>[],
          );
      var nextCatalog = mode == ChatConversationRestoreMode.overwrite
          ? _catalogWithSnapshotFallbacks(backupCatalog, backup.snapshots)
          : _mergeCatalogBackups(
              currentCatalog,
              _catalogWithSnapshotFallbacks(backupCatalog, backup.snapshots),
            );
      final currentConversationIds = currentCatalog.conversations.map(
        (conversation) {
          return conversation.id;
        },
      ).toSet();
      final restoredSnapshots = <String, ChatSessionSnapshot>{};

      if (mode == ChatConversationRestoreMode.overwrite) {
        await _clearConversationSnapshots(currentCatalog.conversations);
      }
      for (final entry in backup.snapshots.entries) {
        final store = _storeForConversation(entry.key);
        var snapshot = entry.value;
        if (mode == ChatConversationRestoreMode.merge &&
            currentConversationIds.contains(entry.key)) {
          final currentSnapshot = await store?.load();
          if (currentSnapshot != null) {
            snapshot = _mergeSnapshots(currentSnapshot, entry.value);
          }
        }
        await store?.save(snapshot);
        restoredSnapshots[entry.key] = snapshot;
      }
      nextCatalog =
          _catalogUpdatedWithSnapshots(nextCatalog, restoredSnapshots);

      await _catalogStore?.save(nextCatalog);
      _replaceConversations(nextCatalog.conversations);
      final active = nextCatalog.activeConversation;
      if (active != null) {
        _conversationId = active.id;
        _conversationTitle = active.title;
        _settings = active.settings;
        _activeSessionStore = _storeForConversation(active.id);
      }

      _messages.clear();
      _deferredIncomingMessages.clear();
      _draft = '';
      await _restoreActiveSnapshot();
      _errorMessage = null;
      _restartIncomingMessageSubscription();
      _notify();
    } catch (error) {
      _errorMessage = '恢复会话备份失败：$error';
      _notify();
      rethrow;
    }
  }

  Future<void> restore() async {
    try {
      await _restoreCatalog();
      await _restoreActiveSnapshot();
      _errorMessage = null;
      unawaited(_saveCatalogSummary());
      _restartIncomingMessageSubscription();
      _notify();
    } catch (error) {
      _errorMessage = '恢复会话失败：$error';
      _notify();
    }
  }

  void updateSettings(ChatConnectionSettings settings) {
    _settings = settings;
    _errorMessage = null;
    _restartIncomingMessageSubscription();
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

  Future<void> createConversation({String? title}) async {
    await _saveSnapshotImmediately();
    await _saveCatalogSummary();

    final id = _newId('conversation');
    _conversationId = id;
    _conversationTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'BareBrain ${_conversations.length + 1}';
    _activeSessionStore = _storeForConversation(id);
    _messages.clear();
    _deferredIncomingMessages.clear();
    _draft = '';
    _errorMessage = null;

    await _saveSnapshot();
    await _saveCatalogSummary();
    _restartIncomingMessageSubscription();
    _notify();
  }

  Future<void> selectConversation(String conversationId) async {
    if (conversationId == _conversationId) {
      return;
    }

    await _saveSnapshotImmediately();
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
    _deferredIncomingMessages.clear();
    _draft = '';
    _errorMessage = null;

    await _restoreActiveSnapshot();
    await _saveCatalogSummary();
    _restartIncomingMessageSubscription();
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
      _replaceConversations(next.conversations);
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
      _replaceConversations(next.conversations);
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

  Future<bool> runBoardCommand(String content, {String? displayContent}) async {
    if (_isSending) {
      return false;
    }

    final runBoardCommand = _runBoardCommand;
    if (runBoardCommand == null) {
      return false;
    }

    final normalized = content.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (BareBrainBoardCommandParser.parse(normalized) == null) {
      return false;
    }
    final normalizedDisplayContent = displayContent?.trim();
    final visibleContent = normalizedDisplayContent?.isNotEmpty == true
        ? normalizedDisplayContent!
        : normalized;

    _cancelDraftSnapshotSave();
    _isSending = true;
    _errorMessage = null;
    _draft = '';
    _messages.add(
      ChatMessage(
        id: _newId('user'),
        author: ChatMessageAuthor.user,
        content: visibleContent,
        createdAt: DateTime.now(),
        isPending: true,
      ),
    );
    final userMessageIndex = _messages.length - 1;
    _notify();
    await _saveSnapshot();
    await _saveCatalogSummary();

    try {
      final result = await runBoardCommand(normalized, _settings);
      if (result == null) {
        _messages.removeAt(userMessageIndex);
        await _saveSnapshot();
        await _saveCatalogSummary();
        return false;
      }

      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      if (result.isError) {
        _errorMessage = result.message;
      }
      _messages.add(
        ChatMessage(
          id: _newId('system'),
          author: ChatMessageAuthor.system,
          content: result.message,
          createdAt: DateTime.now(),
          error: result.isError ? result.message : null,
        ),
      );
      await _saveSnapshot();
      await _saveCatalogSummary();
      return true;
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
      return true;
    } catch (error) {
      _errorMessage = '板子设置执行失败：$error';
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
      return true;
    } finally {
      _isSending = false;
      _notify();
    }
  }

  void updateDraft(String draft) {
    if (draft == _draft) {
      return;
    }

    _draft = draft;
    _scheduleDraftSnapshotSave();
  }

  Future<void> retryLastUserMessage({
    bool deleteFollowingMessages = true,
    String? transportContent,
  }) async {
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

    if (deleteFollowingMessages) {
      _messages.removeRange(retryIndex + 1, _messages.length);
    }
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
    _cancelDraftSnapshotSave();
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
    final assistantMessageIndex = _messages.length;
    final assistantMessageId = _newId('assistant');
    _messages.add(
      ChatMessage(
        id: assistantMessageId,
        author: ChatMessageAuthor.assistant,
        content: '',
        createdAt: DateTime.now(),
        isPending: true,
      ),
    );
    _notify();
    await _saveSnapshot();
    await _saveCatalogSummary();

    try {
      final response = await _sendChatMessage(
        transportContent?.isNotEmpty == true ? transportContent! : normalized,
        _settings,
        chatId: bareBrainChatId,
      );
      _rememberIncomingMessage(content: response, requestId: '');
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      _messages[assistantMessageIndex] =
          _messages[assistantMessageIndex].copyWith(
        content: response,
        createdAt: DateTime.now(),
        isPending: false,
      );
      await _saveSnapshot();
      await _saveCatalogSummary();
    } on ChatException catch (error) {
      _errorMessage = error.message;
      _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(
        isPending: false,
      );
      _removePendingAssistantMessage(assistantMessageIndex, assistantMessageId);
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
      _removePendingAssistantMessage(assistantMessageIndex, assistantMessageId);
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
      unawaited(_flushDeferredIncomingMessages());
      _notify();
    }
  }

  void clear() {
    _cancelDraftSnapshotSave();
    _messages.clear();
    _deferredIncomingMessages.clear();
    _errorMessage = null;
    unawaited(_saveSnapshot());
    unawaited(_saveCatalogSummary());
    _notify();
  }

  void _restartIncomingMessageSubscription() {
    final receiveChatMessages = _receiveChatMessages;
    if (_isDisposed || receiveChatMessages == null) {
      return;
    }

    final chatId = bareBrainChatId;
    final routeKey = '${_settings.websocketUri}|$chatId';
    if (_incomingMessageRouteKey == routeKey &&
        _incomingMessageSubscription != null) {
      return;
    }

    _incomingMessageGeneration++;
    final generation = _incomingMessageGeneration;
    _incomingMessageRouteKey = routeKey;
    _lastIncomingMessageSignature = null;
    _lastIncomingMessageAt = null;
    unawaited(_incomingMessageSubscription?.cancel());
    _incomingMessageSubscription = receiveChatMessages(
      _settings,
      chatId: chatId,
    ).listen(
      (message) {
        if (generation != _incomingMessageGeneration) {
          return;
        }
        unawaited(_appendIncomingMessage(message));
      },
      onError: (Object error) {
        if (generation != _incomingMessageGeneration) {
          return;
        }
        _handleIncomingMessageError(error);
      },
    );
  }

  Future<void> _appendIncomingMessage(IncomingChatMessage message) async {
    if (_isDisposed) {
      return;
    }

    if (_isSending) {
      _deferIncomingMessage(message);
      return;
    }

    final content = message.content.trim();
    if (content.isEmpty || _isDuplicateIncomingMessage(message, content)) {
      return;
    }

    _rememberIncomingMessage(
      content: content,
      requestId: message.requestId,
      chatId: message.chatId,
    );
    if (_errorMessage?.startsWith(_incomingErrorPrefix) == true) {
      _errorMessage = null;
    }
    _messages.add(
      ChatMessage(
        id: _newId('assistant'),
        author: ChatMessageAuthor.assistant,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    await _saveSnapshot();
    await _saveCatalogSummary();
    _notify();
  }

  void _deferIncomingMessage(IncomingChatMessage message) {
    final content = message.content.trim();
    if (content.isEmpty) {
      return;
    }

    final signature = _incomingMessageSignature(
      content: content,
      requestId: message.requestId,
      chatId: message.chatId,
    );
    final alreadyDeferred = _deferredIncomingMessages.any((deferred) {
      return _incomingMessageSignature(
            content: deferred.content.trim(),
            requestId: deferred.requestId,
            chatId: deferred.chatId,
          ) ==
          signature;
    });
    if (alreadyDeferred) {
      return;
    }

    _deferredIncomingMessages.add(message);
    if (_deferredIncomingMessages.length > _maxDeferredIncomingMessages) {
      _deferredIncomingMessages.removeAt(0);
    }
  }

  Future<void> _flushDeferredIncomingMessages() async {
    if (_deferredIncomingMessages.isEmpty || _isDisposed) {
      return;
    }

    final messages =
        List<IncomingChatMessage>.unmodifiable(_deferredIncomingMessages);
    _deferredIncomingMessages.clear();
    for (final message in messages) {
      await _appendIncomingMessage(message);
    }
  }

  bool _isDuplicateIncomingMessage(
    IncomingChatMessage message,
    String content,
  ) {
    final now = DateTime.now();
    final signature = _incomingMessageSignature(
      content: content,
      requestId: message.requestId,
      chatId: message.chatId,
    );
    final lastAt = _lastIncomingMessageAt;
    if (_lastIncomingMessageSignature == signature &&
        lastAt != null &&
        now.difference(lastAt).abs() <= _incomingDuplicateWindow) {
      return true;
    }

    if (_messages.isEmpty) {
      return false;
    }

    final lastMessage = _messages.last;
    return lastMessage.author == ChatMessageAuthor.assistant &&
        lastMessage.content.trim() == content &&
        now.difference(lastMessage.createdAt).abs() <= _incomingDuplicateWindow;
  }

  void _rememberIncomingMessage({
    required String content,
    String requestId = '',
    String chatId = '',
  }) {
    _lastIncomingMessageSignature = _incomingMessageSignature(
      content: content.trim(),
      requestId: requestId,
      chatId: chatId,
    );
    _lastIncomingMessageAt = DateTime.now();
  }

  String _incomingMessageSignature({
    required String content,
    required String requestId,
    required String chatId,
  }) {
    if (requestId.trim().isNotEmpty) {
      return 'request:${requestId.trim()}';
    }

    return 'content:${chatId.trim()}:$content';
  }

  void _handleIncomingMessageError(Object error) {
    final message = '$_incomingErrorPrefix${_chatErrorMessage(error)}';
    if (_errorMessage == message) {
      return;
    }

    _errorMessage = message;
    _notify();
  }

  String _chatErrorMessage(Object error) {
    if (error is ChatException) {
      return error.message;
    }

    return error.toString();
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _removePendingAssistantMessage(int index, String id) {
    if (index < 0 || index >= _messages.length) {
      return;
    }

    final message = _messages[index];
    if (message.id == id &&
        message.author == ChatMessageAuthor.assistant &&
        message.isPending) {
      _messages.removeAt(index);
    }
  }

  Future<void> _saveSnapshot() {
    final activeSave = _snapshotSaveFuture;
    if (activeSave != null) {
      _saveSnapshotAgain = true;
      return activeSave;
    }

    final saveFuture = _runSnapshotSave();
    _snapshotSaveFuture = saveFuture;
    return saveFuture;
  }

  Future<void> _runSnapshotSave() async {
    try {
      do {
        _saveSnapshotAgain = false;
        await _writeSnapshot();
      } while (_saveSnapshotAgain);
    } finally {
      _snapshotSaveFuture = null;
    }
  }

  Future<void> _writeSnapshot() async {
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

  Future<void> _saveSnapshotImmediately() {
    _cancelDraftSnapshotSave();
    return _saveSnapshot();
  }

  void _scheduleDraftSnapshotSave() {
    if (!_storageSettings.autoSaveConversations) {
      return;
    }

    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftSaveDebounce, () {
      _draftSaveTimer = null;
      unawaited(_saveSnapshot());
    });
  }

  void _cancelDraftSnapshotSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
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
      _replaceConversations(next.conversations);
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

    _replaceConversations(catalog.conversations);
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
    _messages.clear();
    for (final message in snapshot.messages) {
      if (message.isPending && message.author == ChatMessageAuthor.assistant) {
        continue;
      }

      _messages.add(
        message.isPending ? message.copyWith(isPending: false) : message,
      );
    }
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

  void _replaceConversations(List<ChatConversationSummary> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
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
        if (BareBrainBoardCommandParser.parse(message.content) != null ||
            message.content.trim().startsWith('板子设置：')) {
          return null;
        }

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

    final last = _messages.last;
    if (last.author == ChatMessageAuthor.assistant && last.isPending) {
      return '等待回复...';
    }

    final normalized = last.content.trim().replaceAll(
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

  ChatConversationCatalog _catalogWithSnapshotFallbacks(
    ChatConversationCatalog catalog,
    Map<String, ChatSessionSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) {
      return catalog;
    }

    final conversations = <ChatConversationSummary>[...catalog.conversations];
    final knownIds = conversations.map((conversation) {
      return conversation.id;
    }).toSet();
    for (final entry in snapshots.entries) {
      if (knownIds.contains(entry.key)) {
        continue;
      }

      conversations.add(_summaryFromSnapshot(entry.key, entry.value));
    }

    conversations.sort((left, right) => right.updatedAt.compareTo(
          left.updatedAt,
        ));

    return ChatConversationCatalog(
      activeConversationId: catalog.activeConversationId.isNotEmpty
          ? catalog.activeConversationId
          : (conversations.isEmpty ? '' : conversations.first.id),
      conversations: List<ChatConversationSummary>.unmodifiable(conversations),
    );
  }

  ChatConversationCatalog _mergeCatalogBackups(
    ChatConversationCatalog current,
    ChatConversationCatalog backup, {
    bool preferBackup = false,
  }) {
    final byId = <String, ChatConversationSummary>{};
    for (final conversation in current.conversations) {
      byId[conversation.id] = conversation;
    }
    for (final conversation in backup.conversations) {
      if (preferBackup) {
        byId[conversation.id] = conversation;
      } else {
        byId.putIfAbsent(conversation.id, () => conversation);
      }
    }

    final conversations = byId.values.toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    return ChatConversationCatalog(
      activeConversationId:
          preferBackup && backup.activeConversationId.isNotEmpty
              ? backup.activeConversationId
              : current.activeConversationId.isNotEmpty
                  ? current.activeConversationId
                  : backup.activeConversationId,
      conversations: List<ChatConversationSummary>.unmodifiable(conversations),
    );
  }

  ChatConversationCatalog _catalogUpdatedWithSnapshots(
    ChatConversationCatalog catalog,
    Map<String, ChatSessionSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) {
      return catalog;
    }

    final conversations = catalog.conversations.map((conversation) {
      final snapshot = snapshots[conversation.id];
      if (snapshot == null) {
        return conversation;
      }

      return _summaryFromSnapshot(conversation.id, snapshot).copyWith(
        title: conversation.title,
      );
    }).toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    return ChatConversationCatalog(
      activeConversationId: catalog.activeConversationId,
      conversations: List<ChatConversationSummary>.unmodifiable(conversations),
    );
  }

  ChatSessionSnapshot _mergeSnapshots(
    ChatSessionSnapshot current,
    ChatSessionSnapshot backup,
  ) {
    final messagesById = <String, ChatMessage>{};
    for (final message in current.messages) {
      messagesById[message.id] = message;
    }
    for (final message in backup.messages) {
      messagesById.putIfAbsent(message.id, () => message);
    }

    final messages = messagesById.values.toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final draft =
        current.draft.trim().isNotEmpty ? current.draft : backup.draft;

    return ChatSessionSnapshot(
      settings: current.settings,
      messages: List<ChatMessage>.unmodifiable(messages),
      draft: draft,
    );
  }

  ChatSessionSnapshot _currentSnapshot() {
    return ChatSessionSnapshot(
      settings: _settings,
      messages: List<ChatMessage>.unmodifiable(_messages),
      draft: _storageSettings.saveDrafts ? _draft : '',
    );
  }

  ChatConversationSummary _summaryFromSnapshot(
    String conversationId,
    ChatSessionSnapshot snapshot,
  ) {
    final messages = snapshot.messages;
    final updatedAt =
        messages.isEmpty ? DateTime.now() : messages.last.createdAt;
    String? title;
    for (final message in messages) {
      if (message.author != ChatMessageAuthor.user) {
        continue;
      }

      final normalized = message.content.trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
      if (normalized.isEmpty) {
        continue;
      }

      title = normalized.length <= 28
          ? normalized
          : '${normalized.substring(0, 28)}...';
      break;
    }

    return ChatConversationSummary(
      id: conversationId,
      title: title ?? conversationId,
      settings: snapshot.settings,
      updatedAt: updatedAt,
      messageCount: messages.length,
      lastMessagePreview: messages.isEmpty
          ? ''
          : messages.last.content.trim().replaceAll(RegExp(r'\s+'), ' '),
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

  Future<void> _clearConversationSnapshots(
    List<ChatConversationSummary> conversations,
  ) async {
    for (final conversation in conversations) {
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

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelDraftSnapshotSave();
    unawaited(_incomingMessageSubscription?.cancel());
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
