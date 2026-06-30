import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/chat_app_settings_codec.dart';
import '../../data/models/chat_connection_settings_codec.dart';
import '../../data/models/chat_conversation_catalog_codec.dart';
import '../../data/models/chat_display_settings_codec.dart';
import '../../data/models/chat_session_snapshot_codec.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import '../controllers/chat_controller.dart';
import 'settings_components.dart';

typedef LoadChatConversationBackup = Future<ChatConversationBackup> Function();
typedef ImportChatConversationBackup = Future<void> Function(
  ChatConversationBackup backup, {
  required ChatConversationRestoreMode mode,
});

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({
    this.settings = const ChatStorageSettings(),
    this.appSettings = const ChatAppSettings(),
    this.connectionSettings,
    this.displaySettings,
    this.loadConversationBackup,
    this.onChanged,
    this.onAppSettingsImported,
    this.onConnectionSettingsImported,
    this.onDisplaySettingsImported,
    this.onConversationBackupImported,
    super.key,
  });

  final ChatStorageSettings settings;
  final ChatAppSettings appSettings;
  final ChatConnectionSettings? connectionSettings;
  final ChatDisplaySettings? displaySettings;
  final LoadChatConversationBackup? loadConversationBackup;
  final ValueChanged<ChatStorageSettings>? onChanged;
  final ValueChanged<ChatAppSettings>? onAppSettingsImported;
  final ValueChanged<ChatConnectionSettings>? onConnectionSettingsImported;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsImported;
  final ImportChatConversationBackup? onConversationBackupImported;

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late ChatStorageSettings _settings;
  late ChatAppSettings _appSettings;
  bool _isBusy = false;
  _BackupSummary? _lastBackupSummary;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _appSettings = widget.appSettings;
  }

  @override
  void didUpdateWidget(covariant BackupRestorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
    if (oldWidget.appSettings != widget.appSettings) {
      _appSettings = widget.appSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '备份与恢复',
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          _ReferenceSection(
            title: '备份管理',
            children: <Widget>[
              _ReferenceSwitchRow(
                icon: Icons.chat_bubble_outline,
                title: '聊天记录',
                value: _settings.autoSaveConversations,
                onChanged: (value) {
                  _updateStorage(
                    _settings.copyWith(autoSaveConversations: value),
                  );
                },
              ),
            ],
          ),
          const _ReferenceSection(
            title: '备份提醒',
            children: <Widget>[
              _ReferenceSwitchRow(
                icon: Icons.timer_outlined,
                title: '定期提醒我备份',
                value: false,
              ),
            ],
          ),
          _ReferenceSection(
            title: 'WebDAV 备份',
            children: <Widget>[
              _ReferenceActionRow(
                icon: Icons.settings_outlined,
                title: 'WebDAV 服务器设置',
                onTap: () => _openUnavailablePage('WebDAV 服务器设置'),
              ),
              _ReferenceActionRow(
                icon: Icons.cable_outlined,
                title: '测试连接',
                onTap: () => _showMessage('WebDAV 服务器未配置'),
              ),
              _ReferenceActionRow(
                icon: Icons.file_download_outlined,
                title: '恢复',
                onTap: () => _showMessage('WebDAV 服务器未配置'),
              ),
              _ReferenceActionRow(
                icon: Icons.file_upload_outlined,
                title: '立即备份',
                onTap: () => _showMessage('WebDAV 服务器未配置'),
              ),
            ],
          ),
          _ReferenceSection(
            title: 'S3 备份',
            children: <Widget>[
              _ReferenceActionRow(
                icon: Icons.settings_outlined,
                title: 'S3 服务器设置',
                onTap: () => _openUnavailablePage('S3 服务器设置'),
              ),
              _ReferenceActionRow(
                icon: Icons.cable_outlined,
                title: '测试连接',
                onTap: () => _showMessage('S3 服务器未配置'),
              ),
              _ReferenceActionRow(
                icon: Icons.file_download_outlined,
                title: '恢复',
                onTap: () => _showMessage('S3 服务器未配置'),
              ),
              _ReferenceActionRow(
                icon: Icons.file_upload_outlined,
                title: '立即备份',
                onTap: () => _showMessage('S3 服务器未配置'),
              ),
            ],
          ),
          _ReferenceSection(
            title: '本地备份',
            children: <Widget>[
              if (_lastBackupSummary != null)
                _ReferenceInfoRow(
                  icon: Icons.info_outline,
                  title: '上次备份内容',
                  value: _lastBackupSummary!.label,
                ),
              _ReferenceActionRow(
                icon: Icons.drive_folder_upload_outlined,
                title: '导出为文件',
                subtitle: _isBusy ? '正在准备完整备份' : '包含设置、连接参数、显示设置和会话数据',
                enabled: !_isBusy,
                onTap: () => unawaited(_exportBackupFile()),
              ),
              _ReferenceActionRow(
                icon: Icons.file_download_outlined,
                title: '恢复',
                subtitle: '支持粘贴 JSON 或填写本地备份文件路径',
                enabled: !_isBusy,
                onTap: () => unawaited(_openRestoreSheet()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateStorage(ChatStorageSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  Future<void> _exportBackupFile() async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final encoded = await _encodeBackup();
      final file = await _nextBackupFile();
      await file.writeAsString(encoded.source, encoding: utf8);
      await Clipboard.setData(ClipboardData(text: encoded.source));
      if (!mounted) {
        return;
      }
      setState(() => _lastBackupSummary = encoded.summary);
      _showMessage('备份已导出：${file.path}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('导出失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _openRestoreSheet() async {
    final request = await showModalBottomSheet<_RestoreBackupRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _RestoreBackupSheet(),
    );

    if (request == null || !mounted) {
      return;
    }

    await _restoreBackup(request);
  }

  Future<void> _restoreBackup(_RestoreBackupRequest request) async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final source = await request.loadSource();
      final summary = await _importBackup(
        source.trim(),
        mode: request.mode,
      );
      if (!mounted) {
        return;
      }
      setState(() => _lastBackupSummary = summary);
      _showMessage('备份已恢复：${summary.label}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('恢复失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<_BackupSummary> _importBackup(
    String source, {
    required ChatConversationRestoreMode mode,
  }) async {
    try {
      final backup = _decodeBackup(source);
      widget.onAppSettingsImported?.call(backup.appSettings);
      final connectionSettings = backup.connectionSettings;
      if (connectionSettings != null) {
        widget.onConnectionSettingsImported?.call(connectionSettings);
      }
      final displaySettings = backup.displaySettings;
      if (displaySettings != null) {
        widget.onDisplaySettingsImported?.call(displaySettings);
      }
      final conversationBackup = backup.conversationBackup;
      if (conversationBackup != null && !conversationBackup.isEmpty) {
        final importer = widget.onConversationBackupImported;
        if (importer == null) {
          throw const FormatException('当前页面缺少会话恢复入口');
        }
        await importer(conversationBackup, mode: mode);
      }
      if (mounted) {
        setState(() {
          _appSettings = backup.appSettings;
          _settings = backup.appSettings.storage;
        });
      }
      return backup.summary;
    } catch (error) {
      if (error is FormatException) {
        rethrow;
      }
      throw Exception(error);
    }
  }

  void _openUnavailablePage(String title) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => _UnavailableBackupPage(title: title),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<_EncodedBackup> _encodeBackup() async {
    final conversationBackup = await widget.loadConversationBackup?.call();
    final summary = _BackupSummary.fromConversationBackup(
      conversationBackup,
      hasConnectionSettings: widget.connectionSettings != null,
      hasDisplaySettings: widget.displaySettings != null,
    );
    final payload = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'appSettings': ChatAppSettingsCodec.toJson(_currentAppSettings),
      if (widget.connectionSettings != null)
        'connectionSettings': ChatConnectionSettingsCodec.toJson(
          widget.connectionSettings!,
        ),
      if (widget.displaySettings != null)
        'displaySettings': ChatDisplaySettingsCodec.toJson(
          widget.displaySettings!,
        ),
      if (conversationBackup != null && !conversationBackup.isEmpty)
        'conversationBackup': _conversationBackupToJson(conversationBackup),
      'summary': summary.toJson(),
    };

    return _EncodedBackup(
      source: const JsonEncoder.withIndent('  ').convert(payload),
      summary: summary,
    );
  }

  _SettingsBackup _decodeBackup(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('设置备份格式无效');
    }

    final hasFullBackupSections = value.containsKey('connectionSettings') ||
        value.containsKey('displaySettings');
    if (!value.containsKey('appSettings')) {
      if (hasFullBackupSections) {
        throw const FormatException('应用设置格式无效');
      }
      return _SettingsBackup(
        appSettings: ChatAppSettingsCodec.fromJson(value),
        summary: const _BackupSummary(
          conversationCount: 0,
          messageCount: 0,
          draftCount: 0,
          hasConnectionSettings: false,
          hasDisplaySettings: false,
        ),
      );
    }

    final appSettings = value['appSettings'];
    if (appSettings is! Map<String, dynamic>) {
      throw const FormatException('应用设置格式无效');
    }

    final connectionSettings = value['connectionSettings'];
    final displaySettings = value['displaySettings'];
    if (connectionSettings != null &&
        connectionSettings is! Map<String, dynamic>) {
      throw const FormatException('连接设置格式无效');
    }
    if (displaySettings != null && displaySettings is! Map<String, dynamic>) {
      throw const FormatException('显示设置格式无效');
    }

    final conversationBackup = _conversationBackupFromJson(
      value['conversationBackup'],
    );
    final summary = _BackupSummary.fromDecodedBackup(
      conversationBackup: conversationBackup,
      hasConnectionSettings: connectionSettings != null,
      hasDisplaySettings: displaySettings != null,
    );

    return _SettingsBackup(
      appSettings: ChatAppSettingsCodec.fromJson(appSettings),
      connectionSettings: connectionSettings == null
          ? null
          : ChatConnectionSettingsCodec.fromJson(connectionSettings),
      displaySettings: displaySettings == null
          ? null
          : ChatDisplaySettingsCodec.fromJson(displaySettings),
      conversationBackup: conversationBackup,
      summary: summary,
    );
  }

  Map<String, dynamic> _conversationBackupToJson(
    ChatConversationBackup backup,
  ) {
    return <String, dynamic>{
      if (backup.catalog != null)
        'catalog': _jsonObjectFromEncoded(
          ChatConversationCatalogCodec.encode(backup.catalog!),
        ),
      'snapshots': <String, dynamic>{
        for (final entry in backup.snapshots.entries)
          entry.key: _jsonObjectFromEncoded(
            ChatSessionSnapshotCodec.encode(entry.value),
          ),
      },
    };
  }

  ChatConversationBackup? _conversationBackupFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('会话备份格式无效');
    }

    final catalogValue = value['catalog'];
    final snapshotsValue = value['snapshots'];
    if (catalogValue != null && catalogValue is! Map<String, dynamic>) {
      throw const FormatException('会话目录格式无效');
    }
    if (snapshotsValue != null && snapshotsValue is! Map<String, dynamic>) {
      throw const FormatException('会话快照格式无效');
    }

    final snapshots = <String, dynamic>{};
    if (snapshotsValue is Map<String, dynamic>) {
      snapshots.addAll(snapshotsValue);
    }

    return ChatConversationBackup(
      catalog: catalogValue == null
          ? null
          : ChatConversationCatalogCodec.decode(jsonEncode(catalogValue)),
      snapshots: <String, dynamic>{
        for (final entry in snapshots.entries)
          if (entry.value is Map<String, dynamic>) entry.key: entry.value,
      }.map((conversationId, snapshotValue) {
        return MapEntry(
          conversationId,
          ChatSessionSnapshotCodec.decode(jsonEncode(snapshotValue)),
        );
      }),
    );
  }

  Map<String, dynamic> _jsonObjectFromEncoded(String source) {
    final value = jsonDecode(source);
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const FormatException('备份 JSON 编码失败');
  }

  ChatAppSettings get _currentAppSettings {
    return _appSettings.copyWith(storage: _settings);
  }
}

class _ReferenceSection extends StatelessWidget {
  const _ReferenceSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsSecondaryTextColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: settingsCardDecoration(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(settingsCardRadius),
              child: Column(children: _withDividers(context)),
            ),
          ),
        ],
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
            indent: 74,
            endIndent: 18,
          ),
        );
      }
    }
    return widgets;
  }
}

