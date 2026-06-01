import 'package:flutter/material.dart';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/services/chat_connection_settings_parser.dart';
import '../settings/settings_components.dart';

typedef TestChatConnection = Future<void> Function(
  ChatConnectionSettings settings,
);

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    required this.settings,
    this.onTestConnection,
    super.key,
  });

  final ChatConnectionSettings settings;
  final TestChatConnection? onTestConnection;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _clientId;
  late final TextEditingController _timeout;
  late bool _secure;
  bool _isTesting = false;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: widget.settings.host);
    _port = TextEditingController(text: widget.settings.port.toString());
    _clientId = TextEditingController(text: widget.settings.clientId);
    _timeout = TextEditingController(
      text: widget.settings.responseTimeout.inSeconds.toString(),
    );
    _secure = widget.settings.secure;
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _clientId.dispose();
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
                  '连接参数',
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
                      key: const Key('connection_host_field'),
                      controller: _host,
                      decoration: const InputDecoration(
                        labelText: '设备 IP',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearFeedback(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            key: const Key('connection_port_field'),
                            controller: _port,
                            decoration: const InputDecoration(
                              labelText: '端口',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _clearFeedback(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('connection_timeout_field'),
                            controller: _timeout,
                            decoration: const InputDecoration(
                              labelText: '超时秒数',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _clearFeedback(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('connection_client_id_field'),
                      controller: _clientId,
                      decoration: const InputDecoration(
                        labelText: '客户端 ID / chat_id 前缀',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _clearFeedback(),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _secure,
                      onChanged: (value) {
                        setState(() {
                          _secure = value;
                          _error = null;
                          _status = null;
                        });
                      },
                      secondary: const Icon(Icons.lock_outline),
                      title: const Text('WSS'),
                      subtitle: const Text('加密 WebSocket'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _SheetFeedback(
                    icon: Icons.error_outline,
                    message: _error!,
                    background: colors.errorContainer,
                    foreground: colors.onErrorContainer,
                    border: colors.error,
                  ),
                ],
                if (_status != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _SheetFeedback(
                    icon: Icons.check_circle_outline,
                    message: _status!,
                    background: colors.secondaryContainer,
                    foreground: colors.onSecondaryContainer,
                    border: colors.secondary,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTesting || widget.onTestConnection == null
                            ? null
                            : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: const Text('测试连接'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('save_connection_settings_button'),
                        onPressed: _isTesting ? null : _save,
                        icon: const Icon(Icons.check),
                        label: const Text('保存'),
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
      setState(() {
        _status = null;
        _error = error.message;
      });
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

  Future<void> _testConnection() async {
    final testConnection = widget.onTestConnection;
    if (testConnection == null) {
      return;
    }

    ChatConnectionSettings settings;
    try {
      settings = _parseSettings();
    } on ChatException catch (error) {
      setState(() {
        _status = null;
        _error = error.message;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _error = null;
      _status = null;
    });

    try {
      await testConnection(settings);
      if (!mounted) {
        return;
      }
      setState(() => _status = '连接成功');
    } on ChatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '连接测试失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  ChatConnectionSettings _parseSettings() {
    return ChatConnectionSettingsParser.parse(
      hostInput: _host.text,
      portInput: _port.text,
      clientIdInput: _clientId.text,
      timeoutSecondsInput: _timeout.text,
      secure: _secure,
    ).copyWith(otaSettings: widget.settings.otaSettings);
  }
}

class _SheetFeedback extends StatelessWidget {
  const _SheetFeedback({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, color: foreground, size: 18),
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
