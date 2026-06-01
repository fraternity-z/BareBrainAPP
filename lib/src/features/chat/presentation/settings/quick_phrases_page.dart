import 'package:flutter/material.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'settings_components.dart';

class QuickPhrasesPage extends StatefulWidget {
  const QuickPhrasesPage({
    this.phrases = const <ChatQuickPhrase>[],
    this.onChanged,
    this.onPhraseSelected,
    super.key,
  });

  final List<ChatQuickPhrase> phrases;
  final ValueChanged<List<ChatQuickPhrase>>? onChanged;
  final ValueChanged<ChatQuickPhrase>? onPhraseSelected;

  @override
  State<QuickPhrasesPage> createState() => _QuickPhrasesPageState();
}

class _QuickPhrasesPageState extends State<QuickPhrasesPage> {
  late List<ChatQuickPhrase> _phrases;

  @override
  void initState() {
    super.initState();
    _phrases = List<ChatQuickPhrase>.of(widget.phrases);
  }

  @override
  void didUpdateWidget(covariant QuickPhrasesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrases != widget.phrases) {
      _phrases = List<ChatQuickPhrase>.of(widget.phrases);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '快捷短语',
      actions: <Widget>[
        IconButton(
          key: const Key('add_quick_phrase_button'),
          tooltip: '添加快捷短语',
          onPressed: _addPhrase,
          icon: const Icon(Icons.add, size: 24),
        ),
      ],
      child: _phrases.isEmpty
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: SettingsEmptyState(
                icon: Icons.flash_on_outlined,
                title: '暂无快捷短语',
                subtitle: '添加后可以在设置里管理，也可以从输入栏快速插入。',
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              itemCount: _phrases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final phrase = _phrases[index];
                return _QuickPhraseTile(
                  phrase: phrase,
                  onTap: widget.onPhraseSelected == null
                      ? () => _editPhrase(phrase)
                      : () => widget.onPhraseSelected?.call(phrase),
                  onEdit: () => _editPhrase(phrase),
                  onDelete: () => _deletePhrase(phrase.id),
                  onEnabledChanged: (enabled) {
                    _replacePhrase(phrase.copyWith(enabled: enabled));
                  },
                );
              },
            ),
    );
  }

  Future<void> _addPhrase() async {
    final phrase = await showModalBottomSheet<ChatQuickPhrase>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const QuickPhraseSheet(),
    );

    if (phrase == null || !mounted) {
      return;
    }

    setState(() => _phrases = <ChatQuickPhrase>[..._phrases, phrase]);
    _emit();
  }

  Future<void> _editPhrase(ChatQuickPhrase phrase) async {
    final next = await showModalBottomSheet<ChatQuickPhrase>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => QuickPhraseSheet(initialPhrase: phrase),
    );

    if (next == null || !mounted) {
      return;
    }

    _replacePhrase(next);
  }

  void _deletePhrase(String id) {
    setState(() {
      _phrases = _phrases.where((phrase) => phrase.id != id).toList();
    });
    _emit();
  }

  void _replacePhrase(ChatQuickPhrase next) {
    setState(() {
      _phrases = _phrases.map((phrase) {
        return phrase.id == next.id ? next : phrase;
      }).toList();
    });
    _emit();
  }

  void _emit() {
    widget.onChanged?.call(List<ChatQuickPhrase>.unmodifiable(_phrases));
  }
}

class _QuickPhraseTile extends StatelessWidget {
  const _QuickPhraseTile({
    required this.phrase,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onEnabledChanged,
  });

  final ChatQuickPhrase phrase;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(settingsCardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.flash_on_outlined,
                color: phrase.enabled
                    ? Theme.of(context).colorScheme.primary
                    : settingsSecondaryTextColor(context),
                size: 32,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      phrase.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: settingsPrimaryTextColor(context),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phrase.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: settingsSecondaryTextColor(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: Key('quick_phrase_enabled_${phrase.id}'),
                value: phrase.enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                key: Key('edit_quick_phrase_${phrase.id}'),
                tooltip: '编辑',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: Key('delete_quick_phrase_${phrase.id}'),
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

class QuickPhraseSheet extends StatefulWidget {
  const QuickPhraseSheet({
    this.initialPhrase,
    super.key,
  });

  final ChatQuickPhrase? initialPhrase;

  @override
  State<QuickPhraseSheet> createState() => _QuickPhraseSheetState();
}

class _QuickPhraseSheetState extends State<QuickPhraseSheet> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhrase;
    _title = TextEditingController(text: initial?.title ?? '');
    _content = TextEditingController(text: initial?.content ?? '');
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
                  widget.initialPhrase == null ? '添加快捷短语' : '编辑快捷短语',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: settingsPrimaryTextColor(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('quick_phrase_title_field'),
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('quick_phrase_content_field'),
                  controller: _content,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '内容',
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
                        key: const Key('save_quick_phrase_button'),
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

    final initial = widget.initialPhrase;
    Navigator.of(context).pop(
      ChatQuickPhrase(
        id: initial?.id ?? _newId(),
        title: title,
        content: content,
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
    return 'phrase-${DateTime.now().microsecondsSinceEpoch}';
  }
}
