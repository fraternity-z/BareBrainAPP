import '../entities/chat_session_snapshot.dart';

abstract class ChatSessionStore {
  Future<ChatSessionSnapshot?> load();
  Future<void> save(ChatSessionSnapshot snapshot);
  Future<void> clear();
}

abstract class ChatSessionStoreFactory {
  ChatSessionStore forConversation(String conversationId);
}
