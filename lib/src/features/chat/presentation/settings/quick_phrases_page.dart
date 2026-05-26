import 'package:flutter/material.dart';

import 'settings_components.dart';

class QuickPhrasesPage extends StatefulWidget {
  const QuickPhrasesPage({super.key});

  @override
  State<QuickPhrasesPage> createState() => _QuickPhrasesPageState();
}

class _QuickPhrasesPageState extends State<QuickPhrasesPage> {
  final List<QuickPhrase> _phrases = <QuickPhrase>[
    const QuickPhrase(title: 'ejej', content: '哎啊啊快啊'),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '快捷短语',
      actions: <Widget>[
        IconButton(
          key: const Key('add_quick_phrase_button'),
          tooltip: '添加快捷短语',
          onPressed: _addPhrase,
          style: IconButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.transparent,
            fixedSize: const Size.square(42),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.add, size: 32),
        ),
      ],
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        itemCount: _phrases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final phrase = _phrases[index];
          return _QuickPhraseTile(phrase: phrase);
        },
      ),
    );
  }

  Future<void> _addPhrase() async {
    final phrase = await showModalBottomSheet<QuickPhrase>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const QuickPhraseSheet(),
    );

    if (phrase == null || !mounted) {
      return;
    }

    setState(() => _phrases.add(phrase));
  }
}

class QuickPhrase {
  const QuickPhrase({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

class _QuickPhraseTile extends StatelessWidget {
  const _QuickPhraseTile({
    required this.phrase,
  });

  final QuickPhrase phrase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.flash_on_outlined,
              color: Theme.of(context).colorScheme.primary,
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
                          color: settingsPrimaryText,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phrase.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: settingsSecondaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              color: settingsSecondaryText,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickPhraseSheet extends StatefulWidget {
  const QuickPhraseSheet({super.key});

  @override
  State<QuickPhraseSheet> createState() => _QuickPhraseSheetState();
}

class _QuickPhraseSheetState extends State<QuickPhraseSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  String? _error;

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
                  '添加快捷短语',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: settingsPrimaryText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('quick_phrase_title_field'),
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
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

    Navigator.of(context).pop(
      QuickPhrase(title: title, content: content),
    );
  }
}
