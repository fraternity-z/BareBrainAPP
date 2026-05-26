import 'package:bare_brain_app/src/features/chat/data/repositories/memory_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryChatSessionStore', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    test('saves and loads a defensive snapshot copy', () async {
      final store = MemoryChatSessionStore();
      final messages = <ChatMessage>[
        ChatMessage(
          id: 'm1',
          author: ChatMessageAuthor.user,
          content: 'hello',
          createdAt: DateTime(2026),
        ),
      ];

      await store.save(
        ChatSessionSnapshot(
          settings: settings,
          messages: messages,
          draft: 'unfinished',
        ),
      );
      messages.clear();

      final snapshot = await store.load();

      expect(snapshot, isNotNull);
      expect(
        snapshot!.settings.websocketUri.toString(),
        'ws://192.168.1.10:18789/',
      );
      expect(snapshot.messages, hasLength(1));
      expect(snapshot.messages.single.content, 'hello');
      expect(snapshot.draft, 'unfinished');
    });

    test('clears saved snapshot', () async {
      final store = MemoryChatSessionStore();

      await store.save(
        const ChatSessionSnapshot(
          settings: settings,
          messages: <ChatMessage>[],
        ),
      );
      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
