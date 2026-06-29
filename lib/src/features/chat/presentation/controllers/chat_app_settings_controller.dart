import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_app_settings.dart';
import '../../domain/repositories/chat_app_settings_store.dart';

class ChatAppSettingsController extends ChangeNotifier {
  ChatAppSettingsController({
    ChatAppSettings initialSettings = const ChatAppSettings(),
    ChatAppSettingsStore? store,
  })  : _settings = initialSettings,
        _store = store;

  final ChatAppSettingsStore? _store;
  ChatAppSettings _settings;
  bool _isDisposed = false;
  bool _isSaving = false;
  bool _saveAgain = false;
  int _revision = 0;
  String? _errorMessage;

  ChatAppSettings get settings => _settings;
  String? get errorMessage => _errorMessage;

  Future<void> restore() async {
    final store = _store;
    if (store == null) {
      return;
    }

    final restoreRevision = _revision;
    try {
      final restored = await store.load();
      if (restoreRevision != _revision) {
        return;
      }
      _settings = restored ?? _settings;
      _errorMessage = null;
      _notify();
    } catch (error) {
      if (restoreRevision != _revision) {
        return;
      }
      _errorMessage = '恢复应用设置失败：$error';
      _notify();
    }
  }

  void update(ChatAppSettings settings) {
    _revision++;
    _settings = settings;
    _errorMessage = null;
    unawaited(_save());
    _notify();
  }

  void updateQuickPhrases(List<ChatQuickPhrase> phrases) {
    update(_settings.copyWith(quickPhrases: phrases));
  }

  void updateNetworkProxy(ChatNetworkProxySettings settings) {
    update(_settings.copyWith(networkProxy: settings));
  }

  void updateWorldBook(ChatWorldBookSettings settings) {
    update(_settings.copyWith(worldBook: settings));
  }

  void updatePromptInjection(ChatPromptInjectionSettings settings) {
    update(_settings.copyWith(promptInjection: settings));
  }

  void updateStorage(ChatStorageSettings settings) {
    update(_settings.copyWith(storage: settings));
  }

  Future<void> _save() async {
    final store = _store;
    if (store == null) {
      return;
    }

    if (_isSaving) {
      _saveAgain = true;
      return;
    }

    _isSaving = true;
    try {
      do {
        _saveAgain = false;
        final settings = _settings;
        final saveRevision = _revision;
        try {
          await store.save(settings);
          if (saveRevision == _revision) {
            _errorMessage = null;
          }
        } catch (error) {
          if (saveRevision == _revision) {
            _errorMessage = '保存应用设置失败：$error';
            _notify();
          }
        }
      } while (_saveAgain);
    } finally {
      _isSaving = false;
    }
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
