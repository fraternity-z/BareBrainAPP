import 'chat_connection_settings.dart';
import 'chat_message.dart';

class ChatSessionSnapshot {
  const ChatSessionSnapshot({
    required this.settings,
    required this.messages,
    this.draft = '',
  });

  final ChatConnectionSettings settings;
  final List<ChatMessage> messages;
  final String draft;
}
