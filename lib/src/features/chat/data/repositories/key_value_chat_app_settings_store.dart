import '../../domain/entities/chat_app_settings.dart';
import '../../domain/repositories/chat_app_settings_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_app_settings_codec.dart';

class KeyValueChatAppSettingsStore implements ChatAppSettingsStore {
  const KeyValueChatAppSettingsStore({
    required KeyValueStore keyValueStore,
    this.key = 'barebrain.chat.app_settings',
  }) : _keyValueStore = keyValueStore;

  final KeyValueStore _keyValueStore;
  final String key;

  @override
  Future<ChatAppSettings?> load() async {
    final source = await _keyValueStore.read(key);
    if (source == null || source.isEmpty) {
      return null;
    }

    return ChatAppSettingsCodec.decode(source);
  }

  @override
  Future<void> save(ChatAppSettings settings) async {
    await _keyValueStore.write(key, ChatAppSettingsCodec.encode(settings));
  }

  @override
  Future<void> clear() async {
    await _keyValueStore.delete(key);
  }
}
