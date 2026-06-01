import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../controllers/chat_app_settings_controller.dart';
import '../controllers/chat_display_settings_controller.dart';
import '../widgets/settings_sheet.dart';
import 'backup_restore_page.dart';
import 'chat_storage_page.dart';
import 'display_settings_page.dart';
import 'network_proxy_page.dart';
import 'ota_settings_sheet.dart';
import 'prompt_injection_page.dart';
import 'quick_phrases_page.dart';
import 'settings_components.dart';
import 'voice_service_page.dart';
import 'world_book_page.dart';

typedef TestOtaVersionCheck = Future<void> Function(
  ChatConnectionSettings settings,
);

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({
    required this.settings,
    required this.onSettingsChanged,
    this.displaySettings = const ChatDisplaySettings(),
    this.displaySettingsController,
    this.displaySettingsError,
    this.onDisplaySettingsChanged,
    this.appSettingsController,
    this.onTestConnection,
    this.onTestNetworkProxyConnection,
    this.onTestVoiceService,
    this.onTestOtaVersionCheck,
    this.loadStorageUsage,
    super.key,
  });

  final ChatConnectionSettings settings;
  final ValueChanged<ChatConnectionSettings> onSettingsChanged;
  final ChatDisplaySettings displaySettings;
  final ChatDisplaySettingsController? displaySettingsController;
  final String? displaySettingsError;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsChanged;
  final ChatAppSettingsController? appSettingsController;
  final TestChatConnection? onTestConnection;
  final TestNetworkProxyConnection? onTestNetworkProxyConnection;
  final TestVoiceService? onTestVoiceService;
  final TestOtaVersionCheck? onTestOtaVersionCheck;
  final LoadChatStorageUsage? loadStorageUsage;

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  late ChatConnectionSettings _settings;
  late ChatDisplaySettings _displaySettings;
  late final ChatAppSettingsController _fallbackAppSettingsController;

  ChatAppSettingsController get _appSettingsController {
    return widget.appSettingsController ?? _fallbackAppSettingsController;
  }

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _displaySettings = widget.displaySettings;
    _fallbackAppSettingsController = ChatAppSettingsController();
  }

  @override
  void dispose() {
    _fallbackAppSettingsController.dispose();
    super.dispose();
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
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[
        _appSettingsController,
        widget.displaySettingsController,
      ]),
      builder: (context, _) {
        final appSettings = _appSettingsController.settings;
        final appSettingsError = _appSettingsController.errorMessage;
        final displaySettings = _currentDisplaySettings;
        final displaySettingsError =
            widget.displaySettingsController?.errorMessage ??
                widget.displaySettingsError;
        return SettingsScreenFrame(
          title: '设置',
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              if (displaySettingsError != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SettingsFeedbackBanner(
                    message: displaySettingsError,
                  ),
                ),
              ],
              if (appSettingsError != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SettingsFeedbackBanner(message: appSettingsError),
                ),
              ],
              SettingsSection(
                title: '通用设置',
                topPadding: 6,
                children: <Widget>[
                  SettingsRow(
                    key: const Key('settings_row_color_mode'),
                    icon: Icons.light_mode_outlined,
                    title: '颜色模式',
                    value: displaySettings.colorMode.label,
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
                    key: const Key('settings_row_voice_service'),
                    icon: Icons.volume_up_outlined,
                    title: '语音服务',
                    value: appSettings.voice.summary,
                    onTap: _openVoiceService,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_world_book'),
                    icon: Icons.menu_book_outlined,
                    title: '世界书',
                    value: appSettings.worldBook.summary,
                    onTap: _openWorldBook,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_quick_phrases'),
                    icon: Icons.flash_on_outlined,
                    title: '快捷短语',
                    value: '${appSettings.quickPhrases.length} 条',
                    onTap: _openQuickPhrases,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_prompt_injection'),
                    icon: Icons.layers_outlined,
                    title: '指令注入',
                    value: appSettings.promptInjection.summary,
                    onTap: _openPromptInjection,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_network_proxy'),
                    icon: Icons.public_outlined,
                    title: '网络代理',
                    value: appSettings.networkProxy.summary,
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
                    key: const Key('settings_row_storage_space'),
                    icon: Icons.storage_outlined,
                    title: '存储空间',
                    value: appSettings.storage.summary,
                    onTap: _openChatStorage,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_backup_restore'),
                    icon: Icons.backup_outlined,
                    title: '备份与恢复',
                    onTap: _openBackupRestore,
                  ),
                ],
              ),
              SettingsSection(
                title: '关于',
                children: <Widget>[
                  SettingsRow(
                    key: const Key('settings_row_about'),
                    icon: Icons.info_outline,
                    title: '关于',
                    onTap: () => _openPlaceholderPage(
                      title: '关于',
                      icon: Icons.info_outline,
                    ),
                  ),
                  SettingsRow(
                    key: const Key('settings_row_statistics'),
                    icon: Icons.bar_chart_outlined,
                    title: '统计',
                    onTap: () => _openPlaceholderPage(
                      title: '统计',
                      icon: Icons.bar_chart_outlined,
                    ),
                  ),
                  SettingsRow(
                    key: const Key('settings_row_docs'),
                    icon: Icons.article_outlined,
                    title: '使用文档',
                    onTap: () => _openPlaceholderPage(
                      title: '使用文档',
                      icon: Icons.article_outlined,
                    ),
                  ),
                  SettingsRow(
                    key: const Key('settings_row_sponsor'),
                    icon: Icons.favorite_border,
                    title: '赞助',
                    onTap: () => _openPlaceholderPage(
                      title: '赞助',
                      icon: Icons.favorite_border,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        return OtaSettingsSheet(
          settings: _settings.otaSettings,
          onTestVersionCheck: widget.onTestOtaVersionCheck == null
              ? null
              : (otaSettings) {
                  return widget.onTestOtaVersionCheck!(
                    _settings.copyWith(otaSettings: otaSettings),
                  );
                },
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    _applySettings(_settings.copyWith(otaSettings: next));
  }

  Future<void> _openColorModeSettings() async {
    final displaySettings = _currentDisplaySettings;
    final next = await showModalBottomSheet<ChatColorMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ColorModePickerSheet(selected: displaySettings.colorMode);
      },
    );

    if (next == null || !mounted) {
      return;
    }

    _applyDisplaySettings(displaySettings.copyWith(colorMode: next));
  }

  void _openDisplaySettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => DisplaySettingsPage(
            settings: _currentDisplaySettings,
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
          builder: (context) => QuickPhrasesPage(
            phrases: _appSettingsController.settings.quickPhrases,
            onChanged: _appSettingsController.updateQuickPhrases,
          ),
        ),
      ),
    );
  }

  void _openNetworkProxy() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => NetworkProxyPage(
            settings: _appSettingsController.settings.networkProxy,
            onChanged: _appSettingsController.updateNetworkProxy,
            onTestConnection: widget.onTestNetworkProxyConnection,
          ),
        ),
      ),
    );
  }

  void _openVoiceService() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => VoiceServicePage(
            settings: _appSettingsController.settings.voice,
            onChanged: _appSettingsController.updateVoice,
            onTestVoiceService: widget.onTestVoiceService,
          ),
        ),
      ),
    );
  }

  void _openWorldBook() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => WorldBookPage(
            settings: _appSettingsController.settings.worldBook,
            onChanged: _appSettingsController.updateWorldBook,
          ),
        ),
      ),
    );
  }

  void _openPromptInjection() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => PromptInjectionPage(
            settings: _appSettingsController.settings.promptInjection,
            onChanged: _appSettingsController.updatePromptInjection,
          ),
        ),
      ),
    );
  }

  void _openChatStorage() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ChatStoragePage(
            loadStorageUsage: widget.loadStorageUsage,
          ),
        ),
      ),
    );
  }

  void _openBackupRestore() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => BackupRestorePage(
            settings: _appSettingsController.settings.storage,
            appSettings: _appSettingsController.settings,
            connectionSettings: _settings,
            displaySettings: _currentDisplaySettings,
            onChanged: _appSettingsController.updateStorage,
            onAppSettingsImported: _appSettingsController.update,
            onConnectionSettingsImported: _applySettings,
            onDisplaySettingsImported: _applyDisplaySettings,
          ),
        ),
      ),
    );
  }

  void _openPlaceholderPage({
    required String title,
    required IconData icon,
  }) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => _SettingsPlaceholderPage(
            title: title,
            icon: icon,
          ),
        ),
      ),
    );
  }

  void _applySettings(ChatConnectionSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
  }

  void _applyDisplaySettings(ChatDisplaySettings settings) {
    final controller = widget.displaySettingsController;
    if (controller != null) {
      controller.update(settings);
      return;
    }

    setState(() => _displaySettings = settings);
    widget.onDisplaySettingsChanged?.call(settings);
  }

  ChatDisplaySettings get _currentDisplaySettings {
    return widget.displaySettingsController?.settings ?? _displaySettings;
  }

  String _otaSummary(ChatOtaSettings settings) {
    return '${settings.channel} · ${settings.autoCheck ? '自动' : '手动'}';
  }
}

class _SettingsPlaceholderPage extends StatelessWidget {
  const _SettingsPlaceholderPage({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: title,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsEmptyState(
            icon: icon,
            title: title,
            subtitle: '内容暂未配置',
          ),
        ],
      ),
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
