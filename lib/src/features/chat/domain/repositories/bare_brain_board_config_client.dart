import '../entities/chat_connection_settings.dart';

abstract class BareBrainBoardConfigClient {
  Future<Map<String, String>> fetchConfig(ChatConnectionSettings settings);

  Future<void> saveConfig(
    ChatConnectionSettings settings,
    Map<String, String> patch,
  );
}
