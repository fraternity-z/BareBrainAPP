import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/repositories/chat_conversation_catalog_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_conversation_catalog_codec.dart';

const int _backgroundCodecThreshold = 64 * 1024;

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

    if (source.length >= _backgroundCodecThreshold) {
      return compute(_decodeChatConversationCatalog, source);
    }

    return ChatConversationCatalogCodec.decode(source);
  }

  @override
  Future<void> save(ChatConversationCatalog catalog) async {
    final encoded =
        _estimatedCatalogPayloadSize(catalog) >= _backgroundCodecThreshold
            ? await compute(_encodeChatConversationCatalog, catalog)
            : ChatConversationCatalogCodec.encode(catalog);

    await _keyValueStore.write(
      key,
      encoded,
    );
  }

  @override
  Future<void> clear() async {
    await _keyValueStore.delete(key);
  }
}

String _encodeChatConversationCatalog(ChatConversationCatalog catalog) {
  return ChatConversationCatalogCodec.encode(catalog);
}

ChatConversationCatalog _decodeChatConversationCatalog(String source) {
  return ChatConversationCatalogCodec.decode(source);
}

int _estimatedCatalogPayloadSize(ChatConversationCatalog catalog) {
  var size = catalog.activeConversationId.length;
  for (final conversation in catalog.conversations) {
    size += conversation.id.length;
    size += conversation.title.length;
    size += conversation.lastMessagePreview.length;
    size += conversation.settings.websocketUri.toString().length;
    size += conversation.settings.clientId.length;
    size += 160;
  }

  return size;
}
