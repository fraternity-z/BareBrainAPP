import 'dart:async';

import 'package:flutter/material.dart';

import '../features/chat/chat_feature_module.dart';
import '../features/chat/presentation/controllers/chat_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ChatFeatureModule.createController(
      initialSettings: AppConfig.defaultChatSettings(),
    );
    unawaited(_controller.restore());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BareBrain',
      theme: BareBrainTheme.light(),
      darkTheme: BareBrainTheme.dark(),
      home: ChatPage(controller: _controller),
    );
  }
}
