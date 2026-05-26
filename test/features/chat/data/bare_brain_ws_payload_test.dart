import 'package:bare_brain_app/src/features/chat/data/models/bare_brain_ws_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BareBrainWsPayload', () {
    test('encodes inbound message with BareBrain protocol fields', () {
      final payload = BareBrainWsPayload.message(
        content: 'hello',
        chatId: 'barebrain_app',
      );

      expect(
        payload.toJson(),
        <String, dynamic>{
          'type': 'message',
          'content': 'hello',
          'chat_id': 'barebrain_app',
        },
      );
    });

    test('decodes outbound response', () {
      final payload = BareBrainWsPayload.decode(
        '{"type":"response","content":"Hi","chat_id":"barebrain_app"}',
      );

      expect(payload.isResponse, isTrue);
      expect(payload.content, 'Hi');
      expect(payload.chatId, 'barebrain_app');
    });

    test('rejects malformed JSON', () {
      expect(
        () => BareBrainWsPayload.decode('{'),
        throwsException,
      );
    });
  });
}
