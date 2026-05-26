import 'package:flutter/material.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../../domain/services/chat_ota_settings_parser.dart';
import 'settings_components.dart';

class OtaSettingsSheet extends StatefulWidget {
  const OtaSettingsSheet({
    required this.settings,
    super.key,
  });

  final ChatOtaSettings settings;

  @override
  State<OtaSettingsSheet> createState() => _OtaSettingsSheetState();
}

class _OtaSettingsSheetState extends State<OtaSettingsSheet> {
  late final TextEditingController _versionPath;
  late final TextEditingController _firmwarePath;
  late final TextEditingController _channel;
  late final TextEditingController _timeout;
  late bool _autoCheck;
  String? _error;

  @override
  void initState() {
    super.initState();
    _versionPath = TextEditingController(text: widget.settings.versionPath);
    _firmwarePath = TextEditingController(text: widget.settings.firmwarePath);
    _channel = TextEditingController(text: widget.settings.channel);
    _timeout = TextEditingController(
      text: widget.settings.requestTimeout.inSeconds.toString(),
    );
    _autoCheck = widget.settings.autoCheck;
  }

  @override
  void dispose() {
    _versionPath.dispose();
    _firmwarePath.dispose();
    _channel.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'OTA 参数',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: settingsPrimaryText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                SettingsFormPanel(
                  children: <Widget>[
                    TextField(
                      key: const Key('ota_version_path_field'),
                      controller: _versionPath,
                      decoration: const InputDecoration(
                        labelText: '版本检查路径',
                        prefixIcon: Icon(Icons.fact_check_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('ota_firmware_path_field'),
                      controller: _firmwarePath,
                      decoration: const InputDecoration(
                        labelText: '固件路径',
                        prefixIcon: Icon(Icons.system_update_alt_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            key: const Key('ota_channel_field'),
                            controller: _channel,
                            decoration: const InputDecoration(
                              labelText: '更新通道',
                              prefixIcon: Icon(Icons.merge_type_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('ota_timeout_field'),
                            controller: _timeout,
                            decoration: const InputDecoration(
                              labelText: '超时秒数',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _autoCheck,
                      onChanged: (value) {
                        setState(() => _autoCheck = value);
                      },
                      secondary:
                          const Icon(Icons.notifications_active_outlined),
                      title: const Text('自动检查更新'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _OtaFeedback(
                    message: _error!,
                    background: colors.errorContainer,
                    foreground: colors.onErrorContainer,
                    border: colors.error,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('save_ota_settings_button'),
                        onPressed: _save,
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    try {
      final settings = ChatOtaSettingsParser.parse(
        versionPathInput: _versionPath.text,
        firmwarePathInput: _firmwarePath.text,
        channelInput: _channel.text,
        timeoutSecondsInput: _timeout.text,
        autoCheck: _autoCheck,
      );
      Navigator.of(context).pop(settings);
    } on ChatException catch (error) {
      setState(() => _error = error.message);
    }
  }
}

class _OtaFeedback extends StatelessWidget {
  const _OtaFeedback({
    required this.message,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String message;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: foreground, size: 18),
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
