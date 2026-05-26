import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/models/chat_session_snapshot_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatSessionSnapshotCodec', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 90),
      secure: true,
    );

    test('round-trips settings and messages', () {
      final snapshot = ChatSessionSnapshot(
        settings: settings,
        messages: <ChatMessage>[
          ChatMessage(
            id: 'm1',
            author: ChatMessageAuthor.user,
            content: 'hello',
            createdAt: DateTime.utc(2026, 5, 25, 8, 30),
          ),
          ChatMessage(
            id: 'm2',
            author: ChatMessageAuthor.system,
            content: 'offline',
            createdAt: DateTime.utc(2026, 5, 25, 8, 31),
            error: 'offline',
          ),
        ],
        draft: 'unfinished prompt',
      );

      final restored = ChatSessionSnapshotCodec.decode(
        ChatSessionSnapshotCodec.encode(snapshot),
      );

      expect(
        restored.settings.websocketUri.toString(),
        'wss://192.168.1.10:18789/',
      );
      expect(restored.settings.responseTimeout, const Duration(seconds: 90));
      expect(restored.messages, hasLength(2));
      expect(restored.messages.first.author, ChatMessageAuthor.user);
      expect(restored.messages.last.error, 'offline');
      expect(restored.draft, 'unfinished prompt');
    });

    test('rejects malformed snapshots', () {
      expect(
        () => ChatSessionSnapshotCodec.decode('{"messages":[]}'),
        throwsA(isA<ChatStorageException>()),
      );
    });
  });
}
