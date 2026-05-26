import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/models/chat_conversation_catalog_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_conversation_catalog.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_conversation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConversationCatalogCodec', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 30),
    );

    test('round-trips catalog summaries', () {
      final catalog = ChatConversationCatalog(
        activeConversationId: 'default',
        conversations: <ChatConversationSummary>[
          ChatConversationSummary(
            id: 'default',
            title: 'BareBrain',
            settings: settings,
            updatedAt: DateTime.utc(2026, 5, 25, 8, 30),
            messageCount: 2,
            lastMessagePreview: 'pong',
          ),
        ],
      );

      final restored = ChatConversationCatalogCodec.decode(
        ChatConversationCatalogCodec.encode(catalog),
      );

      expect(restored.activeConversationId, 'default');
      expect(restored.conversations.single.title, 'BareBrain');
      expect(restored.conversations.single.messageCount, 2);
      expect(restored.conversations.single.settings.port, 18789);
    });

    test('rejects malformed catalog JSON', () {
      expect(
        () => ChatConversationCatalogCodec.decode('{"conversations":[]}'),
        throwsA(isA<ChatStorageException>()),
      );
    });

    test('removes conversations while keeping active id stable', () {
      final catalog = ChatConversationCatalog(
        activeConversationId: 'active',
        conversations: <ChatConversationSummary>[
          ChatConversationSummary(
            id: 'active',
            title: 'Active',
            settings: settings,
            updatedAt: DateTime.utc(2026, 5, 25),
            messageCount: 1,
          ),
          ChatConversationSummary(
            id: 'old',
            title: 'Old',
            settings: settings,
            updatedAt: DateTime.utc(2026, 5, 24),
            messageCount: 1,
          ),
        ],
      );

      final next = catalog.remove('old');

      expect(next.activeConversationId, 'active');
      expect(next.conversations.single.id, 'active');
    });

    test('renames a conversation summary', () {
      final catalog = ChatConversationCatalog(
        activeConversationId: 'default',
        conversations: <ChatConversationSummary>[
          ChatConversationSummary(
            id: 'default',
            title: 'BareBrain',
            settings: settings,
            updatedAt: DateTime.utc(2026, 5, 25),
            messageCount: 1,
          ),
        ],
      );

      final next = catalog.rename('default', 'Office');

      expect(next.activeConversationId, 'default');
      expect(next.conversations.single.title, 'Office');
    });
  });
}
