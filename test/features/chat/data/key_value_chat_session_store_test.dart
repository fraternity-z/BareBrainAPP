import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyValueChatSessionStore', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    test('saves and loads snapshots through key-value storage', () async {
      final keyValueStore = MemoryKeyValueStore();
      final store = KeyValueChatSessionStore(keyValueStore: keyValueStore);

      await store.save(
        ChatSessionSnapshot(
          settings: settings,
          messages: <ChatMessage>[
            ChatMessage(
              id: 'm1',
              author: ChatMessageAuthor.assistant,
              content: 'pong',
              createdAt: DateTime.utc(2026),
            ),
          ],
          draft: 'unfinished',
        ),
      );

      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.settings.clientId, 'barebrain_app');
      expect(restored.messages.single.content, 'pong');
      expect(restored.draft, 'unfinished');
    });

    test('returns null after clear', () async {
      final store = KeyValueChatSessionStore(
        keyValueStore: MemoryKeyValueStore(),
      );

      await store.save(
        const ChatSessionSnapshot(
          settings: settings,
          messages: <ChatMessage>[],
        ),
      );
      await store.clear();

      expect(await store.load(), isNull);
    });

    test('factory isolates snapshots by conversation id', () async {
      final keyValueStore = MemoryKeyValueStore();
      final factory = KeyValueChatSessionStoreFactory(
        keyValueStore: keyValueStore,
      );
      final first = factory.forConversation('default');
      final second = factory.forConversation('mobile');

      await first.save(
        const ChatSessionSnapshot(
          settings: settings,
          messages: <ChatMessage>[],
        ),
      );

      expect(await first.load(), isNotNull);
      expect(await second.load(), isNull);
    });
  });
}
