import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

class PromptInjectionPage extends StatefulWidget {
  const PromptInjectionPage({
    this.settings = const ChatPromptInjectionSettings(),
    this.onChanged,
    super.key,
  });

  final ChatPromptInjectionSettings settings;
  final ValueChanged<ChatPromptInjectionSettings>? onChanged;

  @override
  State<PromptInjectionPage> createState() => _PromptInjectionPageState();
}

class _PromptInjectionPageState extends State<PromptInjectionPage> {
  late ChatPromptInjectionSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant PromptInjectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '指令注入',
      actions: <Widget>[
        IconButton(
          key: const Key('add_prompt_rule_button'),
          tooltip: '添加指令',
          onPressed: _addRule,
          icon: const Icon(Icons.add, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsFormPanel(
            children: <Widget>[
              SwitchListTile(
                key: const Key('prompt_injection_enabled_switch'),
                value: _settings.enabled,
                onChanged: (value) {
                  _update(_settings.copyWith(enabled: value));
                },
                title: const Text('启用指令注入'),
                secondary: const Icon(Icons.layers_outlined),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_settings.rules.isEmpty)
            const SettingsEmptyState(
              icon: Icons.layers_outlined,
              title: '暂无注入指令',
              subtitle: '添加后可在发送前组合系统、用户或后置提示片段。',
            )
          else
            ..._settings.rules.map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PromptRuleTile(
                  rule: rule,
                  onTap: () => _editRule(rule),
                  onEnabledChanged: (enabled) {
                    _replaceRule(rule.copyWith(enabled: enabled));
                  },
                  onDelete: () => _deleteRule(rule.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _addRule() async {
    final rule = await showModalBottomSheet<ChatPromptInjectionRule>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PromptRuleSheet(),
    );

    if (rule == null || !mounted) {
      return;
    }

    _update(
      _settings.copyWith(
        rules: <ChatPromptInjectionRule>[..._settings.rules, rule],
      ),
    );
  }

  Future<void> _editRule(ChatPromptInjectionRule rule) async {
    final next = await showModalBottomSheet<ChatPromptInjectionRule>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => PromptRuleSheet(initialRule: rule),
    );

    if (next == null || !mounted) {
      return;
    }

    _replaceRule(next);
  }

  void _replaceRule(ChatPromptInjectionRule next) {
    _update(
      _settings.copyWith(
        rules: _settings.rules.map((rule) {
          return rule.id == next.id ? next : rule;
        }).toList(growable: false),
      ),
    );
  }

  void _deleteRule(String id) {
    _update(
      _settings.copyWith(
        rules: _settings.rules
            .where((rule) => rule.id != id)
            .toList(growable: false),
      ),
    );
  }

  void _update(ChatPromptInjectionSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }
}

class _PromptRuleTile extends StatelessWidget {
  const _PromptRuleTile({
    required this.rule,
    required this.onTap,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final ChatPromptInjectionRule rule;
  final VoidCallback onTap;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.layers_outlined,
                color: rule.enabled
                    ? Theme.of(context).colorScheme.primary
                    : settingsSecondaryText,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      rule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: settingsPrimaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rule.position.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: settingsSecondaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rule.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: settingsSecondaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: Key('prompt_rule_enabled_${rule.id}'),
                value: rule.enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                key: Key('delete_prompt_rule_${rule.id}'),
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromptRuleSheet extends StatefulWidget {
  const PromptRuleSheet({
    this.initialRule,
    super.key,
  });

  final ChatPromptInjectionRule? initialRule;

  @override
  State<PromptRuleSheet> createState() => _PromptRuleSheetState();
}

class _PromptRuleSheetState extends State<PromptRuleSheet> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late ChatPromptInjectionPosition _position;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRule;
    _title = TextEditingController(text: initial?.title ?? '');
    _content = TextEditingController(text: initial?.content ?? '');
    _position = initial?.position ?? ChatPromptInjectionPosition.systemPrefix;
    _enabled = initial?.enabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
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
                  widget.initialRule == null ? '添加注入指令' : '编辑注入指令',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: settingsPrimaryText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('prompt_rule_title_field'),
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChatPromptInjectionPosition>(
                  key: const Key('prompt_rule_position_dropdown'),
                  initialValue: _position,
                  decoration: const InputDecoration(
                    labelText: '注入位置',
                    prefixIcon: Icon(Icons.call_split_outlined),
                  ),
                  items: ChatPromptInjectionPosition.values.map((position) {
                    return DropdownMenuItem<ChatPromptInjectionPosition>(
                      value: position,
                      child: Text(position.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _position = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('prompt_rule_content_field'),
                  controller: _content,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: '指令内容',
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  title: const Text('启用'),
                  secondary: const Icon(Icons.check_circle_outline),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
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
                        key: const Key('save_prompt_rule_button'),
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
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = '标题和内容不能为空');
      return;
    }

    final initial = widget.initialRule;
    Navigator.of(context).pop(
      ChatPromptInjectionRule(
        id: initial?.id ?? _newId(),
        title: title,
        content: content,
        position: _position,
        enabled: _enabled,
      ),
    );
  }

  void _clearError() {
    if (_error == null) {
      return;
    }

    setState(() => _error = null);
  }

  String _newId() {
    return 'prompt-${DateTime.now().microsecondsSinceEpoch}';
  }
}
