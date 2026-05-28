import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

class ChatStoragePage extends StatefulWidget {
  const ChatStoragePage({
    this.settings = const ChatStorageSettings(),
    this.onChanged,
    super.key,
  });

  final ChatStorageSettings settings;
  final ValueChanged<ChatStorageSettings>? onChanged;

  @override
  State<ChatStoragePage> createState() => _ChatStoragePageState();
}

class _ChatStoragePageState extends State<ChatStoragePage> {
  late ChatStorageSettings _settings;
  late final TextEditingController _maxLocalConversations;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _maxLocalConversations = TextEditingController(
      text: _settings.maxLocalConversations.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant ChatStoragePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
      _maxLocalConversations.text = _settings.maxLocalConversations.toString();
    }
  }

  @override
  void dispose() {
    _maxLocalConversations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '聊天记录存储',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsFormPanel(
            children: <Widget>[
              SwitchListTile(
                key: const Key('storage_auto_save_switch'),
                value: _settings.autoSaveConversations,
                onChanged: (value) {
                  _update(_settings.copyWith(autoSaveConversations: value));
                },
                title: const Text('自动保存会话'),
                secondary: const Icon(Icons.save_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('storage_save_drafts_switch'),
                value: _settings.saveDrafts,
                onChanged: (value) {
                  _update(_settings.copyWith(saveDrafts: value));
                },
                title: const Text('保存输入草稿'),
                secondary: const Icon(Icons.edit_note_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ChatStorageRetentionPolicy>(
                key: const Key('storage_retention_dropdown'),
                initialValue: _settings.retentionPolicy,
                decoration: const InputDecoration(
                  labelText: '保留策略',
                  prefixIcon: Icon(Icons.history_outlined),
                ),
                items: ChatStorageRetentionPolicy.values.map((policy) {
                  return DropdownMenuItem<ChatStorageRetentionPolicy>(
                    value: policy,
                    child: Text(policy.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _update(_settings.copyWith(retentionPolicy: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('storage_max_conversations_field'),
                controller: _maxLocalConversations,
                decoration: const InputDecoration(
                  labelText: '最多本机会话数',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _trySaveMaxLocalConversations(),
                onSubmitted: (_) => _saveMaxLocalConversations(),
                onEditingComplete: _saveMaxLocalConversations,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveMaxLocalConversations() {
    final value = int.tryParse(_maxLocalConversations.text.trim());
    if (value == null) {
      _maxLocalConversations.text = _settings.maxLocalConversations.toString();
      return;
    }

    final next = _settings.copyWith(maxLocalConversations: value);
    _update(next);
    _maxLocalConversations.text = next.maxLocalConversations.toString();
  }

  void _trySaveMaxLocalConversations() {
    final value = int.tryParse(_maxLocalConversations.text.trim());
    if (value == null) {
      return;
    }

    _update(_settings.copyWith(maxLocalConversations: value));
  }

  void _update(ChatStorageSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }
}
