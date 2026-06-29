import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_config.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../controllers/chat_app_settings_controller.dart';
import '../controllers/chat_controller.dart';
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
                    value: _settings.connectionLabel,
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
                    onTap: _openStatisticsPage,
                  ),
                  SettingsRow(
                    key: const Key('settings_row_docs'),
                    icon: Icons.article_outlined,
                    title: '使用文档',
                    onTap: _openDocsPage,
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

  void _openStatisticsPage() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => _StatisticsPage(
            appSettings: _appSettingsController.settings,
            connectionSettings: _settings,
            displaySettings: _currentDisplaySettings,
            loadStorageUsage: widget.loadStorageUsage,
          ),
        ),
      ),
    );
  }

  void _openDocsPage() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => const _DocumentationPage(),
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
    '面向 BareBrain 的本地聊天客户端，支持局域网连接、会话记录、快捷短语和本地备份恢复。';
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
          const SizedBox(height: 20),
          const _SettingsTextCard(
            icon: Icons.favorite_border,
            title: '支持 BareBrainAPP',
            paragraphs: <String>[
              '当前版本未内置收款入口。你可以通过反馈连接问题、提供不同局域网环境的测试结果、整理 BareBrain 固件兼容信息来支持项目。',
              '如果这是团队内部版本，可以在后续发布中把组织自己的赞助渠道或反馈入口接入到这里。',
            ],
          ),
          const SizedBox(height: 18),
          const _SettingsTextCard(
            icon: Icons.handyman_outlined,
            title: '优先需要的帮助',
            paragraphs: <String>[
              '补充更多 BareBrain 设备型号、网络代理和 OTA 检查场景下的实际测试反馈。',
              '整理高频提示词、快捷短语和指令注入模板，降低首次配置成本。',
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

class _StatisticsPage extends StatefulWidget {
  const _StatisticsPage({
    required this.appSettings,
    required this.connectionSettings,
    required this.displaySettings,
    this.loadStorageUsage,
  });

  final ChatAppSettings appSettings;
  final ChatConnectionSettings connectionSettings;
  final ChatDisplaySettings displaySettings;
  final LoadChatStorageUsage? loadStorageUsage;

  @override
  State<_StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<_StatisticsPage> {
  ChatStorageUsage? _usage;
  String? _errorMessage;
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshUsage());
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage ?? const ChatStorageUsage.empty();
    final appSettings = widget.appSettings;
    final displaySettings = widget.displaySettings;
    final connectionSettings = widget.connectionSettings;

    return SettingsScreenFrame(
      title: '统计',
      actions: <Widget>[
        IconButton(
          tooltip: '刷新',
          onPressed: _isLoading ? null : () => unawaited(_refreshUsage()),
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh, size: 30),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          if (_errorMessage != null) ...<Widget>[
            SettingsFeedbackBanner(message: _errorMessage!),
            const SizedBox(height: 18),
          ],
          _AboutInfoCard(
            children: <Widget>[
              _AboutInfoRow(
                icon: Icons.forum_outlined,
                title: '会话',
                value: '${usage.conversationCount} 个',
              ),
              _AboutInfoRow(
                icon: Icons.chat_bubble_outline,
                title: '消息',
                value: '${usage.messageCount} 条',
              ),
              _AboutInfoRow(
                icon: Icons.edit_note_outlined,
                title: '草稿',
                value: '${usage.draftCount} 个',
              ),
              _AboutInfoRow(
                icon: Icons.storage_outlined,
                title: '本地占用',
                value: _formatStorageBytes(usage.totalBytes),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AboutInfoCard(
            children: <Widget>[
              _AboutInfoRow(
                icon: Icons.flash_on_outlined,
                title: '快捷短语',
                value: '${appSettings.quickPhrases.length} 条',
              ),
              _AboutInfoRow(
                icon: Icons.layers_outlined,
                title: '指令注入',
                value: appSettings.promptInjection.summary,
              ),
              _AboutInfoRow(
                icon: Icons.public_outlined,
                title: '网络代理',
                value: appSettings.networkProxy.summary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AboutInfoCard(
            children: <Widget>[
              _AboutInfoRow(
                icon: Icons.router_outlined,
                title: '网关',
                value: connectionSettings.connectionLabel,
                copyValue: connectionSettings.redactedWebsocketUri.toString(),
              ),
              _AboutInfoRow(
                icon: Icons.timer_outlined,
                title: '响应超时',
                value: _formatDuration(connectionSettings.responseTimeout),
              ),
              _AboutInfoRow(
                icon: Icons.palette_outlined,
                title: '主题',
                value:
                    '${displaySettings.colorMode.label} · ${displaySettings.themePreset.label}',
              ),
              _AboutInfoRow(
                icon: Icons.text_fields,
                title: '消息字号',
                value: displaySettings.messageFontScaleLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshUsage() async {
    final loadStorageUsage = widget.loadStorageUsage;
    if (loadStorageUsage == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _usage = const ChatStorageUsage.empty();
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usage = await loadStorageUsage();
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _usage = usage;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _errorMessage = '读取统计失败：$error';
        _isLoading = false;
      });
    }
  }
}

class _DocumentationPage extends StatelessWidget {
  const _DocumentationPage();

  @override
  Widget build(BuildContext context) {
    final defaultGateway = Uri(
      scheme: 'ws',
      host: AppConfig.defaultHost,
      port: AppConfig.defaultPort,
      path: '/',
    ).toString();
    final tabs = _buildDocumentationTabs(defaultGateway);

    return DefaultTabController(
      length: tabs.length,
      child: SettingsScreenFrame(
        title: '使用文档',
        child: Column(
          children: <Widget>[
            _DocumentationTabBar(tabs: tabs),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  for (final tab in tabs) _DocumentationTabView(tab: tab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentationTabBar extends StatelessWidget {
  const _DocumentationTabBar({
    required this.tabs,
  });

  final List<_DocumentationTab> tabs;

  @override
  Widget build(BuildContext context) {
    final primary = settingsPrimaryTextColor(context);
    final secondary = settingsSecondaryTextColor(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: DecoratedBox(
        decoration: settingsCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: TabBar(
            isScrollable: true,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Color.alphaBlend(
                colors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                settingsCardBackgroundColor(context),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: isDark ? 0.36 : 0.24),
              ),
            ),
            labelColor: primary,
            unselectedLabelColor: secondary,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            tabs: <Widget>[
              for (final tab in tabs)
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(tab.icon, size: 19),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentationTabView extends StatelessWidget {
  const _DocumentationTabView({
    required this.tab,
  });

  final _DocumentationTab tab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: <Widget>[
        _DocumentationIntroCard(tab: tab),
        const SizedBox(height: 16),
        for (var index = 0; index < tab.cards.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 16),
          _SettingsTextCard(
            icon: tab.cards[index].icon,
            title: tab.cards[index].title,
            paragraphs: tab.cards[index].paragraphs,
          ),
        ],
      ],
    );
  }
}

class _DocumentationIntroCard extends StatelessWidget {
  const _DocumentationIntroCard({
    required this.tab,
  });

  final _DocumentationTab tab;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);

    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Row(
          children: <Widget>[
            _AboutIconBox(icon: tab.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: strong,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tab.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: soft,
                          fontSize: 15,
                          height: 1.42,
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

class _DocumentationTab {
  const _DocumentationTab({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.cards,
  });

  final String label;
  final String title;
  final String description;
  final IconData icon;
  final List<_DocumentationCardData> cards;
}

class _DocumentationCardData {
  const _DocumentationCardData({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;
}

List<_DocumentationTab> _buildDocumentationTabs(String defaultGateway) {
  return <_DocumentationTab>[
    _DocumentationTab(
      label: '连接',
      title: '连接 BareBrain',
      description: '配置局域网网关、客户端身份和连接验证，先确认设备能稳定握手。',
      icon: Icons.router_outlined,
      cards: <_DocumentationCardData>[
        _DocumentationCardData(
          icon: Icons.settings_ethernet_outlined,
          title: '网关参数',
          paragraphs: <String>[
            '默认网关为 $defaultGateway，可在“连接参数”里修改设备 IP、端口、客户端 ID 和响应超时。',
            '客户端 ID 会随每次聊天请求发送，用来区分不同设备或应用实例。',
          ],
        ),
        const _DocumentationCardData(
          icon: Icons.fact_check_outlined,
          title: '连接测试',
          paragraphs: <String>[
            '设置页里的连接测试只验证 WebSocket 握手，不会向 BareBrain 发送聊天内容。',
            '如果测试失败，优先确认手机或电脑与 BareBrain 位于同一局域网，再检查代理和端口配置。',
          ],
        ),
      ],
    ),
    const _DocumentationTab(
      label: '聊天',
      title: '聊天与会话',
      description: '管理会话列表、消息发送、重新生成以及输入栏左下角的快捷列表。',
      icon: Icons.chat_bubble_outline,
      cards: <_DocumentationCardData>[
        _DocumentationCardData(
          icon: Icons.forum_outlined,
          title: '会话管理',
          paragraphs: <String>[
            '宽屏使用左侧会话栏，窄屏使用抽屉。会话支持新建、切换、重命名和删除非当前会话。',
            '本地会话会根据存储设置自动保存，关闭自动保存后仍可继续当前临时对话。',
          ],
        ),
        _DocumentationCardData(
          icon: Icons.replay_outlined,
          title: '发送与重试',
          paragraphs: <String>[
            '发送失败后可以重试最后一条用户消息；开启确认后，重新生成前会先弹出确认框。',
            '快捷短语可在设置页维护，并从输入栏快速插入。',
          ],
        ),
        _DocumentationCardData(
          icon: Icons.settings_input_component_outlined,
          title: '快捷列表说明',
          paragraphs: <String>[
            '板子设置项从聊天框左下角快捷列表进入，会通过 BareBrain admin 接口读取或写入配置，不会发送给聊天模型。',
            '当前支持查看配置、设置 WiFi、API Key、模型、供应商、Base URL、记忆模型、代理和搜索 Key；设置说明只是用途说明，不需要手动输入命令文本。',
          ],
        ),
      ],
    ),
    const _DocumentationTab(
      label: '增强',
      title: '增强与服务',
      description: '把提示词、网络代理等能力接入日常聊天流程。',
      icon: Icons.tune_outlined,
      cards: <_DocumentationCardData>[
        _DocumentationCardData(
          icon: Icons.auto_awesome_outlined,
          title: '指令注入',
          paragraphs: <String>[
            '指令注入会在发送时拼接到传输内容，本地聊天记录仍保留原始输入。',
            '适合放置角色设定、回复格式、长期偏好等希望每次请求都携带的内容。',
          ],
        ),
        _DocumentationCardData(
          icon: Icons.public_outlined,
          title: '外部服务',
          paragraphs: <String>[
            '网络代理会应用到聊天 WebSocket 和 OTA 检查请求。',
            '命中代理绕过规则时，请求会回到直连，适合保留局域网设备访问路径。',
          ],
        ),
      ],
    ),
    const _DocumentationTab(
      label: '数据',
      title: '数据与迁移',
      description: '了解本地持久化、备份恢复和跨设备迁移配置的方式。',
      icon: Icons.backup_outlined,
      cards: <_DocumentationCardData>[
        _DocumentationCardData(
          icon: Icons.storage_outlined,
          title: '本地数据',
          paragraphs: <String>[
            '本地会话、草稿、显示设置和应用设置会通过 Key-Value JSON 持久化。',
            '存储统计页会展示聊天记录和会话目录占用，便于确认可清理空间。',
          ],
        ),
        _DocumentationCardData(
          icon: Icons.ios_share_outlined,
          title: '备份恢复',
          paragraphs: <String>[
            '备份与恢复支持导出和粘贴恢复 JSON，适合在设备间迁移本地配置。',
            '恢复配置前建议先导出当前数据，便于在参数不符合预期时回退。',
          ],
        ),
      ],
    ),
  ];
}

class _SettingsTextCard extends StatelessWidget {
  const _SettingsTextCard({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _AboutIconBox(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: strong,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < paragraphs.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: 10),
              Text(
                paragraphs[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: soft,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatStorageBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  }

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

String _formatDuration(Duration duration) {
  if (duration.inSeconds < 60) {
    return '${duration.inSeconds}s';
  }

  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  if (seconds == 0) {
    return '${minutes}m';
  }

  return '${minutes}m ${seconds}s';
}
