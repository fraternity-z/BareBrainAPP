import '../entities/chat_app_settings.dart';

abstract class ChatAppSettingsStore {
  Future<ChatAppSettings?> load();
  Future<void> save(ChatAppSettings settings);
  Future<void> clear();
}
