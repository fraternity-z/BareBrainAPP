class IncomingChatMessage {
  const IncomingChatMessage({
    required this.content,
    this.chatId = '',
    this.requestId = '',
  });

  final String content;
  final String chatId;
  final String requestId;
}
