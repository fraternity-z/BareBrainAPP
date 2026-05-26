import '../entities/chat_connection_settings.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_connection_settings_parser.dart';

class CheckChatConnection {
  const CheckChatConnection(this._repository);

  final ChatRepository _repository;

  Future<void> call(ChatConnectionSettings settings) {
    final normalizedSettings = ChatConnectionSettingsParser.normalize(settings);
    return _repository.checkConnection(normalizedSettings);
  }
}
