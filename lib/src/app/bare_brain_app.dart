import 'dart:async';

import 'package:flutter/material.dart';

import '../features/chat/chat_feature_module.dart';
import '../features/chat/domain/entities/chat_display_settings.dart';
import '../features/chat/presentation/controllers/chat_app_settings_controller.dart';
import '../features/chat/presentation/controllers/chat_controller.dart';
import '../features/chat/presentation/controllers/chat_display_settings_controller.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import 'app_config.dart';
import 'app_theme.dart';

class BareBrainApp extends StatefulWidget {
  const BareBrainApp({super.key});

  @override
  State<BareBrainApp> createState() => _BareBrainAppState();
}

class _BareBrainAppState extends State<BareBrainApp> {
  late final ChatController _controller;
  late final ChatDisplaySettingsController _displaySettingsController;
  late final ChatAppSettingsController _appSettingsController;
  bool _isRestoringControllers = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _appSettingsController = ChatFeatureModule.createAppSettingsController();
    _controller = ChatFeatureModule.createController(
      initialSettings: AppConfig.defaultChatSettings(),
      networkProxySettingsProvider: () {
        return _appSettingsController.settings.networkProxy;
      },
    );
    _displaySettingsController =
        ChatFeatureModule.createDisplaySettingsController();
    _appSettingsController.addListener(_syncAppSettings);
    unawaited(_restoreControllers());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _appSettingsController.removeListener(_syncAppSettings);
    _controller.dispose();
    _displaySettingsController.dispose();
    _appSettingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _displaySettingsController,
      builder: (context, _) {
        final displaySettings = _displaySettingsController.settings;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BareBrain',
          themeMode: _themeMode(displaySettings.colorMode),
          theme: BareBrainTheme.light(displaySettings: displaySettings),
          darkTheme: BareBrainTheme.dark(displaySettings: displaySettings),
          themeAnimationDuration: Duration.zero,
          home: ChatPage(
            controller: _controller,
            displaySettings: displaySettings,
            displaySettingsController: _displaySettingsController,
            displaySettingsError: _displaySettingsController.errorMessage,
            onDisplaySettingsChanged: _displaySettingsController.update,
            appSettingsController: _appSettingsController,
            onTestNetworkProxyConnection:
                ChatFeatureModule.testNetworkProxyConnection,
            onTestOtaVersionCheck: (settings) {
              return ChatFeatureModule.testOtaVersionCheck(
                settings,
                networkProxySettingsProvider: () {
                  return _appSettingsController.settings.networkProxy;
                },
              );
            },
          ),
        );
      },
    );
  }

  ThemeMode _themeMode(ChatColorMode colorMode) {
    return switch (colorMode) {
      ChatColorMode.system => ThemeMode.system,
      ChatColorMode.light => ThemeMode.light,
      ChatColorMode.dark => ThemeMode.dark,
    };
  }

  Future<void> _restoreControllers() async {
    _isRestoringControllers = true;
    try {
      await Future.wait(<Future<void>>[
        _displaySettingsController.restore(),
        _appSettingsController.restore(),
      ]);
      _syncAppSettings(persistStorage: false);
      await _controller.restore();
    } finally {
      _isRestoringControllers = false;
    }
    unawaited(_autoCheckOta());
  }

  void _syncAppSettings({bool? persistStorage}) {
    final settings = _appSettingsController.settings;
    final shouldPersistStorage = persistStorage ?? !_isRestoringControllers;
    _controller.updateStorageSettings(
      settings.storage,
      persistImmediately: shouldPersistStorage,
    );
  }

  Future<void> _autoCheckOta() async {
    if (_isDisposed) {
      return;
    }

    final settings = _controller.settings;
    if (!settings.otaSettings.autoCheck) {
      return;
    }

    try {
      await ChatFeatureModule.testOtaVersionCheck(
        settings,
        networkProxySettingsProvider: () {
          return _appSettingsController.settings.networkProxy;
        },
      );
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      _controller.reportError('OTA 自动检查失败：$error');
    }
  }
}
