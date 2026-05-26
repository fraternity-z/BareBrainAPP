class ChatConversationTitleBuilder {
  const ChatConversationTitleBuilder._();

  static const maxLength = 36;
  static final _whitespace = RegExp(r'\s+');

  static String fromMessage(String content) {
    final normalized = content.trim().replaceAll(_whitespace, ' ');
    if (normalized.isEmpty) {
      return '新会话';
    }

    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength - 3)}...';
  }
}
