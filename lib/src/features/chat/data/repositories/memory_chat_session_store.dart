import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/repositories/chat_session_store.dart';

class MemoryChatSessionStore implements ChatSessionStore {
  ChatSessionSnapshot? _snapshot;

  @override
  Future<ChatSessionSnapshot?> load() async {
    final current = _snapshot;
    if (current == null) {
      return null;
    }

    return ChatSessionSnapshot(
      settings: current.settings,
      messages: List<ChatMessage>.unmodifiable(current.messages),
      draft: current.draft,
    );
  }

  @override
  Future<void> save(ChatSessionSnapshot snapshot) async {
    _snapshot = ChatSessionSnapshot(
      settings: snapshot.settings,
      messages: List<ChatMessage>.unmodifiable(snapshot.messages),
      draft: snapshot.draft,
    );
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}
