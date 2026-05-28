import '../entities/chat_app_settings.dart';

abstract class ChatVoiceOutput {
  Future<void> speak(String content, ChatVoiceSettings settings);
}
