import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

typedef TestNetworkProxyConnection = Future<void> Function(
  ChatNetworkProxySettings settings,
);

class NetworkProxyPage extends StatefulWidget {
  const NetworkProxyPage({
    this.settings = const ChatNetworkProxySettings(),
    this.onChanged,
    this.onTestConnection,
    super.key,
  });

  final ChatNetworkProxySettings settings;
  final ValueChanged<ChatNetworkProxySettings>? onChanged;
  final TestNetworkProxyConnection? onTestConnection;

  @override
  State<NetworkProxyPage> createState() => _NetworkProxyPageState();
}

class _NetworkProxyPageState extends State<NetworkProxyPage> {
  late final TextEditingController _server;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _bypass;
  late final TextEditingController _testUrl;

  late bool _enabled;
  late ChatNetworkProxyType _proxyType;
  String? _testMessage;
  bool _testSucceeded = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.enabled;
    _proxyType = widget.settings.type;
    _server = TextEditingController(text: widget.settings.server);
    _port = TextEditingController(text: widget.settings.port.toString());
    _username = TextEditingController(text: widget.settings.username);
    _password = TextEditingController(text: widget.settings.password);
    _bypass =
        TextEditingController(text: widget.settings.bypassRules.join(','));
    _testUrl = TextEditingController(text: widget.settings.testUrl);
  }

  @override
  void didUpdateWidget(covariant NetworkProxyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _enabled = widget.settings.enabled;
      _proxyType = widget.settings.type;
      _server.text = widget.settings.server;
      _port.text = widget.settings.port.toString();
      _username.text = widget.settings.username;
      _password.text = widget.settings.password;
      _bypass.text = widget.settings.bypassRules.join(',');
      _testUrl.text = widget.settings.testUrl;
    }
  }

  @override
  void dispose() {
    _server.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _bypass.dispose();
    _testUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '网络代理',
      actions: <Widget>[
        IconButton(
          key: const Key('network_proxy_save_button'),
          tooltip: '保存',
          onPressed: _save,
          icon: const Icon(Icons.check, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          _ProxyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '启动代理',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: settingsPrimaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Switch(
                      key: const Key('proxy_enabled_switch'),
                      value: _enabled,
                      onChanged: (value) {
                        setState(() {
                          _enabled = value;
                          _testMessage = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const _ProxyFieldLabel('代理类型'),
                DropdownButtonFormField<ChatNetworkProxyType>(
                  key: const Key('proxy_type_dropdown'),
                  initialValue: _proxyType,
                  decoration: _fieldDecoration(context),
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: ChatNetworkProxyType.values.map((type) {
                    return DropdownMenuItem<ChatNetworkProxyType>(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _proxyType = value;
                      _testMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 22),
                const _ProxyFieldLabel('服务器地址'),
                _ProxyTextField(
                  fieldKey: const Key('proxy_server_field'),
                  controller: _server,
                  hintText: '127.0.0.1',
                  keyboardType: TextInputType.url,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 22),
                const _ProxyFieldLabel('端口'),
                _ProxyTextField(
                  fieldKey: const Key('proxy_port_field'),
                  controller: _port,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 22),
                const _ProxyFieldLabel('用户名'),
                _ProxyTextField(
                  fieldKey: const Key('proxy_username_field'),
                  controller: _username,
                  hintText: '可选',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 22),
                const _ProxyFieldLabel('密码'),
                _ProxyTextField(
                  fieldKey: const Key('proxy_password_field'),
                  controller: _password,
                  hintText: '可选',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 22),
                const _ProxyFieldLabel('代理绕过'),
                _ProxyTextField(
                  fieldKey: const Key('proxy_bypass_field'),
                  controller: _bypass,
                  minLines: 2,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 16),
                Text(
                  '代理设置会应用于 BareBrain WebSocket、语音 HTTP 和 OTA 版本检查，命中绕过规则时使用直连。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: settingsSecondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              '连接测试',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsPrimaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          _ProxyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ProxyTextField(
                  fieldKey: const Key('proxy_test_url_field'),
                  controller: _testUrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearTestMessage(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('proxy_test_button'),
                    onPressed: _isTesting ? null : _testConnection,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xfff0f0f1),
                      foregroundColor: settingsPrimaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('测试'),
                  ),
                ),
                if (_testMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _ProxyFeedback(
                    succeeded: _testSucceeded,
                    message: _testMessage!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearTestMessage() {
    if (_testMessage == null) {
      return;
    }

    setState(() => _testMessage = null);
  }

  Future<void> _testConnection() async {
    final settings = _parseSettings(requireTestUrl: true);
    if (settings == null) {
      return;
    }

    final testConnection = widget.onTestConnection;
    if (testConnection == null) {
      final result = _configurationTestResult(settings);
      setState(() {
        _testSucceeded = result.succeeded;
        _testMessage = result.message;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testSucceeded = false;
      _testMessage = null;
    });

    try {
      await testConnection(settings);
      if (!mounted) {
        return;
      }
      setState(() {
        _testSucceeded = true;
        _testMessage = settings.enabled
            ? '连接测试成功：${settings.type.label} '
                '${settings.server}:${settings.port}'
            : '连接测试成功：当前为直连模式';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _testSucceeded = false;
        _testMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  _ProxyTestResult _configurationTestResult(
    ChatNetworkProxySettings settings,
  ) {
    return _ProxyTestResult(
      succeeded: true,
      message: settings.enabled
          ? '配置检查通过：${settings.type.label} '
              '${settings.server}:${settings.port}'
          : '配置检查通过：当前为直连模式',
    );
  }

  void _save() {
    final settings = _parseSettings();
    if (settings == null) {
      return;
    }

    setState(() {
      _enabled = settings.enabled;
      _proxyType = settings.type;
      _server.text = settings.server;
      _port.text = settings.port.toString();
      _username.text = settings.username;
      _password.text = settings.password;
      _bypass.text = settings.bypassRules.join(',');
      _testUrl.text = settings.testUrl;
      _testSucceeded = true;
      _testMessage = '网络代理设置已保存';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('网络代理设置已保存')),
    );
    widget.onChanged?.call(settings);
  }

  ChatNetworkProxySettings? _parseSettings({bool requireTestUrl = false}) {
    final testUrl = _testUrl.text.trim();
    final testUri = Uri.tryParse(testUrl);
    final testUrlIsInvalid = testUri == null ||
        testUri.host.isEmpty ||
        (testUri.scheme != 'http' && testUri.scheme != 'https');
    if (requireTestUrl && testUrlIsInvalid) {
      _setValidationMessage('测试地址必须是 http 或 https URL');
      return null;
    }

    final parsedPort = int.tryParse(_port.text.trim());
    final portIsInvalid =
        parsedPort == null || parsedPort <= 0 || parsedPort > 65535;
    if (_enabled && portIsInvalid) {
      _setValidationMessage('代理端口必须在 1 到 65535 之间');
      return null;
    }

    final rawServer = _server.text.trim();
    final serverIsInvalid =
        rawServer.contains(RegExp(r'\s')) || rawServer.contains('/');
    if (_enabled && serverIsInvalid) {
      _setValidationMessage('服务器地址只填写 IP 或主机名');
      return null;
    }
    final server =
        rawServer.isEmpty || serverIsInvalid ? '127.0.0.1' : rawServer;

    return ChatNetworkProxySettings(
      enabled: _enabled,
      type: _proxyType,
      server: server,
      port: portIsInvalid ? 8080 : parsedPort,
      username: _username.text.trim(),
      password: _password.text,
      bypassRules: _parseBypassRules(_bypass.text),
      testUrl:
          testUrlIsInvalid ? const ChatNetworkProxySettings().testUrl : testUrl,
    );
  }

  void _setValidationMessage(String message) {
    setState(() {
      _testSucceeded = false;
      _testMessage = message;
    });
  }

  List<String> _parseBypassRules(String source) {
    return source
        .split(RegExp(r'[,\n]'))
        .map((rule) => rule.trim())
        .where((rule) => rule.isNotEmpty)
        .toList(growable: false);
  }
}

class _ProxyCard extends StatelessWidget {
  const _ProxyCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: child,
      ),
    );
  }
}

class _ProxyFieldLabel extends StatelessWidget {
  const _ProxyFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: settingsSecondaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProxyTextField extends StatelessWidget {
  const _ProxyTextField({
    required this.fieldKey,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      decoration: _fieldDecoration(context, hintText: hintText),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: settingsPrimaryText,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _ProxyFeedback extends StatelessWidget {
  const _ProxyFeedback({
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

class _ProxyTestResult {
  const _ProxyTestResult({
    required this.succeeded,
    required this.message,
  });

  final bool succeeded;
  final String message;
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  String? hintText,
}) {
  const fillColor = Color(0xfff7f7f9);
  const borderColor = Color(0xfff0f0f3);
  final textTheme = Theme.of(context).textTheme;

  OutlineInputBorder border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    hintStyle: textTheme.titleMedium?.copyWith(
      color: const Color(0xff9b9ba3),
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: border(borderColor),
    focusedBorder: border(settingsPrimaryText),
    border: border(borderColor),
  );
}
