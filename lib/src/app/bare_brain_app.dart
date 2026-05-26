import 'dart:async';

import 'package:flutter/material.dart';

import '../features/chat/chat_feature_module.dart';
import '../features/chat/domain/entities/chat_display_settings.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ChatFeatureModule.createController(
      initialSettings: AppConfig.defaultChatSettings(),
    );
    _displaySettingsController =
        ChatFeatureModule.createDisplaySettingsController();
    unawaited(_controller.restore());
    unawaited(_displaySettingsController.restore());
  }

  @override
  void dispose() {
    _controller.dispose();
    _displaySettingsController.dispose();
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
          home: ChatPage(
            controller: _controller,
            displaySettings: displaySettings,
            onDisplaySettingsChanged: _displaySettingsController.update,
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
}
