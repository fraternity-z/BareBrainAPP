import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_conversation_catalog_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/memory_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/services/chat_route_id_builder.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/send_chat_message.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatController', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    test('adds user and assistant messages after a successful send', () async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
      );

      await controller.send('ping');

      expect(controller.messages, hasLength(2));
      expect(controller.messages[0].author, ChatMessageAuthor.user);
      expect(controller.messages[1].author, ChatMessageAuthor.assistant);
      expect(controller.messages[1].content, 'pong');
      expect(controller.isSending, isFalse);
    });

    test('records a system message when send fails', () async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(
          _FakeRepository(error: const ChatConnectionException('offline')),
        ),
        initialSettings: settings,
      );

      await controller.send('ping');

      expect(controller.errorMessage, 'offline');
      expect(controller.messages.last.author, ChatMessageAuthor.system);
      expect(controller.messages.last.error, 'offline');
    });

    test('retries the last failed user message without duplicating it',
        () async {
      final repository = _RetryRepository();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(repository),
        initialSettings: settings,
      );

      await controller.send('ping');

      expect(controller.canRetryLastMessage, isTrue);
      expect(controller.messages, hasLength(2));
      expect(controller.messages.last.author, ChatMessageAuthor.system);

      await controller.retryLastUserMessage();

      expect(controller.errorMessage, isNull);
      expect(controller.canRetryLastMessage, isFalse);
      expect(controller.messages, hasLength(2));
      expect(
        controller.messages
            .where((message) => message.author == ChatMessageAuthor.user),
        hasLength(1),
      );
      expect(controller.messages.first.content, 'ping');
      expect(controller.messages.first.isPending, isFalse);
      expect(controller.messages.last.author, ChatMessageAuthor.assistant);
      expect(controller.messages.last.content, 'pong');
      expect(repository.contents, <String>['ping', 'ping']);
    });

    test('restores messages and settings from session store', () async {
      final store = MemoryChatSessionStore();
      await store.save(
        ChatSessionSnapshot(
          settings: settings.copyWith(host: '192.168.1.20'),
          messages: <ChatMessage>[
            ChatMessage(
              id: 'm1',
              author: ChatMessageAuthor.assistant,
              content: 'restored',
              createdAt: DateTime(2026),
              isPending: true,
            ),
          ],
          draft: 'unfinished',
        ),
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStore: store,
      );

      await controller.restore();

      expect(controller.settings.host, '192.168.1.20');
      expect(controller.draft, 'unfinished');
      expect(controller.messages.single.content, 'restored');
      expect(controller.messages.single.isPending, isFalse);
    });

    test('persists drafts by conversation', () async {
      final keyValueStore = MemoryKeyValueStore();
      final sessionStoreFactory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStoreFactory: sessionStoreFactory,
        catalogStore: catalogStore,
      );

      controller.updateDraft('first draft');
      await Future<void>.delayed(Duration.zero);
      await controller.createConversation(title: 'Mobile');
      final secondId = controller.conversationId;
      controller.updateDraft('second draft');
      await Future<void>.delayed(Duration.zero);

      await controller.selectConversation('default');

      expect(controller.draft, 'first draft');

      await controller.selectConversation(secondId);

      expect(controller.draft, 'second draft');
    });

    test('clears draft after sending', () async {
      final store = MemoryChatSessionStore();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStore: store,
      );

      controller.updateDraft('unfinished');
      await controller.send('ping');

      final snapshot = await store.load();

      expect(controller.draft, isEmpty);
      expect(snapshot!.draft, isEmpty);
      expect(snapshot.messages.last.content, 'pong');
    });

    test('persists sent messages and keeps settings when clearing chat',
        () async {
      final store = MemoryChatSessionStore();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStore: store,
      );

      await controller.send('ping');
      var snapshot = await store.load();

      expect(snapshot!.messages, hasLength(2));
      expect(snapshot.settings.clientId, 'barebrain_app');

      controller.clear();
      await Future<void>.delayed(Duration.zero);
      snapshot = await store.load();

      expect(snapshot, isNotNull);
      expect(snapshot!.messages, isEmpty);
      expect(snapshot.settings.clientId, 'barebrain_app');
    });

    test('updates conversation catalog when messages change', () async {
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: MemoryKeyValueStore(),
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        catalogStore: catalogStore,
      );

      await controller.send('ping');
      final catalog = await catalogStore.load();

      expect(catalog, isNotNull);
      expect(catalog!.activeConversationId, 'default');
      expect(catalog.activeConversation!.messageCount, 2);
      expect(catalog.activeConversation!.lastMessagePreview, 'pong');
    });

    test('auto titles generated conversations from first user message',
        () async {
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: MemoryKeyValueStore(),
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        catalogStore: catalogStore,
      );

      await controller.send('  summarize\nBareBrain   status  ');

      final catalog = await catalogStore.load();

      expect(
        catalog!.activeConversation!.title,
        'summarize BareBrain status',
      );
    });

    test('keeps manually provided conversation titles', () async {
      final keyValueStore = MemoryKeyValueStore();
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        catalogStore: catalogStore,
      );

      await controller.createConversation(title: 'Office');
      await controller.send('summarize BareBrain status');

      final catalog = await catalogStore.load();

      expect(catalog!.activeConversation!.title, 'Office');
    });

    test('uses session store factory for the current conversation id',
        () async {
      final keyValueStore = MemoryKeyValueStore();
      final sessionStoreFactory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStoreFactory: sessionStoreFactory,
        conversationId: 'mobile',
      );

      await controller.send('ping');

      final mobileSnapshot =
          await sessionStoreFactory.forConversation('mobile').load();
      final defaultSnapshot =
          await sessionStoreFactory.forConversation('default').load();

      expect(mobileSnapshot, isNotNull);
      expect(mobileSnapshot!.messages, hasLength(2));
      expect(defaultSnapshot, isNull);
    });

    test('creates and switches conversations with isolated snapshots',
        () async {
      final keyValueStore = MemoryKeyValueStore();
      final sessionStoreFactory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStoreFactory: sessionStoreFactory,
        catalogStore: catalogStore,
      );

      await controller.send('first');
      await controller.createConversation(title: 'Mobile');
      final secondId = controller.conversationId;
      await controller.send('second');

      expect(controller.conversations, hasLength(2));
      expect(controller.messages.first.content, 'second');

      await controller.selectConversation('default');

      expect(controller.conversationId, 'default');
      expect(controller.messages.first.content, 'first');

      await controller.selectConversation(secondId);

      expect(controller.conversationId, secondId);
      expect(controller.messages.first.content, 'second');
    });

    test('uses isolated BareBrain chat ids for local conversations', () async {
      final repository = _FakeRepository(response: 'pong');
      final keyValueStore = MemoryKeyValueStore();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(repository),
        initialSettings: settings,
        sessionStoreFactory: KeyValueChatSessionStoreFactory(
          keyValueStore: keyValueStore,
        ),
        catalogStore: KeyValueChatConversationCatalogStore(
          keyValueStore: keyValueStore,
        ),
      );

      await controller.send('first');
      await controller.createConversation(title: 'Mobile');
      final secondId = controller.conversationId;
      await controller.send('second');

      expect(repository.chatIds.first, 'barebrain_app');
      expect(
        repository.chatIds.last,
        ChatRouteIdBuilder.build(
          clientId: 'barebrain_app',
          conversationId: secondId,
        ),
      );
      expect(repository.chatIds.last, isNot(repository.chatIds.first));
    });

    test('deletes only inactive conversations', () async {
      final keyValueStore = MemoryKeyValueStore();
      final sessionStoreFactory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStoreFactory: sessionStoreFactory,
        catalogStore: catalogStore,
      );

      await controller.send('first');
      await controller.createConversation(title: 'Mobile');
      await controller.send('second');

      await controller.deleteConversation('default');

      expect(controller.conversations, hasLength(1));
      expect(controller.conversations.single.title, 'Mobile');
      expect(
        await sessionStoreFactory.forConversation('default').load(),
        isNull,
      );

      await controller.deleteConversation(controller.conversationId);

      expect(controller.errorMessage, '不能删除当前会话');
      expect(controller.conversations, hasLength(1));
    });

    test('renames conversations and rejects blank titles', () async {
      final keyValueStore = MemoryKeyValueStore();
      final sessionStoreFactory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final catalogStore = KeyValueChatConversationCatalogStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository(response: 'pong')),
        initialSettings: settings,
        sessionStoreFactory: sessionStoreFactory,
        catalogStore: catalogStore,
      );

      await controller.send('first');
      await controller.renameConversation('default', ' Office ');

      expect(controller.conversations.single.title, 'Office');

      await controller.renameConversation('default', '   ');

      expect(controller.errorMessage, '会话标题不能为空');
      expect(controller.conversations.single.title, 'Office');
    });
  });
}

class _FakeRepository implements ChatRepository {
  _FakeRepository({
    this.response,
    this.error,
  });

  final String? response;
  final ChatException? error;
  final List<String> chatIds = <String>[];

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    chatIds.add(chatId);
    if (error != null) {
      throw error!;
    }
    return response ?? '';
  }
}

class _RetryRepository implements ChatRepository {
  final List<String> contents = <String>[];

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    contents.add(content);
    if (contents.length == 1) {
      throw const ChatConnectionException('offline');
    }

    return 'pong';
  }
}
