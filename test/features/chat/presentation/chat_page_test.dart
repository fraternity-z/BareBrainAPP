import 'package:bare_brain_app/src/features/chat/data/repositories/memory_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/send_chat_message.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:bare_brain_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatPage', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    testWidgets('syncs composer when a restored draft arrives', (tester) async {
      final store = MemoryChatSessionStore();
      await store.save(
        const ChatSessionSnapshot(
          settings: settings,
          messages: [],
          draft: 'half typed',
        ),
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
        sessionStore: store,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      expect(_composerText(tester), isEmpty);

      await controller.restore();
      await tester.pump();

      expect(_composerText(tester), 'half typed');

      controller.dispose();
    });
  });
}

String _composerText(WidgetTester tester) {
  final textField = tester.widget<TextField>(find.byType(TextField));
  return textField.controller!.text;
}

class _FakeRepository implements ChatRepository {
  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    return 'pong';
  }
}
