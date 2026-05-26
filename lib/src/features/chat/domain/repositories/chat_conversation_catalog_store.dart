import '../entities/chat_conversation_catalog.dart';

abstract class ChatConversationCatalogStore {
  Future<ChatConversationCatalog?> load();
  Future<void> save(ChatConversationCatalog catalog);
  Future<void> clear();
}
