import 'package:bare_brain_app/src/features/chat/chat_feature_module.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/chat_transport.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/models/bare_brain_ws_payload.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatFeatureModule', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    test('wires chat transport and persistent stores', () async {
      final keyValueStore = MemoryKeyValueStore();
      final transport = _FakeTransport();
      final controller = ChatFeatureModule.createController(
        initialSettings: settings,
        keyValueStore: keyValueStore,
        transport: transport,
      );

      await controller.send('ping');

      await controller.testConnection(settings);

      expect(transport.lastContent, 'ping');
      expect(transport.lastChatId, 'barebrain_app');
      expect(transport.checked, isTrue);
      expect(controller.messages.last.content, 'pong');

      final restored = ChatFeatureModule.createController(
        initialSettings: settings,
        keyValueStore: keyValueStore,
        transport: _FakeTransport(),
      );
      await restored.restore();

      expect(restored.messages, hasLength(2));
      expect(restored.messages.first.content, 'ping');
      expect(restored.messages.last.content, 'pong');
      expect(restored.conversations.single.messageCount, 2);

      controller.dispose();
      restored.dispose();
    });
  });
}

class _FakeTransport implements ChatTransport {
  String? lastContent;
  String? lastChatId;
  bool checked = false;

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {
    checked = true;
  }

  @override
  Future<BareBrainWsPayload> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    lastContent = content;
    lastChatId = chatId;
    return BareBrainWsPayload(
      type: 'response',
      content: 'pong',
      chatId: chatId,
    );
  }
}