class _ReferenceSwitchRow extends StatelessWidget {
  const _ReferenceSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 31, color: strong),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: strong,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceActionRow extends StatelessWidget {
  const _ReferenceActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    final contentColor = enabled ? strong : soft;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 31, color: contentColor),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: contentColor,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: soft,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 30, color: contentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceInfoRow extends StatelessWidget {
  const _ReferenceInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 86),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 31, color: strong),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: strong,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: soft,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

class _RestoreBackupSheet extends StatefulWidget {
  const _RestoreBackupSheet();

  @override
  State<_RestoreBackupSheet> createState() => _RestoreBackupSheetState();
}

class _RestoreBackupSheetState extends State<_RestoreBackupSheet> {
  final TextEditingController _source = TextEditingController();
  final TextEditingController _filePath = TextEditingController();
  ChatConversationRestoreMode _mode = ChatConversationRestoreMode.overwrite;

  @override
  void dispose() {
    _source.dispose();
    _filePath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '恢复',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<ChatConversationRestoreMode>(
                segments: const <ButtonSegment<ChatConversationRestoreMode>>[
                  ButtonSegment<ChatConversationRestoreMode>(
                    value: ChatConversationRestoreMode.overwrite,
                    icon: Icon(Icons.layers_clear_outlined),
                    label: Text('覆盖'),
                  ),
                  ButtonSegment<ChatConversationRestoreMode>(
                    value: ChatConversationRestoreMode.merge,
                    icon: Icon(Icons.merge_type_outlined),
                    label: Text('合并'),
                  ),
                ],
                selected: <ChatConversationRestoreMode>{_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _filePath,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '本地备份文件路径',
                  hintText: r'C:\Users\...\Downloads\barebrain-backup.json',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _source,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '或粘贴备份 JSON',
                  alignLabelWithHint: true,
                ),
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _submit,
                child: const Text('恢复'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final path = _normalizeBackupFilePath(_filePath.text);
    final source = _source.text.trim();
    if (path.isEmpty && source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写备份文件路径或粘贴备份 JSON')),
      );
      return;
    }

    Navigator.of(context).pop(
      _RestoreBackupRequest(
        source: source,
        filePath: path,
        mode: _mode,
      ),
    );
  }
}

String _normalizeBackupFilePath(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }

