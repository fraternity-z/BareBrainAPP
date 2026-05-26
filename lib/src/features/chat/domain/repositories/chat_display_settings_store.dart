import '../entities/chat_display_settings.dart';

abstract class ChatDisplaySettingsStore {
  Future<ChatDisplaySettings?> load();
  Future<void> save(ChatDisplaySettings settings);
  Future<void> clear();
}
