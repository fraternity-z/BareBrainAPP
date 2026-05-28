import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

class WorldBookPage extends StatefulWidget {
  const WorldBookPage({
    this.settings = const ChatWorldBookSettings(),
    this.onChanged,
    super.key,
  });

  final ChatWorldBookSettings settings;
  final ValueChanged<ChatWorldBookSettings>? onChanged;

  @override
  State<WorldBookPage> createState() => _WorldBookPageState();
}

class _WorldBookPageState extends State<WorldBookPage> {
  late ChatWorldBookSettings _settings;
  late final TextEditingController _maxActiveEntries;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _maxActiveEntries = TextEditingController(
      text: _settings.maxActiveEntries.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant WorldBookPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
      _maxActiveEntries.text = _settings.maxActiveEntries.toString();
    }
  }

  @override
  void dispose() {
    _maxActiveEntries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '世界书',
      actions: <Widget>[
        IconButton(
          key: const Key('add_world_book_entry_button'),
          tooltip: '添加世界书条目',
          onPressed: _addEntry,
          icon: const Icon(Icons.add, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          SettingsFormPanel(
            children: <Widget>[
              SwitchListTile(
                key: const Key('world_book_enabled_switch'),
                value: _settings.enabled,
                onChanged: (value) {
                  _update(_settings.copyWith(enabled: value));
                },
                title: const Text('启用世界书'),
                secondary: const Icon(Icons.menu_book_outlined),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('world_book_max_entries_field'),
                controller: _maxActiveEntries,
                decoration: const InputDecoration(
                  labelText: '单次最多激活条目',
                  prefixIcon: Icon(Icons.filter_list_outlined),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _trySaveMaxActiveEntries(),
                onSubmitted: (_) => _saveMaxActiveEntries(),
                onEditingComplete: _saveMaxActiveEntries,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_settings.entries.isEmpty)
            const SettingsEmptyState(
              icon: Icons.menu_book_outlined,
              title: '暂无世界书条目',
              subtitle: '添加角色、地点或规则信息后，可按关键词启用上下文。',
            )
          else
            ..._settings.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorldBookEntryTile(
                  entry: entry,
                  onTap: () => _editEntry(entry),
                  onEnabledChanged: (enabled) {
                    _replaceEntry(entry.copyWith(enabled: enabled));
                  },
                  onDelete: () => _deleteEntry(entry.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _addEntry() async {
    final entry = await showModalBottomSheet<ChatWorldBookEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const WorldBookEntrySheet(),
    );

    if (entry == null || !mounted) {
      return;
    }

    _update(
      _settings.copyWith(
        entries: <ChatWorldBookEntry>[..._settings.entries, entry],
      ),
    );
  }

  Future<void> _editEntry(ChatWorldBookEntry entry) async {
    final next = await showModalBottomSheet<ChatWorldBookEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => WorldBookEntrySheet(initialEntry: entry),
    );

    if (next == null || !mounted) {
      return;
    }

    _replaceEntry(next);
  }

  void _replaceEntry(ChatWorldBookEntry next) {
    _update(
      _settings.copyWith(
        entries: _settings.entries.map((entry) {
          return entry.id == next.id ? next : entry;
        }).toList(growable: false),
      ),
    );
  }

  void _deleteEntry(String id) {
    _update(
      _settings.copyWith(
        entries: _settings.entries
            .where((entry) => entry.id != id)
            .toList(growable: false),
      ),
    );
  }

  void _saveMaxActiveEntries() {
    final value = int.tryParse(_maxActiveEntries.text.trim());
    if (value == null) {
      _maxActiveEntries.text = _settings.maxActiveEntries.toString();
      return;
    }

    final next = _settings.copyWith(maxActiveEntries: value);
    _update(next);
    _maxActiveEntries.text = next.maxActiveEntries.toString();
  }

  void _trySaveMaxActiveEntries() {
    final value = int.tryParse(_maxActiveEntries.text.trim());
    if (value == null) {
      return;
    }

    _update(_settings.copyWith(maxActiveEntries: value));
  }

  void _update(ChatWorldBookSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }
}

class _WorldBookEntryTile extends StatelessWidget {
  const _WorldBookEntryTile({
    required this.entry,
    required this.onTap,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final ChatWorldBookEntry entry;
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
                Icons.auto_stories_outlined,
                color: entry.enabled
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
                      entry.title,
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
                      entry.keywords.isEmpty
                          ? '始终可用'
                          : entry.keywords.join(' / '),
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
                      entry.content,
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
                key: Key('world_book_entry_enabled_${entry.id}'),
                value: entry.enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                key: Key('delete_world_book_entry_${entry.id}'),
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

class WorldBookEntrySheet extends StatefulWidget {
  const WorldBookEntrySheet({
    this.initialEntry,
    super.key,
  });

  final ChatWorldBookEntry? initialEntry;

  @override
  State<WorldBookEntrySheet> createState() => _WorldBookEntrySheetState();
}

class _WorldBookEntrySheetState extends State<WorldBookEntrySheet> {
  late final TextEditingController _title;
  late final TextEditingController _keywords;
  late final TextEditingController _content;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEntry;
    _title = TextEditingController(text: initial?.title ?? '');
    _keywords = TextEditingController(text: initial?.keywords.join(',') ?? '');
    _content = TextEditingController(text: initial?.content ?? '');
    _enabled = initial?.enabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _keywords.dispose();
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
                  widget.initialEntry == null ? '添加世界书条目' : '编辑世界书条目',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: settingsPrimaryText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('world_book_entry_title_field'),
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('world_book_entry_keywords_field'),
                  controller: _keywords,
                  decoration: const InputDecoration(
                    labelText: '关键词',
                    hintText: '多个关键词用逗号分隔；留空则始终可用',
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('world_book_entry_content_field'),
                  controller: _content,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: '内容',
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
                        key: const Key('save_world_book_entry_button'),
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

    final initial = widget.initialEntry;
    Navigator.of(context).pop(
      ChatWorldBookEntry(
        id: initial?.id ?? _newId(),
        title: title,
        content: content,
        keywords: _parseList(_keywords.text),
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

  List<String> _parseList(String source) {
    return source
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String _newId() {
    return 'world-${DateTime.now().microsecondsSinceEpoch}';
  }
}
