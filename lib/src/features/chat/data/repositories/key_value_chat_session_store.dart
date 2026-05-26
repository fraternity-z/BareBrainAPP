import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/repositories/chat_session_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_session_snapshot_codec.dart';

class KeyValueChatSessionStore implements ChatSessionStore {
  const KeyValueChatSessionStore({
    required KeyValueStore keyValueStore,
    this.key = 'barebrain.chat.session',
  }) : _keyValueStore = keyValueStore;

  final KeyValueStore _keyValueStore;
  final String key;

  @override
  Future<ChatSessionSnapshot?> load() async {
    final source = await _keyValueStore.read(key);
    if (source == null || source.isEmpty) {
      return null;
    }

    return ChatSessionSnapshotCodec.decode(source);
  }

  @override
  Future<void> save(ChatSessionSnapshot snapshot) async {
    await _keyValueStore.write(
      key,
      ChatSessionSnapshotCodec.encode(snapshot),
    );
  }

  @override
  Future<void> clear() async {
    await _keyValueStore.delete(key);
  }
}

class KeyValueChatSessionStoreFactory implements ChatSessionStoreFactory {
  const KeyValueChatSessionStoreFactory({
    required KeyValueStore keyValueStore,
    this.keyPrefix = 'barebrain.chat.session',
  }) : _keyValueStore = keyValueStore;

  final KeyValueStore _keyValueStore;
  final String keyPrefix;

  @override
  ChatSessionStore forConversation(String conversationId) {
    return KeyValueChatSessionStore(
      keyValueStore: _keyValueStore,
      key: '$keyPrefix.${Uri.encodeComponent(conversationId)}',
    );
  }
}
