import 'dart:async';

import 'package:bare_brain_app/src/features/chat/data/datasources/key_value_store.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/key_value_chat_app_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_app_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_app_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatAppSettingsController', () {
    test('restores and saves app settings through the store', () async {
      final keyValueStore = MemoryKeyValueStore();
      final store = KeyValueChatAppSettingsStore(
        keyValueStore: keyValueStore,
      );
      final controller = ChatAppSettingsController(store: store);

      controller.updateQuickPhrases(
        const <ChatQuickPhrase>[
          ChatQuickPhrase(
            id: 'phrase-1',
            title: '开场白',
            content: '你好',
          ),
        ],
      );
      await Future<void>.delayed(Duration.zero);

      final restored = ChatAppSettingsController(store: store);
      await restored.restore();

      expect(restored.settings.quickPhrases, hasLength(1));
      expect(restored.settings.quickPhrases.single.title, '开场白');

      controller.dispose();
      restored.dispose();
    });

    test('does not overwrite updates made while restore is pending', () async {
      final store = _DeferredStore(
        const ChatAppSettings(
          voice: ChatVoiceSettings(enabled: true),
        ),
      );
      final controller = ChatAppSettingsController(store: store);

      final restore = controller.restore();
      controller.updateVoice(
        const ChatVoiceSettings(
          enabled: true,
          provider: ChatVoiceProvider.custom,
          endpoint: 'https://voice.example.com',
        ),
      );
      store.completeLoad();
      await restore;

      expect(controller.settings.voice.provider, ChatVoiceProvider.custom);

      controller.dispose();
    });

    test('ignores stale restore errors after settings update', () async {
      final store = _DeferredStore(null);
      final controller = ChatAppSettingsController(store: store);

      final restore = controller.restore();
      controller.updateVoice(
        const ChatVoiceSettings(
          enabled: true,
          endpoint: 'https://voice.example.com',
        ),
      );
      store.failLoad(Exception('old load failed'));
      await restore;

      expect(controller.errorMessage, isNull);
      expect(controller.settings.voice.endpoint, 'https://voice.example.com');
      controller.dispose();
    });

    test('exposes restore failures without changing settings', () async {
      final controller = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          voice: ChatVoiceSettings(enabled: true),
        ),
        store: _FailingLoadAppSettingsStore(),
      );

      await controller.restore();

      expect(controller.settings.voice.enabled, isTrue);
      expect(controller.errorMessage, contains('恢复应用设置失败'));
      controller.dispose();
    });

    test('exposes save failures after updates', () async {
      final controller = ChatAppSettingsController(
        store: _FailingSaveAppSettingsStore(),
      );

      controller.updateVoice(
        const ChatVoiceSettings(
          enabled: true,
          endpoint: 'https://voice.example.com',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.settings.voice.enabled, isTrue);
      expect(controller.errorMessage, contains('保存应用设置失败'));
      controller.dispose();
    });

    test('serializes pending saves and persists the latest settings', () async {
      final store = _BlockingSaveAppSettingsStore();
      final controller = ChatAppSettingsController(store: store);

      controller.updateVoice(
        const ChatVoiceSettings(
          enabled: true,
          endpoint: 'https://voice.example.com/first',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      controller.updateVoice(
        const ChatVoiceSettings(
          enabled: true,
          endpoint: 'https://voice.example.com/latest',
        ),
      );

      expect(store.savedSettings, hasLength(1));
      expect(
        store.savedSettings.single.voice.endpoint,
        'https://voice.example.com/first',
      );

      store.releaseFirstSave();
      await store.secondSaveCompleted.future;

      expect(store.savedSettings, hasLength(2));
      expect(
        store.savedSettings.last.voice.endpoint,
        'https://voice.example.com/latest',
      );
      controller.dispose();
    });
  });
}

class _DeferredStore implements ChatAppSettingsStore {
  _DeferredStore(this.settings);

  final ChatAppSettings? settings;
  final _loadCompleter = Completer<ChatAppSettings?>();

  void completeLoad() {
    _loadCompleter.complete(settings);
  }

  void failLoad(Object error) {
    _loadCompleter.completeError(error);
  }

  @override
  Future<ChatAppSettings?> load() {
    return _loadCompleter.future;
  }

  @override
  Future<void> save(ChatAppSettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _FailingLoadAppSettingsStore implements ChatAppSettingsStore {
  @override
  Future<ChatAppSettings?> load() {
    throw Exception('load failed');
  }

  @override
  Future<void> save(ChatAppSettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _FailingSaveAppSettingsStore implements ChatAppSettingsStore {
  @override
  Future<ChatAppSettings?> load() async => null;

  @override
  Future<void> save(ChatAppSettings settings) {
    throw Exception('save failed');
  }

  @override
  Future<void> clear() async {}
}

class _BlockingSaveAppSettingsStore implements ChatAppSettingsStore {
  final Completer<void> _firstSaveCompleter = Completer<void>();
  final Completer<void> secondSaveCompleted = Completer<void>();
  final List<ChatAppSettings> savedSettings = <ChatAppSettings>[];

  void releaseFirstSave() {
    _firstSaveCompleter.complete();
  }

  @override
  Future<ChatAppSettings?> load() async => null;

  @override
  Future<void> save(ChatAppSettings settings) async {
    savedSettings.add(settings);
    if (savedSettings.length == 1) {
      await _firstSaveCompleter.future;
      return;
    }
    if (savedSettings.length == 2 && !secondSaveCompleted.isCompleted) {
      secondSaveCompleted.complete();
    }
  }

  @override
  Future<void> clear() async {}
}
