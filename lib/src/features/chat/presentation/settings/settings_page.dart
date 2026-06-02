import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_config.dart';
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
                    onTap: _openAboutPage,
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

  void _openAboutPage() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => const _AboutPage(),
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

const String _aboutAppName = 'BareBrainAPP';
const String _aboutAppSubtitle = 'BareBrain 局域网 AI 聊天客户端';
const String _aboutAppDescription =
    '面向 BareBrain 的本地聊天客户端，支持局域网连接、会话记录、语音服务、快捷短语、世界书和本地备份恢复。';
const String _aboutAppVersion = '0.1.0 / 1';
const String _aboutAppIconAsset = 'assets/branding/barebrain_app_icon_1024.png';

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final defaultGateway = Uri(
      scheme: 'ws',
      host: AppConfig.defaultHost,
      port: AppConfig.defaultPort,
      path: '/',
    ).toString();

    return SettingsScreenFrame(
      title: '关于',
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          const _AboutAppCard(),
          const SizedBox(height: 20),
          _AboutInfoCard(
            children: <Widget>[
              const _AboutInfoRow(
                key: Key('about_row_version'),
                icon: Icons.code,
                title: '版本',
                value: _aboutAppVersion,
                copyValue: '$_aboutAppName $_aboutAppVersion',
              ),
              _AboutInfoRow(
                key: const Key('about_row_system'),
                icon: Icons.devices_outlined,
                title: '系统',
                value: _platformLabel,
              ),
              _AboutInfoRow(
                key: const Key('about_row_gateway'),
                icon: Icons.router_outlined,
                title: '默认网关',
                value: defaultGateway,
                copyValue: defaultGateway,
              ),
              const _AboutInfoRow(
                key: Key('about_row_client_id'),
                icon: Icons.badge_outlined,
                title: '客户端 ID',
                value: AppConfig.defaultClientId,
                copyValue: AppConfig.defaultClientId,
              ),
              const _AboutInfoRow(
                key: Key('about_row_docs'),
                icon: Icons.article_outlined,
                title: '项目说明',
                value: 'README',
                copyValue: _aboutAppDescription,
              ),
              const _AboutInfoRow(
                key: Key('about_row_license'),
                icon: Icons.description_outlined,
                title: '许可证',
                value: '暂未声明',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutAppCard extends StatelessWidget {
  const _AboutAppCard();

  @override
  Widget build(BuildContext context) {
    final paletteTextStrong = settingsPrimaryTextColor(context);
    final paletteTextSoft = settingsSecondaryTextColor(context);

    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                _aboutAppIconAsset,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _AboutIconFallback(size: 64);
                },
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _aboutAppName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: paletteTextStrong,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _aboutAppSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: paletteTextSoft,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(settingsCardRadius),
        child: Column(children: _withDividers(context)),
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context) {
    final widgets = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      widgets.add(children[index]);
      if (index < children.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            thickness: 1,
            color: settingsDividerColorFor(context),
            indent: 76,
            endIndent: 18,
          ),
        );
      }
    }
    return widgets;
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.icon,
    required this.title,
    this.value,
    this.copyValue,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final canCopy = copyValue != null;
    final paletteTextStrong = settingsPrimaryTextColor(context);
    final paletteTextSoft = settingsSecondaryTextColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canCopy
            ? () => unawaited(
                  _copyAboutText(context, label: title, value: copyValue!),
                )
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final valueMaxWidth = constraints.maxWidth * 0.42;
                return Row(
                  children: <Widget>[
                    _AboutIconBox(icon: icon),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: paletteTextStrong,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                    if (value != null) ...<Widget>[
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: valueMaxWidth),
                        child: Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: paletteTextSoft,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                    ],
                    if (canCopy) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: paletteTextSoft,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutIconBox extends StatelessWidget {
  const _AboutIconBox({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: Icon(
        icon,
        size: 26,
        color: settingsPrimaryTextColor(context),
      ),
    );
  }
}

class _AboutIconFallback extends StatelessWidget {
  const _AboutIconFallback({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          Icons.psychology_outlined,
          size: size * 0.52,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

Future<void> _copyAboutText(
  BuildContext context, {
  required String label,
  required String value,
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制$label')),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('复制失败：$error')),
    );
  }
}

String get _platformLabel {
  if (kIsWeb) {
    return 'Web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.fuchsia => 'Fuchsia',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.windows => 'Windows',
  };
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
