import 'chat_connection_settings.dart';

class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    required this.title,
    required this.settings,
    required this.updatedAt,
    required this.messageCount,
    this.lastMessagePreview = '',
  });

  final String id;
  final String title;
  final ChatConnectionSettings settings;
  final DateTime updatedAt;
  final int messageCount;
  final String lastMessagePreview;

  ChatConversationSummary copyWith({
    String? id,
    String? title,
    ChatConnectionSettings? settings,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessagePreview,
  }) {
    return ChatConversationSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
