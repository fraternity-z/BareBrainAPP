import '../../../../core/errors/chat_exception.dart';
import '../entities/chat_connection_settings.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_connection_settings_parser.dart';
import '../services/chat_route_id_builder.dart';

class SendChatMessage {
  const SendChatMessage(this._repository);

  final ChatRepository _repository;

  Future<String> call(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      throw const ChatValidationException('消息不能为空');
    }

    final normalizedSettings = ChatConnectionSettingsParser.normalize(settings);
    ChatRouteIdBuilder.validate(chatId);

    return _repository.sendMessage(
      normalized,
      normalizedSettings,
      chatId: chatId.trim(),
    );
  }
}
