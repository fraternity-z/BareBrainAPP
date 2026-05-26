import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/chat_conversation_summary.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_sheet.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.controller,
    super.key,
  });

  final ChatController controller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _composerConversationId;

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncComposerForConversation();
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            return Scaffold(
              drawer: wide
                  ? null
                  : Drawer(
                      width: 320,
                      child: SafeArea(
                        child: _Sidebar(
                          controller: widget.controller,
                          closeAfterAction: true,
                          showBorder: false,
                          width: double.infinity,
                        ),
                      ),
                    ),
              body: SafeArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (wide) _Sidebar(controller: widget.controller),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Builder(
                              builder: (scaffoldContext) {
                                return _Header(
                                  settings: widget.controller.settings,
                                  onSettingsPressed: _openSettings,
                                  onClearPressed: widget.controller.clear,
                                  onMenuPressed: wide
                                      ? null
                                      : () {
                                          Scaffold.of(scaffoldContext)
                                              .openDrawer();
                                        },
                                );
                              },
                            ),
                            _StatusBanner(controller: widget.controller),
                            Expanded(
                              child: _MessageList(
                                controller: widget.controller,
                                onCopyMessage: (content) {
                                  unawaited(_copyMessage(content));
                                },
                                scrollController: _scrollController,
                              ),
                            ),
                            _Composer(
                              controller: widget.controller,
                              textController: _composer,
                              onChanged: widget.controller.updateDraft,
                              onSend: _send,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _composer.text;
    _composer.clear();
    widget.controller.updateDraft('');
    await widget.controller.send(text);
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _syncComposerForConversation() {
    final conversationId = widget.controller.conversationId;
    final draft = widget.controller.draft;
    if (_composerConversationId == conversationId && _composer.text == draft) {
      return;
    }

    _composerConversationId = conversationId;
    _composer.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  Future<void> _openSettings() async {
    final settings = await showModalBottomSheet<ChatConnectionSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SettingsSheet(
          settings: widget.controller.settings,
          onTestConnection: widget.controller.testConnection,
        );
      },
    );

    if (settings != null) {
      if (!mounted) {
        return;
      }
      widget.controller.updateSettings(settings);
    }
  }

  Future<void> _copyMessage(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.controller,
  });

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message =
        controller.isSending ? '正在等待 BareBrain 回复' : controller.errorMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    final isError = !controller.isSending;
    final background =
        isError ? colors.errorContainer : colors.secondaryContainer;
    final foreground =
        isError ? colors.onErrorContainer : colors.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isError ? colors.error : colors.secondary,
            width: 0.7,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(
                isError ? Icons.error_outline : Icons.hourglass_empty,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (isError && controller.canRetryLastMessage) ...<Widget>[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => unawaited(controller.retryLastUserMessage()),
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.controller,
    this.closeAfterAction = false,
    this.showBorder = true,
    this.width = 280,
  });

  final ChatController controller;
  final bool closeAfterAction;
  final bool showBorder;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: showBorder
            ? Border(
                right: BorderSide(color: colors.outlineVariant),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: <Widget>[
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_alt_outlined,
                    color: colors.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BareBrain',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: '新建会话',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    foregroundColor: colors.onSurface,
                  ),
                  onPressed: () {
                    unawaited(controller.createConversation());
                    if (closeAfterAction) {
                      unawaited(Navigator.of(context).maybePop());
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _ConnectionTile(
            settings: controller.settings,
            chatId: controller.bareBrainChatId,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '会话',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: _ConversationList(
              controller: controller,
              closeAfterSelection: closeAfterAction,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: controller.clear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('清空'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.controller,
    required this.closeAfterSelection,
  });

  final ChatController controller;
  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context) {
    final conversations = controller.conversations;
    if (conversations.isEmpty) {
      return const Center(
        child: Icon(Icons.chat_bubble_outline, size: 32),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(
          conversation: conversation,
          selected: conversation.id == controller.conversationId,
          onRename: () => unawaited(
            _showRenameDialog(context, controller, conversation),
          ),
          onDelete: conversation.id == controller.conversationId
              ? null
              : () => unawaited(
                    controller.deleteConversation(conversation.id),
                  ),
          onTap: () {
            unawaited(controller.selectConversation(conversation.id));
            if (closeAfterSelection) {
              unawaited(Navigator.of(context).maybePop());
            }
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ChatConversationSummary conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = conversation.lastMessagePreview.isEmpty
        ? conversation.settings.websocketUri.toString()
        : conversation.lastMessagePreview;

    return ListTile(
      tileColor: colors.surfaceContainerLowest,
      selected: selected,
      selectedTileColor: colors.primaryContainer,
      leading: Icon(
        Icons.chat_outlined,
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              conversation.messageCount.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: '重命名会话',
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined),
            visualDensity: VisualDensity.compact,
          ),
          if (onDelete != null) ...<Widget>[
            const SizedBox(width: 4),
            IconButton(
              tooltip: '删除会话',
              onPressed: onDelete,
              icon: const Icon(Icons.close),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      onTap: selected ? null : onTap,
    );
  }
}

Future<void> _showRenameDialog(
  BuildContext context,
  ChatController controller,
  ChatConversationSummary conversation,
) async {
  final textController = TextEditingController(text: conversation.title);
  final nextTitle = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '会话标题',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
  textController.dispose();

  if (nextTitle == null) {
    return;
  }

  await controller.renameConversation(conversation.id, nextTitle);
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.settings,
    required this.chatId,
  });

  final ChatConnectionSettings settings;
  final String chatId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ListTile(
          leading: Icon(Icons.lan, color: colors.secondary),
          title: Text(
            settings.websocketUri.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'chat_id: $chatId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              settings.secure ? 'WSS' : 'WS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.settings,
    required this.onSettingsPressed,
    required this.onClearPressed,
    this.onMenuPressed,
  });

  final ChatConnectionSettings settings;
  final VoidCallback onSettingsPressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (onMenuPressed != null) ...<Widget>[
            IconButton(
              tooltip: '会话',
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '局域网聊天',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  settings.websocketUri.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '连接设置',
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHigh,
            ),
            onPressed: onSettingsPressed,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '清空会话',
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHigh,
            ),
            onPressed: onClearPressed,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.onCopyMessage,
    required this.scrollController,
  });

  final ChatController controller;
  final ValueChanged<String> onCopyMessage;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (controller.messages.isEmpty) {
      return Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.forum_outlined,
                size: 34,
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无消息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'BareBrain',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      itemCount: controller.messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return MessageBubble(
          message: controller.messages[index],
          onCopy: () => onCopyMessage(controller.messages[index].content),
          onRetry: controller.canRetryLastMessage &&
                  index == controller.messages.length - 2
              ? () => unawaited(controller.retryLastUserMessage())
              : null,
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.textController,
    required this.onChanged,
    required this.onSend,
  });

  final ChatController controller;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: textController,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: '发给 BareBrain',
                prefixIcon: Icon(
                  Icons.mode_comment_outlined,
                  color: colors.onSurfaceVariant,
                ),
                isDense: true,
              ),
              enabled: !controller.isSending,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: controller.isSending ? null : onSend,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: controller.isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
