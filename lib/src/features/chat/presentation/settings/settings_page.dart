import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../widgets/settings_sheet.dart';
import 'display_settings_page.dart';
import 'network_proxy_page.dart';
import 'ota_settings_sheet.dart';
import 'quick_phrases_page.dart';
import 'settings_components.dart';

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({
    required this.settings,
    required this.onSettingsChanged,
    this.displaySettings = const ChatDisplaySettings(),
    this.onDisplaySettingsChanged,
    this.onTestConnection,
    super.key,
  });

  final ChatConnectionSettings settings;
  final ValueChanged<ChatConnectionSettings> onSettingsChanged;
  final ChatDisplaySettings displaySettings;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsChanged;
  final TestChatConnection? onTestConnection;

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  late ChatConnectionSettings _settings;
  late ChatDisplaySettings _displaySettings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _displaySettings = widget.displaySettings;
  }

  @override
  void didUpdateWidget(covariant ChatSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
    if (oldWidget.displaySettings != widget.displaySettings) {
      _displaySettings = widget.displaySettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '设置',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          SettingsSection(
            title: '通用设置',
            topPadding: 6,
            children: <Widget>[
              SettingsRow(
                key: const Key('settings_row_color_mode'),
                icon: Icons.light_mode_outlined,
                title: '颜色模式',
                value: _displaySettings.colorMode.label,
                onTap: _openColorModeSettings,
              ),
              SettingsRow(
                key: const Key('settings_row_display'),
                icon: Icons.desktop_windows_outlined,
                title: '显示设置',
                onTap: _openDisplaySettings,
              ),
            ],
          ),
          SettingsSection(
            title: '模型与服务',
            children: <Widget>[
              SettingsRow(
                icon: Icons.volume_up_outlined,
                title: '语音服务',
                onTap: () => _showPending('语音服务'),
              ),
              SettingsRow(
                icon: Icons.menu_book_outlined,
                title: '世界书',
                onTap: () => _showPending('世界书'),
              ),
              SettingsRow(
                key: const Key('settings_row_quick_phrases'),
                icon: Icons.flash_on_outlined,
                title: '快捷短语',
                onTap: _openQuickPhrases,
              ),
              SettingsRow(
                icon: Icons.layers_outlined,
                title: '指令注入',
                onTap: () => _showPending('指令注入'),
              ),
              SettingsRow(
                key: const Key('settings_row_network_proxy'),
                icon: Icons.public_outlined,
                title: '网络代理',
                onTap: _openNetworkProxy,
              ),
            ],
          ),
          SettingsSection(
            title: '设备连接',
            children: <Widget>[
              SettingsRow(
                key: const Key('settings_row_connection'),
                icon: Icons.settings_ethernet,
                title: '连接参数',
                value: _settings.websocketUri.toString(),
                onTap: _openConnectionSettings,
              ),
              SettingsRow(
                key: const Key('settings_row_ota'),
                icon: Icons.system_update_alt_outlined,
                title: 'OTA 参数',
                value: _otaSummary(_settings.otaSettings),
                onTap: _openOtaSettings,
              ),
            ],
          ),
          SettingsSection(
            title: '数据设置',
            children: <Widget>[
              SettingsRow(
                icon: Icons.storage_outlined,
                title: '数据备份',
                onTap: () => _showPending('数据备份'),
              ),
              SettingsRow(
                icon: Icons.inventory_2_outlined,
                title: '聊天记录存储',
                value: '本机',
                onTap: () => _showPending('聊天记录存储'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openConnectionSettings() async {
    final next = await showModalBottomSheet<ChatConnectionSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SettingsSheet(
          settings: _settings,
          onTestConnection: widget.onTestConnection,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    _applySettings(next);
  }

  Future<void> _openOtaSettings() async {
    final next = await showModalBottomSheet<ChatOtaSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return OtaSettingsSheet(settings: _settings.otaSettings);
      },
    );

    if (next == null || !mounted) {
      return;
    }

    _applySettings(_settings.copyWith(otaSettings: next));
  }

  Future<void> _openColorModeSettings() async {
    final next = await showModalBottomSheet<ChatColorMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ColorModePickerSheet(selected: _displaySettings.colorMode);
      },
    );

    if (next == null || !mounted) {
      return;
    }

    _applyDisplaySettings(_displaySettings.copyWith(colorMode: next));
  }

  void _openDisplaySettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => DisplaySettingsPage(
            settings: _displaySettings,
            onChanged: _applyDisplaySettings,
          ),
        ),
      ),
    );
  }

  void _openQuickPhrases() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => const QuickPhrasesPage(),
        ),
      ),
    );
  }

  void _openNetworkProxy() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => const NetworkProxyPage(),
        ),
      ),
    );
  }

  void _applySettings(ChatConnectionSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
  }

  void _applyDisplaySettings(ChatDisplaySettings settings) {
    setState(() => _displaySettings = settings);
    widget.onDisplaySettingsChanged?.call(settings);
  }

  String _otaSummary(ChatOtaSettings settings) {
    return '${settings.channel} · ${settings.autoCheck ? '自动' : '手动'}';
  }

  void _showPending(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name 暂未接入')),
    );
  }
}

class _ColorModePickerSheet extends StatelessWidget {
  const _ColorModePickerSheet({
    required this.selected,
  });

  final ChatColorMode selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ChatColorMode.values.map((mode) {
            return ListTile(
              key: Key('color_mode_${mode.name}'),
              title: Text(mode.label),
              trailing: selected == mode ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(mode),
            );
          }).toList(),
        ),
      ),
    );
  }
}
