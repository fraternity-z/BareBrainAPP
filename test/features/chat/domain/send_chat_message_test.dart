import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/send_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendChatMessage', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    test('trims content before sending', () async {
      final repository = _FakeRepository(response: 'pong');
      final useCase = SendChatMessage(repository);

      final response = await useCase(
        '  ping  ',
        settings.copyWith(
          host: ' 192.168.1.10 ',
          clientId: ' barebrain_app ',
        ),
        chatId: 'barebrain_app',
      );

      expect(response, 'pong');
      expect(repository.lastContent, 'ping');
      expect(repository.lastSettings!.host, '192.168.1.10');
      expect(repository.lastSettings!.clientId, 'barebrain_app');
      expect(repository.lastChatId, 'barebrain_app');
    });

    test('rejects blank content', () async {
      final useCase = SendChatMessage(_FakeRepository(response: 'pong'));

      await expectLater(
        useCase('   ', settings, chatId: 'barebrain_app'),
        throwsA(isA<ChatValidationException>()),
      );
    });

    test('rejects invalid port', () async {
      final useCase = SendChatMessage(_FakeRepository(response: 'pong'));

      await expectLater(
        useCase(
          'hello',
          settings.copyWith(port: 0),
          chatId: 'barebrain_app',
        ),
        throwsA(isA<ChatValidationException>()),
      );
    });

    test('rejects invalid client id', () async {
      final useCase = SendChatMessage(_FakeRepository(response: 'pong'));

      await expectLater(
        useCase(
          'hello',
          settings.copyWith(clientId: 'bad id'),
          chatId: 'barebrain_app',
        ),
        throwsA(isA<ChatValidationException>()),
      );
    });

    test('rejects invalid BareBrain chat id', () async {
      final useCase = SendChatMessage(_FakeRepository(response: 'pong'));

      await expectLater(
        useCase('hello', settings, chatId: 'bad chat id'),
        throwsA(isA<ChatValidationException>()),
      );
    });
  });
}

class _FakeRepository implements ChatRepository {
  _FakeRepository({required this.response});

  final String response;
  String? lastContent;
  ChatConnectionSettings? lastSettings;
  String? lastChatId;

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    lastContent = content;
    lastSettings = settings;
    lastChatId = chatId;
    return response;
  }
}
