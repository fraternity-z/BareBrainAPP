import '../../domain/entities/chat_display_settings.dart';
import '../../domain/repositories/chat_display_settings_store.dart';
import '../datasources/key_value_store.dart';
import '../models/chat_display_settings_codec.dart';

class KeyValueChatDisplaySettingsStore implements ChatDisplaySettingsStore {
  const KeyValueChatDisplaySettingsStore({
    required KeyValueStore keyValueStore,
    this.key = 'barebrain.chat.display_settings',
  }) : _keyValueStore = keyValueStore;

  final KeyValueStore _keyValueStore;
  final String key;

  @override
  Future<ChatDisplaySettings?> load() async {
    final source = await _keyValueStore.read(key);
    if (source == null || source.isEmpty) {
      return null;
    }

    return ChatDisplaySettingsCodec.decode(source);
  }

  @override
  Future<void> save(ChatDisplaySettings settings) async {
    await _keyValueStore.write(
      key,
      ChatDisplaySettingsCodec.encode(settings),
    );
  }

  @override
  Future<void> clear() async {
    await _keyValueStore.delete(key);
  }
}
