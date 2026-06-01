import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/chat_app_settings_codec.dart';
import '../../data/models/chat_connection_settings_codec.dart';
import '../../data/models/chat_display_settings_codec.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import 'settings_components.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({
    this.settings = const ChatStorageSettings(),
    this.appSettings = const ChatAppSettings(),
    this.connectionSettings,
    this.displaySettings,
    this.onChanged,
    this.onAppSettingsImported,
    this.onConnectionSettingsImported,
    this.onDisplaySettingsImported,
    super.key,
  });

  final ChatStorageSettings settings;
  final ChatAppSettings appSettings;
  final ChatConnectionSettings? connectionSettings;
  final ChatDisplaySettings? displaySettings;
  final ValueChanged<ChatStorageSettings>? onChanged;
  final ValueChanged<ChatAppSettings>? onAppSettingsImported;
  final ValueChanged<ChatConnectionSettings>? onConnectionSettingsImported;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsImported;

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late ChatStorageSettings _settings;
  late ChatAppSettings _appSettings;

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
              _ReferenceActionRow(
                icon: Icons.drive_folder_upload_outlined,
                title: '导出为文件',
                onTap: () => unawaited(_exportBackupFile()),
              ),
              _ReferenceActionRow(
                icon: Icons.file_download_outlined,
                title: '恢复',
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
    try {
      final source = _encodeBackup();
      final file = await _nextBackupFile();
      await file.writeAsString(source);
      await Clipboard.setData(ClipboardData(text: source));
      if (!mounted) {
        return;
      }
      _showMessage('备份已导出：${file.path}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('导出失败：$error');
    }
  }

  Future<void> _openRestoreSheet() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _RestoreBackupSheet(),
    );

    if (source == null || source.trim().isEmpty || !mounted) {
      return;
    }

    _importBackup(source.trim());
  }

  void _importBackup(String source) {
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
      setState(() {
        _appSettings = backup.appSettings;
        _settings = backup.appSettings.storage;
      });
      _showMessage('备份已恢复');
    } catch (error) {
      _showMessage('恢复失败：$error');
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

  String _encodeBackup() {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'appSettings': ChatAppSettingsCodec.toJson(_currentAppSettings),
      if (widget.connectionSettings != null)
        'connectionSettings': ChatConnectionSettingsCodec.toJson(
          widget.connectionSettings!,
        ),
      if (widget.displaySettings != null)
        'displaySettings': ChatDisplaySettingsCodec.toJson(
          widget.displaySettings!,
        ),
    });
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

    return _SettingsBackup(
      appSettings: ChatAppSettingsCodec.fromJson(appSettings),
      connectionSettings: connectionSettings == null
          ? null
          : ChatConnectionSettingsCodec.fromJson(connectionSettings),
      displaySettings: displaySettings == null
          ? null
          : ChatDisplaySettingsCodec.fromJson(displaySettings),
    );
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                Icon(Icons.chevron_right, size: 30, color: strong),
              ],
            ),
          ),
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

  @override
  void dispose() {
    _source.dispose();
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
            TextField(
              controller: _source,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '粘贴备份 JSON',
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_source.text),
              child: const Text('恢复'),
            ),
          ],
        ),
      ),
    );
  }
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
            subtitle: '内容暂未配置',
          ),
        ],
      ),
    );
  }
}

class _SettingsBackup {
  const _SettingsBackup({
    required this.appSettings,
    this.connectionSettings,
    this.displaySettings,
  });

  final ChatAppSettings appSettings;
  final ChatConnectionSettings? connectionSettings;
  final ChatDisplaySettings? displaySettings;
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
