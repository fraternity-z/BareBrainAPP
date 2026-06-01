import 'package:flutter/material.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../../domain/services/chat_ota_settings_parser.dart';
import 'settings_components.dart';

typedef TestOtaSettings = Future<void> Function(ChatOtaSettings settings);

class OtaSettingsSheet extends StatefulWidget {
  const OtaSettingsSheet({
    required this.settings,
    this.onTestVersionCheck,
    super.key,
  });

  final ChatOtaSettings settings;
  final TestOtaSettings? onTestVersionCheck;

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
  String? _status;
  bool _isTesting = false;

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
                        color: settingsPrimaryTextColor(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
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
                      onChanged: (_) => _clearFeedback(),
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
                      onChanged: (_) => _clearFeedback(),
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
                            onChanged: (_) => _clearFeedback(),
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
                            onChanged: (_) => _clearFeedback(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _autoCheck,
                      onChanged: (value) {
                        setState(() {
                          _autoCheck = value;
                          _error = null;
                          _status = null;
                        });
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
                    succeeded: false,
                    message: _error!,
                  ),
                ],
                if (_status != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _OtaFeedback(
                    succeeded: true,
                    message: _status!,
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('test_ota_version_button'),
                  onPressed: _isTesting ? null : _testVersionCheck,
                  icon: _isTesting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('测试版本检查'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isTesting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('save_ota_settings_button'),
                        onPressed: _isTesting ? null : _save,
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
      final settings = _parseSettings();
      Navigator.of(context).pop(settings);
    } on ChatException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _testVersionCheck() async {
    ChatOtaSettings settings;
    try {
      settings = _parseSettings();
    } on ChatException catch (error) {
      _showError(error.message);
      return;
    }

    final testVersionCheck = widget.onTestVersionCheck;
    if (testVersionCheck == null) {
      setState(() {
        _error = null;
        _status = 'OTA 参数检查通过';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _error = null;
      _status = null;
    });
    try {
      await testVersionCheck(settings);
      if (!mounted) {
        return;
      }
      setState(() => _status = 'OTA 版本检查成功');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _clearFeedback() {
    if (_error == null && _status == null) {
      return;
    }

    setState(() {
      _error = null;
      _status = null;
    });
  }

  ChatOtaSettings _parseSettings() {
    return ChatOtaSettingsParser.parse(
      versionPathInput: _versionPath.text,
      firmwarePathInput: _firmwarePath.text,
      channelInput: _channel.text,
      timeoutSecondsInput: _timeout.text,
      autoCheck: _autoCheck,
    );
  }

  void _showError(String message) {
    setState(() {
      _status = null;
      _error = message;
    });
  }
}

class _OtaFeedback extends StatelessWidget {
  const _OtaFeedback({
    required this.succeeded,
    required this.message,
  });

  final bool succeeded;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background =
        succeeded ? colors.secondaryContainer : colors.errorContainer;
    final foreground =
        succeeded ? colors.onSecondaryContainer : colors.onErrorContainer;
    final border = succeeded ? colors.secondary : colors.error;

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
