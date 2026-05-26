import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_conversation_catalog_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_conversation_catalog.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_conversation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyValueChatConversationCatalogStore', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 30),
    );

    test('saves and loads a catalog', () async {
      final store = KeyValueChatConversationCatalogStore(
        keyValueStore: MemoryKeyValueStore(),
      );

      await store.save(
        ChatConversationCatalog(
          activeConversationId: 'default',
          conversations: <ChatConversationSummary>[
            ChatConversationSummary(
              id: 'default',
              title: 'BareBrain',
              settings: settings,
              updatedAt: DateTime.utc(2026),
              messageCount: 1,
              lastMessagePreview: 'hello',
            ),
          ],
        ),
      );

      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.activeConversation!.lastMessagePreview, 'hello');
    });

    test('clears a catalog', () async {
      final store = KeyValueChatConversationCatalogStore(
        keyValueStore: MemoryKeyValueStore(),
      );

      await store.save(
        const ChatConversationCatalog(
          activeConversationId: 'default',
          conversations: <ChatConversationSummary>[],
        ),
      );
      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