  return trimmed;
}

class _UnavailableBackupPage extends StatelessWidget {
  const _UnavailableBackupPage({
    required this.title,
  });

  final String title;

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
            icon: Icons.cloud_off_outlined,
            title: title,
            subtitle: '当前版本仅支持本地完整 JSON 导出、文件路径恢复和粘贴恢复，云端同步需要接入对应服务后再启用。',
          ),
        ],
      ),
    );
  }
}

class _SettingsBackup {
  const _SettingsBackup({
    required this.appSettings,
    required this.summary,
    this.connectionSettings,
    this.displaySettings,
    this.conversationBackup,
  });

  final ChatAppSettings appSettings;
  final ChatConnectionSettings? connectionSettings;
  final ChatDisplaySettings? displaySettings;
  final ChatConversationBackup? conversationBackup;
  final _BackupSummary summary;
}

class _EncodedBackup {
  const _EncodedBackup({
    required this.source,
    required this.summary,
  });

  final String source;
  final _BackupSummary summary;
}

class _BackupSummary {
  const _BackupSummary({
    required this.conversationCount,
    required this.messageCount,
    required this.draftCount,
    required this.hasConnectionSettings,
    required this.hasDisplaySettings,
  });

  factory _BackupSummary.fromConversationBackup(
    ChatConversationBackup? backup, {
    required bool hasConnectionSettings,
    required bool hasDisplaySettings,
  }) {
    return _BackupSummary(
      conversationCount: backup?.conversationCount ?? 0,
      messageCount: backup?.messageCount ?? 0,
      draftCount: backup?.draftCount ?? 0,
      hasConnectionSettings: hasConnectionSettings,
      hasDisplaySettings: hasDisplaySettings,
    );
  }

