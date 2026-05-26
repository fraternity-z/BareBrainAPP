import '../entities/chat_connection_settings.dart';

abstract class ChatRepository {
  Future<void> checkConnection(ChatConnectionSettings settings);

  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  });
}
