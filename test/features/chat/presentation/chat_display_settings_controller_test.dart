import 'dart:async';

import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_display_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_display_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatDisplaySettingsController', () {
    test('restores settings from the store', () async {
      final store = _MemoryDisplaySettingsStore(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );
      final controller = ChatDisplaySettingsController(store: store);

      await controller.restore();

      expect(controller.settings.colorMode, ChatColorMode.dark);
      controller.dispose();
    });

    test('updates and persists display settings', () async {
      final store = _MemoryDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(store: store);

      controller.update(
        const ChatDisplaySettings(themePreset: ChatThemePreset.warmSun),
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.settings.themePreset, ChatThemePreset.warmSun);
      expect(store.saved!.themePreset, ChatThemePreset.warmSun);
      controller.dispose();
    });

    test('does not overwrite updates made while restore is pending', () async {
      final store = _DeferredDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(store: store);

      final restore = controller.restore();
      controller.update(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );
      store.complete(
        const ChatDisplaySettings(colorMode: ChatColorMode.light),
      );

      await restore;

      expect(controller.settings.colorMode, ChatColorMode.dark);
      controller.dispose();
    });

    test('ignores stale restore errors after settings update', () async {
      final store = _DeferredDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(store: store);

      final restore = controller.restore();
      controller.update(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );
      store.fail(Exception('old load failed'));

      await restore;

      expect(controller.errorMessage, isNull);
      expect(controller.settings.colorMode, ChatColorMode.dark);
      controller.dispose();
    });

    test('exposes restore failures without changing settings', () async {
      final store = _FailingLoadDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(
        initialSettings:
            const ChatDisplaySettings(colorMode: ChatColorMode.light),
        store: store,
      );

      await controller.restore();

      expect(controller.settings.colorMode, ChatColorMode.light);
      expect(controller.errorMessage, contains('恢复显示设置失败'));
      controller.dispose();
    });

    test('exposes save failures after updates', () async {
      final store = _FailingSaveDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(store: store);

      controller.update(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.settings.colorMode, ChatColorMode.dark);
      expect(controller.errorMessage, contains('保存显示设置失败'));
      controller.dispose();
    });

    test('serializes pending saves and persists the latest settings', () async {
      final store = _BlockingSaveDisplaySettingsStore();
      final controller = ChatDisplaySettingsController(store: store);

      controller.update(
        const ChatDisplaySettings(colorMode: ChatColorMode.light),
      );
      await Future<void>.delayed(Duration.zero);
      controller.update(
        const ChatDisplaySettings(colorMode: ChatColorMode.dark),
      );

      expect(store.savedSettings, hasLength(1));
      expect(store.savedSettings.single.colorMode, ChatColorMode.light);

      store.releaseFirstSave();
      await store.secondSaveCompleted.future;

      expect(store.savedSettings, hasLength(2));
      expect(store.savedSettings.last.colorMode, ChatColorMode.dark);
      controller.dispose();
    });
  });
}

class _MemoryDisplaySettingsStore implements ChatDisplaySettingsStore {
  _MemoryDisplaySettingsStore([this.saved]);

  ChatDisplaySettings? saved;

  @override
  Future<ChatDisplaySettings?> load() async => saved;

  @override
  Future<void> save(ChatDisplaySettings settings) async {
    saved = settings;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

class _DeferredDisplaySettingsStore implements ChatDisplaySettingsStore {
  final Completer<ChatDisplaySettings?> _loadCompleter =
      Completer<ChatDisplaySettings?>();

  void complete(ChatDisplaySettings settings) {
    _loadCompleter.complete(settings);
  }

  void fail(Object error) {
    _loadCompleter.completeError(error);
  }

  @override
  Future<ChatDisplaySettings?> load() {
    return _loadCompleter.future;
  }

  @override
  Future<void> save(ChatDisplaySettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _FailingLoadDisplaySettingsStore implements ChatDisplaySettingsStore {
  @override
  Future<ChatDisplaySettings?> load() {
    throw Exception('load failed');
  }

  @override
  Future<void> save(ChatDisplaySettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _FailingSaveDisplaySettingsStore implements ChatDisplaySettingsStore {
  @override
  Future<ChatDisplaySettings?> load() async => null;

  @override
  Future<void> save(ChatDisplaySettings settings) {
    throw Exception('save failed');
  }

  @override
  Future<void> clear() async {}
}

class _BlockingSaveDisplaySettingsStore implements ChatDisplaySettingsStore {
  final Completer<void> _firstSaveCompleter = Completer<void>();
  final Completer<void> secondSaveCompleted = Completer<void>();
  final List<ChatDisplaySettings> savedSettings = <ChatDisplaySettings>[];

  void releaseFirstSave() {
    _firstSaveCompleter.complete();
  }

  @override
  Future<ChatDisplaySettings?> load() async => null;

  @override
  Future<void> save(ChatDisplaySettings settings) async {
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
