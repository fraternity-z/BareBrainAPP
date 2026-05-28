import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/chat_app_settings_codec.dart';
import '../../data/models/chat_connection_settings_codec.dart';
import '../../data/models/chat_display_settings_codec.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import 'settings_components.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({
    this.settings = const ChatAppSettings(),
    this.connectionSettings,
    this.displaySettings,
    this.onAppSettingsImported,
    this.onConnectionSettingsImported,
    this.onDisplaySettingsImported,
    super.key,
  });

  final ChatAppSettings settings;
  final ChatConnectionSettings? connectionSettings;
  final ChatDisplaySettings? displaySettings;
  final ValueChanged<ChatAppSettings>? onAppSettingsImported;
  final ValueChanged<ChatConnectionSettings>? onConnectionSettingsImported;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsImported;

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final TextEditingController _importSource = TextEditingController();
  String? _feedback;
  bool _succeeded = true;

  @override
  void dispose() {
    _importSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '数据备份',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsFormPanel(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('copy_settings_backup_button'),
                  onPressed: _copyBackup,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('复制设置备份'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('settings_backup_import_field'),
                controller: _importSource,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '粘贴备份 JSON',
                  alignLabelWithHint: true,
                ),
                textInputAction: TextInputAction.newline,
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('import_settings_backup_button'),
                  onPressed: _importBackup,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('导入设置备份'),
                ),
              ),
            ],
          ),
          if (_feedback != null) ...<Widget>[
            const SizedBox(height: 14),
            _BackupFeedback(succeeded: _succeeded, message: _feedback!),
          ],
        ],
      ),
    );
  }

  Future<void> _copyBackup() async {
    final source = _encodeBackup();
    await Clipboard.setData(ClipboardData(text: source));
    if (!mounted) {
      return;
    }
    setState(() {
      _succeeded = true;
      _feedback = '设置备份已复制';
    });
  }

  void _importBackup() {
    try {
      final backup = _decodeBackup(_importSource.text.trim());
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
        _succeeded = true;
        _feedback = '设置备份已导入';
      });
    } catch (error) {
      setState(() {
        _succeeded = false;
        _feedback = '导入失败：$error';
      });
    }
  }

  void _clearFeedback() {
    if (_feedback == null) {
      return;
    }

    setState(() => _feedback = null);
  }

  String _encodeBackup() {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'appSettings': ChatAppSettingsCodec.toJson(widget.settings),
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

class _BackupFeedback extends StatelessWidget {
  const _BackupFeedback({
    required this.succeeded,
    required this.message,
  });

  final bool succeeded;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground =
        succeeded ? colors.onSecondaryContainer : colors.onErrorContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: succeeded ? colors.secondaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: succeeded ? colors.secondary : colors.error,
          width: 0.7,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(
              succeeded ? Icons.check_circle_outline : Icons.error_outline,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
