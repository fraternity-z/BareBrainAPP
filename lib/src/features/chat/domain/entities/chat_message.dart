enum ChatMessageAuthor {
  user,
  assistant,
  system,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.isPending = false,
    this.error,
  });

  final String id;
  final ChatMessageAuthor author;
  final String content;
  final DateTime createdAt;
  final bool isPending;
  final String? error;

  ChatMessage copyWith({
    String? id,
    ChatMessageAuthor? author,
    String? content,
    DateTime? createdAt,
    bool? isPending,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPending: isPending ?? this.isPending,
      error: error ?? this.error,
    );
  }
}
