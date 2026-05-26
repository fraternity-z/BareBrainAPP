import 'package:flutter/material.dart';

import 'settings_components.dart';

class NetworkProxyPage extends StatefulWidget {
  const NetworkProxyPage({super.key});

  @override
  State<NetworkProxyPage> createState() => _NetworkProxyPageState();
}

enum _NetworkProxyType {
  http('HTTP'),
  https('HTTPS'),
  socks5('SOCKS5');

  const _NetworkProxyType(this.label);

  final String label;
}

class _NetworkProxyPageState extends State<NetworkProxyPage> {
  static const _defaultServer = '127.0.0.1';
  static const _defaultBypassRules =
      'localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,'
      '192.168.0.0/16,::1';

  final TextEditingController _server = TextEditingController();
  final TextEditingController _port = TextEditingController(text: '8080');
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _bypass = TextEditingController(
    text: _defaultBypassRules,
  );
  final TextEditingController _testUrl = TextEditingController(
    text: 'https://www.google.com',
  );

  var _enabled = false;
  var _proxyType = _NetworkProxyType.http;
  String? _testMessage;
  bool _testSucceeded = false;

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
                DropdownButtonFormField<_NetworkProxyType>(
                  key: const Key('proxy_type_dropdown'),
                  initialValue: _proxyType,
                  decoration: _fieldDecoration(context),
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _NetworkProxyType.values.map((type) {
                    return DropdownMenuItem<_NetworkProxyType>(
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
                  hintText: _defaultServer,
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
                  '当同时开启全局代理与供应商代理时，将优先使用供应商代理。',
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
                    onPressed: _testConnection,
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
                    child: const Text('测试'),
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

  void _testConnection() {
    final result = _validateTestConfiguration();
    setState(() {
      _testSucceeded = result.succeeded;
      _testMessage = result.message;
    });
  }

  _ProxyTestResult _validateTestConfiguration() {
    final testUri = Uri.tryParse(_testUrl.text.trim());
    if (testUri == null ||
        testUri.host.isEmpty ||
        (testUri.scheme != 'http' && testUri.scheme != 'https')) {
      return const _ProxyTestResult(
        succeeded: false,
        message: '测试地址必须是 http 或 https URL',
      );
    }

    final port = int.tryParse(_port.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      return const _ProxyTestResult(
        succeeded: false,
        message: '代理端口必须在 1 到 65535 之间',
      );
    }

    final server =
        _server.text.trim().isEmpty ? _defaultServer : _server.text.trim();
    if (server.contains(RegExp(r'\s')) || server.contains('/')) {
      return const _ProxyTestResult(
        succeeded: false,
        message: '服务器地址只填写 IP 或主机名',
      );
    }

    return _ProxyTestResult(
      succeeded: true,
      message: _enabled
          ? '配置检查通过：${_proxyType.label} $server:$port'
          : '配置检查通过：当前为直连模式',
    );
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