  factory _BackupSummary.fromDecodedBackup({
    required ChatConversationBackup? conversationBackup,
    required bool hasConnectionSettings,
    required bool hasDisplaySettings,
  }) {
    return _BackupSummary(
      conversationCount: conversationBackup?.conversationCount ?? 0,
      messageCount: conversationBackup?.messageCount ?? 0,
      draftCount: conversationBackup?.draftCount ?? 0,
      hasConnectionSettings: hasConnectionSettings,
      hasDisplaySettings: hasDisplaySettings,
    );
  }

  final int conversationCount;
  final int messageCount;
  final int draftCount;
  final bool hasConnectionSettings;
  final bool hasDisplaySettings;

  String get label {
    final parts = <String>[
      '$conversationCount 个会话',
      '$messageCount 条消息',
    ];
    if (draftCount > 0) {
      parts.add('$draftCount 个草稿');
    }
    if (hasConnectionSettings) {
      parts.add('连接参数');
    }
    if (hasDisplaySettings) {
      parts.add('显示设置');
    }

    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'conversationCount': conversationCount,
      'messageCount': messageCount,
      'draftCount': draftCount,
      'hasConnectionSettings': hasConnectionSettings,
      'hasDisplaySettings': hasDisplaySettings,
    };
  }
}

class _RestoreBackupRequest {
  const _RestoreBackupRequest({
    required this.source,
    required this.filePath,
    required this.mode,
  });

  final String source;
  final String filePath;
  final ChatConversationRestoreMode mode;

  Future<String> loadSource() async {
    if (source.trim().isNotEmpty) {
      return source;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('备份文件不存在');
    }

    return file.readAsString(encoding: utf8);
  }
}

Future<File> _nextBackupFile() async {
  final directory = await _backupDirectory();
  final timestamp = DateTime.now()
      .toLocal()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  return File(
    '${directory.path}${Platform.pathSeparator}barebrain-backup-$timestamp.json',
  );
}

Future<Directory> _backupDirectory() async {
  final home = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.systemTemp.path;
  final downloads = Directory('$home${Platform.pathSeparator}Downloads');
  final directory = await downloads.exists() ? downloads : Directory(home);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}
