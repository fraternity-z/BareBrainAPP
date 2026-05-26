import '../../domain/entities/chat_connection_settings.dart';
import '../models/bare_brain_ws_payload.dart';

abstract class ChatTransport {
  Future<void> checkConnection(ChatConnectionSettings settings);

  Future<BareBrainWsPayload> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  });
}
