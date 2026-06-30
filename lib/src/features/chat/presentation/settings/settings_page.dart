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
                    title: '项目文档',
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

class _DocumentationPage extends StatefulWidget {
  const _DocumentationPage();

  @override
  State<_DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<_DocumentationPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultGateway = Uri(
      scheme: 'ws',
      host: AppConfig.defaultHost,
      port: AppConfig.defaultPort,
      path: '/',
    ).toString();
    final pages = _buildDocumentationPages(defaultGateway);

    return SettingsScreenFrame(
      title: '项目文档',
      actions: <Widget>[
        IconButton(
          tooltip: '上一页',
          onPressed:
              _currentPage == 0 ? null : () => _goToPage(_currentPage - 1),
          icon: const Icon(Icons.chevron_left, size: 30),
        ),
        IconButton(
          tooltip: '下一页',
          onPressed: _currentPage == pages.length - 1
              ? null
              : () => _goToPage(_currentPage + 1),
          icon: const Icon(Icons.chevron_right, size: 30),
        ),
      ],
      child: Column(
        children: <Widget>[
          _DocumentationPagePicker(
            pages: pages,
            currentPage: _currentPage,
            onSelected: _goToPage,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return _DocumentationReadingPage(
                  page: pages[index],
                  pageNumber: index + 1,
                  totalPages: pages.length,
                );
              },
            ),
          ),
          _DocumentationPageFooter(
            currentPage: _currentPage,
            totalPages: pages.length,
            onPrevious:
                _currentPage == 0 ? null : () => _goToPage(_currentPage - 1),
            onNext: _currentPage == pages.length - 1
                ? null
                : () => _goToPage(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _DocumentationPagePicker extends StatelessWidget {
  const _DocumentationPagePicker({
    required this.pages,
    required this.currentPage,
    required this.onSelected,
  });

  final List<_DocumentationPageData> pages;
  final int currentPage;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        itemBuilder: (context, index) {
          final page = pages[index];
          return _DocumentationPageChip(
            page: page,
            selected: index == currentPage,
            onTap: () => onSelected(index),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: pages.length,
      ),
    );
  }
}

class _DocumentationPageChip extends StatelessWidget {
  const _DocumentationPageChip({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final _DocumentationPageData page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = selected
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            settingsCardBackgroundColor(context),
          )
        : settingsCardBackgroundColor(context);
    final border = selected
        ? colors.primary.withValues(alpha: isDark ? 0.38 : 0.28)
        : settingsDividerColorFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                page.icon,
                size: 19,
                color: selected
                    ? colors.primary
                    : settingsSecondaryTextColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                page.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? settingsPrimaryTextColor(context)
                          : settingsSecondaryTextColor(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentationReadingPage extends StatelessWidget {
  const _DocumentationReadingPage({
    required this.page,
    required this.pageNumber,
    required this.totalPages,
  });

  final _DocumentationPageData page;
  final int pageNumber;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        _DocumentationIntroCard(
          page: page,
          pageNumber: pageNumber,
          totalPages: totalPages,
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < page.sections.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 16),
          _DocumentationSectionCard(section: page.sections[index]),
        ],
      ],
    );
  }
}

class _DocumentationIntroCard extends StatelessWidget {
  const _DocumentationIntroCard({
    required this.page,
    required this.pageNumber,
    required this.totalPages,
  });

  final _DocumentationPageData page;
  final int pageNumber;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _AboutIconBox(icon: page.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    page.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: strong,
                          fontSize: 21,
                          height: 1.16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      '$pageNumber/$totalPages',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              page.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: soft,
                    fontSize: 15,
                    height: 1.46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentationSectionCard extends StatelessWidget {
  const _DocumentationSectionCard({
    required this.section,
  });

  final _DocumentationSectionData section;

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
                _AboutIconBox(icon: section.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    section.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: strong,
                          fontSize: 19,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < section.paragraphs.length; index++)
              _DocumentationParagraph(
                text: section.paragraphs[index],
                color: soft,
                addTopGap: index > 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentationParagraph extends StatelessWidget {
  const _DocumentationParagraph({
    required this.text,
    required this.color,
    required this.addTopGap,
  });

  final String text;
  final Color color;
  final bool addTopGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: addTopGap ? 10 : 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 15,
              height: 1.48,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _DocumentationPageFooter extends StatelessWidget {
  const _DocumentationPageFooter({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '上一页',
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var index = 0; index < totalPages; index++)
                  _DocumentationPageDot(selected: index == currentPage),
              ],
            ),
          ),
          IconButton(
            tooltip: '下一页',
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DocumentationPageDot extends StatelessWidget {
  const _DocumentationPageDot({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: selected ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: selected
            ? colors.primary
            : settingsSecondaryTextColor(context).withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DocumentationPageData {
  const _DocumentationPageData({
    required this.label,
    required this.title,
    required this.summary,
    required this.icon,
    required this.sections,
  });

  final String label;
  final String title;
  final String summary;
  final IconData icon;
  final List<_DocumentationSectionData> sections;
}

class _DocumentationSectionData {
  const _DocumentationSectionData({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;
}

List<_DocumentationPageData> _buildDocumentationPages(String defaultGateway) {
  return <_DocumentationPageData>[
    _DocumentationPageData(
      label: '连接',
      title: '连接与网关配置',
      summary:
          '先确认 BareBrain 网关地址、连接模式和客户端身份。连接测试只验证 WebSocket 握手，不会向模型发送聊天内容。',
      icon: Icons.router_outlined,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.settings_ethernet_outlined,
          title: '局域网直连',
          paragraphs: <String>[
            '默认地址为 $defaultGateway。直连模式下只需要填写设备 IP、端口、客户端 ID 和响应超时，端口默认 18789。',
            '设备地址支持直接粘贴 ws:// 或 wss:// 根地址；保存时会拆分并归一化为主机名、端口和 WSS 开关。',
            '客户端 ID 会作为 chat_id 前缀参与会话隔离，只能使用字母、数字、下划线、点和短横线，最长 31 个字符。',
          ],
        ),
        const _DocumentationSectionData(
          icon: Icons.cloud_outlined,
          title: '云端 Relay',
          paragraphs: <String>[
            'Relay 模式用于让 BareBrain 先连到云端，再由 App 连接同一个 Relay。公开网络建议打开 WSS，端口通常使用 443。',
            'App 侧需要填写 Relay 域名或 IP、端口、设备 ID、App Token 和 App 路径。默认 App 路径为 /ws/app。',
            'Relay Token 只用于连接鉴权，界面会隐藏输入内容；板子设置依赖局域网 admin 接口，Relay 模式下暂不支持。',
          ],
        ),
        const _DocumentationSectionData(
          icon: Icons.timer_outlined,
          title: '超时与测试',
          paragraphs: <String>[
            '聊天响应超时允许 5 到 300 秒。模型回复较慢时可以适当调高，局域网排障时建议先保持默认值。',
            '连接测试失败时，先检查设备和 App 是否在同一网络、端口是否开放、WSS 是否与服务端一致，再检查网络代理绕过规则。',
          ],
        ),
      ],
    ),
    const _DocumentationPageData(
      label: '板子',
      title: 'BareBrain 板子设置',
      summary: '板子设置从聊天输入栏左下角快捷列表进入，通过设备 admin 接口读写配置，不会发送到聊天模型。',
      icon: Icons.memory_outlined,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.fact_check_outlined,
          title: '支持的配置项',
          paragraphs: <String>[
            '快捷列表支持查看板子配置、设置 WiFi、主模型 API Key、模型名称、模型供应商、Base URL、记忆模型配置、代理和搜索服务 Key。',
            '设置说明页只解释每个动作的用途；实际读写需要点击具体动作并填写表单，不需要在聊天框手动输入命令文本。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.lock_outline,
          title: '敏感信息处理',
          paragraphs: <String>[
            'API Key、Token、密码和代理凭据会作为表单内容提交到 BareBrain admin 接口，不会写进本地聊天记录。',
            '查看配置时会展示板子返回的当前配置。处理截图或转发结果前，记得确认里面没有需要隐藏的密钥。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.restart_alt_outlined,
          title: '保存后的状态',
          paragraphs: <String>[
            '部分板子配置保存后设备会自动重启，短时间内 WebSocket 断开属于正常现象。',
            '写入失败通常与局域网地址、admin 接口、设备重启中或 Relay 模式有关。等待设备恢复后可重新执行同一设置。',
          ],
        ),
      ],
    ),
    const _DocumentationPageData(
      label: '聊天',
      title: '聊天、会话与增强',
      summary: '这里记录消息发送、会话管理、快捷短语和指令注入的工作方式，帮助你知道哪些内容会进入模型上下文。',
      icon: Icons.chat_bubble_outline,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.forum_outlined,
          title: '会话管理',
          paragraphs: <String>[
            '宽屏会显示左侧会话栏，窄屏使用抽屉。会话支持新建、切换、重命名和删除非当前会话。',
            '默认会话沿用客户端 ID，新建会话会派生短 chat_id，避免设备侧会话历史互相串联。',
            '开启草稿保存后，输入框内容会按会话保留；切换会话再回来不会丢失未发送文本。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.flash_on_outlined,
          title: '快捷短语',
          paragraphs: <String>[
            '快捷短语在设置页维护，可从输入栏快速插入，适合保存高频提问、固定开场和调试提示。',
            '关闭某条快捷短语后，它会保留在本地配置里，但不会出现在可插入列表中。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.layers_outlined,
          title: '指令注入',
          paragraphs: <String>[
            '指令注入支持系统前置、用户前置和消息后置三种位置，会在发送时拼接到传输内容。',
            '本地聊天记录仍显示用户原始输入。发送失败后重试，会按当前启用的注入规则重新生成增强文本。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.replay_outlined,
          title: '重试与重新生成',
          paragraphs: <String>[
            '发送失败后可以重试最后一条用户消息，重试不会在本地历史里重复追加同一条提问。',
            '显示设置里可以开启重新生成前确认，以及重新生成时删除下方消息，适合控制历史分叉方式。',
          ],
        ),
      ],
    ),
    const _DocumentationPageData(
      label: '外观',
      title: '显示与交互配置',
      summary: '显示设置只影响本机 UI 呈现，不会改变已经发送给 BareBrain 的消息内容。',
      icon: Icons.palette_outlined,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.color_lens_outlined,
          title: '主题与颜色',
          paragraphs: <String>[
            '颜色模式支持跟随系统、浅色和深色。主题预设包含默认主题、黑白灰、Claude 风格、自然风格、未来科技、柔和渐变、海洋、日落和若干趋势色。',
            '主题会影响设置页、聊天页和消息气泡的整体色彩，但不会影响备份 JSON 的结构。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.article_outlined,
          title: '消息呈现',
          paragraphs: <String>[
            '可独立控制头像、作者名、时间、消息操作、消息文本选择、紧凑间距、气泡背景和消息导航按钮。',
            'Markdown、行内公式、块级公式、代码块自动折叠和移动端代码自动换行都在显示设置中控制。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.text_fields_outlined,
          title: '字体与输入',
          paragraphs: <String>[
            '应用字体支持系统默认、屏显黑体和宋体；代码字体支持系统默认、等宽和衬线。',
            '消息字号范围为 90% 到 140%。发送后回到底部延迟范围为 0 到 60 秒，设置为 0 时会立即滚动。',
            '可以控制 Enter 是否发送消息、是否启用触觉反馈，以及窄屏选择会话后是否保持抽屉打开。',
          ],
        ),
      ],
    ),
    const _DocumentationPageData(
      label: '网络',
      title: '网络代理与 OTA',
      summary:
          '网络代理会影响 App 发起的 BareBrain WebSocket 和 OTA 请求；OTA 参数用于版本检查和固件路径约定。',
      icon: Icons.public_outlined,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.public_outlined,
          title: 'HTTP 代理',
          paragraphs: <String>[
            '代理支持开启状态、HTTP 类型、服务器地址、端口、用户名、密码、绕过规则和测试地址。',
            '默认绕过 localhost、127.0.0.1、10.0.0.0/8、172.16.0.0/12、192.168.0.0/16 和 ::1，方便局域网设备保持直连。',
            '测试地址必须是 http 或 https URL。代理端口必须在 1 到 65535 之间。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.system_update_alt_outlined,
          title: 'OTA 参数',
          paragraphs: <String>[
            '版本检查路径默认 /ota/version，固件路径默认 /ota/firmware，路径必须以 / 开头且不能包含查询、片段或空白字符。',
            '更新通道默认 stable，只能使用字母、数字、下划线、点和短横线，最长 24 个字符。',
            'OTA 请求超时允许 10 到 600 秒。启用自动检查后，应用恢复会话时会发起版本检查并显示失败提示。',
          ],
        ),
      ],
    ),
    const _DocumentationPageData(
      label: '数据',
      title: '数据、备份与 Relay 服务端',
      summary: '本页说明本地持久化范围、备份 JSON 内容，以及自建 Relay 服务端相关配置入口。',
      icon: Icons.backup_outlined,
      sections: <_DocumentationSectionData>[
        _DocumentationSectionData(
          icon: Icons.storage_outlined,
          title: '本地持久化',
          paragraphs: <String>[
            '会话快照、会话目录、草稿、连接参数、显示设置和应用设置会通过 Key-Value JSON 持久化到底层 shared_preferences。',
            '存储空间页会统计聊天记录和会话目录占用。关闭聊天记录保存后，当前临时对话仍可继续使用。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.ios_share_outlined,
          title: '备份与恢复',
          paragraphs: <String>[
            '本地备份会导出 JSON，并同时复制到剪贴板。完整备份包含 appSettings、connectionSettings 和 displaySettings。',
            '恢复前建议先导出当前配置，便于参数不符合预期时回退。WebDAV 和 S3 入口目前是占位配置。',
          ],
        ),
        _DocumentationSectionData(
          icon: Icons.dns_outlined,
          title: 'Relay 服务端',
          paragraphs: <String>[
            'server/ 目录提供自建 WebSocket Relay，可配置监听地址、端口、设备 ID、设备 Token、App Token 和推送 Webhook。',
            '手机锁屏或 App 被系统回收后，WebSocket 不能保证保活。需要后台通知时，应由 Relay 调用 PUSH_WEBHOOK_URL 接入系统推送或自建推送服务。',
            '公网部署建议用 Caddy 或 Nginx 终止 TLS，对外暴露 WSS，Relay 本身监听内网或 127.0.0.1。',
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: strong,
                          fontSize: 19,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < paragraphs.length; index++)
              _DocumentationParagraph(
                text: paragraphs[index],
                color: soft,
                addTopGap: index > 0,
              ),
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
