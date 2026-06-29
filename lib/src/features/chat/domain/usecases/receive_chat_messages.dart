import '../entities/chat_connection_settings.dart';
import '../entities/incoming_chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_connection_settings_parser.dart';
import '../services/chat_route_id_builder.dart';

class ReceiveChatMessages {
  const ReceiveChatMessages(this._repository);

  final ChatRepository _repository;

  Stream<IncomingChatMessage> call(
    ChatConnectionSettings settings, {
    required String chatId,
  }) {
    final normalizedSettings = ChatConnectionSettingsParser.normalize(settings);
    ChatRouteIdBuilder.validate(chatId);

    return _repository.receiveMessages(
      normalizedSettings,
      chatId: chatId.trim(),
    );
  }
}
