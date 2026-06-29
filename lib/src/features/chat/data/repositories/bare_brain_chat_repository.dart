import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/incoming_chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_transport.dart';

class BareBrainChatRepository implements ChatRepository {
  const BareBrainChatRepository({
    required ChatTransport transport,
  }) : _transport = transport;

  final ChatTransport _transport;

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) {
    return _transport.checkConnection(settings);
  }

  @override
  Stream<IncomingChatMessage> receiveMessages(
    ChatConnectionSettings settings, {
    required String chatId,
  }) {
    return _transport.receiveMessages(settings, chatId: chatId).map((event) {
      return IncomingChatMessage(
        content: event.content,
        chatId: event.chatId,
        requestId: event.requestId,
      );
    });
  }

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    final response = await _transport.sendMessage(
      content,
      settings,
      chatId: chatId,
    );
    final text = response.content.trim();

    if (text.isEmpty) {
      throw const ChatProtocolException('BareBrain 返回了空响应');
    }

    return text;
  }
}
