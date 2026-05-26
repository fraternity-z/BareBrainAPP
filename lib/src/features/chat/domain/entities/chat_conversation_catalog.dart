import 'chat_conversation_summary.dart';

class ChatConversationCatalog {
  const ChatConversationCatalog({
    required this.activeConversationId,
    required this.conversations,
  });

  final String activeConversationId;
  final List<ChatConversationSummary> conversations;

  ChatConversationSummary? get activeConversation {
    for (final conversation in conversations) {
      if (conversation.id == activeConversationId) {
        return conversation;
      }
    }

    return conversations.isEmpty ? null : conversations.first;
  }

  ChatConversationCatalog upsertActive(ChatConversationSummary summary) {
    final next = <ChatConversationSummary>[];
    var found = false;

    for (final conversation in conversations) {
      if (conversation.id == summary.id) {
        next.add(summary);
        found = true;
      } else {
        next.add(conversation);
      }
    }

    if (!found) {
      next.add(summary);
    }

    next.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

    return ChatConversationCatalog(
      activeConversationId: summary.id,
      conversations: List<ChatConversationSummary>.unmodifiable(next),
    );
  }

  ChatConversationCatalog remove(String conversationId) {
    final next = conversations
        .where((conversation) => conversation.id != conversationId)
        .toList(growable: false);
    final nextActiveId = activeConversationId == conversationId
        ? (next.isEmpty ? '' : next.first.id)
        : activeConversationId;

    return ChatConversationCatalog(
      activeConversationId: nextActiveId,
      conversations: List<ChatConversationSummary>.unmodifiable(next),
    );
  }

  ChatConversationCatalog rename(String conversationId, String title) {
    final next = conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }

      return conversation.copyWith(title: title);
    }).toList(growable: false);

    return ChatConversationCatalog(
      activeConversationId: activeConversationId,
      conversations: List<ChatConversationSummary>.unmodifiable(next),
    );
  }
}
