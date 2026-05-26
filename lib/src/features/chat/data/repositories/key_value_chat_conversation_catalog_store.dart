import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/repositories/chat_conversation_catalog_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_conversation_catalog_codec.dart';

class KeyValueChatConversationCatalogStore
    implements ChatConversationCatalogStore {
  const KeyValueChatConversationCatalogStore({
    required KeyValueStore keyValueStore,
    this.key = 'barebrain.chat.catalog',
  }) : _keyValueStore = keyValueStore;

  final KeyValueStore _keyValueStore;
  final String key;

  @override
  Future<ChatConversationCatalog?> load() async {
    final source = await _keyValueStore.read(key);
    if (source == null || source.isEmpty) {
      return null;
    }

    return ChatConversationCatalogCodec.decode(source);
  }

  @override
  Future<void> save(ChatConversationCatalog catalog) async {
    await _keyValueStore.write(
      key,
      ChatConversationCatalogCodec.encode(catalog),
    );
  }

  @override
  Future<void> clear() async {
    await _keyValueStore.delete(key);
  }
}
