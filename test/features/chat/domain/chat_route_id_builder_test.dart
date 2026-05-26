import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/services/chat_route_id_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRouteIdBuilder', () {
    test('uses client id for the default conversation', () {
      final chatId = ChatRouteIdBuilder.build(
        clientId: 'barebrain_app',
        conversationId: 'default',
      );

      expect(chatId, 'barebrain_app');
    });

    test('derives a stable short id for non-default conversations', () {
      final chatId = ChatRouteIdBuilder.build(
        clientId: 'barebrain_app',
        conversationId: 'conversation-1780000000000000',
      );

      expect(chatId, startsWith('barebrain_app-'));
      expect(chatId.length, lessThanOrEqualTo(ChatRouteIdBuilder.maxLength));
      expect(
        chatId,
        ChatRouteIdBuilder.build(
          clientId: 'barebrain_app',
          conversationId: 'conversation-1780000000000000',
        ),
      );
    });

    test('sanitizes generated ids before validation', () {
      final chatId = ChatRouteIdBuilder.build(
        clientId: ' bare brain app ',
        conversationId: 'mobile room',
      );

      expect(chatId, 'bare-brain-app-mobile-room');
      expect(() => ChatRouteIdBuilder.validate(chatId), returnsNormally);
    });

    test('rejects externally supplied invalid ids', () {
      expect(
        () => ChatRouteIdBuilder.validate('bad chat id'),
        throwsA(isA<ChatValidationException>()),
      );
    });
  });
}
