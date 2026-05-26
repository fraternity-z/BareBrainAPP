import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_display_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyValueChatDisplaySettingsStore', () {
    test('saves and loads display settings', () async {
      final keyValueStore = MemoryKeyValueStore();
      final store = KeyValueChatDisplaySettingsStore(
        keyValueStore: keyValueStore,
      );

      await store.save(
        const ChatDisplaySettings(
          colorMode: ChatColorMode.dark,
          themePreset: ChatThemePreset.graphite,
          messageFontScale: 1.25,
        ),
      );

      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.colorMode, ChatColorMode.dark);
      expect(restored.themePreset, ChatThemePreset.graphite);
      expect(restored.messageFontScale, 1.25);
    });

    test('returns null when no settings are stored', () async {
      final store = KeyValueChatDisplaySettingsStore(
        keyValueStore: MemoryKeyValueStore(),
      );

      expect(await store.load(), isNull);
    });

    test('clears stored display settings', () async {
      final store = KeyValueChatDisplaySettingsStore(
        keyValueStore: MemoryKeyValueStore(),
      );

      await store.save(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );
      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
