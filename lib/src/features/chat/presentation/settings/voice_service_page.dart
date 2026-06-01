import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

typedef TestVoiceService = Future<void> Function(ChatVoiceSettings settings);

class VoiceServicePage extends StatefulWidget {
  const VoiceServicePage({
    this.settings = const ChatVoiceSettings(),
    this.onChanged,
    this.onTestVoiceService,
    super.key,
  });

  final ChatVoiceSettings settings;
  final ValueChanged<ChatVoiceSettings>? onChanged;
  final TestVoiceService? onTestVoiceService;

  @override
  State<VoiceServicePage> createState() => _VoiceServicePageState();
}

class _VoiceServicePageState extends State<VoiceServicePage> {
  late ChatVoiceSettings _settings;
  late final TextEditingController _endpoint;
  late final TextEditingController _speaker;
  late final TextEditingController _timeout;
  String? _feedback;
  bool _feedbackSucceeded = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _endpoint = TextEditingController(text: _settings.endpoint);
    _speaker = TextEditingController(text: _settings.speaker);
    _timeout = TextEditingController(
      text: _settings.timeout.inSeconds.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceServicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
      _endpoint.text = _settings.endpoint;
      _speaker.text = _settings.speaker;
      _timeout.text = _settings.timeout.inSeconds.toString();
    }
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _speaker.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '语音服务',
      actions: <Widget>[
        IconButton(
          key: const Key('voice_service_save_button'),
          tooltip: '保存',
          onPressed: _save,
          icon: const Icon(Icons.check, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsFormPanel(
            children: <Widget>[
              SwitchListTile(
                key: const Key('voice_enabled_switch'),
                value: _settings.enabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(enabled: value);
                    _feedback = null;
                  });
                },
                title: const Text('启用语音服务'),
                secondary: const Icon(Icons.volume_up_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ChatVoiceProvider>(
                key: const Key('voice_provider_dropdown'),
                initialValue: _settings.provider,
                decoration: const InputDecoration(
                  labelText: '服务类型',
                  prefixIcon: Icon(Icons.record_voice_over_outlined),
                ),
                items: ChatVoiceProvider.values.map((provider) {
                  return DropdownMenuItem<ChatVoiceProvider>(
                    value: provider,
                    child: Text(provider.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _settings = _settings.copyWith(provider: value);
                    _feedback = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('voice_endpoint_field'),
                controller: _endpoint,
                decoration: const InputDecoration(
                  labelText: '服务地址',
                  hintText: 'https://voice.example.com',
                  prefixIcon: Icon(Icons.link_outlined),
                  helperText: '保存后会在收到助手回复时 POST 文本到该地址。',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('voice_speaker_field'),
                controller: _speaker,
                decoration: const InputDecoration(
                  labelText: '默认音色',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('voice_timeout_field'),
                controller: _timeout,
                decoration: const InputDecoration(
                  labelText: '超时秒数',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('voice_streaming_switch'),
                value: _settings.streaming,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(streaming: value);
                    _feedback = null;
                  });
                },
                title: const Text('流式播放'),
                secondary: const Icon(Icons.graphic_eq_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('voice_service_test_button'),
                  onPressed: _isTesting ? null : _testVoiceService,
                  icon: _isTesting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('测试语音服务'),
                ),
              ),
            ],
          ),
          if (_feedback != null) ...<Widget>[
            const SizedBox(height: 14),
            _VoiceFeedback(
              succeeded: _feedbackSucceeded,
              message: _feedback!,
            ),
          ],
        ],
      ),
    );
  }

  void _clearFeedback() {
    if (_feedback == null) {
      return;
    }
    setState(() => _feedback = null);
  }

  void _save() {
    final parsed = _parse();
    if (parsed == null) {
      return;
    }

    setState(() {
      _settings = parsed;
      _endpoint.text = parsed.endpoint;
      _speaker.text = parsed.speaker;
      _timeout.text = parsed.timeout.inSeconds.toString();
      _feedbackSucceeded = true;
      _feedback = parsed.enabled ? '语音服务设置已保存' : '语音服务已关闭';
    });
    widget.onChanged?.call(parsed);
  }

  Future<void> _testVoiceService() async {
    final parsed = _parse(requireEndpoint: true);
    if (parsed == null) {
      return;
    }

    final testVoiceService = widget.onTestVoiceService;
    if (testVoiceService == null) {
      setState(() {
        _feedbackSucceeded = true;
        _feedback = '语音服务配置检查通过';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _feedback = null;
    });

    try {
      await testVoiceService(parsed.copyWith(enabled: true));
      if (!mounted) {
        return;
      }
      setState(() {
        _feedbackSucceeded = true;
        _feedback = '语音服务测试成功';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _feedbackSucceeded = false;
        _feedback = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  ChatVoiceSettings? _parse({bool requireEndpoint = false}) {
    final timeout = int.tryParse(_timeout.text.trim());
    final timeoutIsInvalid = timeout == null || timeout <= 0 || timeout > 60;
    if ((_settings.enabled || requireEndpoint) && timeoutIsInvalid) {
      setState(() {
        _feedbackSucceeded = false;
        _feedback = '超时秒数必须在 1 到 60 之间';
      });
      return null;
    }

    final endpoint = _endpoint.text.trim();
    if ((_settings.enabled || requireEndpoint) && !_isHttpUrl(endpoint)) {
      setState(() {
        _feedbackSucceeded = false;
        _feedback = '自定义语音服务需要填写 http 或 https 地址';
      });
      return null;
    }

    final speaker = _speaker.text.trim();
    return _settings.copyWith(
      endpoint: endpoint,
      speaker: speaker.isEmpty ? '默认' : speaker,
      timeout:
          timeoutIsInvalid ? _settings.timeout : Duration(seconds: timeout),
    );
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _VoiceFeedback extends StatelessWidget {
  const _VoiceFeedback({
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
