import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/check_chat_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckChatConnection', () {
    const settings = ChatConnectionSettings(
      host: ' 192.168.1.10 ',
      port: 18789,
      clientId: ' barebrain_app ',
      responseTimeout: Duration(seconds: 10),
    );

    test('normalizes settings before checking connection', () async {
      final repository = _FakeRepository();
      final useCase = CheckChatConnection(repository);

      await useCase(settings);

      expect(repository.lastSettings!.host, '192.168.1.10');
      expect(repository.lastSettings!.clientId, 'barebrain_app');
    });

    test('rejects invalid settings before checking connection', () async {
      final useCase = CheckChatConnection(_FakeRepository());

      await expectLater(
        useCase(settings.copyWith(port: 0)),
        throwsA(isA<ChatValidationException>()),
      );
    });
  });
}

class _FakeRepository implements ChatRepository {
  ChatConnectionSettings? lastSettings;

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {
    lastSettings = settings;
  }

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    return 'pong';
  }
}
