import '../entities/chat_connection_settings.dart';
import '../entities/incoming_chat_message.dart';

abstract class ChatRepository {
  Future<void> checkConnection(ChatConnectionSettings settings);

  Stream<IncomingChatMessage> receiveMessages(
    ChatConnectionSettings settings, {
    required String chatId,
  });

  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  });
}
