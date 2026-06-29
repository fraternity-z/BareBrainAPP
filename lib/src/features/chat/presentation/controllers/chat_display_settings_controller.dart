import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_display_settings.dart';
import '../../domain/repositories/chat_display_settings_store.dart';

class ChatDisplaySettingsController extends ChangeNotifier {
  ChatDisplaySettingsController({
    ChatDisplaySettings initialSettings = const ChatDisplaySettings(),
    ChatDisplaySettingsStore? store,
  })  : _settings = initialSettings,
        _store = store;

  final ChatDisplaySettingsStore? _store;
  ChatDisplaySettings _settings;
  bool _isDisposed = false;
  bool _isSaving = false;
  bool _saveAgain = false;
  int _revision = 0;
  String? _errorMessage;

  ChatDisplaySettings get settings => _settings;
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
      _errorMessage = '恢复显示设置失败：$error';
      _notify();
    }
  }

  void update(ChatDisplaySettings settings) {
    if (settings == _settings) {
      return;
    }

    _revision++;
    _settings = settings;
    _errorMessage = null;
    unawaited(_save());
    _notify();
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
            _errorMessage = '保存显示设置失败：$error';
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
