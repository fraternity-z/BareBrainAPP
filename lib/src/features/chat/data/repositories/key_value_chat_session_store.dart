import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_session_snapshot.dart';
import '../../domain/repositories/chat_session_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_session_snapshot_codec.dart';

const int _backgroundCodecThreshold = 64 * 1024;

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

    if (source.length >= _backgroundCodecThreshold) {
      return compute(_decodeChatSessionSnapshot, source);
    }

    return ChatSessionSnapshotCodec.decode(source);
  }

  @override
  Future<void> save(ChatSessionSnapshot snapshot) async {
    final encoded =
        _estimatedSnapshotPayloadSize(snapshot) >= _backgroundCodecThreshold
            ? await compute(_encodeChatSessionSnapshot, snapshot)
            : ChatSessionSnapshotCodec.encode(snapshot);

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

String _encodeChatSessionSnapshot(ChatSessionSnapshot snapshot) {
  return ChatSessionSnapshotCodec.encode(snapshot);
}

ChatSessionSnapshot _decodeChatSessionSnapshot(String source) {
  return ChatSessionSnapshotCodec.decode(source);
}

int _estimatedSnapshotPayloadSize(ChatSessionSnapshot snapshot) {
  var size = snapshot.draft.length;
  for (final message in snapshot.messages) {
    size += message.id.length;
    size += message.content.length;
    size += message.error?.length ?? 0;
    size += 96;
  }

  return size;
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
